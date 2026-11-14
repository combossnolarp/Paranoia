local Blossom = ...

local ASSET_BASE = "https://raw.githubusercontent.com/combossnolarp/Paranoia/claude/wizardly-dijkstra-5vzykn/assets/"
local ASSET_FOLDER = "Paranoia/assets_v2"
local ICON_KEYS = {
	"rage", "ragebot", "silent", "antiaim", "targeting", "legit", "aimassist", "recoil", "trigger",
	"players", "effects", "local", "world", "movement", "speed", "bhop", "exploits", "plugins", "settings",
	"profiles", "autoload", "theming", "menu", "background",
	"esp", "preview", "misc", "character", "weaponmods", "automation",
}
local ASSET_LIST = {
	"logo_base.png", "logo_tint.png", "logo_anim_base.png", "logo_anim_tint.png",
	"fx/snow.png", "fx/flake.png", "fx/petal.png", "fx/blossom.png", "fx/leaf.png", "fx/rain.png", "fx/star.png", "fx/glow.png",
	"esp/preview.png", "fonts/Anton-Regular.ttf",
}
for _, key in ipairs(ICON_KEYS) do
	table.insert(ASSET_LIST, "icons/" .. key .. ".png")
end

local Assets = {}
local AssetFiles = {}
local GetAsset = getcustomasset or getsynasset

local function validAsset(path, data)
	if type(data) ~= "string" or #data < 4 then return false end
	if string.sub(path, -4) == ".png" then return string.sub(data, 2, 4) == "PNG" end
	local magic = string.sub(data, 1, 4)
	return magic == "\0\1\0\0" or magic == "OTTO" or magic == "true"
end

do
	local getAsset = GetAsset
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
						if not validAsset(path, data) then return nil end
						writefile(file, data)
					end
					return getAsset(file)
				end)
				if ok and result then
					Assets[path] = result
					AssetFiles[path] = file
				end
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

		src = replacePlain(src,
			"\tlocal keybind, color\n\tif options.Color then\n",
			"\tlocal keybind, color\n\tif options.Colors then\n\t\titem.ExtraColors = {}\n\t\tfor index = #options.Colors, 1, -1 do\n\t\t\titem.ExtraColors[index] = attachColor(section, item, { Default = options.Colors[index], Callback = options.ColorCallbacks and options.ColorCallbacks[index] })\n\t\tend\n\tend\n\tif options.Color then\n")

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

		src = replacePlain(src, [==[	button.MouseButton1Click:Connect(function()
		object.Listening = true
		win.Listening = object
		object.Refresh()
	end)
	button.MouseButton2Click:Connect(function() win:OpenKeybindMenu(chip, object) end)]==], [==[	function object.StartListening()
		object.Listening = true
		win.Listening = object
		object.Refresh()
	end
	local holdId, held = 0, false
	local function startHold()
		holdId += 1
		held = false
		local id = holdId
		task.delay(0.35, function()
			if holdId == id and button.Parent and not held then
				held = true
				win:OpenKeybindMenu(chip, object)
			end
		end)
	end
	local function cancelHold() holdId += 1 end
	button.MouseButton1Down:Connect(startHold)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then startHold() end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then cancelHold() end
	end)
	button.TouchLongPress:Connect(function(_, state)
		if state == Enum.UserInputState.Begin and not held then
			held = true
			win:OpenKeybindMenu(chip, object)
		end
	end)
	button.MouseButton1Click:Connect(function()
		if held then held = false return end
		win:OpenKeybindMenu(chip, object)
	end)
	button.MouseButton2Click:Connect(function() win:OpenKeybindMenu(chip, object) end)]==])

		src = replacePlain(src,
			"\t\t\tif toggle.Keybind.Mode == \"Hold\" then toggle:Set(true) else toggle:Set(not toggle.Value) end\n\t\tend\n\t\ttoggle.Keybind.OnRelease = function()\n\t\t\tif toggle.Keybind.Mode == \"Hold\" then toggle:Set(false) end\n\t\tend",
			"\t\t\tlocal mode = toggle.Keybind.Mode\n\t\t\tif mode == \"Always\" then return end\n\t\t\tif mode == \"Hold\" then toggle:Set(true) else toggle:Set(not toggle.Value) end\n\t\tend\n\t\ttoggle.Keybind.OnRelease = function()\n\t\t\tif toggle.Keybind.Mode == \"Hold\" then toggle:Set(false) end\n\t\tend\n\t\ttoggle.Keybind.OnModeChanged = function(mode, previous)\n\t\t\tif mode == \"Always\" then toggle:Set(true) elseif previous == \"Always\" then toggle:Set(false) end\n\t\tend\n\t\ttoggle.Keybind.GetState = function() return toggle.Value end")

		src = replacePlain(src, [==[		if isClick(input) then
			local point = mousePos()]==], [==[		if isClick(input) then
			local point = mousePos()
			local rawPoint = point
			if input.UserInputType == Enum.UserInputType.Touch then
				rawPoint = Vector2.new(input.Position.X, input.Position.Y) + (ScreenRef and ScreenRef.AbsolutePosition or Vector2.zero)
				point = rawPoint + game:GetService("GuiService"):GetGuiInset()
			end]==])

		src = replacePlain(src,
			"if win.ActivePopup and not overDropdown and not inside(win.ActivePopup.Frame, point, 6) then",
			"if win.ActivePopup and not overDropdown and not inside(win.ActivePopup.Frame, point, 6) and not inside(win.ActivePopup.Frame, rawPoint, 6) then")

		do
			local menuStart = string.find(src, "function Window:_buildKeybindMenu()", 1, true)
			local menuEnd = string.find(src, "function Window:_buildPicker()", 1, true)
			if menuStart and menuEnd then
				local menuSource = [==[function Window:_buildKeybindMenu()
	local pad, gap, rowH = Metrics.Pad, Metrics.Gap, Metrics.InputH
	local width = 226
	local inner = width - pad * 2
	local third = (inner - gap * 2) / 3
	local MODES = { "Toggle", "Hold", "Always" }
	local frame, body, controls = self:_popupFrame(width, pad * 2 + rowH * 4 + gap * 3)
	local menu = { Frame = frame, Fader = newFader(frame), Target = nil }
	local function modeX(index) return pad + (index - 1) * (third + gap) end
	local pill = new("Frame", { Bg = "Accent", Size = Offset(third - 2, rowH - 2), Position = Offset(modeX(1) + 1, pad + 1), Radius = Metrics.Radius, Border = "Outline" }, body)
	addGradient(pill)
	for index, mode in ipairs(MODES) do
		local hit = new("TextButton", { Position = Offset(modeX(index), pad), Size = Offset(third, rowH), ZIndex = 2 }, body)
		centeredLabel(hit, third, { Text = mode, RowH = rowH })
		table.insert(controls, hit)
		hit.MouseButton1Click:Connect(function() menu.SetMode(mode) end)
	end
	local function actionRow(text)
		local row = new("TextButton", { Position = Offset(pad + 1, 0), Size = Offset(inner - 2, rowH - 2), Radius = Metrics.Radius, Border = "Outline", BackgroundTransparency = 0 }, body)
		interactive(row, "Element")
		addGradient(row)
		table.insert(controls, row)
		local rowLabel = centeredLabel(row, inner - 2, { Text = text, RowH = rowH - 2 })
		return row, rowLabel
	end
	local bindRow = actionRow("Bind Key")
	local mobileRow, mobileLabel = actionRow("Spawn Mobile Button")
	local reset = actionRow("Reset")

	function menu.Paint(animated)
		local target = menu.Target
		if not target then return end
		local showMobile = target.Mode ~= "Always"
		local y = pad + rowH + gap
		bindRow.Position = Offset(pad + 1, y + 1)
		y += rowH + gap
		mobileRow.Visible = showMobile
		if showMobile then
			setText(mobileLabel, target.MobileButton and "Remove Mobile Button" or "Spawn Mobile Button")
			mobileRow.Position = Offset(pad + 1, y + 1)
			y += rowH + gap
		end
		reset.Position = Offset(pad + 1, y + 1)
		frame.Size = Offset(width, y + rowH + pad)
		local index = table.find(MODES, target.Mode) or 1
		place(pill, "Position", Offset(modeX(index) + 1, pad + 1), animated, "Knob")
	end

	function menu.SetMode(mode)
		local target = menu.Target
		if not target or target.Mode == mode then return end
		local previous = target.Mode
		target.Mode = mode
		if target.OnModeChanged then target.OnModeChanged(mode, previous) end
		if self.OnKeybindMode then self.OnKeybindMode(target, mode, previous) end
		menu.Paint(true)
	end

	bindRow.MouseButton1Click:Connect(function()
		local target = menu.Target
		self:ClosePopup()
		if target then target.StartListening() end
	end)
	mobileRow.MouseButton1Click:Connect(function()
		local target = menu.Target
		if target and self.OnMobileButton then self.OnMobileButton(target) end
		menu.Paint(false)
	end)
	reset.MouseButton1Click:Connect(function()
		if menu.Target then menu.Target:Set(nil) end
		self:ClosePopup()
	end)
	self.KeybindMenu = menu
end

]==]
				src = string.sub(src, 1, menuStart - 1) .. menuSource .. string.sub(src, menuEnd)
			end
		end

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

local FontList = {}
do
	local HttpService = game:GetService("HttpService")
	local fonts = Blossom.Fonts or {}
	local BASE_FONTS = { "Inter", "Builder Sans", "Roboto", "Montserrat", "Source Sans Pro", "Ubuntu", "Nunito", "Arimo" }
	local STYLE_FONTS = {
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

	local function add(name, family)
		if not family or family == "" then return end
		fonts[name] = family
		if not table.find(FontList, name) then table.insert(FontList, name) end
	end

	local function familyFromFile(name, fontFile)
		if not (GetAsset and writefile) then return nil end
		local ok, family = pcall(function()
			local face = GetAsset(fontFile)
			local jsonFile = ASSET_FOLDER .. "/family_" .. (string.gsub(name, "[^%w]", "_")) .. ".json"
			writefile(jsonFile, HttpService:JSONEncode({
				name = name,
				faces = { { name = "Regular", weight = 400, style = "normal", assetId = face } },
			}))
			return GetAsset(jsonFile)
		end)
		return ok and family or nil
	end

	for _, name in ipairs(BASE_FONTS) do
		if fonts[name] then table.insert(FontList, name) end
	end

	local customFonts = {}
	pcall(function()
		if not (listfiles and isfolder and makefolder) then return end
		if not isfolder("Paranoia/fonts") then makefolder("Paranoia/fonts") end
		for _, path in ipairs(listfiles("Paranoia/fonts")) do
			local fileName = string.match(path, "([^/\\]+)$") or path
			local base, extension = string.match(fileName, "^(.+)%.([%w]+)$")
			extension = extension and string.lower(extension)
			if base and (extension == "ttf" or extension == "otf") then
				customFonts[base] = familyFromFile(base, path)
			elseif base and (extension == "json" or extension == "font") then
				local ok, family = pcall(GetAsset, path)
				if ok and family then customFonts[base] = family end
			end
		end
	end)

	local fortnite = customFonts.Fortnite
	if fortnite then
		add("Fortnite", fortnite)
		customFonts.Fortnite = nil
	end
	local antonFile = AssetFiles["fonts/Anton-Regular.ttf"]
	local anton = antonFile and familyFromFile("Anton", antonFile)
	if anton then
		add("Fortnite Style", anton)
	else
		local ok, family = pcall(function() return Font.fromEnum(Enum.Font.Oswald).Family end)
		if ok then add("Fortnite Style", family) end
	end
	for _, entry in ipairs(STYLE_FONTS) do
		local ok, family = pcall(function() return Font.fromEnum(Enum.Font[entry[2]]).Family end)
		if ok then add(entry[1], family) end
	end
	local names = {}
	for name in pairs(customFonts) do table.insert(names, name) end
	table.sort(names)
	for _, name in ipairs(names) do add(name, customFonts[name]) end
end

local function fontFace(name, weight)
	local family = (Blossom.Fonts or {})[name]
	if not family then return nil end
	local ok, face = pcall(Font.new, family, weight or Enum.FontWeight.Bold)
	return ok and face or nil
end

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
local LegitSilent, LegitAim, LegitTrigger, MainTargeting, MiscWeapons, RageMain = Group({ Name = "Main", Icon = Icon("rage", "target") }, {
	{ Name = "Silent Aim", Icon = Icon("silent", "bullet") },
	{ Name = "Aimbot", Icon = Icon("aimassist", "target") },
	{ Name = "Triggerbot", Icon = Icon("trigger", "bullet") },
	{ Name = "Targeting", Icon = Icon("targeting", "bullet") },
	{ Name = "Weapons", Icon = Icon("weaponmods", "wrench") },
	{ Name = "Ragebot", Icon = Icon("ragebot", "robot") },
})
Category("Visuals")
local VisualsWorld = Tab({ Name = "World", Icon = Icon("world", "globe") })
local VisualsLocal = VisualsWorld
local EspMain, EspWorld, EspCosmetics = Group({ Name = "ESP", Icon = Icon("esp", "smile") }, {
	{ Name = "Main", Icon = Icon("esp", "smile") },
	{ Name = "World", Icon = Icon("world", "globe") },
	{ Name = "Cosmetics", Icon = Icon("preview", "smile") },
})
local VisualsHits, VisualsHud, VisualsCosmetics, VisualsFx, VisualsCrosshair, VisualsGrenades = Group({ Name = "Visuals", Icon = Icon("effects", "globe") }, {
	{ Name = "Hit Effects", Icon = Icon("silent", "bullet") },
	{ Name = "Target HUD", Icon = Icon("preview", "smile") },
	{ Name = "Viewmodel", Icon = Icon("character", "smile") },
	{ Name = "Weapon FX", Icon = Icon("effects", "globe") },
	{ Name = "Crosshair", Icon = Icon("local", "smile") },
	{ Name = "Grenades", Icon = Icon("targeting", "bullet") },
})
Category("Player")
local MovementMain, RageAntiAim, MiscCharacter = Group({ Name = "Character", Icon = Icon("movement", "smile") }, {
	{ Name = "Movement", Icon = Icon("speed", "smile") },
	{ Name = "Anti Aim", Icon = Icon("antiaim", "wrench") },
	{ Name = "Animation Player", Icon = Icon("character", "smile") },
})
Category("Misc")
local MiscAutomation, MiscSpoof, MiscChat = Group({ Name = "Misc", Icon = Icon("misc", "cube") }, {
	{ Name = "Automation", Icon = Icon("automation", "robot") },
	{ Name = "Spoofers", Icon = Icon("local", "smile") },
	{ Name = "Chat", Icon = Icon("misc", "cube") },
})
local Settings = Tab({ Name = "Settings", Icon = Icon("settings", "gear") })

local EspState = { Enabled = false, TeamCheck = false, LimitDistance = false, MaxDistance = 1000, Font = "Inter", Elements = {} }
do
	local RunService = game:GetService("RunService")
	local WHITE = Color3.fromRGB(255, 255, 255)

	local ELEMENTS = {
		{ Key = "Box", Section = "Main", Name = "Box", Gradient = true, Rotation = 0,
			Colors = { WHITE, WHITE, WHITE } },
		{ Key = "BoxFill", Section = "Main", Name = "Box Fill", Gradient = true, Rotation = 90,
			Colors = { WHITE, WHITE, WHITE } },
		{ Key = "Skeleton", Section = "Main", Name = "Skeleton", Color = WHITE },
		{ Key = "HealthBar", Section = "Main", Name = "Health Bar", Gradient = true, Rotation = 90,
			Colors = { Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 0) } },
		{ Key = "AmmoBar", Section = "Main", Name = "Ammo Bar", Gradient = true, Rotation = 0,
			Colors = { WHITE, WHITE, WHITE } },
		{ Key = "HeadDot", Section = "Main", Name = "Head Dot", Color = WHITE },
		{ Key = "Name", Section = "Main", Name = "Name", Color = WHITE },
		{ Key = "Rank", Section = "Main", Name = "Rank", Color = WHITE },
		{ Key = "Weapon", Section = "Main", Name = "Weapon", Color = WHITE },
		{ Key = "Chams", Section = "Main", Name = "Chams", Color = WHITE },
		{ Key = "Staring", Section = "Main", Name = "Staring", Color = WHITE },
	}

	local function setShown(object, shown)
		local item = object and object.Item
		if not item or item.Visible == shown then return end
		item.Visible = shown
		item.Frame.Visible = shown
		item.Section:Layout(true)
	end

	local mainSection = EspMain:Section({ Name = "Main", Icon = Icon("esp", "smile"), Side = 1 })
	local mainPreview = EspMain:Section({ Name = "Preview", Icon = Icon("preview", "smile"), Side = 2 })

	mainSection:Toggle({ Name = "Enabled", Default = false, Callback = function(value) EspState.Enabled = value end })
	mainSection:Toggle({ Name = "Team Check", Default = false, Callback = function(value) EspState.TeamCheck = value end })
	local maxDistance
	mainSection:Toggle({ Name = "Limit Distance", Default = false, Callback = function(value)
		EspState.LimitDistance = value
		setShown(maxDistance, value)
	end })
	maxDistance = mainSection:Slider({ Name = "Max Distance", Min = 1, Max = 100000, Default = EspState.MaxDistance, Suffix = " studs", Callback = function(value) EspState.MaxDistance = value end })
	setShown(maxDistance, EspState.LimitDistance)

	local previewFonts = {}
	local function applyPreviewFont()
		for _, apply in ipairs(previewFonts) do apply() end
	end

	for _, def in ipairs(ELEMENTS) do
		local espSection = mainSection
		local element = {
			Enabled = false, Color = def.Color, Colors = def.Colors and table.clone(def.Colors),
			Animate = false, Rotation = def.Rotation or 0, Speed = 1, Gradient = def.Gradient,
		}
		EspState.Elements[def.Key] = element
		local children = {}
		local function refresh()
			for _, child in ipairs(children) do
				local shown = element.Enabled
				if child.NeedsAnimate then shown = shown and element.Animate end
				setShown(child.Object, shown)
			end
		end

		if def.Gradient then
			local callbacks = {}
			for index = 1, 3 do
				callbacks[index] = function(color) element.Colors[index] = color end
			end
			local toggle = espSection:Toggle({
				Name = def.Name, Default = false, Colors = def.Colors, ColorCallbacks = callbacks,
				Callback = function(value) element.Enabled = value; refresh() end,
			})
			local extra = toggle.Item and toggle.Item.ExtraColors
			if extra then
				if toggle.Flag then
					for index, color in ipairs(extra) do
						Window.Flags[toggle.Flag .. "/Color" .. index] = color
					end
				end
			else
				for index = 1, 3 do
					local picker = espSection:Colorpicker({ Name = def.Name .. " Color " .. index, Default = def.Colors[index], Callback = callbacks[index] })
					table.insert(children, { Object = picker })
				end
			end
			local animate = espSection:Toggle({ Name = "Animate Gradient", Default = false, Callback = function(value) element.Animate = value; refresh() end })
			table.insert(children, { Object = animate })
			local rotation = espSection:Slider({ Name = "Rotation", Min = 0, Max = 360, Default = element.Rotation, Suffix = "°", Callback = function(value) element.Rotation = value end })
			table.insert(children, { Object = rotation, NeedsAnimate = true })
			local speed = espSection:Slider({ Name = "Speed", Min = 0.01, Max = 5, Default = 1, Decimals = 2, Suffix = " rps", Callback = function(value) element.Speed = value end })
			table.insert(children, { Object = speed, NeedsAnimate = true })
		else
			espSection:Toggle({
				Name = def.Name, Default = false, Color = def.Color,
				ColorCallback = function(color) element.Color = color end,
				Callback = function(value) element.Enabled = value; refresh() end,
			})
		end
		refresh()
	end

	mainSection:Dropdown({ Name = "ESP Font", Options = FontList, Default = "Inter", MaxRows = 12, Callback = function(value)
		EspState.Font = value
		applyPreviewFont()
	end })

	local function buildPreview(previewSection)
		local PREVIEW_H = 360
		local item = previewSection:_item(PREVIEW_H, "Preview", nil, false)
		local stage = Instance.new("Frame")
		stage.Name = "EspPreview"
		stage.Size = UDim2.fromScale(1, 1)
		stage.BackgroundColor3 = Color3.new(0, 0, 0)
		stage.BackgroundTransparency = 0.55
		stage.BorderSizePixel = 0
		stage.ClipsDescendants = true
		stage.Parent = item.Frame
		local stageCorner = Instance.new("UICorner")
		stageCorner.CornerRadius = UDim.new(0, 4)
		stageCorner.Parent = stage

		local CHAR_H = PREVIEW_H - 96
		local CHAR_W = math.floor(CHAR_H * 377 / 658)
		local body = Instance.new("Frame")
		body.Name = "Body"
		body.BackgroundTransparency = 1
		body.AnchorPoint = Vector2.new(0.5, 0.5)
		body.Position = UDim2.new(0.5, 0, 0.5, 2)
		body.Size = UDim2.fromOffset(CHAR_W, CHAR_H)
		body.Parent = stage

		local character = Instance.new("ImageLabel")
		character.Name = "Character"
		character.BackgroundTransparency = 1
		character.Size = UDim2.fromScale(1, 1)
		character.ScaleType = Enum.ScaleType.Fit
		character.Image = Assets["esp/preview.png"] or ""
		character.ZIndex = 2
		character.Parent = body

		local function frame(name, parent, zindex)
			local f = Instance.new("Frame")
			f.Name = name
			f.BorderSizePixel = 0
			f.BackgroundTransparency = 1
			f.ZIndex = zindex or 3
			f.Parent = parent
			return f
		end

		local function gradient(parent)
			local g = Instance.new("UIGradient")
			g.Parent = parent
			return g
		end

		local PAD = 5
		local boxFill = frame("BoxFill", body, 1)
		boxFill.Position = UDim2.fromOffset(-PAD, -PAD)
		boxFill.Size = UDim2.new(1, PAD * 2, 1, PAD * 2)
		boxFill.BackgroundColor3 = WHITE
		boxFill.BackgroundTransparency = 0.72
		local fillGradient = gradient(boxFill)

		local box = frame("Box", body, 4)
		box.Position = boxFill.Position
		box.Size = boxFill.Size
		local boxOutline = Instance.new("UIStroke")
		boxOutline.Thickness = 3
		boxOutline.Color = Color3.new(0, 0, 0)
		boxOutline.Transparency = 0.2
		boxOutline.Parent = box
		local boxInner = frame("Inner", box, 5)
		boxInner.Size = UDim2.fromScale(1, 1)
		local boxStroke = Instance.new("UIStroke")
		boxStroke.Thickness = 1
		boxStroke.Color = WHITE
		boxStroke.Parent = boxInner
		local boxGradient = gradient(boxStroke)

		local healthBack = frame("HealthBar", body, 4)
		healthBack.BackgroundColor3 = Color3.new(0, 0, 0)
		healthBack.BackgroundTransparency = 0.25
		healthBack.Position = UDim2.fromOffset(-PAD - 7, -PAD - 1)
		healthBack.Size = UDim2.new(0, 4, 1, PAD * 2 + 2)
		local healthFill = frame("Fill", healthBack, 5)
		healthFill.BackgroundColor3 = WHITE
		healthFill.BackgroundTransparency = 0
		healthFill.AnchorPoint = Vector2.new(0, 1)
		healthFill.Position = UDim2.new(0, 1, 1, -1)
		local healthGradient = gradient(healthFill)

		local ammoBack = frame("AmmoBar", body, 4)
		ammoBack.BackgroundColor3 = Color3.new(0, 0, 0)
		ammoBack.BackgroundTransparency = 0.25
		ammoBack.Position = UDim2.new(0, -PAD - 1, 1, PAD + 3)
		ammoBack.Size = UDim2.new(1, PAD * 2 + 2, 0, 4)
		local ammoFill = frame("Fill", ammoBack, 5)
		ammoFill.BackgroundColor3 = WHITE
		ammoFill.BackgroundTransparency = 0
		ammoFill.Position = UDim2.fromOffset(1, 1)
		local ammoGradient = gradient(ammoFill)

		local JOINTS = {
			Head = Vector2.new(0.49, 0.19), Neck = Vector2.new(0.50, 0.33),
			LeftShoulder = Vector2.new(0.29, 0.40), RightShoulder = Vector2.new(0.75, 0.39),
			LeftElbow = Vector2.new(0.32, 0.61), LeftHand = Vector2.new(0.43, 0.36),
			RightElbow = Vector2.new(0.76, 0.63), RightHand = Vector2.new(0.63, 0.89),
			Pelvis = Vector2.new(0.50, 0.72), LeftHip = Vector2.new(0.37, 0.73), RightHip = Vector2.new(0.65, 0.73),
			LeftKnee = Vector2.new(0.39, 0.99), RightKnee = Vector2.new(0.61, 0.99),
		}
		local BONES = {
			{ "Head", "Neck" }, { "Neck", "Pelvis" },
			{ "Neck", "LeftShoulder" }, { "LeftShoulder", "LeftElbow" }, { "LeftElbow", "LeftHand" },
			{ "Neck", "RightShoulder" }, { "RightShoulder", "RightElbow" }, { "RightElbow", "RightHand" },
			{ "Pelvis", "LeftHip" }, { "LeftHip", "LeftKnee" }, { "Pelvis", "RightHip" }, { "RightHip", "RightKnee" },
		}
		local skeleton = frame("Skeleton", body, 6)
		skeleton.Size = UDim2.fromScale(1, 1)
		local boneFrames = {}
		for _, bone in ipairs(BONES) do
			local line = frame("Bone", skeleton, 6)
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.BackgroundTransparency = 0
			local outline = Instance.new("UIStroke")
			outline.Thickness = 1
			outline.Color = Color3.new(0, 0, 0)
			outline.Transparency = 0.45
			outline.Parent = line
			table.insert(boneFrames, { Line = line, From = JOINTS[bone[1]], To = JOINTS[bone[2]] })
		end
		local function layoutSkeleton()
			local size = body.AbsoluteSize
			for _, bone in ipairs(boneFrames) do
				local a = bone.From * size
				local b = bone.To * size
				local delta = b - a
				bone.Line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
				bone.Line.Size = UDim2.fromOffset(delta.Magnitude, 1.5)
				bone.Line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			end
		end
		body:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutSkeleton)
		layoutSkeleton()

		local headDot = frame("HeadDot", body, 7)
		headDot.AnchorPoint = Vector2.new(0.5, 0.5)
		headDot.Position = UDim2.fromScale(JOINTS.Head.X, JOINTS.Head.Y)
		headDot.Size = UDim2.fromOffset(7, 7)
		headDot.BackgroundTransparency = 0
		local headCorner = Instance.new("UICorner")
		headCorner.CornerRadius = UDim.new(1, 0)
		headCorner.Parent = headDot
		local headStroke = Instance.new("UIStroke")
		headStroke.Thickness = 1
		headStroke.Color = Color3.new(0, 0, 0)
		headStroke.Parent = headDot

		local function text(name, content, position, anchor)
			local label = Instance.new("TextLabel")
			label.Name = name
			label.BackgroundTransparency = 1
			label.AnchorPoint = anchor
			label.Position = position
			label.Size = UDim2.fromOffset(160, 14)
			label.Text = content
			label.TextSize = 12
			label.TextStrokeTransparency = 0.35
			label.TextColor3 = WHITE
			label.ZIndex = 8
			label.Parent = body
			return label
		end
		local nameLabel = text("Name", "Paranoia", UDim2.new(0.5, 0, 0, -PAD - 3), Vector2.new(0.5, 1))
		local rankLabel = text("Rank", "Diamond II", UDim2.new(0.5, 0, 0, -PAD - 17), Vector2.new(0.5, 1))
		rankLabel.TextSize = 11
		local weaponLabel = text("Weapon", "Assault Rifle", UDim2.new(0.5, 0, 1, PAD + 10), Vector2.new(0.5, 0))
		weaponLabel.TextSize = 11

		local textLabels = { nameLabel, rankLabel, weaponLabel }
		local function applyThisFont()
			local face = fontFace(EspState.Font, Enum.FontWeight.Bold)
			for _, label in ipairs(textLabels) do
				if face then label.FontFace = face end
			end
		end
		table.insert(previewFonts, applyThisFont)
		applyThisFont()

		local function sequence(colors)
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, colors[1]),
				ColorSequenceKeypoint.new(0.5, colors[2]),
				ColorSequenceKeypoint.new(1, colors[3]),
			})
		end

		local clock = 0
		local function paintGradient(g, element)
			g.Color = sequence(element.Colors)
			local rotation = element.Rotation
			if element.Animate then rotation += clock * element.Speed * 360 end
			g.Rotation = rotation % 360
		end

		local E = EspState.Elements
		RunService.RenderStepped:Connect(function(dt)
			if not (Window.Visible and stage.AbsoluteSize.X > 0 and stage.Parent and item.Frame.Visible) then return end
			clock += dt

			boxFill.Visible = E.BoxFill.Enabled
			if E.BoxFill.Enabled then paintGradient(fillGradient, E.BoxFill) end

			box.Visible = E.Box.Enabled
			if E.Box.Enabled then paintGradient(boxGradient, E.Box) end

			healthBack.Visible = E.HealthBar.Enabled
			if E.HealthBar.Enabled then
				local health = 0.62 + 0.33 * math.sin(clock * 0.7)
				healthFill.Size = UDim2.new(1, -2, health, -2)
				paintGradient(healthGradient, E.HealthBar)
			end

			ammoBack.Visible = E.AmmoBar.Enabled
			if E.AmmoBar.Enabled then
				local ammo = 1 - (math.floor(clock * 5) % 34) / 30
				ammo = math.clamp(ammo, 0, 1)
				ammoFill.Size = UDim2.new(ammo, -2, 1, -2)
				paintGradient(ammoGradient, E.AmmoBar)
			end

			skeleton.Visible = E.Skeleton.Enabled
			if E.Skeleton.Enabled then
				for _, bone in ipairs(boneFrames) do bone.Line.BackgroundColor3 = E.Skeleton.Color end
			end

			headDot.Visible = E.HeadDot.Enabled
			headDot.BackgroundColor3 = E.HeadDot.Color

			nameLabel.Visible = E.Name.Enabled
			nameLabel.TextColor3 = E.Name.Color
			rankLabel.Visible = E.Rank.Enabled
			rankLabel.TextColor3 = E.Rank.Color
			weaponLabel.Visible = E.Weapon.Enabled
			weaponLabel.TextColor3 = E.Weapon.Color
			weaponLabel.Position = E.AmmoBar.Enabled and UDim2.new(0.5, 0, 1, PAD + 10) or UDim2.new(0.5, 0, 1, PAD + 2)
			local topOffset = E.Name.Enabled and -PAD - 17 or -PAD - 3
			rankLabel.Position = UDim2.new(0.5, 0, 0, topOffset)
		end)
	end
	buildPreview(mainPreview)
end

do
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)

	local old = playerGui:FindFirstChild("ParanoiaESP")
	if old then old:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "ParanoiaESP"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local function make(class, props, parent)
		local object = Instance.new(class)
		for key, value in pairs(props) do object[key] = value end
		object.Parent = parent
		return object
	end

	local function box(name, parent, zindex)
		return make("Frame", { Name = name, BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = zindex }, parent)
	end

	local R15_BONES = {
		{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
		{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
		{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
		{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
		{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
	}
	local R6_BONES = {
		{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
		{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
	}

	local function gradientColors(colors)
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, colors[1]),
			ColorSequenceKeypoint.new(0.5, colors[2]),
			ColorSequenceKeypoint.new(1, colors[3]),
		})
	end

	local clock = 0
	local function paint(gradient, element)
		gradient.Color = gradientColors(element.Colors)
		local rotation = element.Rotation
		if element.Animate then rotation += clock * element.Speed * 360 end
		gradient.Rotation = rotation % 360
	end

	local function newLabel(parent, size)
		return make("TextLabel", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(200, 14),
			TextSize = size, TextStrokeTransparency = 0.35, TextColor3 = WHITE, ZIndex = 8, Text = "",
		}, parent)
	end

	local function newEntry()
		local entry = {}
		local root = box("Entry", gui, 1)
		root.Visible = false
		entry.Root = root

		entry.Fill = box("BoxFill", root, 1)
		entry.Fill.Size = UDim2.fromScale(1, 1)
		entry.Fill.BackgroundColor3 = WHITE
		entry.Fill.BackgroundTransparency = 0.72
		entry.FillGradient = make("UIGradient", {}, entry.Fill)

		entry.Box = box("Box", root, 4)
		entry.Box.Size = UDim2.fromScale(1, 1)
		make("UIStroke", { Thickness = 3, Color = BLACK, Transparency = 0.2 }, entry.Box)
		local inner = box("Inner", entry.Box, 5)
		inner.Size = UDim2.fromScale(1, 1)
		local stroke = make("UIStroke", { Thickness = 1, Color = WHITE }, inner)
		entry.BoxGradient = make("UIGradient", {}, stroke)

		entry.Health = box("HealthBar", root, 4)
		entry.Health.BackgroundTransparency = 0.25
		entry.Health.BackgroundColor3 = BLACK
		entry.Health.Position = UDim2.fromOffset(-7, -1)
		entry.Health.Size = UDim2.new(0, 4, 1, 2)
		entry.HealthFill = box("Fill", entry.Health, 5)
		entry.HealthFill.BackgroundTransparency = 0
		entry.HealthFill.BackgroundColor3 = WHITE
		entry.HealthFill.AnchorPoint = Vector2.new(0, 1)
		entry.HealthFill.Position = UDim2.new(0, 1, 1, -1)
		entry.HealthGradient = make("UIGradient", {}, entry.HealthFill)

		entry.Ammo = box("AmmoBar", root, 4)
		entry.Ammo.BackgroundTransparency = 0.25
		entry.Ammo.BackgroundColor3 = BLACK
		entry.Ammo.Position = UDim2.new(0, -1, 1, 3)
		entry.Ammo.Size = UDim2.new(1, 2, 0, 4)
		entry.AmmoFill = box("Fill", entry.Ammo, 5)
		entry.AmmoFill.BackgroundTransparency = 0
		entry.AmmoFill.BackgroundColor3 = WHITE
		entry.AmmoFill.Position = UDim2.fromOffset(1, 1)
		entry.AmmoGradient = make("UIGradient", {}, entry.AmmoFill)

		entry.Name = newLabel(root, 12)
		entry.Rank = newLabel(root, 11)
		entry.Weapon = newLabel(root, 11)
		entry.Weapon.AnchorPoint = Vector2.new(0.5, 0)
		entry.Staring = newLabel(root, 11)

		local skeleton = box("Skeleton", gui, 6)
		skeleton.Size = UDim2.fromScale(1, 1)
		skeleton.Visible = false
		entry.Skeleton = skeleton
		entry.Bones = {}
		for index = 1, #R15_BONES do
			local line = box("Bone", skeleton, 6)
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.BackgroundTransparency = 0
			line.Visible = false
			make("UIStroke", { Thickness = 1, Color = BLACK, Transparency = 0.45 }, line)
			entry.Bones[index] = line
		end

		entry.Chams = make("Highlight", { Enabled = false, FillTransparency = 0.5, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, gui)

		entry.Dot = box("HeadDot", skeleton, 7)
		entry.Dot.AnchorPoint = Vector2.new(0.5, 0.5)
		entry.Dot.Size = UDim2.fromOffset(7, 7)
		entry.Dot.BackgroundTransparency = 0
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, entry.Dot)
		make("UIStroke", { Thickness = 1, Color = BLACK }, entry.Dot)
		return entry
	end

	local entries = {}
	local function hide(entry)
		entry.Root.Visible = false
		entry.Skeleton.Visible = false
		entry.Chams.Enabled = false
	end

	local function readNumber(instance, names)
		for _, name in ipairs(names) do
			local value = instance:GetAttribute(name)
			if type(value) ~= "number" then
				local child = instance:FindFirstChild(name)
				value = child and child:IsA("ValueBase") and child.Value or nil
			end
			if type(value) == "number" then return value end
		end
	end

	local function readText(instance, names)
		for _, name in ipairs(names) do
			local value = instance:GetAttribute(name)
			if value == nil then
				local child = instance:FindFirstChild(name, true)
				value = child and child:IsA("ValueBase") and child.Value or nil
			end
			if value ~= nil and tostring(value) ~= "" then return tostring(value) end
		end
	end

	local function weaponInfo(player, character)
		local tool = character:FindFirstChildOfClass("Tool")
		local name = tool and tool.Name or readText(character, { "CurrentWeapon", "EquippedWeapon", "Weapon" }) or readText(player, { "CurrentWeapon", "EquippedWeapon", "Weapon" })
		local source = tool or character
		local ammo = readNumber(source, { "Ammo", "CurrentAmmo", "Clip", "Magazine" })
		local maxAmmo = readNumber(source, { "MaxAmmo", "ClipSize", "MagSize", "MaxClip" })
		return name, ammo, maxAmmo
	end

	local function rankInfo(player)
		return readText(player, { "Rank", "RankName", "Division", "Tier" })
	end

	local appliedFont
	local function applyFonts(entry, face)
		for _, label in ipairs({ entry.Name, entry.Rank, entry.Weapon, entry.Staring }) do
			if face then label.FontFace = face end
		end
	end

	local function update(entry, player, camera, viewport)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and humanoid) or humanoid.Health <= 0 then return hide(entry) end
		if EspState.TeamCheck and player.Team ~= nil and player.Team == localPlayer.Team then return hide(entry) end
		local distance = (root.Position - camera.CFrame.Position).Magnitude
		if EspState.LimitDistance and distance > EspState.MaxDistance then return hide(entry) end

		local cframe, size = character:GetBoundingBox()
		local half = Vector3.new(0, size.Y / 2, 0)
		local top = camera:WorldToViewportPoint(cframe.Position + half)
		local bottom = camera:WorldToViewportPoint(cframe.Position - half)
		if top.Z <= 0 or bottom.Z <= 0 then return hide(entry) end

		local height = math.abs(bottom.Y - top.Y)
		local width = height * 0.55
		local centerX = (top.X + bottom.X) / 2
		local x, y = math.floor(centerX - width / 2), math.floor(math.min(top.Y, bottom.Y))
		if x + width < 0 or x > viewport.X or y + height < 0 or y > viewport.Y or height < 4 then return hide(entry) end

		local E = EspState.Elements
		entry.Root.Position = UDim2.fromOffset(x, y)
		entry.Root.Size = UDim2.fromOffset(math.floor(width), math.floor(height))
		entry.Root.Visible = true

		entry.Chams.Adornee = character
		entry.Chams.FillColor = E.Chams.Color
		entry.Chams.OutlineColor = E.Chams.Color
		entry.Chams.Enabled = E.Chams.Enabled

		entry.Fill.Visible = E.BoxFill.Enabled
		if E.BoxFill.Enabled then paint(entry.FillGradient, E.BoxFill) end
		entry.Box.Visible = E.Box.Enabled
		if E.Box.Enabled then paint(entry.BoxGradient, E.Box) end

		entry.Health.Visible = E.HealthBar.Enabled
		if E.HealthBar.Enabled then
			local health = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
			entry.HealthFill.Size = UDim2.new(1, -2, health, -2)
			paint(entry.HealthGradient, E.HealthBar)
		end

		local weapon, ammo, maxAmmo = weaponInfo(player, character)
		local showAmmo = E.AmmoBar.Enabled and ammo ~= nil and maxAmmo ~= nil and maxAmmo > 0
		entry.Ammo.Visible = showAmmo
		if showAmmo then
			entry.AmmoFill.Size = UDim2.new(math.clamp(ammo / maxAmmo, 0, 1), -2, 1, -2)
			paint(entry.AmmoGradient, E.AmmoBar)
		end

		local rank = E.Rank.Enabled and rankInfo(player) or nil
		entry.Name.Visible = E.Name.Enabled
		entry.Name.Text = player.DisplayName
		entry.Name.TextColor3 = E.Name.Color
		local stack = -3
		entry.Name.Position = UDim2.new(0.5, 0, 0, stack)
		if E.Name.Enabled then stack -= 14 end
		entry.Rank.Visible = rank ~= nil
		entry.Rank.Text = rank or ""
		entry.Rank.TextColor3 = E.Rank.Color
		entry.Rank.Position = UDim2.new(0.5, 0, 0, stack)
		if rank then stack -= 14 end
		local staring = false
		if E.Staring.Enabled then
			local head = character:FindFirstChild("Head")
			local myCharacter = localPlayer.Character
			local myHead = myCharacter and myCharacter:FindFirstChild("Head")
			local target = myHead and myHead.Position or camera.CFrame.Position
			if head then
				local toMe = target - head.Position
				staring = toMe.Magnitude > 0.1 and head.CFrame.LookVector:Dot(toMe.Unit) > 0.96
			end
		end
		entry.Staring.Visible = staring
		entry.Staring.Text = "Staring"
		entry.Staring.TextColor3 = E.Staring.Color
		entry.Staring.Position = UDim2.new(0.5, 0, 0, stack)
		entry.Weapon.Visible = E.Weapon.Enabled and weapon ~= nil
		entry.Weapon.Text = weapon or ""
		entry.Weapon.TextColor3 = E.Weapon.Color
		entry.Weapon.Position = UDim2.new(0.5, 0, 1, showAmmo and 10 or 2)

		local wantSkeleton = E.Skeleton.Enabled
		local wantDot = E.HeadDot.Enabled
		entry.Skeleton.Visible = wantSkeleton or wantDot
		for _, line in ipairs(entry.Bones) do line.Visible = false end
		if wantSkeleton then
			local bones = character:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
			for index, pair in ipairs(bones) do
				local a, b = character:FindFirstChild(pair[1]), character:FindFirstChild(pair[2])
				local line = entry.Bones[index]
				if a and b and line then
					local pa, pb = camera:WorldToViewportPoint(a.Position), camera:WorldToViewportPoint(b.Position)
					if pa.Z > 0 and pb.Z > 0 then
						local delta = Vector2.new(pb.X - pa.X, pb.Y - pa.Y)
						line.Position = UDim2.fromOffset((pa.X + pb.X) / 2, (pa.Y + pb.Y) / 2)
						line.Size = UDim2.fromOffset(delta.Magnitude, 1.5)
						line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
						line.BackgroundColor3 = E.Skeleton.Color
						line.Visible = true
					end
				end
			end
		end
		entry.Dot.Visible = false
		if wantDot then
			local head = character:FindFirstChild("Head")
			if head then
				local point = camera:WorldToViewportPoint(head.Position)
				if point.Z > 0 then
					entry.Dot.Position = UDim2.fromOffset(point.X, point.Y)
					entry.Dot.BackgroundColor3 = E.HeadDot.Color
					entry.Dot.Visible = true
				end
			end
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		local entry = entries[player]
		if entry then
			entry.Root:Destroy()
			entry.Skeleton:Destroy()
			entry.Chams:Destroy()
			entries[player] = nil
		end
	end)

	local lastFont
	RunService.RenderStepped:Connect(function(dt)
		clock += dt
		local camera = workspace.CurrentCamera
		if not (EspState.Enabled and camera) then
			for _, entry in pairs(entries) do hide(entry) end
			return
		end
		if lastFont ~= EspState.Font then
			lastFont = EspState.Font
			appliedFont = fontFace(EspState.Font, Enum.FontWeight.Bold)
			for _, entry in pairs(entries) do applyFonts(entry, appliedFont) end
		end
		local viewport = camera.ViewportSize
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer then
				local entry = entries[player]
				if not entry then
					entry = newEntry()
					applyFonts(entry, appliedFont)
					entries[player] = entry
				end
				local ok = pcall(update, entry, player, camera, viewport)
				if not ok then hide(entry) end
			end
		end
	end)
end

local Fire = { Last = 0, Held = false }
local HitSignals = {}
local PX = {}
do
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	PX.Players, PX.Local = Players, localPlayer

	function PX.root(character)
		return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head"))
	end

	function PX.alive(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return humanoid and humanoid.Health > 0 and humanoid or nil
	end

	function PX.isEnemy(player, teamCheck)
		if player == localPlayer then return false end
		if teamCheck and player.Team ~= nil and player.Team == localPlayer.Team then return false end
		return PX.alive(player.Character) ~= nil
	end

	function PX.visible(camera, part, character)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { localPlayer.Character, character, camera }
		local origin = camera.CFrame.Position
		return workspace:Raycast(origin, part.Position - origin, params) == nil
	end

	function PX.gui(name, order)
		local playerGui = localPlayer:WaitForChild("PlayerGui")
		local old = playerGui:FindFirstChild(name)
		if old then old:Destroy() end
		local gui = Instance.new("ScreenGui")
		gui.Name = name
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = order or 45
		gui.Parent = playerGui
		return gui
	end

	function PX.closestPart(character, camera, center, names)
		local best, bestDistance
		for _, name in ipairs(names) do
			local part = character:FindFirstChild(name)
			if part then
				local point, onScreen = camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
					if not bestDistance or distance < bestDistance then best, bestDistance = part, distance end
				end
			end
		end
		return best, bestDistance
	end

	function PX.equipped()
		local character = localPlayer.Character
		return character and character:FindFirstChildOfClass("Tool")
	end

	function PX.tools()
		local list = {}
		local backpack = localPlayer:FindFirstChildOfClass("Backpack")
		if backpack then for _, tool in ipairs(backpack:GetChildren()) do if tool:IsA("Tool") then table.insert(list, tool) end end end
		local held = PX.equipped()
		if held then table.insert(list, 1, held) end
		return list
	end

	PX.BodyParts = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
	PX.Materials = { "ForceField", "Neon", "Plastic", "SmoothPlastic", "Marble", "Slate", "Concrete", "Granite", "Brick", "Pebble", "Cobblestone", "Rock", "Sandstone", "Basalt", "CrackedLava", "Limestone", "Pavement", "Glass", "Metal", "DiamondPlate", "Foil", "Ice", "Fabric", "WoodPlanks", "Wood" }
end


local Targeting = { VisibleOnly = false, IgnoreProtected = false, ProtectedIf = {}, DisableFlash = false, LimitDistance = false, MaxDistance = 250, ReactionTime = 0, ForgetTime = 1, Part = "Head", ClosestBlacklist = {} }
do
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local localPlayer = PX.Local
	local reactions = {}
	PX.Flashed = false

	function PX.reaction(key, hasTarget)
		local now = os.clock()
		local entry = reactions[key]
		if not entry then entry = { Acquired = nil, Last = 0 } reactions[key] = entry end
		if not hasTarget then
			if entry.Acquired and now - entry.Last > Targeting.ForgetTime then entry.Acquired = nil end
			return false
		end
		if not entry.Acquired then
			local recent = entry.Last > 0 and now - entry.Last <= Targeting.ForgetTime
			entry.Acquired = recent and now - Targeting.ReactionTime / 1000 or now
		end
		entry.Last = now
		return now - entry.Acquired >= Targeting.ReactionTime / 1000
	end

	function PX.pickPart(character, camera, center, closest)
		if closest then
			local names = {}
			for _, name in ipairs(PX.BodyParts) do
				if not Targeting.ClosestBlacklist[name] then table.insert(names, name) end
			end
			return (PX.closestPart(character, camera, center, names))
		end
		return character:FindFirstChild(Targeting.Part) or character:FindFirstChild("Head")
	end

	function PX.ammo(tool)
		if not tool then return nil end
		local function read(names)
			for _, name in ipairs(names) do
				local value = tool:GetAttribute(name)
				if value == nil then
					local object = tool:FindFirstChild(name)
					value = object and object:IsA("ValueBase") and object.Value or nil
				end
				if tonumber(value) then return tonumber(value) end
			end
		end
		return read({ "Ammo", "CurrentAmmo", "Magazine", "Clip" }), read({ "Reserve", "ReserveAmmo", "StoredAmmo", "Spare" }), read({ "MaxAmmo", "MagSize", "ClipSize" })
	end

	function PX.barrelPoint(camera)
		for _, model in ipairs(camera:GetChildren()) do
			if model:IsA("Model") and not model:FindFirstChildOfClass("Humanoid") then
				for _, descendant in ipairs(model:GetDescendants()) do
					if descendant:IsA("BasePart") or descendant:IsA("Attachment") then
						local lower = string.lower(descendant.Name)
						if string.find(lower, "muzzle") or string.find(lower, "barrel") or string.find(lower, "firepoint") then
							local position = descendant:IsA("Attachment") and descendant.WorldPosition or descendant.Position
							local point, onScreen = camera:WorldToViewportPoint(position)
							if onScreen then return Vector2.new(point.X, point.Y) end
						end
					end
				end
			end
		end
		return nil
	end

	function PX.aimPosition(camera, part, matchAxis)
		if not matchAxis then return part.Position end
		local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
		local toPart = part.Position - ray.Origin
		local closest = ray.Origin + ray.Direction * math.max(toPart:Dot(ray.Direction), 0)
		local offset = part.CFrame:VectorToObjectSpace(closest - part.Position)
		local half = part.Size / 2
		offset = Vector3.new(math.clamp(offset.X, -half.X, half.X), math.clamp(offset.Y, -half.Y, half.Y), math.clamp(offset.Z, -half.Z, half.Z))
		return part.Position + part.CFrame:VectorToWorldSpace(offset)
	end

	local function protected(character, camera, part)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { localPlayer.Character, camera }
		local origin = camera.CFrame.Position
		local result = workspace:Raycast(origin, part.Position - origin, params)
		if Targeting.ProtectedIf["blocked by riot shield"] and result and result.Instance:IsDescendantOf(character) then
			local node = result.Instance
			while node and node ~= character do
				if string.find(string.lower(node.Name), "shield") then return true end
				node = node.Parent
			end
		end
		if Targeting.ProtectedIf["katana deflecting"] then
			local tool = character:FindFirstChildOfClass("Tool")
			if tool and string.find(string.lower(tool.Name), "katana") and (character:GetAttribute("Deflecting") or tool:GetAttribute("Deflecting") or character:GetAttribute("Blocking")) then return true end
		end
		return false
	end

	function PX.canTarget(player, part, camera)
		local character = player.Character
		if Targeting.DisableFlash and PX.Flashed then return false end
		if Targeting.LimitDistance and (part.Position - camera.CFrame.Position).Magnitude > Targeting.MaxDistance then return false end
		if Targeting.VisibleOnly and not PX.visible(camera, part, character) then return false end
		if Targeting.IgnoreProtected and protected(character, camera, part) then return false end
		return true
	end

	local lastFlash = 0
	RunService.Heartbeat:Connect(function()
		if not Targeting.DisableFlash or os.clock() - lastFlash < 0.15 then return end
		lastFlash = os.clock()
		local flashed = false
		local camera = workspace.CurrentCamera
		for _, holder in ipairs({ Lighting, camera }) do
			if holder then
				for _, effect in ipairs(holder:GetChildren()) do
					if effect:IsA("PostEffect") and effect.Enabled and string.find(string.lower(effect.Name), "flash") then flashed = true end
				end
			end
		end
		local gui = localPlayer:FindFirstChild("PlayerGui")
		if gui and not flashed then
			for _, object in ipairs(gui:GetDescendants()) do
				if object:IsA("Frame") and object.Visible and object.BackgroundTransparency < 0.6 and string.find(string.lower(object.Name), "flash") then flashed = true break end
			end
		end
		PX.Flashed = flashed
	end)

	local section = MainTargeting:Section({ Name = "Targeting", Icon = Icon("targeting", "bullet"), Side = 1 })
	section:Toggle({ Name = "Visible Only", Default = false, Callback = function(value) Targeting.VisibleOnly = value end })
	section:Toggle({ Name = "Ignore Protected", Default = false, Callback = function(value) Targeting.IgnoreProtected = value end })
	section:Dropdown({ Name = "Ignore If", Options = { "blocked by riot shield", "katana deflecting" }, Default = { "katana deflecting" }, Multi = true, Callback = function(value) Targeting.ProtectedIf = value end })
	section:Toggle({ Name = "Disable On Flash", Default = false, Callback = function(value) Targeting.DisableFlash = value end })
	section:Toggle({ Name = "Limit Distance", Default = false, Callback = function(value) Targeting.LimitDistance = value end })
	section:Slider({ Name = "Max Distance", Min = 25, Max = 250, Default = 250, Suffix = "s", Callback = function(value) Targeting.MaxDistance = value end })
	section:Slider({ Name = "Reaction Time", Min = 0, Max = 300, Default = 0, Suffix = "ms", Callback = function(value) Targeting.ReactionTime = value end })
	section:Slider({ Name = "Forget Time", Min = 0, Max = 10, Default = 1, Decimals = 1, Suffix = "s", Callback = function(value) Targeting.ForgetTime = value end })
	section:Dropdown({ Name = "Target Part", Options = PX.BodyParts, Default = "Head", MaxRows = 12, Callback = function(value) Targeting.Part = value end })
	section:Dropdown({ Name = "Closest Part Blacklist", Options = PX.BodyParts, Default = { "LeftHand", "LeftLowerArm", "LeftUpperArm", "RightHand", "RightLowerArm", "RightUpperArm" }, Multi = true, MaxRows = 12, Callback = function(value) Targeting.ClosestBlacklist = value end })
	for _, name in ipairs({ "LeftHand", "LeftLowerArm", "LeftUpperArm", "RightHand", "RightLowerArm", "RightUpperArm" }) do Targeting.ClosestBlacklist[name] = true end
	Targeting.ProtectedIf["katana deflecting"] = true
end
local AimState = { Enabled = false, Fov = 120, DrawFov = true, FovColor = Color3.fromRGB(255, 255, 255), Smoothing = 0, TeamCheck = true, Closest = false, MatchAxis = false, FovPosition = {}, SmoothX = 100, SmoothY = 100, SmoothJump = 100, Fill = false, FillColor = Color3.fromRGB(255, 255, 255), FillTransparency = 0.85, Rotation = 0, Moving = false, RotationSpeed = 1, Outline = true, DelayPosition = false, Lerp = 1 }
do
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("ParanoiaAimbot")
	if old then old:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "ParanoiaAimbot"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 40
	gui.Parent = playerGui

	local circle = Instance.new("Frame")
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.BackgroundTransparency = 1
	circle.Visible = false
	circle.Parent = gui
	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = circle
	local circleStroke = Instance.new("UIStroke")
	circleStroke.Thickness = 1
	circleStroke.Parent = circle
	local circleGradient = Instance.new("UIGradient")
	circleGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1) })
	circleGradient.Parent = circleStroke
	local delayedPoint, fovTarget = nil, nil

	local section = LegitAim:Section({ Name = "Aimbot", Icon = Icon("aimassist", "target"), Side = 1 })
	section:Toggle({ Name = "Enabled", Default = false, Keybind = Enum.UserInputType.MouseButton2, KeybindMode = "Hold", Callback = function(value) AimState.Enabled = value end })
	section:Toggle({ Name = "Closest Part", Default = false, Callback = function(value) AimState.Closest = value end })
	section:Toggle({ Name = "Closest Position", Default = false, Callback = function(value) AimState.MatchAxis = value end })
	section:Toggle({ Name = "Delay Position", Default = false, Callback = function(value) AimState.DelayPosition = value end })
	section:Slider({ Name = "X Smooth", Min = 1, Max = 100, Default = 100, Suffix = "%", Callback = function(value) AimState.SmoothX = value end })
	section:Slider({ Name = "Y Smooth", Min = 1, Max = 100, Default = 100, Suffix = "%", Callback = function(value) AimState.SmoothY = value end })
	section:Slider({ Name = "Jump Smoothing", Min = 1, Max = 100, Default = 100, Suffix = "%", Callback = function(value) AimState.SmoothJump = value end })
	section:Toggle({ Name = "Show FOV", Default = true, Color = AimState.FovColor, ColorCallback = function(color) AimState.FovColor = color end, Callback = function(value) AimState.DrawFov = value end })
	section:Toggle({ Name = "FOV Outline", Default = true, Callback = function(value) AimState.Outline = value end })
	section:Toggle({ Name = "FOV Fill", Default = false, Color = AimState.FillColor, ColorCallback = function(color) AimState.FillColor = color end, Callback = function(value) AimState.Fill = value end })
	section:Slider({ Name = "FOV Lerp", Min = 0.01, Max = 1, Default = 1, Decimals = 2, Suffix = "x", Callback = function(value) AimState.Lerp = value end })
	section:Toggle({ Name = "Moving Rotation", Default = false, Callback = function(value) AimState.Moving = value end })
	section:Slider({ Name = "FOV Rotation", Min = 0, Max = 360, Default = 0, Suffix = "deg", Callback = function(value) AimState.Rotation = value end })
	section:Slider({ Name = "Rotation Speed", Min = 0.1, Max = 10, Default = 1, Decimals = 1, Suffix = "rps", Callback = function(value) AimState.RotationSpeed = value end })
	section:Dropdown({ Name = "FOV Settings", Options = { "position on target", "position on barrel" }, Default = {}, Multi = true, Callback = function(value) AimState.FovPosition = value end })
	section:Slider({ Name = "Radius", Min = 0, Max = 1000, Default = AimState.Fov, Suffix = "px", Callback = function(value) AimState.Fov = value end })
	section:Slider({ Name = "Smoothing", Min = 1, Max = 100, Default = 100 - AimState.Smoothing, Suffix = "%", Callback = function(value) AimState.Smoothing = 100 - value end })
	section:Toggle({ Name = "Team Check", Default = true, Callback = function(value) AimState.TeamCheck = value end })

	local function pickTarget(camera, center)
		local best, bestPart, bestDistance = nil, nil, AimState.Fov
		for _, player in ipairs(Players:GetPlayers()) do
			if PX.isEnemy(player, AimState.TeamCheck) then
				local part = PX.pickPart(player.Character, camera, center, AimState.Closest)
				if part and PX.canTarget(player, part, camera) then
					local point, onScreen = camera:WorldToViewportPoint(part.Position)
					if onScreen then
						local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
						if distance < bestDistance then best, bestPart, bestDistance = player, part, distance end
					end
				end
			end
		end
		return best, bestPart
	end

	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then return end
		local viewport = camera.ViewportSize
		local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
		circle.Visible = AimState.DrawFov and AimState.Enabled
		local fovCenter = center
		if AimState.FovPosition["position on barrel"] then fovCenter = PX.barrelPoint(camera) or fovCenter end
		if AimState.FovPosition["position on target"] and fovTarget then fovCenter = fovTarget end
		circle.Position = UDim2.fromOffset(fovCenter.X, fovCenter.Y)
		local radius = AimState.Fov * AimState.Lerp
		circle.Size = UDim2.fromOffset(radius * 2, radius * 2)
		circleStroke.Color = AimState.FovColor
		circleStroke.Enabled = AimState.Outline
		circle.BackgroundColor3 = AimState.FillColor
		circle.BackgroundTransparency = AimState.Fill and AimState.FillTransparency or 1
		circleGradient.Rotation = AimState.Moving and (os.clock() * AimState.RotationSpeed * 360) % 360 or AimState.Rotation
		circleGradient.Enabled = AimState.Moving or AimState.Rotation ~= 0
		if not AimState.Enabled then return end
		local _, part = pickTarget(camera, center)
		AimState.Part = part
		if part then
			local point = camera:WorldToViewportPoint(part.Position)
			fovTarget = Vector2.new(point.X, point.Y)
		else
			fovTarget = nil
		end
		if not PX.reaction("aimbot", part ~= nil) then return end
		local alpha = 1 - AimState.Smoothing / 100
		if mousemoverel then
			local point = camera:WorldToViewportPoint(PX.aimPosition(camera, part, AimState.MatchAxis))
			local goal = Vector2.new(point.X, point.Y)
			if AimState.DelayPosition then
				delayedPoint = delayedPoint and delayedPoint:Lerp(goal, 0.25) or goal
				goal = delayedPoint
			else
				delayedPoint = nil
			end
			local jump = 1
			local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
			if root and math.abs(root.AssemblyLinearVelocity.Y) > 4 then jump = AimState.SmoothJump / 100 end
			mousemoverel((goal.X - center.X) * alpha * (AimState.SmoothX / 100) * jump, (goal.Y - center.Y) * alpha * (AimState.SmoothY / 100) * jump)
		else
			local goal = CFrame.new(camera.CFrame.Position, PX.aimPosition(camera, part, AimState.MatchAxis))
			camera.CFrame = camera.CFrame:Lerp(goal, alpha)
		end
	end)
end

do
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local Players = game:GetService("Players")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local PROPS = {
		{ "Ambient", "color" }, { "ColorShift_Bottom", "color" }, { "ColorShift_Top", "color" }, { "FogColor", "color" },
		{ "FogEnd", "number", 0, 100000, 1000 }, { "FogStart", "number", 0, 100000, 0 }, { "Brightness", "number", 0, 10, 2 },
		{ "ClockTime", "number", 0, 24, 14 }, { "ExposureCompensation", "number", -5, 5, 0 },
	}
	local lighting = {}
	local lightSection = VisualsLocal:Section({ Name = "Lighting", Icon = Icon("world", "globe"), Side = 1 })
	for _, def in ipairs(PROPS) do
		local entry = { Enabled = false, Value = def[2] == "color" and Color3.fromRGB(255, 255, 255) or def[5], Original = nil }
		lighting[def[1]] = entry
		if def[2] == "color" then
			lightSection:Toggle({ Name = def[1], Default = false, Color = entry.Value, ColorCallback = function(color) entry.Value = color end, Callback = function(value) entry.Enabled = value end })
		else
			lightSection:Toggle({ Name = def[1], Default = false, Callback = function(value) entry.Enabled = value end })
			lightSection:Slider({ Name = def[1] .. " Value", Min = def[3], Max = def[4], Default = def[5], Decimals = def[4] <= 24 and 1 or 0, Callback = function(value) entry.Value = value end })
		end
	end

	RunService.RenderStepped:Connect(function()
		for property, entry in pairs(lighting) do
			if entry.Enabled then
				if entry.Original == nil then entry.Original = Lighting[property] end
				Lighting[property] = entry.Value
			elseif entry.Original ~= nil then
				Lighting[property] = entry.Original
				entry.Original = nil
			end
		end
	end)
end

local RageState = { Enabled = false, Priority = "Closest", Hitbox = "Head", TeamCheck = true, WallCheck = false, Range = math.huge, AutoFire = true, FireDelay = 80, KnifeMode = false, KnifeRange = 14 }
local VoidState = { Enabled = true, Hide = 0.25, Attack = 0.1, Attempts = 1, Mode = "gun", Weapon = "primary", SwapEmpty = false, Priority = false, Notify = true, Settings = { attackers = true }, Attackers = {}, Cheaters = {} }
do
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local lastShot = 0

	local section = RageMain:Section({ Name = "Ragebot", Icon = Icon("ragebot", "robot"), Side = 1 })
	section:Toggle({ Name = "Enabled", Default = false, Keybind = Enum.KeyCode.C, Callback = function(value) RageState.Enabled = value end })
	section:Toggle({ Name = "Void Spam", Default = true, Callback = function(value) VoidState.Enabled = value end })
	section:Slider({ Name = "Hide", Min = 0.01, Max = 1, Default = 0.25, Decimals = 2, Suffix = "s", Callback = function(value) VoidState.Hide = value end })
	section:Slider({ Name = "Attack", Min = 0.01, Max = 1, Default = 0.1, Decimals = 2, Suffix = "s", Callback = function(value) VoidState.Attack = value end })
	section:Slider({ Name = "Shoot Attempts", Min = 1, Max = 2, Default = 1, Suffix = "x", Callback = function(value) VoidState.Attempts = value end })
	section:Dropdown({ Name = "Attack Mode", Options = { "gun", "knife", "melee" }, Default = "gun", Callback = function(value)
		VoidState.Mode = value
		RageState.KnifeMode = value ~= "gun"
	end })
	section:Dropdown({ Name = "Preferred Weapon", Options = { "primary", "secondary" }, Default = "primary", Callback = function(value) VoidState.Weapon = value end })
	section:Dropdown({ Name = "Settings", Options = { "swap weapons when empty" }, Default = {}, Multi = true, Callback = function(value) VoidState.SwapEmpty = value["swap weapons when empty"] == true end })
	section:Dropdown({ Name = "Target Priority", Options = { "Closest", "Lowest Health", "Closest To Crosshair" }, Default = "Closest", Callback = function(value) RageState.Priority = value end })
	section:Dropdown({ Name = "Hitbox", Options = { "Head", "Torso", "Random" }, Default = "Head", Callback = function(value) RageState.Hitbox = value end })
	section:Slider({ Name = "Fire Delay", Min = 0, Max = 500, Default = RageState.FireDelay, Suffix = " ms", Callback = function(value) RageState.FireDelay = value end })

	local priority = RageMain:Section({ Name = "Priority", Icon = Icon("targeting", "target"), Side = 2 })
	priority:Toggle({ Name = "Auto Prioritize", Default = false, Callback = function(value) VoidState.Priority = value end })
	priority:Dropdown({ Name = "Auto Priority Settings", Options = { "attackers", "cheaters" }, Default = { "attackers" }, Multi = true, Callback = function(value) VoidState.Settings = value end })
	priority:Toggle({ Name = "Send Notification", Default = true, Callback = function(value) VoidState.Notify = value end })
	priority:Button({ Name = "Clear Priority", Callback = function() VoidState.Attackers = {} VoidState.Cheaters = {} end })

	local function pickPart(character)
		local mode = RageState.Hitbox
		if mode == "Random" then mode = math.random() < 0.5 and "Head" or "Torso" end
		if mode == "Torso" then
			return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
		end
		return character:FindFirstChild("Head")
	end

	local function prioritized(player)
		if not VoidState.Priority then return false end
		if VoidState.Settings.attackers and VoidState.Attackers[player] then return true end
		if VoidState.Settings.cheaters and VoidState.Cheaters[player] then return true end
		return false
	end
	RageState.Prioritized = prioritized

	RunService.RenderStepped:Connect(function()
		if not RageState.Enabled then return end
		local camera = workspace.CurrentCamera
		local myCharacter = localPlayer.Character
		local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
		if not (camera and myRoot) then return end
		local center = camera.ViewportSize / 2
		local bestPart, bestScore, bestDistance
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player ~= localPlayer and player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health > 0 and not (player.Team ~= nil and player.Team == localPlayer.Team) then
				local distance = (root.Position - myRoot.Position).Magnitude
				local part = pickPart(character)
				if part and PX.canTarget(player, part, camera) then
					local score = distance
					if RageState.Priority == "Lowest Health" then
						score = humanoid.Health
					elseif RageState.Priority == "Closest To Crosshair" then
						local point, onScreen = camera:WorldToViewportPoint(part.Position)
						score = onScreen and (Vector2.new(point.X, point.Y) - center).Magnitude or math.huge
					end
					if prioritized(player) then score -= 1e9 end
					if not bestScore or score < bestScore then
						bestPart, bestScore, bestDistance = part, score, distance
					end
				end
			end
		end
		RageState.Part = bestPart
		if not bestPart or bestScore == math.huge then PX.reaction("rage", false) return end
		if not PX.reaction("rage", true) then return end
		camera.CFrame = CFrame.new(camera.CFrame.Position, bestPart.Position)
		if RageState.KnifeMode and bestDistance > RageState.KnifeRange then return end
		local now = os.clock()
		if now - lastShot >= RageState.FireDelay / 1000 and mouse1click then
			lastShot = now
			Fire.Last = now
			pcall(mouse1click)
		end
	end)

	local lastHealth
	local function watch(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then return end
		lastHealth = humanoid.Health
		humanoid.HealthChanged:Connect(function(health)
			if VoidState.Priority and VoidState.Settings.attackers and lastHealth and health < lastHealth then
				local myRoot = PX.root(character)
				local nearest, nearestAngle
				for _, player in ipairs(Players:GetPlayers()) do
					local root = player ~= localPlayer and PX.alive(player.Character) and PX.root(player.Character)
					if root and myRoot then
						local toMe = (myRoot.Position - root.Position).Unit
						local angle = math.acos(math.clamp(root.CFrame.LookVector:Dot(toMe), -1, 1))
						if angle < math.rad(25) and (not nearestAngle or angle < nearestAngle) then nearest, nearestAngle = player, angle end
					end
				end
				if nearest and not VoidState.Attackers[nearest] then
					VoidState.Attackers[nearest] = true
					if VoidState.Notify then pcall(function() Window:Notify("Prioritizing attacker " .. nearest.DisplayName) end) end
				end
			end
			lastHealth = health
		end)
	end
	if localPlayer.Character then task.spawn(watch, localPlayer.Character) end
	localPlayer.CharacterAdded:Connect(watch)

	local tracks = {}
	local lastScan = 0
	RunService.Heartbeat:Connect(function(dt)
		if not (VoidState.Priority and VoidState.Settings.cheaters) or os.clock() - lastScan < 0.2 then return end
		local elapsed = os.clock() - lastScan
		lastScan = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			local root = player ~= localPlayer and PX.alive(player.Character) and PX.root(player.Character)
			local track = tracks[player]
			if root then
				if track and track.Root == root then
					local delta = root.Position - track.Position
					local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude / math.max(elapsed, 0.05)
					local flag = false
					if delta.Magnitude > 120 and elapsed < 0.6 then flag = true end
					if horizontal > 95 then track.Fast = (track.Fast or 0) + elapsed else track.Fast = 0 end
					if track.Fast > 1 then flag = true end
					local grounded = PX.alive(player.Character) and player.Character:FindFirstChildOfClass("Humanoid").FloorMaterial ~= Enum.Material.Air
					if not grounded and math.abs(root.AssemblyLinearVelocity.Y) < 0.5 and horizontal > 20 then track.Hover = (track.Hover or 0) + elapsed else track.Hover = 0 end
					if track.Hover > 1.5 then flag = true end
					if flag and not VoidState.Cheaters[player] then
						VoidState.Cheaters[player] = true
						if VoidState.Notify then pcall(function() Window:Notify("Flagged cheater " .. player.DisplayName) end) end
					end
				else
					track = { Root = root }
					tracks[player] = track
				end
				track.Position = root.Position
			end
		end
	end)

	local function equip(slot)
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		local tools = PX.tools()
		local chosen
		for _, tool in ipairs(tools) do
			local name = string.lower(tool.Name)
			if slot == "knife" and (string.find(name, "knife") or string.find(name, "dagger")) then chosen = tool break end
			if slot == "melee" and (string.find(name, "katana") or string.find(name, "sword") or string.find(name, "bat") or string.find(name, "melee") or string.find(name, "fist")) then chosen = tool break end
		end
		if not chosen and (slot == "primary" or slot == "gun") then chosen = tools[1] end
		if not chosen and slot == "secondary" then chosen = tools[2] or tools[1] end
		if chosen and chosen.Parent ~= character then pcall(function() humanoid:EquipTool(chosen) end) end
	end

	local function ammoOf(tool)
		local value = tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo")
		if value == nil then
			local object = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo")
			value = object and object:IsA("ValueBase") and object.Value
		end
		return tonumber(value)
	end

	local function pickTarget()
		local best, bestScore
		local myRoot = PX.root(localPlayer.Character)
		if not myRoot then return nil end
		for _, player in ipairs(Players:GetPlayers()) do
			if PX.isEnemy(player, true) then
				local root = PX.root(player.Character)
				local score = (root.Position - myRoot.Position).Magnitude
				if prioritized(player) then score -= 1e6 end
				if not bestScore or score < bestScore then best, bestScore = player, score end
			end
		end
		return best
	end

	local phase, phaseStart, home = "hide", os.clock(), nil
	local swapSlot
	RunService.Heartbeat:Connect(function()
		local character = localPlayer.Character
		local myRoot = character and character:FindFirstChild("HumanoidRootPart")
		if not (VoidState.Enabled and RageState.Enabled and myRoot) then
			if home and myRoot then myRoot.CFrame = home end
			home = nil
			phase = "hide"
			return
		end
		local now = os.clock()
		local target = pickTarget()
		if phase == "hide" then
			if not home then home = myRoot.CFrame end
			myRoot.CFrame = CFrame.new(home.X, -480, home.Z)
			myRoot.AssemblyLinearVelocity = Vector3.zero
			if now - phaseStart >= VoidState.Hide and target then
				phase, phaseStart = "attack", now
			end
		else
			local targetRoot = target and PX.root(target.Character)
			if not targetRoot then
				phase, phaseStart = "hide", now
				return
			end
			local back = targetRoot.CFrame * CFrame.new(0, 0, VoidState.Mode == "gun" and 6 or 2.5)
			myRoot.CFrame = CFrame.lookAt(back.Position, targetRoot.Position)
			myRoot.AssemblyLinearVelocity = Vector3.zero
			local slot = VoidState.Mode == "gun" and (swapSlot or VoidState.Weapon) or VoidState.Mode
			equip(slot)
			local tool = PX.equipped()
			if VoidState.SwapEmpty and VoidState.Mode == "gun" and tool and ammoOf(tool) == 0 then
				swapSlot = (swapSlot or VoidState.Weapon) == "primary" and "secondary" or "primary"
			end
			local camera = workspace.CurrentCamera
			if camera then camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetRoot.Position) end
			for _ = 1, VoidState.Attempts do
				Fire.Last = now
				if tool then pcall(function() tool:Activate() end) end
				if mouse1click then pcall(mouse1click) end
			end
			if now - phaseStart >= VoidState.Attack then phase, phaseStart = "hide", now end
		end
	end)
end

local TriggerState = { Enabled = false, Delay = 100, TeamCheck = true, Offset = 0, Forget = 0.5, ShootDelay = 0, MaxDistance = 100, Blacklist = {}, NoDelayBetween = false, AntiKatana = true, Scoped = { Sniper = true, Crossbow = true } }
do
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local mouse = localPlayer:GetMouse()
	local lastClick, seenAt, lostAt, jitter, lastPlayer = 0, nil, nil, 0, nil

	local section = LegitTrigger:Section({ Name = "Triggerbot", Icon = Icon("trigger", "bullet"), Side = 1 })
	section:Toggle({ Name = "Enabled", Default = false, Keybind = Enum.KeyCode.T, Callback = function(value) TriggerState.Enabled = value end })
	section:Slider({ Name = "Reaction Time", Min = 0, Max = 300, Default = 100, Suffix = "ms", Callback = function(value) TriggerState.Delay = value end })
	section:Slider({ Name = "Reaction Time Offset", Min = 0, Max = 100, Default = 0, Suffix = "ms", Callback = function(value) TriggerState.Offset = value end })
	section:Slider({ Name = "Forget Time", Min = 0, Max = 10, Default = 0.5, Decimals = 1, Suffix = "s", Callback = function(value) TriggerState.Forget = value end })
	section:Slider({ Name = "Shoot Delay", Min = 0, Max = 300, Default = 0, Suffix = "ms", Callback = function(value) TriggerState.ShootDelay = value end })
	section:Slider({ Name = "Max Distance", Min = 25, Max = 500, Default = 100, Suffix = "s", Callback = function(value) TriggerState.MaxDistance = value end })
	section:Dropdown({ Name = "Part Blacklist", Options = PX.BodyParts, Default = {}, Multi = true, MaxRows = 12, Callback = function(value) TriggerState.Blacklist = value end })
	section:Dropdown({ Name = "Settings", Options = { "no delay between targets", "anti katana" }, Default = { "anti katana" }, Multi = true, Callback = function(value)
		TriggerState.NoDelayBetween = value["no delay between targets"] == true
		TriggerState.AntiKatana = value["anti katana"] == true
	end })
	section:Dropdown({ Name = "Check Scoped If", Options = { "Sniper", "Crossbow" }, Default = { "Sniper", "Crossbow" }, Multi = true, Callback = function(value) TriggerState.Scoped = value end })
	section:Toggle({ Name = "Team Check", Default = true, Callback = function(value) TriggerState.TeamCheck = value end })

	local function playerUnder(part)
		local model = part and part:FindFirstAncestorWhichIsA("Model")
		while model and not model:FindFirstChildOfClass("Humanoid") do
			model = model:FindFirstAncestorWhichIsA("Model")
		end
		return model and Players:GetPlayerFromCharacter(model), model
	end

	RunService.RenderStepped:Connect(function()
		if not TriggerState.Enabled then seenAt = nil return end
		local target = mouse.Target
		local player, model = playerUnder(target)
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if not player or player == localPlayer or not humanoid or humanoid.Health <= 0 then
			if seenAt and os.clock() - (lostAt or 0) > TriggerState.Forget then seenAt = nil end
			lostAt = lostAt or os.clock()
			return
		end
		lostAt = nil
		TriggerState.Player = player
		if TriggerState.TeamCheck and player.Team ~= nil and player.Team == localPlayer.Team then seenAt = nil return end
		if Targeting.DisableFlash and PX.Flashed then return end
		local blacklist = TriggerState.Blacklist
		if type(blacklist) == "table" and blacklist[target.Name] == true then return end
		local camera = workspace.CurrentCamera
		if camera and (target.Position - camera.CFrame.Position).Magnitude > TriggerState.MaxDistance then return end
		if Targeting.LimitDistance and camera and (target.Position - camera.CFrame.Position).Magnitude > Targeting.MaxDistance then return end
		if Targeting.VisibleOnly and camera and not PX.visible(camera, target, model) then return end
		if TriggerState.AntiKatana then
			local tool = model:FindFirstChildOfClass("Tool")
			if tool and string.find(string.lower(tool.Name), "katana") then return end
		end
		local held = PX.equipped()
		if held then
			for name in pairs(TriggerState.Scoped) do
				if string.find(string.lower(held.Name), string.lower(name)) and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
			end
		end
		local now = os.clock()
		if lastPlayer ~= player then
			if TriggerState.NoDelayBetween and seenAt then
				-- keep the existing reaction timer when switching targets
			else
				seenAt = nil
			end
			lastPlayer = player
		end
		if not seenAt then
			seenAt = now
			jitter = math.random() * TriggerState.Offset
		end
		if now - seenAt >= (TriggerState.Delay + jitter) / 1000 and now - lastClick > math.max(0.08, TriggerState.ShootDelay / 1000) and mouse1click then
			lastClick = now
			Fire.Last = now
			pcall(mouse1click)
		end
	end)
end

do
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer

	local state = { Speed = false, SpeedValue = 50, InfiniteJump = false, NoClip = false }
	local section = MovementMain:Section({ Name = "Character", Icon = Icon("speed", "smile"), Side = 1 })
	section:Toggle({ Name = "Speed", Default = false, Callback = function(value) state.Speed = value end })
	section:Slider({ Name = "Speed Amount", Min = 16, Max = 200, Default = state.SpeedValue, Callback = function(value) state.SpeedValue = value end })
	section:Toggle({ Name = "Infinite Jump", Default = false, Callback = function(value) state.InfiniteJump = value end })
	section:Toggle({ Name = "NoClip", Default = false, Keybind = Enum.KeyCode.N, Callback = function(value) state.NoClip = value end })

	RunService.Heartbeat:Connect(function()
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and state.Speed then humanoid.WalkSpeed = state.SpeedValue end
	end)
	RunService.Stepped:Connect(function()
		local character = localPlayer.Character
		if not (character and state.NoClip) then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end)
	UserInputService.JumpRequest:Connect(function()
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and state.InfiniteJump then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
end

do
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer

	local state = { Enabled = false, Material = "Neon", Color = Color3.fromRGB(255, 255, 255) }
	local section = VisualsCosmetics:Section({ Name = "Character", Icon = Icon("character", "smile"), Side = 1 })
	section:Toggle({ Name = "Character Material", Default = false, Color = state.Color, ColorCallback = function(color) state.Color = color end, Callback = function(value) state.Enabled = value end })
	section:Dropdown({ Name = "Material", Options = { "Neon", "ForceField", "Glass", "SmoothPlastic" }, Default = "Neon", Callback = function(value) state.Material = value end })

	local originals = setmetatable({}, { __mode = "k" })
	local function restore()
		for part, saved in pairs(originals) do
			if part.Parent then
				part.Material = saved.Material
				part.Color = saved.Color
			end
			originals[part] = nil
		end
	end

	RunService.RenderStepped:Connect(function()
		local character = localPlayer.Character
		if not (state.Enabled and character) then
			if next(originals) then restore() end
			return
		end
		local material = Enum.Material[state.Material]
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				if not originals[part] then originals[part] = { Material = part.Material, Color = part.Color } end
				part.Material = material
				part.Color = state.Color
			end
		end
	end)
end

do
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local Debris = game:GetService("Debris")
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("ParanoiaHits")
	if old then old:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "ParanoiaHits"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 60
	gui.Parent = playerGui

	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.AnchorPoint = Vector2.new(0.5, 0)
	list.Position = UDim2.new(0.5, 0, 0, 70)
	list.Size = UDim2.fromOffset(300, 200)
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list

	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BorderSizePixel = 0
	flash.BackgroundTransparency = 1
	flash.ZIndex = 0
	flash.Parent = gui

	local marker = Instance.new("Frame")
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Position = UDim2.fromScale(0.5, 0.5)
	marker.Size = UDim2.fromOffset(20, 20)
	marker.BackgroundTransparency = 1
	marker.Parent = gui
	local markerLines = {}
	for _, angle in ipairs({ 45, -45 }) do
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromScale(0.5, 0.5)
		line.Size = UDim2.fromOffset(20, 2)
		line.Rotation = angle
		line.BorderSizePixel = 0
		line.BackgroundTransparency = 1
		line.Parent = marker
		table.insert(markerLines, line)
	end

	local H = {
		Notify = { Enabled = false, Duration = 2.5, Color = Color3.fromRGB(255, 255, 255) },
		Marker = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
		Screen = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Intensity = 60, Duration = 0.35 },
		Chams = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Neon = true, Duration = 0.8 },
		Effect = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Kind = "Aura", Size = 10 },
	}

	local notify = VisualsHits:Section({ Name = "Hit Notify", Icon = Icon("preview", "smile"), Side = 1 })
	notify:Toggle({ Name = "Hit Notify", Default = false, Color = H.Notify.Color, ColorCallback = function(color) H.Notify.Color = color end, Callback = function(value) H.Notify.Enabled = value end })
	notify:Slider({ Name = "Notify Duration", Min = 0.5, Max = 6, Default = H.Notify.Duration, Decimals = 1, Suffix = "s", Callback = function(value) H.Notify.Duration = value end })
	notify:Divider()
	notify:Toggle({ Name = "Hit Marker", Default = false, Color = H.Marker.Color, ColorCallback = function(color) H.Marker.Color = color end, Callback = function(value) H.Marker.Enabled = value end })
	notify:Divider()
	notify:Toggle({ Name = "Hit Screen", Default = false, Color = H.Screen.Color, ColorCallback = function(color) H.Screen.Color = color end, Callback = function(value) H.Screen.Enabled = value end })
	notify:Slider({ Name = "Screen Intensity", Min = 5, Max = 100, Default = H.Screen.Intensity, Suffix = "%", Callback = function(value) H.Screen.Intensity = value end })
	notify:Slider({ Name = "Screen Duration", Min = 0.1, Max = 2, Default = H.Screen.Duration, Decimals = 2, Suffix = "s", Callback = function(value) H.Screen.Duration = value end })

	local chams = VisualsHits:Section({ Name = "Hit Chams", Icon = Icon("effects", "globe"), Side = 2 })
	chams:Toggle({ Name = "Hit Chams", Default = false, Color = H.Chams.Color, ColorCallback = function(color) H.Chams.Color = color end, Callback = function(value) H.Chams.Enabled = value end })
	chams:Toggle({ Name = "Neon Glow", Default = true, Callback = function(value) H.Chams.Neon = value end })
	chams:Slider({ Name = "Chams Duration", Min = 0.1, Max = 4, Default = H.Chams.Duration, Decimals = 1, Suffix = "s", Callback = function(value) H.Chams.Duration = value end })
	chams:Divider()
	chams:Toggle({ Name = "Hit Effect", Default = false, Color = H.Effect.Color, ColorCallback = function(color) H.Effect.Color = color end, Callback = function(value) H.Effect.Enabled = value end })
	chams:Dropdown({ Name = "Effect", Options = { "Aura", "Bubble", "Ring", "Sparks" }, Default = "Aura", Callback = function(value) H.Effect.Kind = value end })
	chams:Slider({ Name = "Effect Size", Min = 3, Max = 30, Default = H.Effect.Size, Callback = function(value) H.Effect.Size = value end })

	local function toast(text)
		local label = Instance.new("TextLabel")
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.fromOffset(0, 24)
		label.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
		label.BackgroundTransparency = 0.1
		label.BorderSizePixel = 0
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 13
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = text
		label.Parent = list
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = label
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = label
		local stroke = Instance.new("UIStroke")
		stroke.Color = H.Notify.Color
		stroke.Thickness = 1.5
		stroke.Parent = label
		task.delay(H.Notify.Duration, function()
			local info = TweenInfo.new(0.25)
			TweenService:Create(label, info, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
			TweenService:Create(stroke, info, { Transparency = 1 }):Play()
			Debris:AddItem(label, 0.3)
		end)
	end

	local function burst(position, kind, color, size)
		local function part(shape, partSize, material, transparency)
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Shape = shape
			p.Size = partSize
			p.Material = material
			p.Color = color
			p.Transparency = transparency
			p.Position = position
			p.Parent = workspace
			Debris:AddItem(p, 2)
			return p
		end
		if kind == "Aura" then
			local p = part(Enum.PartType.Ball, Vector3.one * 2, Enum.Material.Neon, 0.35)
			TweenService:Create(p, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.one * size, Transparency = 1 }):Play()
		elseif kind == "Bubble" then
			local p = part(Enum.PartType.Ball, Vector3.one * 1.5, Enum.Material.ForceField, 0.2)
			TweenService:Create(p, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = Vector3.one * size * 0.8, Position = position + Vector3.new(0, size * 0.4, 0), Transparency = 1 }):Play()
		elseif kind == "Ring" then
			local p = part(Enum.PartType.Cylinder, Vector3.new(0.3, 2, 2), Enum.Material.Neon, 0.2)
			p.CFrame = CFrame.new(position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
			TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.3, size * 1.6, size * 1.6), Transparency = 1 }):Play()
		else
			local p = part(Enum.PartType.Block, Vector3.one * 0.2, Enum.Material.SmoothPlastic, 1)
			local emitter = Instance.new("ParticleEmitter")
			emitter.Texture = "rbxasset://textures/particles/sparkles_main.dng"
			emitter.Color = ColorSequence.new(color)
			emitter.LightEmission = 1
			emitter.Lifetime = NumberRange.new(0.4, 0.8)
			emitter.Speed = NumberRange.new(10, 22)
			emitter.SpreadAngle = Vector2.new(180, 180)
			emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
			emitter.Rate = 0
			emitter.Parent = p
			emitter:Emit(30)
		end
	end

	PX.H = H
	local function hitChams(character)
		local info = TweenInfo.new(H.Chams.Duration)
		local highlight = Instance.new("Highlight")
		highlight.Adornee = character
		highlight.FillColor = H.Chams.Color
		highlight.OutlineColor = H.Chams.Color
		highlight.FillTransparency = 0.3
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = gui
		TweenService:Create(highlight, info, { FillTransparency = 1, OutlineTransparency = 1 }):Play()
		Debris:AddItem(highlight, H.Chams.Duration + 0.1)
		if H.Chams.Neon then
			local saved = {}
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					saved[part] = { part.Material, part.Color }
					part.Material = Enum.Material[H.Chams.MaterialName or "Neon"] or Enum.Material.Neon
					part.Color = H.Chams.Color
				end
			end
			task.delay(H.Chams.Duration, function()
				for part, original in pairs(saved) do
					if part.Parent then
						part.Material = original[1]
						part.Color = original[2]
					end
				end
			end)
		end
	end

	local function registerHit(player, character, damage, killed)
		local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
		for _, handler in ipairs(HitSignals) do pcall(handler, player, character, damage, killed) end
		if H.Notify.Enabled then
			toast(killed and ("Killed " .. player.DisplayName) or string.format("Hit %s  -%d", player.DisplayName, math.floor(damage + 0.5)))
		end
		if H.Marker.Enabled then
			for _, line in ipairs(markerLines) do
				line.BackgroundColor3 = H.Marker.Color
				line.BackgroundTransparency = 0
				TweenService:Create(line, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			end
		end
		if H.Screen.Enabled then
			flash.BackgroundColor3 = H.Screen.Color
			flash.BackgroundTransparency = 1 - H.Screen.Intensity / 100
			TweenService:Create(flash, TweenInfo.new(H.Screen.Duration), { BackgroundTransparency = 1 }):Play()
		end
		if H.Chams.Enabled then hitChams(character) end
		if H.Effect.Enabled and root then burst(root.Position, H.Effect.Kind, H.Effect.Color, H.Effect.Size) end
	end

	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Fire.Held = true
			Fire.Last = os.clock()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Fire.Held = false
			Fire.Last = os.clock()
		end
	end)

	local health = setmetatable({}, { __mode = "k" })
	RunService.Heartbeat:Connect(function()
		local camera = workspace.CurrentCamera
		local armed = Fire.Held or os.clock() - Fire.Last < 0.4
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player ~= localPlayer and player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local previous = health[humanoid]
				health[humanoid] = humanoid.Health
				if previous and humanoid.Health < previous and armed and camera then
					local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
					if head then
						local point, onScreen = camera:WorldToViewportPoint(head.Position)
						local center = camera.ViewportSize / 2
						if onScreen and (Vector2.new(point.X, point.Y) - center).Magnitude < 400 then
							registerHit(player, character, previous - humanoid.Health, humanoid.Health <= 0)
						end
					end
				end
			end
		end
	end)
end

do
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local UTILITIES = { "Flashbang", "Freeze Ray", "Grenade", "Jump Pad", "Molotov", "Satchel", "Smoke Grenade", "War Horn", "Medkit", "Subspace Tripmine", "Warpstone", "Grappler" }
	local P = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Whitelist = {}, Impact = true, Speed = 70, Lift = 0.25, Radius = 12 }
	for _, name in ipairs(UTILITIES) do P.Whitelist[name] = true end

	local section = VisualsGrenades:Section({ Name = "Projectile", Icon = Icon("targeting", "bullet"), Side = 1 })
	section:Toggle({ Name = "Grenade Projectory", Default = false, Color = P.Color, ColorCallback = function(color) P.Color = color end, Callback = function(value) P.Enabled = value end })
	section:Dropdown({ Name = "Whitelisted Utilities", Options = UTILITIES, Default = UTILITIES, Multi = true, MaxRows = 12, Callback = function(value) P.Whitelist = value end })
	section:Toggle({ Name = "Show Impact Circle", Default = true, Callback = function(value) P.Impact = value end })
	section:Slider({ Name = "Impact Radius", Min = 2, Max = 40, Default = P.Radius, Suffix = " studs", Callback = function(value) P.Radius = value end })
	section:Slider({ Name = "Throw Speed", Min = 20, Max = 200, Default = P.Speed, Callback = function(value) P.Speed = value end })
	section:Slider({ Name = "Throw Lift", Min = 0, Max = 100, Default = P.Lift * 100, Suffix = "%", Callback = function(value) P.Lift = value / 100 end })

	local old = playerGui:FindFirstChild("ParanoiaProjectile")
	if old then old:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "ParanoiaProjectile"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 45
	gui.Parent = playerGui

	local STEPS = 70
	local dots = {}
	for index = 1, STEPS do
		local dot = Instance.new("Frame")
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Size = UDim2.fromOffset(4, 4)
		dot.BorderSizePixel = 0
		dot.Visible = false
		dot.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot
		dots[index] = dot
	end

	local disc = Instance.new("Part")
	disc.Name = "ParanoiaImpact"
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.CanTouch = false
	disc.CastShadow = false
	disc.Shape = Enum.PartType.Cylinder
	disc.Material = Enum.Material.Neon
	disc.Transparency = 1
	disc.Size = Vector3.new(0.15, 1, 1)
	disc.Parent = workspace

	local function equippedName()
		local character = localPlayer.Character
		local tool = character and character:FindFirstChildOfClass("Tool")
		if tool then return tool.Name end
		for _, key in ipairs({ "EquippedItem", "CurrentItem", "Equipped", "CurrentWeapon" }) do
			local value = localPlayer:GetAttribute(key) or (character and character:GetAttribute(key))
			if type(value) == "string" then return value end
		end
	end

	local function allowed(name)
		if not name then return false end
		local lowered = string.lower(name)
		for utility, enabled in pairs(P.Whitelist) do
			if enabled and string.find(lowered, string.lower(utility), 1, true) then return true end
		end
		return false
	end

	local function hideAll()
		for _, dot in ipairs(dots) do dot.Visible = false end
		disc.Transparency = 1
	end

	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not (P.Enabled and camera and allowed(equippedName())) then return hideAll() end

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { localPlayer.Character, disc }
		local look = camera.CFrame.LookVector
		local velocity = (look + Vector3.new(0, P.Lift, 0)).Unit * P.Speed
		local position = camera.CFrame.Position + look * 2
		local gravity = Vector3.new(0, -workspace.Gravity, 0)
		local step = 1 / 30
		local impact, normal

		for index = 1, STEPS do
			local nextPosition = position + velocity * step + gravity * (0.5 * step * step)
			velocity += gravity * step
			local hit = workspace:Raycast(position, nextPosition - position, params)
			local dot = dots[index]
			local point, onScreen = camera:WorldToViewportPoint(hit and hit.Position or nextPosition)
			dot.Visible = onScreen and point.Z > 0
			dot.Position = UDim2.fromOffset(point.X, point.Y)
			dot.BackgroundColor3 = P.Color
			if hit then
				impact, normal = hit.Position, hit.Normal
				for rest = index + 1, STEPS do dots[rest].Visible = false end
				break
			end
			position = nextPosition
		end

		if impact and P.Impact then
			disc.Color = P.Color
			disc.Transparency = 0.45
			disc.Size = Vector3.new(0.15, P.Radius * 2, P.Radius * 2)
			disc.CFrame = CFrame.lookAt(impact + normal * 0.1, impact + normal * 2) * CFrame.Angles(0, math.rad(90), 0)
		else
			disc.Transparency = 1
		end
	end)
end

EspWorld:Section({ Name = "World", Icon = Icon("world", "globe"), Side = 1 }):Label({ Name = "Nothing here yet" })
EspCosmetics:Section({ Name = "Cosmetics", Icon = Icon("preview", "smile"), Side = 1 }):Label({ Name = "Nothing here yet" })

local SilentState = { Enabled = false, Radius = 100, HitChance = 100, Closest = false, Manipulation = false, Visualize = true, ShowFov = false, Color = Color3.fromRGB(255, 255, 255), Fill = false, Outline = false, Part = nil, Roll = true, Moving = false, Rotation = 0, RotationSpeed = 1, Lerp = 1, FillColor = Color3.fromRGB(255, 255, 255), TeamCheck = true, FovPosition = {} }
do
	local RunService = game:GetService("RunService")
	local localPlayer = PX.Local
	local mouse = localPlayer:GetMouse()
	local gui = PX.gui("ParanoiaSilent", 41)

	local circle = Instance.new("Frame")
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.BackgroundTransparency = 1
	circle.Visible = false
	circle.Parent = gui
	Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke", circle)
	stroke.Thickness = 1
	local gradient = Instance.new("UIGradient", stroke)
	gradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1) })
	local visual = Instance.new("Frame")
	visual.AnchorPoint = Vector2.new(0, 0.5)
	visual.BorderSizePixel = 0
	visual.Visible = false
	visual.Parent = gui

	local section = LegitSilent:Section({ Name = "Silent Aim", Icon = Icon("silent", "bullet"), Side = 1 })
	section:Toggle({ Name = "Enabled", Default = false, Keybind = Enum.KeyCode.V, Callback = function(value) SilentState.Enabled = value end })
	section:Toggle({ Name = "Manipulation", Default = false, Callback = function(value) SilentState.Manipulation = value end })
	section:Toggle({ Name = "Closest Part", Default = false, Callback = function(value) SilentState.Closest = value end })
	section:Toggle({ Name = "Visualize", Default = true, Callback = function(value) SilentState.Visualize = value end })
	section:Toggle({ Name = "Show FOV", Default = false, Color = SilentState.Color, ColorCallback = function(color) SilentState.Color = color end, Callback = function(value) SilentState.ShowFov = value end })
	section:Toggle({ Name = "FOV Outline", Default = false, Callback = function(value) SilentState.Outline = value end })
	section:Toggle({ Name = "FOV Fill", Default = false, Color = SilentState.FillColor, ColorCallback = function(color) SilentState.FillColor = color end, Callback = function(value) SilentState.Fill = value end })
	section:Slider({ Name = "FOV Lerp", Min = 0.01, Max = 1, Default = 1, Decimals = 2, Suffix = "x", Callback = function(value) SilentState.Lerp = value end })
	section:Toggle({ Name = "Moving Rotation", Default = false, Callback = function(value) SilentState.Moving = value end })
	section:Slider({ Name = "FOV Rotation", Min = 0, Max = 360, Default = 0, Suffix = "deg", Callback = function(value) SilentState.Rotation = value end })
	section:Slider({ Name = "Rotation Speed", Min = 0.1, Max = 10, Default = 1, Decimals = 1, Suffix = "rps", Callback = function(value) SilentState.RotationSpeed = value end })
	section:Dropdown({ Name = "FOV Settings", Options = { "position on target", "position on barrel" }, Default = {}, Multi = true, Callback = function(value) SilentState.FovPosition = value end })
	section:Slider({ Name = "Radius", Min = 0, Max = 1000, Default = 100, Suffix = "px", Callback = function(value) SilentState.Radius = value end })
	section:Slider({ Name = "Hit Chance", Min = 1, Max = 100, Default = 100, Suffix = "%", Callback = function(value) SilentState.HitChance = value end })
	section:Toggle({ Name = "Team Check", Default = true, Callback = function(value) SilentState.TeamCheck = value end })

	local function pick(camera, center)
		local bestPart, bestDistance = nil, SilentState.Radius
		for _, player in ipairs(PX.Players:GetPlayers()) do
			if PX.isEnemy(player, SilentState.TeamCheck) then
				local part = PX.pickPart(player.Character, camera, center, SilentState.Closest)
				if part and PX.canTarget(player, part, camera) then
					local point, onScreen = camera:WorldToViewportPoint(part.Position)
					if onScreen then
						local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
						if distance <= bestDistance then bestPart, bestDistance = part, distance end
					end
				end
			end
		end
		return bestPart
	end

	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then return end
		local viewport = camera.ViewportSize
		local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
		local part = SilentState.Enabled and pick(camera, center) or nil
		if not PX.reaction("silent", part ~= nil) then part = nil end
		SilentState.Part = part
		SilentState.Roll = math.random(1, 100) <= SilentState.HitChance
		local targetPoint
		if part then
			local point = camera:WorldToViewportPoint(part.Position)
			targetPoint = Vector2.new(point.X, point.Y)
		end
		local fovCenter = center
		if SilentState.FovPosition["position on barrel"] then fovCenter = PX.barrelPoint(camera) or fovCenter end
		if SilentState.FovPosition["position on target"] and targetPoint then fovCenter = targetPoint end
		local radius = SilentState.Radius * SilentState.Lerp
		circle.Visible = SilentState.ShowFov and SilentState.Enabled
		circle.Position = UDim2.fromOffset(fovCenter.X, fovCenter.Y)
		circle.Size = UDim2.fromOffset(radius * 2, radius * 2)
		stroke.Color = SilentState.Color
		stroke.Enabled = SilentState.Outline
		circle.BackgroundColor3 = SilentState.FillColor
		circle.BackgroundTransparency = SilentState.Fill and 0.85 or 1
		gradient.Rotation = SilentState.Moving and (os.clock() * SilentState.RotationSpeed * 360) % 360 or SilentState.Rotation
		gradient.Enabled = SilentState.Moving or SilentState.Rotation ~= 0
		if SilentState.Visualize and targetPoint then
			local delta = targetPoint - fovCenter
			visual.Visible = true
			visual.BackgroundColor3 = SilentState.Color
			visual.Position = UDim2.fromOffset(fovCenter.X, fovCenter.Y)
			visual.Size = UDim2.fromOffset(delta.Magnitude, 1)
			visual.Rotation = math.deg(math.atan2(delta.Y, delta.X))
		else
			visual.Visible = false
		end
	end)

	local function redirect(origin, direction)
		local part = SilentState.Part
		if not part or not SilentState.Roll then return nil end
		if SilentState.Manipulation then
			local toTarget = part.Position - origin
			if toTarget.Magnitude > 12 then origin = origin + toTarget.Unit * math.min(toTarget.Magnitude - 4, 12) end
		end
		local length = math.max(direction.Magnitude, 1000)
		return origin, (part.Position - origin).Unit * length
	end

	if hookmetamethod and getnamecallmethod and newcclosure then
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			if SilentState.Part and not (checkcaller and checkcaller()) then
				local method = getnamecallmethod()
				if self == workspace and method == "Raycast" then
					local args = table.pack(...)
					if typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
						local origin, direction = redirect(args[1], args[2])
						if origin then
							args[1], args[2] = origin, direction
							return oldNamecall(self, table.unpack(args, 1, args.n))
						end
					end
				elseif self == workspace and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") then
					local args = table.pack(...)
					if typeof(args[1]) == "Ray" then
						local origin, direction = redirect(args[1].Origin, args[1].Direction)
						if origin then
							args[1] = Ray.new(origin, direction)
							return oldNamecall(self, table.unpack(args, 1, args.n))
						end
					end
				elseif self == workspace.CurrentCamera and (method == "ViewportPointToRay" or method == "ScreenPointToRay") then
					local ray = oldNamecall(self, ...)
					local origin, direction = redirect(ray.Origin, ray.Direction)
					if origin then return Ray.new(origin, direction.Unit) end
					return ray
				end
			end
			return oldNamecall(self, ...)
		end))
		local oldIndex
		oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
			if self == mouse and SilentState.Part and SilentState.Roll and not (checkcaller and checkcaller()) then
				if key == "Hit" then return SilentState.Part.CFrame end
				if key == "Target" then return SilentState.Part end
			end
			return oldIndex(self, key)
		end))
	else
		section:Label({ Name = "Executor lacks hookmetamethod" })
	end
end

local AntiAim = { Enabled = false, Pitch = "disabled", PitchAngle = 0, Yaw = "disabled", YawAngle = 0, Underground = false }
do
	local RunService = game:GetService("RunService")
	local localPlayer = PX.Local
	local section = RageAntiAim:Section({ Name = "Anti Aim", Icon = Icon("antiaim", "wrench"), Side = 1 })
	section:Toggle({ Name = "Enabled", Default = false, Callback = function(value) AntiAim.Enabled = value end })
	section:Dropdown({ Name = "Pitch", Options = { "disabled", "offset", "look up", "look down", "custom", "extended custom", "extended random" }, Default = "disabled", Callback = function(value) AntiAim.Pitch = value end })
	section:Slider({ Name = "Pitch Angle", Min = -180, Max = 180, Default = 0, Suffix = "deg", Callback = function(value) AntiAim.PitchAngle = value end })
	section:Dropdown({ Name = "Yaw", Options = { "disabled", "backwards", "random", "custom", "offset" }, Default = "disabled", Callback = function(value) AntiAim.Yaw = value end })
	section:Slider({ Name = "Yaw Angle", Min = -180, Max = 180, Default = 0, Suffix = "deg", Callback = function(value) AntiAim.YawAngle = value end })
	section:Toggle({ Name = "Underground", Default = false, Keybind = Enum.KeyCode.U, Callback = function(value) AntiAim.Underground = value end })

	local defaults = setmetatable({}, { __mode = "k" })
	local originalHip
	RunService.Heartbeat:Connect(function()
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (humanoid and root) then return end
		local neck = character:FindFirstChild("Neck", true)
		if neck and neck:IsA("Motor6D") and not defaults[neck] then defaults[neck] = neck.C0 end
		if AntiAim.Underground then
			originalHip = originalHip or humanoid.HipHeight
			humanoid.HipHeight = -math.max(humanoid.HipHeight + 3.2, 3.2)
		elseif originalHip then
			humanoid.HipHeight = originalHip
			originalHip = nil
		end
		if not AntiAim.Enabled then
			if neck and defaults[neck] then neck.C0 = defaults[neck] end
			if humanoid.AutoRotate == false and AntiAim.Yaw == "disabled" then humanoid.AutoRotate = true end
			return
		end
		if neck and defaults[neck] then
			local pitch = 0
			local mode = AntiAim.Pitch
			if mode == "offset" then pitch = AntiAim.PitchAngle
			elseif mode == "look up" then pitch = 85
			elseif mode == "look down" then pitch = -85
			elseif mode == "custom" then pitch = math.clamp(AntiAim.PitchAngle, -89, 89)
			elseif mode == "extended custom" then pitch = AntiAim.PitchAngle
			elseif mode == "extended random" then pitch = math.random(-180, 180) end
			if mode == "disabled" then
				neck.C0 = defaults[neck]
			else
				neck.C0 = defaults[neck] * CFrame.Angles(math.rad(pitch), 0, 0)
			end
		end
		local yaw = AntiAim.Yaw
		if yaw ~= "disabled" then
			humanoid.AutoRotate = false
			local camera = workspace.CurrentCamera
			local _, cameraYaw = camera.CFrame:ToOrientation()
			local angle
			if yaw == "backwards" then angle = cameraYaw + math.pi
			elseif yaw == "random" then angle = math.rad(math.random(-180, 180))
			elseif yaw == "custom" then angle = math.rad(AntiAim.YawAngle)
			else angle = cameraYaw + math.rad(AntiAim.YawAngle) end
			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, angle, 0)
		end
	end)
end

local WeaponMods = { NoSpread = false, FullAuto = false, Firerate = 100, Backstab = false, Grenade = {} }
do
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local section = MiscWeapons:Section({ Name = "Weapon Mods", Icon = Icon("weaponmods", "wrench"), Side = 1 })
	local originals = {}
	local SPREAD = { "spread", "shotspread", "bulletspread", "inaccuracy", "recoil", "recoilx", "recoily", "shake" }
	local RATE = { "shootcooldown", "firecooldown", "cooldown", "firedelay", "firerate", "rpm", "shotdelay" }

	local function scan()
		local ok, library = pcall(function() return require(ReplicatedStorage:FindFirstChild("Modules"):FindFirstChild("ItemLibrary")) end)
		local roots = {}
		if ok and type(library) == "table" then table.insert(roots, library) end
		if getgc then
			for _, value in ipairs(getgc(true)) do
				if type(value) == "table" and rawget(value, "ShootCooldown") ~= nil then table.insert(roots, { value }) end
			end
		end
		return roots
	end

	local function apply()
		for _, root in ipairs(scan()) do
			local seen = {}
			local function walk(tbl, depth)
				if depth > 5 or seen[tbl] then return end
				seen[tbl] = true
				for key, value in pairs(tbl) do
					if type(key) == "string" then
						local lower = string.lower(key)
						local record = originals[tbl] or {}
						if type(value) == "number" or type(value) == "boolean" then
							if WeaponMods.NoSpread and table.find(SPREAD, lower) and type(value) == "number" then
								record[key] = record[key] == nil and value or record[key]
								originals[tbl] = record
								tbl[key] = 0
							elseif table.find(RATE, lower) and type(value) == "number" then
								if record[key] == nil then record[key] = value originals[tbl] = record end
								tbl[key] = record[key] * (100 / math.max(WeaponMods.Firerate, 10))
							elseif WeaponMods.FullAuto and (lower == "auto" or lower == "automatic" or lower == "fullauto") then
								if record[key] == nil then record[key] = value originals[tbl] = record end
								tbl[key] = true
							end
						elseif type(value) == "table" then
							walk(value, depth + 1)
						end
					end
				end
			end
			pcall(walk, root, 0)
		end
	end

	local function restore()
		for tbl, record in pairs(originals) do
			for key, value in pairs(record) do pcall(function() tbl[key] = value end) end
		end
		table.clear(originals)
	end

	local function refresh()
		if WeaponMods.NoSpread or WeaponMods.FullAuto or WeaponMods.Firerate < 100 then
			restore()
			apply()
		else
			restore()
		end
	end

	section:Toggle({ Name = "No Spread", Default = false, Callback = function(value) WeaponMods.NoSpread = value refresh() end })
	section:Toggle({ Name = "Full Auto", Default = false, Callback = function(value) WeaponMods.FullAuto = value refresh() end })
	section:Slider({ Name = "Firerate", Min = 10, Max = 100, Default = 100, Suffix = "%", Callback = function(value) WeaponMods.Firerate = value refresh() end })
	section:Toggle({ Name = "Always Backstab", Default = false, Callback = function(value) WeaponMods.Backstab = value end })
	section:Dropdown({ Name = "Grenade Options", Options = { "explode on throw", "remove fuse" }, Default = {}, Multi = true, Callback = function(value) WeaponMods.Grenade = value end })

	local viewmodelSection = VisualsCosmetics:Section({ Name = "Viewmodel", Icon = Icon("weaponmods", "wrench"), Side = 2 })
	local VM = { Disable = {}, Offset = false, X = 0, Y = 0, Z = 0, Override = false, Color = false, ColorValue = Color3.fromRGB(255, 255, 255), Material = false, MaterialValue = "ForceField", Wireframe = false, Transparency = 0, Chams = false, ChamColor = Color3.fromRGB(255, 255, 255), ChamFill = 0.5, ChamOutline = 0 }
	VM.Disable = {}
	viewmodelSection:Dropdown({ Name = "Disable", Options = { "sway", "bobbing", "muzzle flash", "idle animation", "jump animation", "shoot animation", "aiming animation", "sprint animation" }, Default = {}, Multi = true, MaxRows = 8, Callback = function(value) VM.Disable = value end })
	viewmodelSection:Toggle({ Name = "Offset", Default = false, Callback = function(value) VM.Offset = value end })
	viewmodelSection:Slider({ Name = "Offset X", Min = -3, Max = 3, Default = 0, Decimals = 1, Callback = function(value) VM.X = value end })
	viewmodelSection:Slider({ Name = "Offset Y", Min = -3, Max = 3, Default = 0, Decimals = 1, Callback = function(value) VM.Y = value end })
	viewmodelSection:Slider({ Name = "Offset Z", Min = -3, Max = 3, Default = 0, Decimals = 1, Callback = function(value) VM.Z = value end })
	viewmodelSection:Button({ Name = "Reset Offset", Callback = function() VM.X, VM.Y, VM.Z = 0, 0, 0 end })
	viewmodelSection:Toggle({ Name = "Override Appearance", Default = false, Color = VM.ColorValue, ColorCallback = function(color) VM.ColorValue = color end, Callback = function(value) VM.Override = value end })
	viewmodelSection:Dropdown({ Name = "Viewmodel Material", Options = PX.Materials, Default = "ForceField", MaxRows = 10, Callback = function(value) VM.MaterialValue = value VM.Material = true end })
	viewmodelSection:Toggle({ Name = "Wireframe", Default = false, Callback = function(value) VM.Wireframe = value end })
	viewmodelSection:Slider({ Name = "Viewmodel Transparency", Min = 0, Max = 100, Default = 0, Suffix = "%", Callback = function(value) VM.Transparency = value / 100 end })
	viewmodelSection:Toggle({ Name = "Viewmodel Chams", Default = false, Color = VM.ChamColor, ColorCallback = function(color) VM.ChamColor = color end, Callback = function(value) VM.Chams = value end })
	viewmodelSection:Slider({ Name = "Cham Fill", Min = 0, Max = 100, Default = 50, Suffix = "%", Callback = function(value) VM.ChamFill = value / 100 end })
	viewmodelSection:Slider({ Name = "Cham Outline", Min = 0, Max = 100, Default = 0, Suffix = "%", Callback = function(value) VM.ChamOutline = value / 100 end })

	local RunService = game:GetService("RunService")
	local appearance = setmetatable({}, { __mode = "k" })
	local function viewmodels()
		local camera = workspace.CurrentCamera
		local list = {}
		if not camera then return list end
		for _, child in ipairs(camera:GetChildren()) do
			if child:IsA("Model") and not child:FindFirstChildOfClass("Humanoid") then table.insert(list, child) end
		end
		return list
	end

	RunService.RenderStepped:Connect(function()
		for _, model in ipairs(viewmodels()) do
			if VM.Offset then
				pcall(function() model:PivotTo(model:GetPivot() * CFrame.new(VM.X, VM.Y, VM.Z)) end)
			end
			local highlight = model:FindFirstChild("ParanoiaVMChams")
			if VM.Chams then
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "ParanoiaVMChams"
					highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					highlight.Parent = model
				end
				highlight.FillColor, highlight.OutlineColor = VM.ChamColor, VM.ChamColor
				highlight.FillTransparency, highlight.OutlineTransparency = VM.ChamFill, VM.ChamOutline
			elseif highlight then
				highlight:Destroy()
			end
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					local record = appearance[part]
					if VM.Override then
						if not record then record = { Color = part.Color, Material = part.Material, Transparency = part.Transparency } appearance[part] = record end
						part.Color = VM.ColorValue
						if VM.Material then part.Material = Enum.Material[VM.MaterialValue] or part.Material end
						part.Transparency = math.max(record.Transparency, VM.Transparency)
					elseif record then
						part.Color, part.Material, part.Transparency = record.Color, record.Material, record.Transparency
						appearance[part] = nil
					end
				elseif part:IsA("ParticleEmitter") and VM.Disable["muzzle flash"] then
					part.Enabled = false
				end
			end
		end
	end)
end

local Automation = { Chat = { Enabled = false, Order = false, Texts = { "Paranoia on top" }, Index = 1 }, Respawn = false, Drops = false, SpoofDevice = false, Device = "computer", NameLocal = false, NameValue = "Paranoia", NameOthers = false, NameOtherValue = "Paranoia", HitNotify = false, HitDuration = 1, HitText = "Hit {NAME} for {DMG}" }
do
	local RunService = game:GetService("RunService")
	local TextChatService = game:GetService("TextChatService")
	local UserInputService = game:GetService("UserInputService")
	local localPlayer = PX.Local
	local chat = MiscChat:Section({ Name = "Chat Spam", Icon = Icon("automation", "robot"), Side = 1 })
	chat:Toggle({ Name = "Chat Spam", Default = false, Callback = function(value) Automation.Chat.Enabled = value end })
	chat:Toggle({ Name = "In Order", Default = false, Callback = function(value) Automation.Chat.Order = value end })
	chat:Dropdown({ Name = "Chat Mode", Options = { "custom", "gg", "ez" }, Default = "custom", Callback = function(value)
		if value == "gg" then Automation.Chat.Texts = { "gg", "good game", "gg wp" }
		elseif value == "ez" then Automation.Chat.Texts = { "ez", "too easy", "sit down" }
		else Automation.Chat.Texts = { "Paranoia on top" } end
		Automation.Chat.Index = 1
	end })
	chat:Textbox({ Name = "Add Custom Text", Placeholder = "Add custom text", Callback = function(text)
		if text and text ~= "" then table.insert(Automation.Chat.Texts, text) end
	end })
	chat:Button({ Name = "Reset Texts", Callback = function() Automation.Chat.Texts = { "Paranoia on top" } Automation.Chat.Index = 1 end })

	local lastChat = 0
	RunService.Heartbeat:Connect(function()
		if not Automation.Chat.Enabled or os.clock() - lastChat < 3 then return end
		lastChat = os.clock()
		local texts = Automation.Chat.Texts
		local index = Automation.Chat.Order and Automation.Chat.Index or math.random(1, #texts)
		Automation.Chat.Index = Automation.Chat.Index % #texts + 1
		pcall(function()
			local channel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
			if channel then channel:SendAsync(texts[index]) end
		end)
	end)

	local arcade = MiscAutomation:Section({ Name = "Arcade", Icon = Icon("automation", "robot"), Side = 2 })
	arcade:Toggle({ Name = "Automatically Grab Drops", Default = false, Callback = function(value) Automation.Drops = value end })
	arcade:Toggle({ Name = "Auto Respawn", Default = false, Callback = function(value) Automation.Respawn = value end })

	local lastDrop = 0
	RunService.Heartbeat:Connect(function()
		if not Automation.Drops or os.clock() - lastDrop < 0.5 then return end
		lastDrop = os.clock()
		local root = PX.root(localPlayer.Character)
		if not (root and firetouchinterest) then return end
		for _, object in ipairs(workspace:GetDescendants()) do
			if object:IsA("BasePart") and not object:IsDescendantOf(localPlayer.Character) then
				local name = string.lower(object.Name)
				if (string.find(name, "ammo") or string.find(name, "drop") or string.find(name, "pickup")) and (object.Position - root.Position).Magnitude < 200 then
					pcall(function() firetouchinterest(root, object, 0) firetouchinterest(root, object, 1) end)
				end
			end
		end
	end)

	local function onCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then return end
		humanoid.Died:Connect(function()
			if Automation.Respawn then
				task.wait(0.5)
				pcall(function() localPlayer:LoadCharacter() end)
			end
		end)
	end
	if localPlayer.Character then task.spawn(onCharacter, localPlayer.Character) end
	localPlayer.CharacterAdded:Connect(onCharacter)

	local info = MiscSpoof:Section({ Name = "Spoofers", Icon = Icon("automation", "robot"), Side = 1 })
	info:Toggle({ Name = "Spoof Local Name", Default = false, Callback = function(value) Automation.NameLocal = value end })
	info:Textbox({ Name = "Local Name", Placeholder = "Local name", Default = "Paranoia", Callback = function(text) Automation.NameValue = text end })
	info:Toggle({ Name = "Spoof Other Names", Default = false, Callback = function(value) Automation.NameOthers = value end })
	info:Textbox({ Name = "Other Name", Placeholder = "Name for others", Default = "Paranoia", Callback = function(text) Automation.NameOtherValue = text end })
	info:Toggle({ Name = "Spoof Device", Default = false, Callback = function(value) Automation.SpoofDevice = value end })
	info:Dropdown({ Name = "Device", Options = { "computer", "mobile", "controller", "virtual reality" }, Default = "computer", Callback = function(value) Automation.Device = value end })

	local replaced = setmetatable({}, { __mode = "k" })
	local lastNames = 0
	RunService.Heartbeat:Connect(function()
		if os.clock() - lastNames < 0.5 then return end
		lastNames = os.clock()
		if not (Automation.NameLocal or Automation.NameOthers) then
			for label, text in pairs(replaced) do
				pcall(function() label.Text = text end)
				replaced[label] = nil
			end
			return
		end
		local gui = localPlayer:FindFirstChild("PlayerGui")
		if not gui then return end
		for _, label in ipairs(gui:GetDescendants()) do
			if (label:IsA("TextLabel") or label:IsA("TextButton")) and label.Text ~= "" then
				for _, player in ipairs(PX.Players:GetPlayers()) do
					local isLocal = player == localPlayer
					local wanted = isLocal and Automation.NameLocal and Automation.NameValue or (not isLocal and Automation.NameOthers and Automation.NameOtherValue)
					if wanted and (label.Text == player.Name or label.Text == player.DisplayName) then
						replaced[label] = replaced[label] or label.Text
						label.Text = wanted
					end
				end
			end
		end
	end)

	if hookmetamethod and newcclosure then
		local oldIndex
		oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
			if Automation.SpoofDevice and self == UserInputService and not (checkcaller and checkcaller()) then
				local device = Automation.Device
				if key == "TouchEnabled" then return device == "mobile" end
				if key == "KeyboardEnabled" or key == "MouseEnabled" then return device == "computer" end
				if key == "GamepadEnabled" then return device == "controller" end
				if key == "VREnabled" then return device == "virtual reality" end
			end
			return oldIndex(self, key)
		end))
	end

	local notify = MiscChat:Section({ Name = "Notify Hit", Icon = Icon("preview", "smile"), Side = 2 })
	notify:Toggle({ Name = "Notify Hit", Default = false, Callback = function(value) Automation.HitNotify = value end })
	notify:Slider({ Name = "Notify Duration", Min = 0.1, Max = 3, Default = 1, Decimals = 1, Suffix = "s", Callback = function(value) Automation.HitDuration = value end })
	notify:Textbox({ Name = "Notify Text", Placeholder = "Hit {NAME} for {DMG} in the {PART}", Default = "Hit {NAME} for {DMG}", Callback = function(text) if text ~= "" then Automation.HitText = text end end })
	table.insert(HitSignals, function(player, character, damage, killed)
		if not Automation.HitNotify then return end
		local text = string.gsub(Automation.HitText, "{NAME}", player.DisplayName)
		text = string.gsub(text, "{DMG}", tostring(math.floor(damage + 0.5)))
		text = string.gsub(text, "{PART}", "body")
		Window:Notify({ Title = "Hit", Text = text, Duration = Automation.HitDuration })
	end)
end

do
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local localPlayer = PX.Local
	local section = VisualsLocal:Section({ Name = "Camera", Icon = Icon("local", "smile"), Side = 1 })
	local state = { Flash = false, Fov = false, FovValue = 90, Aspect = false, AspectX = 1, AspectY = 1, Blur = 0, Vignette = false, NoSun = false, NoStars = false }
	section:Toggle({ Name = "Anti Flashbang", Default = false, Callback = function(value) state.Flash = value end })
	section:Toggle({ Name = "FOV Changer", Default = false, Callback = function(value) state.Fov = value end })
	section:Slider({ Name = "Changer FOV", Min = 5, Max = 120, Default = 90, Callback = function(value) state.FovValue = value end })
	section:Toggle({ Name = "Aspect Ratio", Default = false, Callback = function(value) state.Aspect = value end })
	section:Slider({ Name = "Ratio X", Min = 0.01, Max = 1, Default = 1, Decimals = 2, Callback = function(value) state.AspectX = value end })
	section:Slider({ Name = "Ratio Y", Min = 0.01, Max = 1, Default = 1, Decimals = 2, Callback = function(value) state.AspectY = value end })
	section:Slider({ Name = "Blur", Min = 0, Max = 10, Default = 0, Decimals = 1, Suffix = "x", Callback = function(value) state.Blur = value end })
	section:Toggle({ Name = "Remove Vignette", Default = false, Callback = function(value) state.Vignette = value end })

	local blur = Instance.new("BlurEffect")
	blur.Name = "ParanoiaBlur"
	blur.Size = 0
	blur.Enabled = false
	blur.Parent = Lighting

	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then return end
		if state.Fov then camera.FieldOfView = state.FovValue end
		if state.Aspect and (state.AspectX < 1 or state.AspectY < 1) then
			camera.CFrame = camera.CFrame * CFrame.new(0, 0, 0, state.AspectX, 0, 0, 0, state.AspectY, 0, 0, 0, 1)
		end
		blur.Enabled = state.Blur > 0
		blur.Size = state.Blur * 4
		if state.Flash then
			for _, effect in ipairs(Lighting:GetChildren()) do
				if string.find(string.lower(effect.Name), "flash") and effect:IsA("PostEffect") then effect.Enabled = false end
			end
			for _, effect in ipairs(camera:GetChildren()) do
				if string.find(string.lower(effect.Name), "flash") and effect:IsA("PostEffect") then effect.Enabled = false end
			end
		end
	end)

	local lastScan = 0
	RunService.Heartbeat:Connect(function()
		if os.clock() - lastScan < 0.4 then return end
		lastScan = os.clock()
		local gui = localPlayer:FindFirstChild("PlayerGui")
		if not gui then return end
		for _, object in ipairs(gui:GetDescendants()) do
			if object:IsA("GuiObject") and object.Name ~= "ParanoiaAimbot" then
				local name = string.lower(object.Name)
				if state.Vignette and string.find(name, "vignette") then object.Visible = false end
				if state.Flash and (string.find(name, "flashbang") or name == "flash" or name == "flashframe") then
					object.Visible = false
				end
			end
		end
	end)

	local effects = VisualsLocal:Section({ Name = "Lighting Effects", Icon = Icon("world", "globe"), Side = 2 })
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "ParanoiaColorCorrection"
	cc.Enabled = false
	cc.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "ParanoiaBloom"
	bloom.Enabled = false
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Name = "ParanoiaSunRays"
	rays.Enabled = false
	rays.Parent = Lighting
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "ParanoiaAtmosphere"
	local previousAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

	effects:Toggle({ Name = "Color Correction", Default = false, Color = Color3.fromRGB(255, 255, 255), ColorCallback = function(color) cc.TintColor = color end, Callback = function(value) cc.Enabled = value end })
	effects:Slider({ Name = "Saturation", Min = -10, Max = 10, Default = 0, Decimals = 1, Callback = function(value) cc.Saturation = value end })
	effects:Slider({ Name = "Contrast", Min = -10, Max = 10, Default = 0, Decimals = 1, Callback = function(value) cc.Contrast = value end })
	effects:Slider({ Name = "Color Brightness", Min = -1, Max = 1, Default = 0, Decimals = 2, Callback = function(value) cc.Brightness = value end })
	effects:Toggle({ Name = "Bloom", Default = false, Callback = function(value) bloom.Enabled = value end })
	effects:Slider({ Name = "Bloom Intensity", Min = 0, Max = 10, Default = 1, Decimals = 1, Callback = function(value) bloom.Intensity = value end })
	effects:Slider({ Name = "Bloom Size", Min = 0, Max = 100, Default = 24, Callback = function(value) bloom.Size = value end })
	effects:Slider({ Name = "Bloom Threshold", Min = 0.1, Max = 1, Default = 0.8, Decimals = 2, Callback = function(value) bloom.Threshold = value end })
	effects:Toggle({ Name = "Sun Rays", Default = false, Callback = function(value) rays.Enabled = value end })
	effects:Slider({ Name = "Rays Intensity", Min = 0, Max = 1, Default = 0.25, Decimals = 2, Callback = function(value) rays.Intensity = value end })
	effects:Slider({ Name = "Rays Spread", Min = 0, Max = 1, Default = 1, Decimals = 2, Callback = function(value) rays.Spread = value end })
	effects:Toggle({ Name = "Atmosphere", Default = false, Color = Color3.fromRGB(255, 255, 255), ColorCallback = function(color) atmosphere.Color = color end, Callback = function(value)
		if value then
			if previousAtmosphere then previousAtmosphere.Parent = nil end
			atmosphere.Parent = Lighting
		else
			atmosphere.Parent = nil
			if previousAtmosphere then previousAtmosphere.Parent = Lighting end
		end
	end })
	effects:Slider({ Name = "Glare", Min = 0, Max = 10, Default = 1.5, Decimals = 1, Callback = function(value) atmosphere.Glare = value end })
	effects:Slider({ Name = "Haze", Min = 0, Max = 10, Default = 10, Decimals = 1, Callback = function(value) atmosphere.Haze = value end })
	effects:Slider({ Name = "Atmosphere Offset", Min = 0, Max = 1, Default = 0.4, Decimals = 2, Callback = function(value) atmosphere.Offset = value end })
	effects:Slider({ Name = "Density", Min = 0, Max = 1, Default = 0.5, Decimals = 2, Callback = function(value) atmosphere.Density = value end })
end

do
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local Debris = game:GetService("Debris")
	local localPlayer = PX.Local
	local gui = PX.gui("ParanoiaCrosshair", 43)

	local C = { Enabled = false, Outline = true, Rotation = 0, Speed = 0.2, Bounce = 0, BounceSpeed = 1, Offset = 5, Length = 20, Thickness = 2, Color = Color3.fromRGB(255, 255, 255), DisableGame = false, Position = false }
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(0, 0)
	holder.Visible = false
	holder.Parent = gui
	local bars = {}
	for index = 1, 4 do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.BorderSizePixel = 0
		bar.Parent = holder
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Parent = bar
		bars[index] = { Bar = bar, Stroke = stroke }
	end

	local section = VisualsCrosshair:Section({ Name = "Crosshair", Icon = Icon("local", "smile"), Side = 1 })
	section:Toggle({ Name = "Custom Crosshair", Default = false, Color = C.Color, ColorCallback = function(color) C.Color = color end, Callback = function(value) C.Enabled = value end })
	section:Toggle({ Name = "Crosshair Outline", Default = true, Callback = function(value) C.Outline = value end })
	section:Slider({ Name = "Crosshair Rotation", Min = 0, Max = 360, Default = 0, Suffix = "deg", Callback = function(value) C.Rotation = value end })
	section:Slider({ Name = "Spin Speed", Min = 0, Max = 5, Default = 0.2, Decimals = 1, Suffix = "rps", Callback = function(value) C.Speed = value end })
	section:Slider({ Name = "Bounce", Min = 0, Max = 300, Default = 0, Suffix = "px", Callback = function(value) C.Bounce = value end })
	section:Slider({ Name = "Bounce Speed", Min = 0.1, Max = 5, Default = 1, Decimals = 1, Suffix = "x", Callback = function(value) C.BounceSpeed = value end })
	section:Slider({ Name = "Crosshair Offset", Min = 0, Max = 100, Default = 5, Suffix = "px", Callback = function(value) C.Offset = value end })
	section:Slider({ Name = "Arm Length", Min = 5, Max = 500, Default = 20, Suffix = "px", Callback = function(value) C.Length = value end })
	section:Slider({ Name = "Arm Thickness", Min = 1, Max = 10, Default = 2, Suffix = "px", Callback = function(value) C.Thickness = value end })
	section:Toggle({ Name = "Position On Target", Default = false, Callback = function(value) C.Position = value end })
	section:Toggle({ Name = "Disable Game Crosshair", Default = false, Callback = function(value) C.DisableGame = value end })

	local lastScan = 0
	RunService.RenderStepped:Connect(function(dt)
		local camera = workspace.CurrentCamera
		if not camera then return end
		holder.Visible = C.Enabled
		if C.Enabled then
			local viewport = camera.ViewportSize
			local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
			if C.Position then
				local target = SilentState.Part or nil
				if target then
					local point, onScreen = camera:WorldToViewportPoint(target.Position)
					if onScreen then center = Vector2.new(point.X, point.Y) end
				end
			end
			holder.Position = UDim2.fromOffset(center.X, center.Y)
			holder.Rotation = (C.Rotation + os.clock() * C.Speed * 360) % 360
			local bounce = C.Bounce > 0 and (math.sin(os.clock() * C.BounceSpeed * math.pi * 2) * 0.5 + 0.5) * C.Bounce or 0
			local distance = C.Offset + C.Length / 2 + bounce
			local layout = {
				{ 0, -distance, C.Thickness, C.Length },
				{ 0, distance, C.Thickness, C.Length },
				{ -distance, 0, C.Length, C.Thickness },
				{ distance, 0, C.Length, C.Thickness },
			}
			for index, spec in ipairs(layout) do
				local entry = bars[index]
				entry.Bar.Position = UDim2.fromOffset(spec[1], spec[2])
				entry.Bar.Size = UDim2.fromOffset(spec[3], spec[4])
				entry.Bar.BackgroundColor3 = C.Color
				entry.Stroke.Enabled = C.Outline
			end
		end
		if C.DisableGame and os.clock() - lastScan > 0.4 then
			lastScan = os.clock()
			local playerGui = localPlayer:FindFirstChild("PlayerGui")
			if playerGui then
				for _, object in ipairs(playerGui:GetDescendants()) do
					if object:IsA("GuiObject") and string.lower(object.Name) == "crosshair" and not object:IsDescendantOf(gui) then object.Visible = false end
				end
			end
		end
	end)

	local tracer = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Lifetime = 1, Fade = 1, Width = 0.3, Glow = false }
	local tracerSection = VisualsFx:Section({ Name = "Custom Tracers", Icon = Icon("effects", "globe"), Side = 1 })
	tracerSection:Toggle({ Name = "Custom Tracers", Default = false, Color = tracer.Color, ColorCallback = function(color) tracer.Color = color end, Callback = function(value) tracer.Enabled = value end })
	tracerSection:Slider({ Name = "Tracer Lifetime", Min = 0.1, Max = 3, Default = 1, Decimals = 1, Suffix = "s", Callback = function(value) tracer.Lifetime = value end })
	tracerSection:Slider({ Name = "Tracer Fade", Min = 0.1, Max = 3, Default = 1, Decimals = 1, Suffix = "s", Callback = function(value) tracer.Fade = value end })
	tracerSection:Slider({ Name = "Tracer Size", Min = 0.1, Max = 3, Default = 0.3, Decimals = 1, Callback = function(value) tracer.Width = value end })
	tracerSection:Toggle({ Name = "Tracer Glow", Default = false, Callback = function(value) tracer.Glow = value end })

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not tracer.Enabled or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local camera = workspace.CurrentCamera
		local character = localPlayer.Character
		if not (camera and character) then return end
		local origin = camera.CFrame.Position + camera.CFrame.LookVector * 1 + camera.CFrame.RightVector * 0.6 - camera.CFrame.UpVector * 0.5
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character, camera }
		local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 1000, params)
		local goal = result and result.Position or camera.CFrame.Position + camera.CFrame.LookVector * 1000
		local length = (goal - origin).Magnitude
		local beam = Instance.new("Part")
		beam.Anchored, beam.CanCollide, beam.CanQuery, beam.CanTouch = true, false, false, false
		beam.Material = tracer.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
		beam.Color = tracer.Color
		beam.Size = Vector3.new(tracer.Width, tracer.Width, length)
		beam.CFrame = CFrame.lookAt(origin, goal) * CFrame.new(0, 0, -length / 2)
		beam.Parent = workspace
		Debris:AddItem(beam, tracer.Lifetime + tracer.Fade + 0.1)
		task.delay(tracer.Lifetime, function()
			if beam.Parent then TweenService:Create(beam, TweenInfo.new(tracer.Fade), { Transparency = 1 }):Play() end
		end)
	end)
end

do
	local SoundService = game:GetService("SoundService")
	local HitSounds = { Enabled = false, Volume = 0.5, Selected = "neverlose" }
	local IDS = {
		neverlose = "rbxassetid://8726881116",
		skeet = "rbxassetid://5447626464",
		rust = "rbxassetid://1255040462",
		bameware = "rbxassetid://3124331820",
		bell = "rbxassetid://6534947240",
	}
	local names = {}
	for name in pairs(IDS) do table.insert(names, name) end
	table.sort(names)
	local section = VisualsHits:Section({ Name = "Hit Sounds", Icon = Icon("effects", "globe"), Side = 1 })
	section:Toggle({ Name = "Hit Sounds", Default = false, Callback = function(value) HitSounds.Enabled = value end })
	section:Slider({ Name = "Sound Volume", Min = 0.1, Max = 2, Default = 0.5, Decimals = 1, Callback = function(value) HitSounds.Volume = value end })
	section:Dropdown({ Name = "Hit Sound", Options = names, Default = "neverlose", Callback = function(value) HitSounds.Selected = value end })
	local function play()
		local sound = Instance.new("Sound")
		sound.SoundId = IDS[HitSounds.Selected] or IDS.neverlose
		sound.Volume = HitSounds.Volume
		sound.Parent = SoundService
		sound.Ended:Connect(function() sound:Destroy() end)
		sound:Play()
	end
	section:Button({ Name = "Preview Sound", Callback = play })
	table.insert(HitSignals, function() if HitSounds.Enabled then play() end end)
end

do
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local localPlayer = PX.Local
	local M = { Velocity = false, VelocitySpeed = 50, Slide = false, SlideValue = 1, DoubleJump = false, DoubleJumpValue = 1, InfiniteDouble = false, Fly = false, FlySpeed = 50, Third = false, Head = false }
	local section = MovementMain:Section({ Name = "Advanced", Icon = Icon("movement", "smile"), Side = 2 })
	section:Toggle({ Name = "Velocity", Default = false, Keybind = Enum.KeyCode.X, Callback = function(value) M.Velocity = value end })
	section:Slider({ Name = "Velocity Speed", Min = 10, Max = 250, Default = 50, Suffix = "s", Callback = function(value) M.VelocitySpeed = value end })
	section:Toggle({ Name = "Slide Boost", Default = false, Callback = function(value) M.Slide = value end })
	section:Slider({ Name = "Slide Boost Amount", Min = 1, Max = 5, Default = 1, Decimals = 1, Suffix = "x", Callback = function(value) M.SlideValue = value end })
	section:Toggle({ Name = "Double Jump Height", Default = false, Callback = function(value) M.DoubleJump = value end })
	section:Slider({ Name = "Double Jump Multiplier", Min = 1, Max = 10, Default = 1, Decimals = 1, Suffix = "x", Callback = function(value) M.DoubleJumpValue = value end })
	section:Toggle({ Name = "Infinite Double Jump", Default = false, Callback = function(value) M.InfiniteDouble = value end })
	section:Toggle({ Name = "Fly", Default = false, Keybind = Enum.KeyCode.F, Callback = function(value) M.Fly = value end })
	section:Slider({ Name = "Fly Speed", Min = 50, Max = 500, Default = 50, Suffix = "s", Callback = function(value) M.FlySpeed = value end })
	section:Toggle({ Name = "Third Person", Default = false, Keybind = Enum.KeyCode.P, Callback = function(value) M.Third = value end })

	local function directionFromInput(camera)
		local move = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
		return move
	end

	UserInputService.JumpRequest:Connect(function()
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (humanoid and root) then return end
		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
			if M.InfiniteDouble or M.DoubleJump then
				if M.DoubleJump then
					root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, humanoid.JumpPower * M.DoubleJumpValue, root.AssemblyLinearVelocity.Z)
				elseif M.InfiniteDouble then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end
	end)

	RunService.Heartbeat:Connect(function()
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		if not (humanoid and root and camera) then return end
		if M.Fly then
			local direction = directionFromInput(camera)
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end
			root.AssemblyLinearVelocity = direction.Magnitude > 0 and direction.Unit * M.FlySpeed or Vector3.zero
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		elseif M.Velocity and humanoid.MoveDirection.Magnitude > 0 then
			local direction = humanoid.MoveDirection
			root.AssemblyLinearVelocity = Vector3.new(direction.X * M.VelocitySpeed, root.AssemblyLinearVelocity.Y, direction.Z * M.VelocitySpeed)
		end
		if M.Slide and humanoid:GetState() == Enum.HumanoidStateType.Running and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and humanoid.MoveDirection.Magnitude > 0 then
			local velocity = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(velocity.X * (1 + 0.02 * (M.SlideValue - 1) + 0.0), velocity.Y, velocity.Z * (1 + 0.02 * (M.SlideValue - 1)))
		end
		if M.Third then
			localPlayer.CameraMode = Enum.CameraMode.Classic
			localPlayer.CameraMaxZoomDistance = 12
			localPlayer.CameraMinZoomDistance = 12
		elseif localPlayer.CameraMinZoomDistance == 12 then
			localPlayer.CameraMinZoomDistance = 0.5
			localPlayer.CameraMaxZoomDistance = 128
		end
	end)
end

do
	local RunService = game:GetService("RunService")
	local localPlayer = PX.Local
	local section = MiscCharacter:Section({ Name = "Animation Player", Icon = Icon("character", "smile"), Side = 1 })
	local A = { Enabled = false, Animation = "custom", Custom = "", Speed = 1, Start = 0, End = 100, Track = nil }
	local PRESETS = {
		dance = "rbxassetid://507771019",
		dance2 = "rbxassetid://507776043",
		wave = "rbxassetid://507770239",
		cheer = "rbxassetid://507770677",
		laugh = "rbxassetid://507770818",
		point = "rbxassetid://507770453",
	}
	local names = { "custom" }
	for name in pairs(PRESETS) do table.insert(names, name) end
	table.sort(names)

	section:Toggle({ Name = "Animation Player", Default = false, Keybind = Enum.KeyCode.J, Callback = function(value)
		A.Enabled = value
		if not value and A.Track then A.Track:Stop() A.Track = nil end
	end })
	section:Dropdown({ Name = "Animation", Options = names, Default = "custom", Callback = function(value)
		A.Animation = value
		if A.Track then A.Track:Stop() A.Track = nil end
	end })
	section:Textbox({ Name = "Custom Animation", Placeholder = "Animation ID", Callback = function(text) A.Custom = text if A.Track then A.Track:Stop() A.Track = nil end end })
	section:Slider({ Name = "Animation Speed", Min = 0, Max = 10, Default = 1, Decimals = 1, Callback = function(value) A.Speed = value end })
	section:Slider({ Name = "Start", Min = 0, Max = 100, Default = 0, Suffix = "%", Callback = function(value) A.Start = value end })
	section:Slider({ Name = "End", Min = 0, Max = 100, Default = 100, Suffix = "%", Callback = function(value) A.End = value end })

	RunService.Heartbeat:Connect(function()
		if not A.Enabled then return end
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 1))
		if not animator then return end
		if not A.Track then
			local id = A.Animation == "custom" and A.Custom or PRESETS[A.Animation]
			if not id or id == "" then return end
			if tonumber(id) then id = "rbxassetid://" .. id end
			local animation = Instance.new("Animation")
			animation.AnimationId = id
			local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
			if not ok then return end
			track.Priority = Enum.AnimationPriority.Action4
			track.Looped = true
			track:Play()
			A.Track = track
		end
		local track = A.Track
		track:AdjustSpeed(A.Speed)
		local length = track.Length
		if length > 0 then
			local startTime, endTime = length * A.Start / 100, length * math.max(A.End, A.Start + 1) / 100
			if track.TimePosition < startTime or track.TimePosition > endTime then track.TimePosition = startTime end
		end
	end)
end

do
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local SoundService = game:GetService("SoundService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local skyboxSection = VisualsWorld:Section({ Name = "Skybox", Icon = Icon("world", "globe"), Side = 2 })
	local S = { Enabled = false, Selected = "custom", Custom = "", NoSun = false, NoStars = false }
	local skies = { "custom" }
	local skyByName = {}
	for _, container in ipairs({ Lighting, ReplicatedStorage }) do
		for _, object in ipairs(container:GetDescendants()) do
			if object:IsA("Sky") and not skyByName[object.Name] then
				skyByName[object.Name] = object
				table.insert(skies, object.Name)
			end
		end
	end
	skyboxSection:Toggle({ Name = "Skybox", Default = false, Callback = function(value) S.Enabled = value end })
	skyboxSection:Dropdown({ Name = "Selected", Options = skies, Default = "custom", MaxRows = 10, Callback = function(value) S.Selected = value end })
	skyboxSection:Textbox({ Name = "Custom Skybox Id", Placeholder = "Skybox asset id", Callback = function(text) S.Custom = text end })
	skyboxSection:Dropdown({ Name = "Disable", Options = { "sun", "stars" }, Default = {}, Multi = true, Callback = function(value) S.NoSun = value["sun"] == true S.NoStars = value["stars"] == true end })

	local sky, original
	local FACES = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }
	RunService.RenderStepped:Connect(function()
		sky = Lighting:FindFirstChildOfClass("Sky") or sky
		if sky and not original then
			original = { SunAngularSize = sky.SunAngularSize, StarCount = sky.StarCount }
			for _, face in ipairs(FACES) do original[face] = sky[face] end
		end
		if not (sky and original) then return end
		sky.SunAngularSize = S.NoSun and 0 or original.SunAngularSize
		sky.StarCount = S.NoStars and 0 or original.StarCount
		for _, face in ipairs(FACES) do
			local texture = original[face]
			if S.Enabled then
				local source = skyByName[S.Selected]
				if source then
					texture = source[face]
				elseif S.Custom ~= "" then
					texture = tonumber(S.Custom) and ("rbxassetid://" .. S.Custom) or S.Custom
				end
			end
			if sky[face] ~= texture then sky[face] = texture end
		end
	end)

	local weatherSection = VisualsWorld:Section({ Name = "Weather", Icon = Icon("world", "globe"), Side = 2 })
	local W = { Enabled = false, Selected = "Snow", Rate = 1, Lifetime = 100, Timescale = 1 }
	local PRESETS = {
		Snow = { Rate = 120, Lifetime = 7, Speed = 8, Size = 0.25, Color = Color3.fromRGB(255, 255, 255), Texture = "rbxasset://textures/particles/sparkles_main.dds" },
		Rain = { Rate = 400, Lifetime = 2, Speed = 90, Size = 0.15, Color = Color3.fromRGB(190, 210, 255), Texture = "rbxasset://textures/particles/sparkles_main.dds" },
		Ash = { Rate = 80, Lifetime = 8, Speed = 4, Size = 0.3, Color = Color3.fromRGB(140, 140, 140), Texture = "rbxasset://textures/particles/smoke_main.dds" },
		Embers = { Rate = 60, Lifetime = 5, Speed = -5, Size = 0.25, Color = Color3.fromRGB(255, 140, 60), Texture = "rbxasset://textures/particles/sparkles_main.dds" },
	}
	local names = {}
	for name in pairs(PRESETS) do table.insert(names, name) end
	table.sort(names)
	weatherSection:Toggle({ Name = "Weather", Default = false, Callback = function(value) W.Enabled = value end })
	weatherSection:Dropdown({ Name = "Weather Selected", Options = names, Default = "Snow", Callback = function(value) W.Selected = value end })
	weatherSection:Slider({ Name = "Rate", Min = 0.1, Max = 10, Default = 1, Decimals = 1, Suffix = "x", Callback = function(value) W.Rate = value end })
	weatherSection:Slider({ Name = "Lifetime", Min = 1, Max = 100, Default = 100, Suffix = "%", Callback = function(value) W.Lifetime = value end })
	weatherSection:Slider({ Name = "Timescale", Min = 0.05, Max = 1, Default = 1, Decimals = 2, Suffix = "x", Callback = function(value) W.Timescale = value end })

	local anchor = Instance.new("Part")
	anchor.Name = "ParanoiaWeather"
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(80, 1, 80)
	local emitter = Instance.new("ParticleEmitter")
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Enabled = false
	emitter.Parent = anchor
	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then return end
		if W.Enabled then
			local preset = PRESETS[W.Selected] or PRESETS.Snow
			anchor.Parent = workspace
			anchor.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 40, 0))
			emitter.Texture = preset.Texture
			emitter.Color = ColorSequence.new(preset.Color)
			emitter.Rate = preset.Rate * W.Rate
			emitter.Lifetime = NumberRange.new(preset.Lifetime * W.Lifetime / 100)
			emitter.Speed = NumberRange.new(preset.Speed)
			emitter.TimeScale = W.Timescale
			emitter.Size = NumberSequence.new(preset.Size)
			emitter.Acceleration = Vector3.new(0, preset.Speed > 0 and -10 or 6, 0)
			emitter.Enabled = true
		else
			emitter.Enabled = false
		end
	end)

	local ambienceSection = VisualsWorld:Section({ Name = "Ambience", Icon = Icon("world", "globe"), Side = 2 })
	local A = { Enabled = false, Id = "", Volume = 0.5 }
	local sound = Instance.new("Sound")
	sound.Name = "ParanoiaAmbience"
	sound.Looped = true
	sound.Parent = SoundService
	ambienceSection:Toggle({ Name = "Ambience", Default = false, Callback = function(value)
		A.Enabled = value
		if value and A.Id ~= "" then sound:Play() else sound:Stop() end
	end })
	ambienceSection:Textbox({ Name = "Ambience Asset Id", Placeholder = "Sound asset id", Callback = function(text)
		A.Id = text
		sound.SoundId = tonumber(text) and ("rbxassetid://" .. text) or text
		if A.Enabled and text ~= "" then sound:Play() end
	end })
	ambienceSection:Slider({ Name = "Ambience Volume", Min = 0.1, Max = 10, Default = 0.5, Decimals = 1, Suffix = "db", Callback = function(value) sound.Volume = value end })
end

do
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local localPlayer = PX.Local
	local gui = PX.gui("ParanoiaHud", 46)

	local HUD = { Enabled = false, X = 50, Y = 70, ItemScale = 170, Scale = 170, Show = { aimbot = true, ["silent aim"] = true, ragebot = true, triggerbot = true } }
	local section = VisualsHud:Section({ Name = "Target HUD", Icon = Icon("preview", "smile"), Side = 1 })
	section:Toggle({ Name = "Enabled", Default = false, Callback = function(value) HUD.Enabled = value end })
	section:Slider({ Name = "Offset X", Min = 0, Max = 100, Default = 50, Suffix = "%", Callback = function(value) HUD.X = value end })
	section:Slider({ Name = "Offset Y", Min = 0, Max = 100, Default = 70, Suffix = "%", Callback = function(value) HUD.Y = value end })
	section:Slider({ Name = "Item Scale", Min = 75, Max = 235, Default = 170, Suffix = "%", Callback = function(value) HUD.ItemScale = value end })
	section:Slider({ Name = "UI Scale", Min = 50, Max = 235, Default = 170, Suffix = "%", Callback = function(value) HUD.Scale = value end })
	section:Dropdown({ Name = "Show Targets", Options = { "aimbot", "silent aim", "ragebot", "triggerbot" }, Default = { "aimbot", "silent aim", "ragebot", "triggerbot" }, Multi = true, Callback = function(value) HUD.Show = value end })

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromOffset(150, 46)
	frame.Visible = false
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
	local frameScale = Instance.new("UIScale", frame)
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(8, 4)
	title.Size = UDim2.new(1, -16, 0, 14)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	local sub = title:Clone()
	sub.Position = UDim2.fromOffset(8, 19)
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 11
	sub.TextColor3 = Color3.fromRGB(200, 200, 200)
	sub.Parent = frame
	local barBack = Instance.new("Frame")
	barBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	barBack.BorderSizePixel = 0
	barBack.Position = UDim2.new(0, 8, 1, -10)
	barBack.Size = UDim2.new(1, -16, 0, 4)
	barBack.Parent = frame
	local bar = Instance.new("Frame")
	bar.BorderSizePixel = 0
	bar.Size = UDim2.fromScale(1, 1)
	bar.Parent = barBack

	local function currentTarget()
		if HUD.Show["silent aim"] and SilentState.Part then return PX.Players:GetPlayerFromCharacter(SilentState.Part.Parent) end
		if HUD.Show.ragebot and RageState.Enabled and RageState.Part then return PX.Players:GetPlayerFromCharacter(RageState.Part.Parent) end
		if HUD.Show.aimbot and AimState.Enabled and AimState.Part then return PX.Players:GetPlayerFromCharacter(AimState.Part.Parent) end
		if HUD.Show.triggerbot and TriggerState.Enabled and TriggerState.Player then return TriggerState.Player end
	end

	RunService.RenderStepped:Connect(function()
		local player = HUD.Enabled and currentTarget()
		local humanoid = player and PX.alive(player.Character)
		frame.Visible = humanoid ~= nil and humanoid ~= false
		if not frame.Visible then return end
		local camera = workspace.CurrentCamera
		local viewport = camera.ViewportSize
		frame.Position = UDim2.fromOffset(viewport.X * HUD.X / 100, viewport.Y * HUD.Y / 100)
		frameScale.Scale = HUD.Scale / 170
		local tool = player.Character:FindFirstChildOfClass("Tool")
		title.Text = player.DisplayName
		sub.Text = string.format("%d hp  |  %s", math.floor(humanoid.Health + 0.5), tool and tool.Name or "none")
		local fraction = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
		bar.Size = UDim2.fromScale(fraction, 1)
		bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), fraction)
		frame.Size = UDim2.fromOffset(150 * HUD.ItemScale / 170, 46)
	end)

	-- indicators
	local I = { Manipulated = true, Ragebot = true, RageStyle = { text = true, status = true }, Ammo = false, AmmoStyle = { ammo = true }, Lerp = 1, X = 0, Y = 25, Font = "Inter", Case = "lower", OnTarget = false,
		ManipColor = Color3.fromRGB(255, 255, 255), RageText = Color3.fromRGB(255, 255, 255), RageStatus = Color3.fromRGB(255, 255, 255), AmmoColor = Color3.fromRGB(255, 255, 255), AmmoDivider = Color3.fromRGB(255, 255, 255), AmmoMax = Color3.fromRGB(255, 255, 255), ReserveColor = Color3.fromRGB(255, 255, 255), EmptyColor = Color3.fromRGB(255, 255, 255) }
	local ind = VisualsHud:Section({ Name = "Indicators", Icon = Icon("preview", "smile"), Side = 2 })
	ind:Toggle({ Name = "Manipulated", Default = true, Color = I.ManipColor, ColorCallback = function(color) I.ManipColor = color end, Callback = function(value) I.Manipulated = value end })
	ind:Toggle({ Name = "Ragebot Indicator", Default = true, Color = I.RageText, ColorCallback = function(color) I.RageText = color end, Callback = function(value) I.Ragebot = value end })
	ind:Colorpicker({ Name = "Ragebot Status Color", Default = I.RageStatus, Callback = function(color) I.RageStatus = color end })
	ind:Dropdown({ Name = "Ragebot Style", Options = { "text", "status" }, Default = { "text", "status" }, Multi = true, Callback = function(value) I.RageStyle = value end })
	ind:Toggle({ Name = "Ammo", Default = false, Color = I.AmmoColor, ColorCallback = function(color) I.AmmoColor = color end, Callback = function(value) I.Ammo = value end })
	ind:Colorpicker({ Name = "Ammo Divider Color", Default = I.AmmoDivider, Callback = function(color) I.AmmoDivider = color end })
	ind:Colorpicker({ Name = "Ammo Max Color", Default = I.AmmoMax, Callback = function(color) I.AmmoMax = color end })
	ind:Colorpicker({ Name = "Reserve Color", Default = I.ReserveColor, Callback = function(color) I.ReserveColor = color end })
	ind:Colorpicker({ Name = "Empty Color", Default = I.EmptyColor, Callback = function(color) I.EmptyColor = color end })
	ind:Dropdown({ Name = "Ammo Style", Options = { "ammo", "reserve" }, Default = { "ammo" }, Multi = true, Callback = function(value) I.AmmoStyle = value end })
	ind:Slider({ Name = "Indicator Lerp", Min = 0.01, Max = 1, Default = 1, Decimals = 2, Suffix = "x", Callback = function(value) I.Lerp = value end })
	ind:Slider({ Name = "Indicator Offset X", Min = -100, Max = 100, Default = 0, Suffix = "px", Callback = function(value) I.X = value end })
	ind:Slider({ Name = "Indicator Offset Y", Min = -100, Max = 100, Default = 25, Suffix = "px", Callback = function(value) I.Y = value end })
	ind:Dropdown({ Name = "Indicator Font", Options = FontList, Default = "Inter", MaxRows = 12, Callback = function(value) I.Font = value end })
	ind:Dropdown({ Name = "Text Style", Options = { "lower", "upper" }, Default = "lower", Callback = function(value) I.Case = value end })
	ind:Dropdown({ Name = "Position", Options = { "position on target" }, Default = {}, Multi = true, Callback = function(value) I.OnTarget = value["position on target"] == true end })

	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(240, 60)
	holder.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 2)
	layout.Parent = holder
	local function newLabel(order)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.RichText = true
		label.Size = UDim2.new(1, 0, 0, 16)
		label.TextSize = 14
		label.Font = Enum.Font.GothamBold
		label.TextStrokeTransparency = 0.4
		label.LayoutOrder = order
		label.Visible = false
		label.Parent = holder
		return label
	end
	local manipLabel, rageLabel, ammoLabel = newLabel(1), newLabel(2), newLabel(3)

	local function hex(color) return string.format("#%02x%02x%02x", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)) end
	local function styled(text) return I.Case == "upper" and string.upper(text) or string.lower(text) end
	local position
	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then return end
		local viewport = camera.ViewportSize
		local goal = Vector2.new(viewport.X / 2 + I.X, viewport.Y / 2 + I.Y)
		if I.OnTarget then
			local part = SilentState.Part or RageState.Part or AimState.Part
			if part then
				local point, onScreen = camera:WorldToViewportPoint(part.Position)
				if onScreen then goal = Vector2.new(point.X + I.X, point.Y + I.Y) end
			end
		end
		position = position and position:Lerp(goal, math.clamp(I.Lerp, 0.01, 1)) or goal
		holder.Position = UDim2.fromOffset(position.X, position.Y)
		local face = fontFace(I.Font, Enum.FontWeight.Bold)
		for _, label in ipairs({ manipLabel, rageLabel, ammoLabel }) do
			if face then label.FontFace = face end
		end
		manipLabel.Visible = I.Manipulated and SilentState.Enabled and SilentState.Manipulation and SilentState.Part ~= nil
		manipLabel.Text = styled("manipulated")
		manipLabel.TextColor3 = I.ManipColor
		rageLabel.Visible = I.Ragebot
		local parts = {}
		if I.RageStyle.text then table.insert(parts, string.format('<font color="%s">%s</font>', hex(I.RageText), styled("ragebot"))) end
		if I.RageStyle.status then table.insert(parts, string.format('<font color="%s">%s</font>', hex(I.RageStatus), styled(RageState.Enabled and (RageState.Part and "target" or "on") or "off"))) end
		rageLabel.Text = table.concat(parts, " ")
		local tool = PX.equipped()
		local ammo, reserve, maxAmmo = PX.ammo(tool)
		ammoLabel.Visible = I.Ammo and ammo ~= nil
		if ammoLabel.Visible then
			local pieces = {}
			if I.AmmoStyle.ammo then
				local color = ammo <= 0 and I.EmptyColor or I.AmmoColor
				local text = string.format('<font color="%s">%d</font>', hex(color), ammo)
				if maxAmmo then text ..= string.format('<font color="%s">/</font><font color="%s">%d</font>', hex(I.AmmoDivider), hex(I.AmmoMax), maxAmmo) end
				table.insert(pieces, text)
			end
			if I.AmmoStyle.reserve and reserve then table.insert(pieces, string.format('<font color="%s">%d</font>', hex(I.ReserveColor), reserve)) end
			ammoLabel.Text = table.concat(pieces, " ")
		end
	end)

	-- target tracer + highlight
	local T = { Tracer = false, TracerColor = Color3.fromRGB(255, 255, 255), Highlight = false, Outline = Color3.fromRGB(255, 255, 255), Fill = Color3.fromRGB(255, 255, 255), Culling = "AlwaysOnTop" }
	local target = VisualsCrosshair:Section({ Name = "Target", Icon = Icon("targeting", "bullet"), Side = 2 })
	target:Toggle({ Name = "Tracer", Default = false, Color = T.TracerColor, ColorCallback = function(color) T.TracerColor = color end, Callback = function(value) T.Tracer = value end })
	target:Toggle({ Name = "Highlight", Default = false, Color = T.Outline, ColorCallback = function(color) T.Outline = color end, Callback = function(value) T.Highlight = value end })
	target:Colorpicker({ Name = "Highlight Fill", Default = T.Fill, Callback = function(color) T.Fill = color end })
	target:Dropdown({ Name = "Culling Mode", Options = { "Occluded", "AlwaysOnTop" }, Default = "AlwaysOnTop", Callback = function(value) T.Culling = value end })

	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.BorderSizePixel = 0
	line.Visible = false
	line.Parent = gui
	local highlight = Instance.new("Highlight")
	highlight.Enabled = false
	highlight.Parent = gui
	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		local player = currentTarget()
		local character = player and PX.alive(player.Character) and player.Character
		if T.Highlight and character then
			highlight.Adornee = character
			highlight.OutlineColor = T.Outline
			highlight.FillColor = T.Fill
			highlight.DepthMode = Enum.HighlightDepthMode[T.Culling] or Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Enabled = true
		else
			highlight.Enabled = false
		end
		if T.Tracer and character and camera then
			local root = PX.root(character)
			local point, onScreen = camera:WorldToViewportPoint(root.Position)
			if onScreen then
				local from = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
				local delta = Vector2.new(point.X, point.Y) - from
				line.Visible = true
				line.BackgroundColor3 = T.TracerColor
				line.Position = UDim2.fromOffset(from.X, from.Y)
				line.Size = UDim2.fromOffset(delta.Magnitude, 1)
				line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			else
				line.Visible = false
			end
		else
			line.Visible = false
		end
	end)
end

do
	local UserInputService = game:GetService("UserInputService")
	local SoundService = game:GetService("SoundService")
	local RunService = game:GetService("RunService")
	local localPlayer = PX.Local

	local SS = { Change = false, Selected = "disable", Custom = "", Speed = 1, Volume = 0.3, Start = 0 }
	local section = VisualsFx:Section({ Name = "Shoot Sound", Icon = Icon("effects", "globe"), Side = 2 })
	section:Toggle({ Name = "Change Sound", Default = false, Callback = function(value) SS.Change = value end })
	section:Dropdown({ Name = "Sound", Options = { "disable", "custom" }, Default = "disable", Callback = function(value) SS.Selected = value end })
	section:Textbox({ Name = "Custom Sound", Placeholder = "Sound asset id", Callback = function(text) SS.Custom = text end })
	section:Slider({ Name = "Sound Speed", Min = 0.2, Max = 5, Default = 1, Decimals = 1, Suffix = "x", Callback = function(value) SS.Speed = value end })
	section:Slider({ Name = "Sound Volume", Min = 0, Max = 2, Default = 0.3, Decimals = 1, Suffix = "db", Callback = function(value) SS.Volume = value end })
	section:Slider({ Name = "Start Position", Min = 0, Max = 100, Default = 0, Suffix = "%", Callback = function(value) SS.Start = value end })

	local function play()
		if SS.Custom == "" then return end
		local sound = Instance.new("Sound")
		sound.SoundId = tonumber(SS.Custom) and ("rbxassetid://" .. SS.Custom) or SS.Custom
		sound.Volume = SS.Volume
		sound.PlaybackSpeed = SS.Speed
		sound.Parent = SoundService
		sound.Loaded:Connect(function()
			sound.TimePosition = sound.TimeLength * SS.Start / 100
			sound:Play()
		end)
		sound.Ended:Connect(function() sound:Destroy() end)
		task.delay(10, function() if sound.Parent then sound:Destroy() end end)
		if sound.IsLoaded then
			sound.TimePosition = sound.TimeLength * SS.Start / 100
			sound:Play()
		end
	end
	section:Button({ Name = "Preview Shoot Sound", Callback = play })

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not SS.Change or SS.Selected ~= "custom" or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if PX.equipped() then play() end
	end)

	local lastScan = 0
	RunService.Heartbeat:Connect(function()
		if not (SS.Change and SS.Selected == "disable") or os.clock() - lastScan < 0.25 then return end
		lastScan = os.clock()
		local roots = { workspace.CurrentCamera, localPlayer.Character }
		for _, root in ipairs(roots) do
			if root then
				for _, object in ipairs(root:GetDescendants()) do
					if object:IsA("Sound") then
						local name = string.lower(object.Name)
						if string.find(name, "shoot") or string.find(name, "fire") or string.find(name, "shot") then object.Volume = 0 end
					end
				end
			end
		end
	end)
end

do
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local Debris = game:GetService("Debris")
	local localPlayer = PX.Local
	local H = PX.H
	local D = { Enabled = false, Weld = false, Stack = true, Cycle = false, Material = "Neon", NoMarker = false, NoNumbers = false }
	local section = VisualsHits:Section({ Name = "Hit Effects", Icon = Icon("effects", "globe"), Side = 2 })
	section:Toggle({ Name = "Damage Numbers", Default = false, Callback = function(value) D.Enabled = value end })
	section:Toggle({ Name = "Weld To Player", Default = false, Callback = function(value) D.Weld = value end })
	section:Dropdown({ Name = "Number Settings", Options = { "stack damage together", "cycle colors for text" }, Default = { "stack damage together" }, Multi = true, Callback = function(value)
		D.Stack = value["stack damage together"] == true
		D.Cycle = value["cycle colors for text"] == true
	end })
	section:Dropdown({ Name = "Preferred Material", Options = { "Neon", "ForceField", "Plastic", "SmoothPlastic", "Glass" }, Default = "Neon", Callback = function(value) D.Material = value if H then H.Chams.MaterialName = value end end })
	section:Toggle({ Name = "Disable Hit Marker", Default = false, Callback = function(value) D.NoMarker = value end })
	section:Toggle({ Name = "Disable Damage Numbers", Default = false, Callback = function(value) D.NoNumbers = value end })

	local palette = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 120, 60), Color3.fromRGB(255, 60, 60) }
	local cycle, stacked = 0, {}
	table.insert(HitSignals, function(player, character, damage, killed)
		if not D.Enabled then return end
		local root = PX.root(character)
		if not root then return end
		local now = os.clock()
		local entry = stacked[player]
		if D.Stack and entry and entry.Label.Parent and now - entry.Time < 1 then
			entry.Total += damage
			entry.Time = now
			entry.Label.Text = tostring(math.floor(entry.Total + 0.5))
			return
		end
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(90, 34)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop = true
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Text = tostring(math.floor(damage + 0.5))
		cycle = cycle % #palette + 1
		label.TextColor3 = D.Cycle and palette[cycle] or Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.Parent = billboard
		if D.Weld then
			billboard.Adornee = root
			billboard.Parent = root
		else
			local anchor = Instance.new("Part")
			anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
			anchor.Transparency = 1
			anchor.Size = Vector3.one
			anchor.Position = root.Position
			anchor.Parent = workspace
			billboard.Adornee = anchor
			billboard.Parent = anchor
			Debris:AddItem(anchor, 1.6)
		end
		Debris:AddItem(billboard, 1.5)
		stacked[player] = { Label = label, Total = damage, Time = now }
		TweenService:Create(billboard, TweenInfo.new(1.2), { StudsOffset = Vector3.new(0, 5.5, 0) }):Play()
		TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)

	local lastScan = 0
	RunService.Heartbeat:Connect(function()
		if not (D.NoMarker or D.NoNumbers) or os.clock() - lastScan < 0.3 then return end
		lastScan = os.clock()
		local gui = localPlayer:FindFirstChild("PlayerGui")
		if not gui then return end
		for _, object in ipairs(gui:GetDescendants()) do
			if object:IsA("GuiObject") and object.Name ~= "ParanoiaHits" then
				local name = string.lower(object.Name)
				if D.NoMarker and string.find(name, "hitmarker") then object.Visible = false end
				if D.NoNumbers and (string.find(name, "damagenumber") or string.find(name, "damageindicator")) then object.Visible = false end
			end
		end
	end)
end

do
	local RunService = game:GetService("RunService")
	local localPlayer = PX.Local

	-- viewmodel animation disables and recoil / sway scaling
	local V = { Disable = {}, Recoil = 100 }
	local section = VisualsCosmetics:Section({ Name = "Animations", Icon = Icon("weaponmods", "wrench"), Side = 1 })
	section:Dropdown({ Name = "Disable Animations", Options = { "sway", "bobbing", "muzzle flash", "idle animation", "jump animation", "shoot animation", "aiming animation", "sprint animation" }, Default = {}, Multi = true, MaxRows = 8, Callback = function(value) V.Disable = value end })
	section:Slider({ Name = "Recoil Percent", Min = 0, Max = 100, Default = 100, Suffix = "%", Callback = function(value) V.Recoil = value end })

	local KEYWORDS = { ["idle animation"] = "idle", ["jump animation"] = "jump", ["shoot animation"] = "shoot", ["aiming animation"] = "aim", ["sprint animation"] = "sprint" }
	local recoilOriginals = {}
	local lastScan = 0
	RunService.Heartbeat:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then return end
		for _, model in ipairs(camera:GetChildren()) do
			if model:IsA("Model") and not model:FindFirstChildOfClass("Humanoid") then
				local animator = model:FindFirstChildWhichIsA("Animator", true)
				if animator then
					for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
						local name = string.lower(track.Name)
						for option, keyword in pairs(KEYWORDS) do
							if V.Disable[option] and string.find(name, keyword) then track:Stop(0) end
						end
						if (V.Disable.sway and string.find(name, "sway")) or (V.Disable.bobbing and (string.find(name, "bob") or string.find(name, "walk"))) then track:Stop(0) end
					end
				end
			end
		end
		if os.clock() - lastScan < 1 then return end
		lastScan = os.clock()
		local tool = PX.equipped()
		if tool then
			for _, object in ipairs(tool:GetDescendants()) do
				if object:IsA("NumberValue") and string.find(string.lower(object.Name), "recoil") then
					recoilOriginals[object] = recoilOriginals[object] or object.Value
					object.Value = recoilOriginals[object] * V.Recoil / 100
				end
			end
			for name, value in pairs(tool:GetAttributes()) do
				if type(value) == "number" and string.find(string.lower(name), "recoil") then
					recoilOriginals[name] = recoilOriginals[name] or value
					tool:SetAttribute(name, recoilOriginals[name] * V.Recoil / 100)
				end
			end
		end
	end)
end

do
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local localPlayer = PX.Local

	-- always backstab: snap behind a nearby enemy while attacking with a knife
	local B = { Enabled = false }
	local weapons = MiscWeapons:Section({ Name = "Melee", Icon = Icon("weaponmods", "wrench"), Side = 2 })
	weapons:Toggle({ Name = "Always Backstab", Default = false, Callback = function(value) B.Enabled = value end })
	local fuse = { Remove = false }
	weapons:Dropdown({ Name = "Grenade Settings", Options = { "explode on throw", "remove fuse" }, Default = {}, Multi = true, Callback = function(value)
		fuse.Remove = value["remove fuse"] == true
		fuse.Instant = value["explode on throw"] == true
	end })

	RunService.Heartbeat:Connect(function()
		local character = localPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local tool = PX.equipped()
		if not root or not tool then return end
		local name = string.lower(tool.Name)
		if B.Enabled and (string.find(name, "knife") or string.find(name, "dagger")) and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			local best, bestDistance
			for _, player in ipairs(PX.Players:GetPlayers()) do
				if PX.isEnemy(player, true) then
					local targetRoot = PX.root(player.Character)
					local distance = (targetRoot.Position - root.Position).Magnitude
					if distance < 14 and (not bestDistance or distance < bestDistance) then best, bestDistance = targetRoot, distance end
				end
			end
			if best then
				local behind = best.CFrame * CFrame.new(0, 0, 2)
				root.CFrame = CFrame.lookAt(behind.Position, best.Position)
			end
		end
		if (fuse.Remove or fuse.Instant) and string.find(name, "grenade") then
			for key, value in pairs(tool:GetAttributes()) do
				if type(value) == "number" and string.find(string.lower(key), "fuse") then tool:SetAttribute(key, 0) end
			end
			for _, object in ipairs(tool:GetDescendants()) do
				if object:IsA("NumberValue") and string.find(string.lower(object.Name), "fuse") then object.Value = 0 end
			end
		end
	end)
end

do
	local L = { Enabled = false, Silent = false }
	local section = MiscAutomation:Section({ Name = "Auto Load", Icon = Icon("autoload", "robot"), Side = 1 })
	section:Toggle({ Name = "Enabled", Default = false, Callback = function(value)
		L.Enabled = value
		if value and queue_on_teleport then
			local source = string.gsub(ASSET_BASE, "assets/$", "paranoia.lua")
			pcall(queue_on_teleport, string.format("getgenv().ParanoiaSilent = %s; loadstring(game:HttpGet(%q))()", tostring(L.Silent), source))
		end
	end })
	section:Toggle({ Name = "Silent Mode", Default = false, Callback = function(value) L.Silent = value end })
	if getgenv and getgenv().ParanoiaSilent then
		task.defer(function() pcall(function() Window:SetVisible(false) end) end)
	end
end

Window:BuildSettings(Settings)
finishNav()

do
	local menuFont, themeFont
	for _, object in pairs(Window.FlagOwners or {}) do
		if type(object) == "table" and type(object.Options) == "table" and type(object.SetOptions) == "function"
			and table.find(object.Options, "Inter") and table.find(object.Options, "Arimo") and object.Item
			and object.Item.Section and object.Item.Section.Tab == Settings then
			menuFont = object
			object:SetOptions(table.clone(FontList))
		end
	end
	local theming
	for _, section in pairs(Window.Sections or {}) do
		if section.Name == "Theming" and section.Tab == Settings then theming = section end
	end
	if theming then
		theming:Divider()
		themeFont = theming:Dropdown({ Name = "Menu Font", Options = FontList, Default = "Inter", MaxRows = 12, Callback = function(value)
			Window:SetFont(value)
			if menuFont and menuFont.Value ~= value then pcall(function() menuFont:Set(value, true) end) end
		end })
	end
	if menuFont and themeFont then
		local original = menuFont.Callback
		menuFont.Callback = function(value, ...)
			if themeFont.Value ~= value then pcall(function() themeFont:Set(value, true) end) end
			if original then return original(value, ...) end
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
local existingBinds = PlayerGui:FindFirstChild("ParanoiaMobileBinds")
if existingBinds then existingBinds:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ParanoiaMobileToggle"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = PlayerGui

local bindGui = Instance.new("ScreenGui")
bindGui.Name = "ParanoiaMobileBinds"
bindGui.ResetOnSpawn = false
bindGui.IgnoreGuiInset = true
bindGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
bindGui.DisplayOrder = 998
bindGui.Parent = PlayerGui

local IDLE_STROKE = Color3.fromRGB(65, 68, 80)
local IDLE_TEXT = Color3.fromRGB(232, 234, 245)
local RunService = game:GetService("RunService")

local MobileButtons = {}
local mobileFont = "Inter"

local function applyMobileFont(panel)
	local face = fontFace(mobileFont, Enum.FontWeight.SemiBold)
	if face then
		panel.Label.FontFace = face
	else
		panel.Label.Font = Enum.Font.GothamMedium
	end
end

local function createPanelButton(parent, text, position)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 108, 0, 32)
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	button.BackgroundTransparency = 0
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Active = true
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = IDLE_STROKE
	stroke.Thickness = 1
	stroke.Parent = button

	local glow = Instance.new("ImageLabel")
	glow.Name = "Glow"
	glow.BackgroundTransparency = 1
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.new(1, 44, 1, 44)
	glow.Image = Assets["fx/glow.png"] or ""
	glow.ImageColor3 = accentColor
	glow.ImageTransparency = 1
	glow.ZIndex = 1
	glow.Parent = button

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = IDLE_TEXT
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 2
	label.Parent = button

	local panel = { Button = button, Label = label, Stroke = stroke, Glow = glow, Pressed = false, Lit = 0, Sticky = false }
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			panel.Pressed = true
		end
	end)
	applyMobileFont(panel)
	table.insert(MobileButtons, panel)
	button.Destroying:Connect(function()
		local index = table.find(MobileButtons, panel)
		if index then table.remove(MobileButtons, index) end
	end)
	return panel
end

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		for _, panel in ipairs(MobileButtons) do
			if panel.Pressed then
				panel.Pressed = false
				if panel.OnRelease then task.spawn(panel.OnRelease) end
			end
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local alpha = math.min(1, dt * 16)
	for _, panel in ipairs(MobileButtons) do
		local lit = panel.Pressed and 1 or ((panel.Sticky and panel.Sticky()) and 0.55 or 0)
		panel.Lit += (lit - panel.Lit) * alpha
		local amount = panel.Lit
		panel.Stroke.Color = IDLE_STROKE:Lerp(accentColor, amount)
		panel.Stroke.Thickness = 1 + amount * 1.5
		panel.Glow.ImageColor3 = accentColor
		panel.Glow.ImageTransparency = 1 - amount * 0.7
		panel.Label.TextColor3 = IDLE_TEXT:Lerp(Color3.new(1, 1, 1), amount)
		panel.Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0):Lerp(accentColor:Lerp(Color3.new(0, 0, 0), 0.8), amount)
	end
end)

do
	local setFont = Window.SetFont
	Window.SetFont = function(self, name, ...)
		mobileFont = name
		for _, panel in ipairs(MobileButtons) do applyMobileFont(panel) end
		return setFont(self, name, ...)
	end
end

local toggleBtn
local open = false
local toggleUI = createPanelButton(gui, "Toggle UI", UDim2.new(0, 14, 0.5, -16))
toggleBtn = toggleUI.Button
toggleBtn.Name = "ToggleButton"
toggleBtn.Draggable = true
toggleBtn.Visible = UserInputService.TouchEnabled
toggleUI.Sticky = function() return open end

local function setOpen(state)
	open = state
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

local function removeMobileButton(bind)
	local panel = bind.MobileButton
	if not panel then return end
	bind.MobileButton = nil
	if panel.Pressed and bind.OnRelease then pcall(bind.OnRelease) end
	panel.Button:Destroy()
end

local function spawnMobileButton(bind)
	if bind.MobileButton then
		removeMobileButton(bind)
		return
	end
	if bind.Mode == "Always" then return end
	local count = 0
	for _, other in ipairs(Window.Binds or {}) do
		if other.MobileButton then count += 1 end
	end
	local panel = createPanelButton(bindGui, bind.Name or "Keybind", UDim2.new(0, 14, 0.5, 24 + count * 40))
	panel.Button.Name = "Bind_" .. tostring(bind.Name or "Key")
	panel.Button.Draggable = false
	panel.Sticky = bind.GetState
	bind.MobileButton = panel
	panel.Button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if Window.Visible then return end
		if bind.Mode == "Always" then return end
		if bind.OnPress then task.spawn(bind.OnPress) end
	end)
	panel.OnRelease = function()
		if Window.Visible or bind.Mode == "Always" then return end
		if bind.OnRelease then bind.OnRelease() end
	end
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not panel.Button.Parent then
			connection:Disconnect()
			return
		end
		panel.Button.Draggable = Window.Visible == true
		if Window.Visible then panel.Pressed = false end
	end)
end

Window.OnMobileButton = spawnMobileButton
Window.OnKeybindMode = function(bind, mode)
	if mode == "Always" then removeMobileButton(bind) end
end

if not UserInputService.TouchEnabled then
	gui.Enabled = false
end

return Window
