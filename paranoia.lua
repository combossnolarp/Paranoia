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

		src = replacePlain(src,
			"\tbutton.MouseButton1Click:Connect(function()\n\t\tobject.Listening = true\n\t\twin.Listening = object\n\t\tobject.Refresh()\n\tend)\n\tbutton.MouseButton2Click:Connect(function() win:OpenKeybindMenu(chip, object) end)",
			"\tfunction object.StartListening()\n\t\tobject.Listening = true\n\t\twin.Listening = object\n\t\tobject.Refresh()\n\tend\n\tlocal holdId, held = 0, false\n\tbutton.MouseButton1Down:Connect(function()\n\t\tholdId += 1\n\t\theld = false\n\t\tlocal id = holdId\n\t\ttask.delay(0.35, function()\n\t\t\tif holdId == id and button.Parent then\n\t\t\t\theld = true\n\t\t\t\twin:OpenKeybindMenu(chip, object)\n\t\t\tend\n\t\tend)\n\tend)\n\tbutton.MouseButton1Up:Connect(function() holdId += 1 end)\n\tbutton.MouseLeave:Connect(function() holdId += 1 end)\n\tbutton.TouchLongPress:Connect(function(_, state)\n\t\tif state == Enum.UserInputState.Begin and not held then\n\t\t\theld = true\n\t\t\twin:OpenKeybindMenu(chip, object)\n\t\tend\n\tend)\n\tbutton.MouseButton1Click:Connect(function()\n\t\tif held then held = false return end\n\t\twin:OpenKeybindMenu(chip, object)\n\tend)\n\tbutton.MouseButton2Click:Connect(function() win:OpenKeybindMenu(chip, object) end)")

		src = replacePlain(src,
			"\t\t\tif toggle.Keybind.Mode == \"Hold\" then toggle:Set(true) else toggle:Set(not toggle.Value) end\n\t\tend\n\t\ttoggle.Keybind.OnRelease = function()\n\t\t\tif toggle.Keybind.Mode == \"Hold\" then toggle:Set(false) end\n\t\tend",
			"\t\t\tlocal mode = toggle.Keybind.Mode\n\t\t\tif mode == \"Always\" then return end\n\t\t\tif mode == \"Hold\" then toggle:Set(true) else toggle:Set(not toggle.Value) end\n\t\tend\n\t\ttoggle.Keybind.OnRelease = function()\n\t\t\tif toggle.Keybind.Mode == \"Hold\" then toggle:Set(false) end\n\t\tend\n\t\ttoggle.Keybind.OnModeChanged = function(mode, previous)\n\t\t\tif mode == \"Always\" then toggle:Set(true) elseif previous == \"Always\" then toggle:Set(false) end\n\t\tend\n\t\ttoggle.Keybind.GetState = function() return toggle.Value end")

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
local RageMain, RageAntiAim = Group({ Name = "Rage", Icon = Icon("rage", "target") }, {
	{ Name = "Ragebot", Icon = Icon("ragebot", "robot") },
	{ Name = "Anti Aim", Icon = Icon("antiaim", "wrench") },
})
local LegitAim, LegitSilent, LegitTrigger = Group({ Name = "Legit", Icon = Icon("legit", "bullet") }, {
	{ Name = "Aim Assist", Icon = Icon("aimassist", "target") },
	{ Name = "Silent Aim", Icon = Icon("silent", "bullet") },
	{ Name = "Triggerbot", Icon = Icon("trigger", "bullet") },
})
Category("Visuals")
local EspMain, EspInfo, EspWorld, EspCosmetics = Group({ Name = "ESP", Icon = Icon("esp", "smile") }, {
	{ Name = "Main", Icon = Icon("esp", "smile") },
	{ Name = "Info", Icon = Icon("esp", "smile") },
	{ Name = "World", Icon = Icon("world", "globe") },
	{ Name = "Cosmetics", Icon = Icon("preview", "smile") },
})
local EffectsLocal, EffectsWorld = Group({ Name = "Visuals", Icon = Icon("effects", "globe") }, {
	{ Name = "Local", Icon = Icon("local", "smile") },
	{ Name = "World", Icon = Icon("world", "globe") },
})
Category("Misc")
local MiscCharacter, MiscWeapons, MiscAutomation = Group({ Name = "Misc", Icon = Icon("misc", "cube") }, {
	{ Name = "Character", Icon = Icon("character", "smile") },
	{ Name = "Weapon Mods", Icon = Icon("weaponmods", "wrench") },
	{ Name = "Automation", Icon = Icon("automation", "robot") },
})
Category("Player")
local MovementMain = Group({ Name = "Movement", Icon = Icon("movement", "smile") }, {
	{ Name = "Character", Icon = Icon("speed", "smile") },
})
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

local Silent = LegitSilent:Section({ Name = "Silent Aim", Icon = Icon("silent", "bullet"), Side = 1 })
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

local Trigger = LegitTrigger:Section({ Name = "Triggerbot", Icon = Icon("trigger", "bullet"), Side = 1 })
Trigger:Toggle({ Name = "Enabled", Default = false, Keybind = Enum.KeyCode.T })
Trigger:Divider()
Trigger:Slider({ Name = "Reaction Delay", Min = 0, Max = 500, Default = 60, Suffix = "ms" })
Trigger:Toggle({ Name = "Magnet Trigger", Default = false })
Trigger:Slider({ Name = "Magnet FOV", Min = 0, Max = 100, Default = 25 })
Trigger:Toggle({ Name = "Head Only", Default = true })

local EspState = { Enabled = false, TeamCheck = false, LimitDistance = false, MaxDistance = 1000, Font = "Inter", Elements = {} }
do
	local RunService = game:GetService("RunService")
	local WHITE = Color3.fromRGB(255, 255, 255)

	local ELEMENTS = {
		{ Key = "Box", Section = "Cosmetics", Name = "Box", Gradient = true, Rotation = 0,
			Colors = { WHITE, Color3.fromRGB(230, 160, 255), Color3.fromRGB(120, 90, 255) } },
		{ Key = "BoxFill", Section = "Cosmetics", Name = "Box Fill", Gradient = true, Rotation = 90,
			Colors = { Color3.fromRGB(230, 160, 255), Color3.fromRGB(150, 110, 255), Color3.fromRGB(60, 40, 140) } },
		{ Key = "Skeleton", Section = "Cosmetics", Name = "Skeleton", Color = WHITE },
		{ Key = "HealthBar", Section = "Info", Name = "Health Bar", Gradient = true, Rotation = 90,
			Colors = { Color3.fromRGB(90, 255, 120), Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 70, 70) } },
		{ Key = "AmmoBar", Section = "Info", Name = "Ammo Bar", Gradient = true, Rotation = 0,
			Colors = { Color3.fromRGB(255, 220, 110), Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 110, 40) } },
		{ Key = "HeadDot", Section = "Cosmetics", Name = "Head Dot", Color = Color3.fromRGB(230, 160, 255) },
		{ Key = "Name", Section = "Info", Name = "Name", Color = WHITE },
		{ Key = "Rank", Section = "Info", Name = "Rank", Color = Color3.fromRGB(255, 215, 120) },
		{ Key = "Weapon", Section = "Info", Name = "Weapon", Color = Color3.fromRGB(205, 205, 205) },
		{ Key = "Staring", Section = "Info", Name = "Staring", Color = Color3.fromRGB(255, 90, 90) },
	}

	local function setShown(object, shown)
		local item = object and object.Item
		if not item or item.Visible == shown then return end
		item.Visible = shown
		item.Frame.Visible = shown
		item.Section:Layout(true)
	end

	local mainSection = EspMain:Section({ Name = "Main", Icon = Icon("esp", "smile"), Side = 1 })
	local infoSection = EspInfo:Section({ Name = "Info", Icon = Icon("esp", "smile"), Side = 1 })
	local infoPreview = EspInfo:Section({ Name = "Preview", Icon = Icon("preview", "smile"), Side = 2 })
	local worldSection = EspWorld:Section({ Name = "World", Icon = Icon("world", "globe"), Side = 1 })
	local cosmeticsSection = EspCosmetics:Section({ Name = "Cosmetics", Icon = Icon("preview", "smile"), Side = 1 })
	local cosmeticsPreview = EspCosmetics:Section({ Name = "Preview", Icon = Icon("preview", "smile"), Side = 2 })

	mainSection:Toggle({ Name = "Enabled", Default = false, Callback = function(value) EspState.Enabled = value end })
	mainSection:Toggle({ Name = "Team Check", Default = false, Callback = function(value) EspState.TeamCheck = value end })
	local maxDistance
	worldSection:Toggle({ Name = "Limit Distance", Default = false, Callback = function(value)
		EspState.LimitDistance = value
		setShown(maxDistance, value)
	end })
	maxDistance = worldSection:Slider({ Name = "Max Distance", Min = 1, Max = 100000, Default = EspState.MaxDistance, Suffix = " studs", Callback = function(value) EspState.MaxDistance = value end })
	setShown(maxDistance, EspState.LimitDistance)

	local previewFonts = {}
	local function applyPreviewFont()
		for _, apply in ipairs(previewFonts) do apply() end
	end

	for _, def in ipairs(ELEMENTS) do
		local espSection = def.Section == "Info" and infoSection or cosmeticsSection
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
	buildPreview(infoPreview)
	buildPreview(cosmeticsPreview)
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

MiscCharacter:Section({ Name = "Character", Icon = Icon("character", "smile"), Side = 1 }):Label({ Name = "Nothing here yet" })
MiscWeapons:Section({ Name = "Weapon Mods", Icon = Icon("weaponmods", "wrench"), Side = 1 }):Label({ Name = "Nothing here yet" })
MiscAutomation:Section({ Name = "Automation", Icon = Icon("automation", "robot"), Side = 1 }):Label({ Name = "Nothing here yet" })

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
