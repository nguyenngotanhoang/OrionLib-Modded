local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local getgenv = getgenv or function()
    return shared
end
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local ContentProvider: ContentProvider = cloneref(game:GetService("ContentProvider"))
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = cloneref(LocalPlayer:GetMouse())
local cam = workspace.CurrentCamera

local PARENT = (gethui and gethui()) or cloneref(game:GetService("CoreGui"))
local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or function() end
local getcustomasset = getcustomasset or getsynasset or function() end
local makefolder = makefolder or function() end
local ResolveExternalAssetSource

local function IsHttpUrl(value)
    return type(value) == "string" and value:match("^https?://") ~= nil
end

local function IsRobloxAssetUrl(value)
    return type(value) == "string"
        and (
            value:find("^rbxassetid://")
            or value:find("^rbxasset://")
            or value:find("^rbxthumb://")
            or value:find("^https?://www%.roblox%.com/")
            or value:find("^https?://assetdelivery%.roblox%.com/")
            or value:find("^https?://tr%.rbxcdn%.com/")
        )
end

local function TryGetCustomAsset(path)
    if type(path) ~= "string" or path == "" then
        return nil
    end
    if type(getcustomasset) ~= "function" then
        return nil
    end
    local ok, asset = pcall(getcustomasset, path)
    if ok and type(asset) == "string" and asset ~= "" then
        return asset
    end
    return nil
end

local function ResolveLocalFileAsset(path)
    if type(path) ~= "string" or type(isfile) ~= "function" then
        return nil
    end
    local ok, exists = pcall(isfile, path)
    if not ok or not exists then
        return nil
    end
    if type(readfile) == "function" then
        local readOk, content = pcall(readfile, path)
        if readOk and type(content) == "string" and #content == 0 then
            return nil
        end
    end
    return TryGetCustomAsset(path) or path
end

local function SanitizeAssetName(value)
    value = tostring(value or "asset")
    value = value:gsub("^https?://", "")
    value = value:gsub("[^%w%-%_%.]", "_")
    if #value > 80 then
        value = value:sub(#value - 79)
    end
    return value ~= "" and value or "asset"
end

local function LoadBundleModule(path)
    if not (readfile and isfile and loadstring and isfile(path)) then
        return nil
    end
    local ok, result = pcall(function()
        return loadstring(readfile(path), path)()
    end)
    if ok then
        return result
    end
    warn("[OrionLib] Failed loading module " .. tostring(path) .. ": " .. tostring(result))
    return nil
end

local BundlePalette = LoadBundleModule("scr/theme/palette.lua")
local BundleThemes = BundlePalette and BundlePalette.Themes or nil
local BundleStyle = BundlePalette and BundlePalette.Style or nil

getgenv().OrionLib = {
    Elements = {},
    ThemeObjects = {},
    ThemeChangedCallbacks = {},
    Connections = {},
    Flags = {},
    SizeMin = Vector2.new(480, 360),
    OnDestroyTo = {},
    Themes = BundleThemes or {
        Default = {
            Main = Color3.fromRGB(18, 20, 27),
            Second = Color3.fromRGB(25, 28, 38),
            Stroke = Color3.fromRGB(58, 64, 82),
            Divider = Color3.fromRGB(43, 48, 62),
            Text = Color3.fromRGB(245, 247, 252),
            TextDark = Color3.fromRGB(156, 164, 181),
            Accent = Color3.fromRGB(96, 165, 250),
            AccentDark = Color3.fromRGB(37, 99, 235),
        },
        Dark = {
            Main = Color3.fromRGB(18, 18, 22),
            Second = Color3.fromRGB(27, 27, 34),
            Stroke = Color3.fromRGB(58, 58, 72),
            Divider = Color3.fromRGB(58, 58, 72),
            Text = Color3.fromRGB(245, 245, 250),
            TextDark = Color3.fromRGB(165, 166, 180),
            Accent = Color3.fromRGB(129, 140, 248),
            AccentDark = Color3.fromRGB(79, 70, 229),
        },
        Light = {
            Main = Color3.fromRGB(245, 246, 250),
            Second = Color3.fromRGB(255, 255, 255),
            Stroke = Color3.fromRGB(210, 214, 225),
            Divider = Color3.fromRGB(210, 214, 225),
            Text = Color3.fromRGB(30, 32, 40),
            TextDark = Color3.fromRGB(95, 101, 116),
            Accent = Color3.fromRGB(37, 99, 235),
            AccentDark = Color3.fromRGB(29, 78, 216),
        },
        Ubuntu = {
            Main = Color3.fromRGB(233, 84, 32),
            Second = Color3.fromRGB(45, 45, 45),
            Stroke = Color3.fromRGB(70, 70, 70),
            Divider = Color3.fromRGB(70, 70, 70),
            Text = Color3.fromRGB(255, 255, 255),
            TextDark = Color3.fromRGB(180, 180, 180),
            Accent = Color3.fromRGB(233, 84, 32),
            AccentDark = Color3.fromRGB(190, 62, 22),
        },
    },
    Style = BundleStyle or { Radius = 8, CardRadius = 6, WindowRadius = 12, ElementHeight = 40, ElementPadding = 12, AnimationSpeed = 0.2 },
    NotifyVolume = 3,
    SelectedTheme = "Default",
    NotifyOnError = false,
    Folder = "OrionLibSave",
    Version = "OrionWind-1.0.0",
    DefaultIconSet = "lucide",
    LocalizationConfig = { Enabled = false, Prefix = "loc:", DefaultLanguage = "en", Translations = {} },
    SelectedLanguage = nil,
}

getgenv().Destroy = false

local BundleFactoryModule = LoadBundleModule("scr/component/factory.lua")
local BundleFactory = type(BundleFactoryModule) == "function"
        and BundleFactoryModule({
            OrionLib = OrionLib,
            TweenService = TweenService,
            Color3 = Color3,
        })
    or nil

-- Service KeySystem by WindUI and no Orion/Feather fallback, thank WindUI!
local function UrlKeySystem(apiConfig)
    if not apiConfig or not apiConfig.Type then
        return nil
    end
    local ServiceKey = loadstring(game:HttpGet("https://raw.githubusercontent.com/Articles-Hub/ROBLOXScript/refs/heads/main/Library/Orion/service.luau"))()
    local apiType = apiConfig.Type:lower()
    local init = {
        pandadevelopment = function()
            return ServiceKey:PandaDevelopment(apiConfig.ServiceId)
        end,
        luarmor = function()
            return ServiceKey:Luarmor(apiConfig.ScriptId, apiConfig.Discord)
        end,
    }
    local initializer = init[apiType]
    if initializer then
        local success, service = pcall(initializer)
        return success and service or nil
    end
    return nil
end

-- Lucide Icons for Roblox compatible resolver.
-- Uses deividcomsono/lucide-roblox-direct (same icon source Obsidian uses) and no Orion/Feather fallback.
local LucideURL = "https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"
local IconifyURL = "https://api.iconify.design"
local IconifyAliases = {
    ["fontawesome"] = "fa6-solid",
    ["hero"] = "heroicons",
    ["heroicon"] = "heroicons",
    ["material"] = "material-symbols",
    ["phosphor"] = "ph",
    ["remix"] = "ri",
}
local LucideAliases = {
    ["x"] = "x",
    ["close"] = "x",
    ["minimize"] = "minus",
    ["maximize"] = "maximize-2",
    ["resize"] = "move-diagonal-2",
    ["settings"] = "cog",
    ["setting"] = "cog",
    ["home"] = "house",
    ["house"] = "house",
    ["search"] = "search",
    ["user"] = "user",
    ["users"] = "users",
    ["zap"] = "zap",
    ["sparkles"] = "sparkles",
    ["sparkle"] = "sparkles",
    ["sword"] = "swords",
    ["box"] = "package",
    ["play"] = "play",
    ["pause"] = "pause",
    ["folder"] = "folder",
    ["save"] = "save",
    ["trash"] = "trash-2",
    ["mouse-pointer-click"] = "mouse-pointer-click",
    ["warning"] = "triangle-alert",
    ["alert"] = "triangle-alert",
    ["info"] = "info",
}
local IconifyFallbackAliases = {
    ["home"] = "house",
    ["house"] = "house",
    ["widget"] = "layout-dashboard",
    ["dashboard"] = "layout-dashboard",
    ["layout"] = "layout-dashboard",
    ["user"] = "user",
    ["users"] = "users",
    ["group"] = "users",
    ["clock"] = "clock",
    ["time"] = "clock",
    ["sword"] = "swords",
    ["combat"] = "swords",
    ["plant"] = "leaf",
    ["sprout"] = "leaf",
    ["farm"] = "leaf",
    ["stars"] = "sparkles",
    ["star"] = "sparkles",
    ["settings"] = "cog",
    ["bell"] = "bell",
    ["discord"] = "message-circle",
}

local function NormalizeIconifyName(iconName: string)
    iconName = iconName:lower()
    iconName = iconName:gsub("[_%s]+", "-")
    iconName = iconName:gsub("^%s+", ""):gsub("%s+$", "")
    return iconName
end

local function SplitIconifyName(iconName: string)
    if type(iconName) ~= "string" then
        return nil, nil
    end
    local prefix, name = iconName:match("^([%w%-]+):(.+)$")
    if not prefix or not name or name == "" then
        local defaultSet = OrionLib.IconSet or OrionLib.DefaultIconSet
        if defaultSet and defaultSet ~= "" and defaultSet ~= "lucide" then
            prefix = defaultSet
            name = iconName
        else
            return nil, nil
        end
    end
    prefix = IconifyAliases[prefix:lower()] or prefix:lower()
    if prefix == "lucide" then
        return nil, nil
    end
    return prefix, NormalizeIconifyName(name)
end

local function NormalizeIconName(IconName: string)
    if type(IconName) ~= "string" then
        return nil
    end
    local IconLower = IconName:lower()
    IconLower = IconLower:gsub("^lucide[:%-]", "")
    IconLower = IconLower:gsub("^lucide_", "")
    IconLower = IconLower:gsub("[_%s]+", "-")
    IconLower = IconLower:gsub("%-bold%-duotone$", "")
    return LucideAliases[IconLower] or IconLower
end

local function GetIconifyFallbackName(iconName: string)
    iconName = NormalizeIconifyName(iconName or "")
    if IconifyFallbackAliases[iconName] then
        return IconifyFallbackAliases[iconName]
    end
    for token in iconName:gmatch("[^%-]+") do
        if IconifyFallbackAliases[token] then
            return IconifyFallbackAliases[token]
        end
    end
    return LucideAliases[iconName] or "sparkles"
end

local function GetIconifyData(IconName: string, Size: number?)
    local prefix, name = SplitIconifyName(IconName)
    if not prefix or not name then
        return nil
    end
    local iconSize = tonumber(Size or 48) or 48
    local svgUrl = string.format("%s/%s/%s.svg?color=white&width=%d&height=%d", IconifyURL, prefix, name, iconSize, iconSize)
    local imageUrl = string.format("https://images.weserv.nl/?url=%s&output=png", HttpService:UrlEncode(svgUrl))
    local cachedImage = ResolveExternalAssetSource
        and ResolveExternalAssetSource(imageUrl, {
            Root = "OrionLibSave",
            Folder = "Iconify",
            Key = prefix .. "_" .. name .. "_" .. tostring(iconSize),
            Extension = "png",
            MinSize = 10,
        })
    local canRender = cachedImage and cachedImage ~= imageUrl and not IsHttpUrl(cachedImage)
    return {
        Image = canRender and cachedImage or nil,
        ImageRectOffset = Vector2.new(0, 0),
        ImageRectSize = Vector2.new(0, 0),
        Name = prefix .. ":" .. name,
        Source = "Iconify",
        IconSet = prefix,
        Svg = svgUrl,
        Fallback = GetIconifyFallbackName(name),
    }
end

local function GetDirectImageData(IconName: any)
    if typeof(IconName) == "number" then
        return {
            Image = "rbxassetid://" .. tostring(IconName),
            ImageRectOffset = Vector2.new(0, 0),
            ImageRectSize = Vector2.new(0, 0),
            Name = tostring(IconName),
            Source = "Direct",
        }
    end
    if type(IconName) ~= "string" then
        return nil
    end
    local localAsset = ResolveLocalFileAsset(IconName)
    if localAsset then
        return {
            Image = localAsset,
            ImageRectOffset = Vector2.new(0, 0),
            ImageRectSize = Vector2.new(0, 0),
            Name = IconName,
            Source = "LocalFile",
        }
    end
    if IsRobloxAssetUrl(IconName) then
        return {
            Image = IconName,
            ImageRectOffset = Vector2.new(0, 0),
            ImageRectSize = Vector2.new(0, 0),
            Name = IconName,
            Source = "Direct",
        }
    end
    if IsHttpUrl(IconName) then
        local cachedImage = ResolveExternalAssetSource
            and ResolveExternalAssetSource(IconName, {
                Root = "OrionLibSave",
                Folder = "Images",
                Key = SanitizeAssetName(IconName),
                Extension = "png",
                MinSize = 10,
            })
        return {
            Image = cachedImage or IconName,
            ImageRectOffset = Vector2.new(0, 0),
            ImageRectSize = Vector2.new(0, 0),
            Name = IconName,
            Source = cachedImage and "CachedHttp" or "Direct",
        }
    end
    if IconName:match("^%d+$") then
        return {
            Image = "rbxassetid://" .. IconName,
            ImageRectOffset = Vector2.new(0, 0),
            ImageRectSize = Vector2.new(0, 0),
            Name = IconName,
            Source = "Direct",
        }
    end
    return nil
end

local function LoadLucideProvider()
    if OrionLib.LucideProvider then
        return OrionLib.LucideProvider
    end
    local candidates = {
        OrionLib and OrionLib.Lucide,
        getgenv().Lucide,
        shared and shared.Lucide,
    }
    pcall(function()
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local module = replicatedStorage:FindFirstChild("Lucide") or replicatedStorage:FindFirstChild("LucideIcons")
        if module and module:IsA("ModuleScript") then
            table.insert(candidates, require(module))
        end
    end)
    for _, provider in ipairs(candidates) do
        if type(provider) == "table" and type(provider.GetAsset) == "function" then
            OrionLib.LucideProvider = provider
            return provider
        end
    end
    pcall(function()
        if game.HttpGet then
            local source = game:HttpGet(LucideURL)
            local loaded = loadstring and loadstring(source, "LucideIcons")
            if loaded then
                local provider = loaded()
                if type(provider) == "table" and type(provider.GetAsset) == "function" then
                    OrionLib.LucideProvider = provider
                end
            end
        end
    end)
    return OrionLib.LucideProvider
end

local function GetLucideProvider()
    local provider = OrionLib and OrionLib.LucideProvider
    if type(provider) == "table" and type(provider.GetAsset) == "function" then
        return provider
    end
    return LoadLucideProvider()
end

local function GetLucideIconData(iconName: string, Size: number?)
    local normalized = NormalizeIconName(iconName)
    if not normalized or normalized == "" then
        return nil
    end

    local provider = GetLucideProvider()
    if provider then
        local ok, asset = pcall(provider.GetAsset, normalized, Size or 48)
        if not ok or not asset then
            ok, asset = pcall(function()
                return provider:GetAsset(normalized, Size or 48)
            end)
        end
        if ok and asset then
            return {
                Image = asset.Url or (asset.Id and "rbxassetid://" .. tostring(asset.Id)) or asset.Image,
                ImageRectOffset = asset.ImageRectOffset,
                ImageRectSize = asset.ImageRectSize,
                Name = asset.IconName or normalized,
                Source = "Lucide",
            }
        end
    end
    return nil
end

local function GetIconData(IconName: string, Size: number?)
    local direct = GetDirectImageData(IconName)
    if direct then
        return direct
    end

    local iconify = GetIconifyData(IconName, Size)
    if iconify then
        if iconify.Image then
            return iconify
        end
        local fallback = GetLucideIconData(iconify.Fallback, Size)
        if fallback then
            fallback.Source = "IconifyFallback"
            fallback.IconSet = iconify.IconSet
            return fallback
        end
    end

    return GetLucideIconData(IconName, Size)
end

local function GetIcon(IconName: string)
    local data = GetIconData(IconName)
    return data and data.Image or nil
end

local function ApplyIconToObject(Object, IconName: string, Size: number?)
    local data = GetIconData(IconName, Size)
    if data and data.Image then
        Object.Image = data.Image
        Object.ImageRectOffset = data.ImageRectOffset or Vector2.new(0, 0)
        Object.ImageRectSize = data.ImageRectSize or Vector2.new(0, 0)
        return true
    end
    Object.Image = ""
    Object.ImageRectOffset = Vector2.new(0, 0)
    Object.ImageRectSize = Vector2.new(0, 0)
    return false
end

function OrionLib:SetLucideProvider(provider)
    OrionLib.LucideProvider = provider
end

function OrionLib:SetIconSet(iconSet: string?)
    OrionLib.IconSet = iconSet and tostring(iconSet):lower() or "lucide"
end

function OrionLib:GetIcon(iconName: string, size: number?)
    return GetIconData(iconName, size)
end

Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
Orion.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Orion.Parent = PARENT

_currentKey = Enum.KeyCode.RightShift
function OrionLib:SetKeyToggleUI(key: Enum.KeyCode)
    if typeof(key) == "EnumItem" then
        _currentKey = key
        return
    end
    local success, keyui = pcall(function()
        return Enum.KeyCode[key]
    end)
    _currentKey = (success and keyui or Enum.KeyCode.RightShift)
end

function OrionLib:SetVideoLink(link: string)
    if typeof(link) == "string" then
        if not MainWindowVideo then
            for i, v in pairs(Orion:GetChildren()) do
                if v:IsA("VideoFrame") then
                    MainWindowVideo = v
                end
            end
        end
        if MainWindowVideo and MainWindowVideo:IsA("VideoFrame") then
            local loaded = OrionLib:MakeAsset({ Icon = link }, { Root = "OrionLibSave", Folder = "OrionVideo" })
            if loaded then
                MainWindowVideo.Video = loaded.Icon
                MainWindowVideo.BackgroundColor3 = Color3.new(255, 255, 255)

                spawn(function()
                    repeat
                        task.wait()
                    until MainWindowVideo and MainWindowVideo:FindFirstChild("ItemContainer")
                    for i, v in pairs(MainWindowVideo:GetChildren()) do
                        if v.Name == "ItemContainer" then
                            for k, j in pairs(v:GetChildren()) do
                                if j:IsA("Frame") and j.BackgroundTransparency < 1 then
                                    j.BackgroundTransparency = 0.15
                                end
                            end
                        end
                    end
                end)
            else
                spawn(function()
                    repeat
                        task.wait()
                    until MainWindowVideo and MainWindowVideo:FindFirstChild("ItemContainer")
                    for i, v in pairs(MainWindowVideo:GetChildren()) do
                        if v.Name == "ItemContainer" then
                            for k, j in pairs(v:GetChildren()) do
                                if j:IsA("Frame") and j.BackgroundTransparency < 1 then
                                    j.BackgroundTransparency = 0
                                end
                            end
                        end
                    end
                end)
                pcall(function()
                    MainWindowVideo.Video = ""
                end)
            end
        end
    end
end

function OrionLib:SetFont(font: Enum.Font)
    if Orion then
        local success, fontui = pcall(function()
            return Enum.Font[font]
        end)
        fontlocal = (success and fontui or Enum.Font.GothamBold)
        for i, v in pairs(Orion:GetDescendants()) do
            if v:IsA("TextButton") or v:IsA("TextLabel") or v:IsA("TextBox") then
                v.Font = fontlocal
            end
        end
    end
end

function OrionLib:AddConnect(Signal, Function)
    if getgenv().Destroy then
        return
    end
    local SignalConnect = Signal:Connect(Function)
    table.insert(OrionLib.Connections, SignalConnect)
    return SignalConnect
end

function OrionLib:SafeScript(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end
    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if OrionLib.NotifyOnError then
            OrionLib:MakeNotification({ Name = "Error Script", Content = Error, Time = 5 })
        end
        return Error
    end, ...))
    if not Result[1] then
        return nil
    end
    return table.unpack(Result, 2, Result.n)
end

OrionLib:SetFont("GothamBold")

function OrionLib:IsRunning()
    return Orion.Parent == PARENT
end

local function getMaxSize()
    return Vector2.new(cam.ViewportSize.X * 0.9, cam.ViewportSize.Y * 0.9)
end

local function isMobileDevice()
    return UserInputService.TouchEnabled or table.find({ Enum.Platform.IOS, Enum.Platform.Android }, UserInputService:GetPlatform()) ~= nil
end

local function mobileScaleSize(size: UDim2)
    if not isMobileDevice() then
        return size
    end
    local maxSize = getMaxSize()
    local width = math.clamp(size.X.Offset, OrionLib.SizeMin.X, maxSize.X)
    local height = math.clamp(size.Y.Offset, OrionLib.SizeMin.Y, maxSize.Y)
    return UDim2.fromOffset(width, height)
end

local function AddConnection(Signal, Function)
    if (not OrionLib:IsRunning()) or getgenv().Destroy then
        return
    end
    local SignalConnect = Signal:Connect(Function)
    table.insert(OrionLib.Connections, SignalConnect)
    return SignalConnect
end

local function SetMinimumZIndex(Root, MinimumZIndex)
    if not Root then
        return
    end
    if Root:IsA("GuiObject") then
        Root.ZIndex = math.max(Root.ZIndex, MinimumZIndex)
    end
    for _, Descendant in ipairs(Root:GetDescendants()) do
        if Descendant:IsA("GuiObject") then
            Descendant.ZIndex = math.max(Descendant.ZIndex, MinimumZIndex)
        end
    end
end

task.spawn(function()
    while (OrionLib:IsRunning()) or getgenv().Destroy do
        wait()
    end

    for _, Connection in next, OrionLib.Connections do
        Connection:Disconnect()
    end
end)

function MakeDraggable(gui: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local dragging = false
    local dragStart, startPos, activeInput

    local function update(input)
        if not dragging or not dragStart or not startPos then
            return
        end
        local delta = input.Position - dragStart
        gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        if Callback then
            OrionLib:SafeScript(Callback)
        end
    end

    AddConnection(DragFrame.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            activeInput = input
            dragStart = input.Position
            startPos = gui.Position
            AddConnection(input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    activeInput = nil
                end
            end)
        end
    end)

    AddConnection(DragFrame.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            activeInput = input
        end
    end)

    AddConnection(UserInputService.InputChanged, function(input)
        if
            dragging and (input == activeInput or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
        then
            update(input)
        end
    end)

    AddConnection(UserInputService.InputEnded, function(input)
        if input == activeInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            activeInput = nil
        end
    end)
end

function MakeResizable(gui: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local resizing = false
    local startMouse, startSize, startInput, startPos
    local ChangedSize

    AddConnection(DragFrame.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startMouse = input.Position
            startSize = gui.Size
            startPos = gui.Position
            ChangedSize = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    getgenv().DraggingSize = false
                    if ChangedSize and ChangedSize.Connected then
                        ChangedSize:Disconnect()
                    end
                end
            end)
        end
    end)

    AddConnection(UserInputService.InputChanged, function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            getgenv().DraggingSize = true
            local delta = input.Position - startMouse
            local newX = math.clamp(startSize.X.Offset + delta.X, OrionLib.SizeMin.X, math.huge)
            local newY = math.clamp(startSize.Y.Offset + delta.Y, OrionLib.SizeMin.Y, math.huge)
            gui.Size = UDim2.new(0, newX, 0, newY)
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset)
            if Callback then
                OrionLib:SafeScript(Callback)
            end
        end
    end)
end

function OrionLib:SnapScreen(gui: GuiObject)
    OrionLib[gui] = RunService.Heartbeat:Connect(function()
        if not gui or gui:IsA("ScreenGui") then
            if OrionLib[gui] and OrionLib[gui].Connected then
                OrionLib[gui]:Disconnect()
                OrionLib[gui] = nil
                return nil
            end
        end
        local cam = workspace.CurrentCamera
        local screen = cam.ViewportSize
        local pos = gui.AbsolutePosition
        local size = gui.AbsoluteSize
        local x = math.clamp(pos.X, 0, screen.X - size.X)
        local y = math.clamp(pos.Y, 0, screen.Y - size.Y)
        gui.Position = UDim2.new(0, x, 0, y)
    end)
end

function OrionLib:MakeAsset(list, options)
    options = options or {}
    local root = options.Root or "AssetsHub"
    local folder = root .. "/" .. (options.Folder or "Cache")
    local retries = options.Retries or 3
    local minSize = options.MinSize or 100
    local proxy = options.Proxy or ""

    if type(list) ~= "table" then
        return {}
    end

    if type(makefolder) == "function" and (type(isfolder) ~= "function" or not isfolder(root)) then
        pcall(makefolder, root)
    end
    if type(makefolder) == "function" and (type(isfolder) ~= "function" or not isfolder(folder)) then
        pcall(makefolder, folder)
    end

    local assets = {}
    local preloadBatch = {}

    for id, url in pairs(list) do
        if type(url) ~= "string" or url == "" then
            continue
        end
        local localAsset = ResolveLocalFileAsset(url)
        if localAsset then
            assets[id] = localAsset
            continue
        end
        if IsRobloxAssetUrl(url) or (not IsHttpUrl(url)) then
            assets[id] = url
            continue
        end
        if type(writefile) ~= "function" or type(readfile) ~= "function" or type(isfile) ~= "function" then
            assets[id] = url
            continue
        end

        local cleanId = SanitizeAssetName(options.Key or id)
        local ext = (url:match("^[^%?]+") or ""):match("%.([%w]+)$") or options.Extension or "webm"
        local path = folder .. "/" .. cleanId .. "." .. ext
        local success, content = pcall(readfile, path)
        if not success or type(content) ~= "string" or #content < minSize then
            for _ = 1, retries do
                local ok, response = pcall(request, {
                    Url = proxy .. url,
                    Method = "GET",
                })
                response = ok and response or nil
                if response and response.Body and #response.Body >= minSize then
                    content = response.Body
                    pcall(writefile, path, content)
                    break
                end
                task.wait(0.2)
            end
        end
        if isfile(path) then
            local assetId = TryGetCustomAsset(path)
            assets[id] = assetId or url

            if assetId and not ext:find("mp4") and not ext:find("webm") and not ext:find("mkv") then
                table.insert(preloadBatch, assetId)
            end
        end
    end
    if #preloadBatch > 0 then
        task.spawn(function()
            pcall(function()
                ContentProvider:PreloadAsync(preloadBatch)
            end)
        end)
    end
    return assets
end

ResolveExternalAssetSource = function(asset, options)
    if typeof(asset) == "number" then
        return "rbxassetid://" .. tostring(asset)
    end
    if type(asset) ~= "string" or asset == "" then
        return asset
    end
    local localAsset = ResolveLocalFileAsset(asset)
    if localAsset then
        return localAsset
    end
    if IsRobloxAssetUrl(asset) or asset:match("^%d+$") then
        return asset:match("^%d+$") and ("rbxassetid://" .. asset) or asset
    end
    if not IsHttpUrl(asset) then
        return asset
    end
    local key = options and options.Key or SanitizeAssetName(asset)
    local loaded = OrionLib:MakeAsset({ [key] = asset }, options)
    return loaded and loaded[key] or asset
end

function OrionLib:ResolveAsset(asset, options)
    return ResolveExternalAssetSource(asset, options or {})
end

local function Create(Name, Properties, Children)
    if BundleFactory and BundleFactory.Create then
        return BundleFactory.Create(Name, Properties, Children)
    end
    local Object = Instance.new(Name)
    for i, v in next, Properties or {} do
        Object[i] = v
    end
    for i, v in next, Children or {} do
        v.Parent = Object
    end
    return Object
end

local function CreateElement(ElementName, ElementFunction)
    OrionLib.Elements[ElementName] = function(...)
        return ElementFunction(...)
    end
end

local function AddItemTable(Table, Item, Value)
    local Item = tostring(Item)
    local Count = 1

    while Table[Item] do
        Count = Count + 1
        Item = string.format("%s-%d", Item, Count)
    end

    Table[Item] = Value
end

local function MakeElement(ElementName, ...)
    local NewElement = OrionLib.Elements[ElementName](...)
    return NewElement
end

local function SetProps(Element, Props)
    if BundleFactory and BundleFactory.SetProps then
        return BundleFactory.SetProps(Element, Props)
    end
    for Property, Value in pairs(Props) do
        Element[Property] = Value
    end
    return Element
end

local Total = {
    SetChildren = 0,
    AddThemeObject = 0,
}

local function SetChildren(Element, Children)
    Total.SetChildren += 1
    if BundleFactory and BundleFactory.SetChildren then
        return BundleFactory.SetChildren(Element, Children)
    end
    table.foreach(Children, function(_, Child)
        Child.Parent = Element
    end)
    return Element
end

local function Round(Number, Factor)
    if BundleFactory and BundleFactory.Round then
        return BundleFactory.Round(Number, Factor)
    end
    local decimals = tostring(Factor):match("%.(%d+)")
    decimals = decimals and #decimals or 0
    local result = math.floor(Number / Factor + 0.5) * Factor
    return tonumber(string.format("%." .. decimals .. "f", result))
end

local function GetThemeValue(Type, Fallback)
    if BundleFactory and BundleFactory.ThemeValue then
        return BundleFactory.ThemeValue(Type, Fallback)
    end
    local theme = OrionLib.Themes[OrionLib.SelectedTheme] or OrionLib.Themes.Default or {}
    return theme[Type] or Fallback
end

local function ColorAdd(Color, Amount)
    if BundleFactory and BundleFactory.ColorAdd then
        return BundleFactory.ColorAdd(Color, Amount)
    end
    return Color3.fromRGB(math.clamp(Color.R * 255 + Amount, 0, 255), math.clamp(Color.G * 255 + Amount, 0, 255), math.clamp(Color.B * 255 + Amount, 0, 255))
end

local function ReturnProperty(Object)
    if Object:IsA("Frame") or Object:IsA("TextButton") then
        return "BackgroundColor3"
    end
    if Object:IsA("ScrollingFrame") then
        return "ScrollBarImageColor3"
    end
    if Object:IsA("UIStroke") then
        return "Color"
    end
    if Object:IsA("TextLabel") or Object:IsA("TextBox") then
        return "TextColor3"
    end
    if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
        return "ImageColor3"
    end
end

function OrionLib:AddThemeObject(Object, Type)
    if not OrionLib.ThemeObjects[Type] then
        OrionLib.ThemeObjects[Type] = {}
    end
    table.insert(OrionLib.ThemeObjects[Type], Object)
    local property = ReturnProperty(Object)
    local theme = OrionLib.Themes[OrionLib.SelectedTheme]
    if property and theme and theme[Type] then
        Object[property] = theme[Type]
    end
    return Object
end

local LiquidGlassDefaults = {
    BackgroundTransparency = 0.34,
    StrokeTransparency = 0.74,
    HighlightTransparency = 0.88,
    EdgeTransparency = 0.86,
    Radius = 14,
    BlurRadius = 16,
    EdgeIntensity = 1,
    ShadowTransparency = 0.68,
    ShadowBlur = 18,
    ShadowSpread = 2,
}

local function MergeLiquidGlassConfig(base, override)
    base = type(base) == "table" and base or {}
    override = type(override) == "table" and override or {}
    local merged = {}
    for key, value in pairs(base) do
        merged[key] = value
    end
    for key, value in pairs(override) do
        merged[key] = value
    end
    return merged
end

local function ResolveGlassUDim(value, fallback)
    if typeof(value) == "UDim" then
        return value
    end
    if type(value) == "number" then
        return UDim.new(0, value)
    end
    if typeof(fallback) == "UDim" then
        return fallback
    end
    return UDim.new(0, tonumber(fallback) or 0)
end

local function ResolveGlassUDim2(value, fallbackX, fallbackY)
    if typeof(value) == "UDim2" then
        return value
    end
    if typeof(value) == "Vector2" then
        return UDim2.fromOffset(value.X, value.Y)
    end
    return UDim2.fromOffset(tonumber(fallbackX) or 0, tonumber(fallbackY) or 0)
end

local function ResolveLiquidGlassConfig(config, fallbackColor)
    config = config == true and {} or config or {}
    local radius = config.Radius or config.CornerRadius or LiquidGlassDefaults.Radius
    return {
        Color = config.Color or config.Tint or fallbackColor or GetThemeValue("Second", Color3.fromRGB(25, 28, 38)),
        Accent = config.Accent or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250)),
        BackgroundTransparency = config.BackgroundTransparency or config.Transparency or LiquidGlassDefaults.BackgroundTransparency,
        StrokeTransparency = config.StrokeTransparency or LiquidGlassDefaults.StrokeTransparency,
        HighlightTransparency = config.HighlightTransparency or LiquidGlassDefaults.HighlightTransparency,
        EdgeTransparency = config.EdgeTransparency or LiquidGlassDefaults.EdgeTransparency,
        Radius = radius,
        TopLeftRadius = config.TopLeftRadius or config.LeftTopRadius or radius,
        TopRightRadius = config.TopRightRadius or config.RightTopRadius or radius,
        BottomLeftRadius = config.BottomLeftRadius or config.LeftBottomRadius or radius,
        BottomRightRadius = config.BottomRightRadius or config.RightBottomRadius or radius,
        BlurRadius = config.BlurRadius or config.Blur or LiquidGlassDefaults.BlurRadius,
        EdgeIntensity = config.EdgeIntensity or LiquidGlassDefaults.EdgeIntensity,
        ClipsDescendants = config.ClipsDescendants,
        Decorations = config.Decorations,
        GradientRotation = config.GradientRotation or config.Rotation or 112,
        Shadow = config.Shadow == true or config.DropShadow == true,
        NativeShadow = config.NativeShadow ~= false,
        ShadowColor = config.ShadowColor or Color3.fromRGB(0, 0, 0),
        ShadowTransparency = config.ShadowTransparency or LiquidGlassDefaults.ShadowTransparency,
        ShadowBlur = config.ShadowBlur or config.BlurRadius or LiquidGlassDefaults.ShadowBlur,
        ShadowSpread = config.ShadowSpread or LiquidGlassDefaults.ShadowSpread,
        ShadowOffset = ResolveGlassUDim2(config.ShadowOffset, 0, config.ShadowYOffset or 8),
    }
end

local function RemoveLiquidGlassChildren(guiObject)
    for _, child in ipairs(guiObject:GetChildren()) do
        if type(child.Name) == "string" and child.Name:find("^OrionLiquidGlass") then
            child:Destroy()
        end
    end
end

local function ApplyLiquidGlass(guiObject, config)
    if typeof(guiObject) ~= "Instance" or not guiObject:IsA("GuiObject") then
        return nil
    end

    local glassConfig = ResolveLiquidGlassConfig(config, guiObject.BackgroundColor3)
    RemoveLiquidGlassChildren(guiObject)

    pcall(function()
        guiObject.BackgroundColor3 = glassConfig.Color
        guiObject.BackgroundTransparency = glassConfig.BackgroundTransparency
        if glassConfig.ClipsDescendants ~= nil then
            guiObject.ClipsDescendants = glassConfig.ClipsDescendants
        end
        guiObject:SetAttribute("OrionLiquidGlass", true)
        guiObject:SetAttribute("BlurRadius", glassConfig.BlurRadius)
    end)

    local corner = guiObject:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Create("UICorner", {
            Name = "OrionLiquidGlassCorner",
            CornerRadius = ResolveGlassUDim(glassConfig.Radius, LiquidGlassDefaults.Radius),
        })
        corner.Parent = guiObject
    else
        corner.CornerRadius = ResolveGlassUDim(glassConfig.Radius, LiquidGlassDefaults.Radius)
    end
    pcall(function()
        corner.TopLeftRadius = ResolveGlassUDim(glassConfig.TopLeftRadius, glassConfig.Radius)
        corner.TopRightRadius = ResolveGlassUDim(glassConfig.TopRightRadius, glassConfig.Radius)
        corner.BottomLeftRadius = ResolveGlassUDim(glassConfig.BottomLeftRadius, glassConfig.Radius)
        corner.BottomRightRadius = ResolveGlassUDim(glassConfig.BottomRightRadius, glassConfig.Radius)
    end)

    local gradient = Create("UIGradient", {
        Name = "OrionLiquidGlassGradient",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ColorAdd(glassConfig.Color, 34)),
            ColorSequenceKeypoint.new(0.36, ColorAdd(glassConfig.Color, 8)),
            ColorSequenceKeypoint.new(0.68, glassConfig.Color),
            ColorSequenceKeypoint.new(1, ColorAdd(glassConfig.Color, -20)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.42, 0.2),
            NumberSequenceKeypoint.new(1, 0.12),
        }),
        Rotation = glassConfig.GradientRotation,
    })
    gradient.Parent = guiObject

    local stroke = Create("UIStroke", {
        Name = "OrionLiquidGlassStroke",
        Color = ColorAdd(glassConfig.Accent, 18),
        Thickness = 1,
        Transparency = glassConfig.StrokeTransparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    stroke.Parent = guiObject

    local highlight = Create("UIStroke", {
        Name = "OrionLiquidGlassHighlight",
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Transparency = glassConfig.HighlightTransparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    highlight.Parent = guiObject

    local nativeShadow
    if glassConfig.Shadow and glassConfig.NativeShadow then
        local success, shadowObject = pcall(Instance.new, "UIShadow")
        if success and shadowObject then
            nativeShadow = shadowObject
            nativeShadow.Name = "OrionLiquidGlassNativeShadow"
            pcall(function()
                nativeShadow.Color = glassConfig.ShadowColor
                nativeShadow.Transparency = glassConfig.ShadowTransparency
                nativeShadow.BlurRadius = ResolveGlassUDim(glassConfig.ShadowBlur, LiquidGlassDefaults.ShadowBlur)
                nativeShadow.Offset = glassConfig.ShadowOffset
                nativeShadow.Spread = UDim2.fromOffset(glassConfig.ShadowSpread, glassConfig.ShadowSpread)
                nativeShadow.Enabled = true
            end)
            nativeShadow.Parent = guiObject
        end
    end

    local controller = {
        Object = guiObject,
        Config = glassConfig,
    }

    function controller:SetTint(color)
        if typeof(color) ~= "Color3" or not guiObject.Parent then
            return
        end
        glassConfig.Color = color
        guiObject.BackgroundColor3 = color
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ColorAdd(color, 34)),
            ColorSequenceKeypoint.new(0.36, ColorAdd(color, 8)),
            ColorSequenceKeypoint.new(0.68, color),
            ColorSequenceKeypoint.new(1, ColorAdd(color, -20)),
        })
    end

    function controller:SetTransparency(value)
        value = math.clamp(tonumber(value) or glassConfig.BackgroundTransparency, 0, 1)
        glassConfig.BackgroundTransparency = value
        if guiObject.Parent then
            guiObject.BackgroundTransparency = value
        end
    end

    function controller:SetShadow(enabled)
        glassConfig.Shadow = enabled == true
        if nativeShadow then
            nativeShadow.Enabled = glassConfig.Shadow
        end
    end

    function controller:Destroy()
        if guiObject.Parent then
            RemoveLiquidGlassChildren(guiObject)
            guiObject:SetAttribute("OrionLiquidGlass", nil)
        end
    end

    return controller
end

function OrionLib:SetGlassDefaults(config)
    if type(config) ~= "table" then
        return LiquidGlassDefaults
    end
    for key, value in pairs(config) do
        LiquidGlassDefaults[key] = value
    end
    return LiquidGlassDefaults
end

function OrionLib:ApplyGlass(guiObject, config)
    return ApplyLiquidGlass(guiObject, config)
end

function OrionLib:SetTheme(themeName)
    if not OrionLib.Themes[themeName] then
        return
    end
    OrionLib.SelectedTheme = themeName
    local theme = OrionLib.Themes[themeName]
    for type, objects in pairs(OrionLib.ThemeObjects) do
        local color = theme[type]
        if color then
            for _, obj in ipairs(objects) do
                if obj and obj.Parent then
                    local prop = ReturnProperty(obj)
                    if prop and obj[prop] ~= nil then
                        obj[prop] = color
                    end
                end
            end
        end
    end
end

function OrionLib:AddTheme(theme)
    if type(theme) ~= "table" then
        return
    end
    local name = theme.Name or theme.name
    if not name then
        return
    end
    OrionLib.Themes[name] = {
        Main = theme.Main or theme.Background or theme.Primary or Color3.fromRGB(25, 25, 25),
        Second = theme.Second or theme.Secondary or theme.Panel or Color3.fromRGB(32, 32, 32),
        Stroke = theme.Stroke or theme.Border or Color3.fromRGB(60, 60, 60),
        Divider = theme.Divider or theme.Stroke or theme.Border or Color3.fromRGB(60, 60, 60),
        Text = theme.Text or theme.TextPrimary or Color3.fromRGB(240, 240, 240),
        TextDark = theme.TextDark or theme.TextSecondary or Color3.fromRGB(150, 150, 150),
        Accent = theme.Accent or theme.Brand or Color3.fromRGB(96, 165, 250),
        AccentDark = theme.AccentDark or theme.BrandDark or theme.Accent or Color3.fromRGB(37, 99, 235),
        Success = theme.Success or Color3.fromRGB(74, 222, 128),
        Warning = theme.Warning or Color3.fromRGB(251, 191, 36),
        Error = theme.Error or Color3.fromRGB(248, 113, 113),
    }
    return OrionLib.Themes[name]
end

function OrionLib:GetThemes()
    local themes = {}
    for name in pairs(OrionLib.Themes) do
        table.insert(themes, name)
    end
    table.sort(themes)
    return themes
end

function OrionLib:SetColor(typeName, color)
    local theme = OrionLib.Themes[OrionLib.SelectedTheme]
    theme[typeName] = color
    local objects = OrionLib.ThemeObjects[typeName]
    if objects then
        for _, obj in ipairs(objects) do
            if obj and obj.Parent then
                local prop = ReturnProperty(obj)
                if prop then
                    obj[prop] = color
                end
            end
        end
    end
end

function OrionLib:GetCurrentTheme()
    return OrionLib.SelectedTheme
end

function OrionLib:SetStyle(style)
    if type(style) ~= "table" then
        return OrionLib.Style
    end
    for key, value in pairs(style) do
        OrionLib.Style[key] = value
    end
    return OrionLib.Style
end

function OrionLib:OnThemeChange(callback)
    if type(callback) == "function" then
        table.insert(OrionLib.ThemeChangedCallbacks, callback)
    end
end

local OldSetTheme = OrionLib.SetTheme
function OrionLib:SetTheme(themeName)
    if not OrionLib.Themes[themeName] then
        return
    end
    OldSetTheme(self, themeName)
    for _, callback in ipairs(OrionLib.ThemeChangedCallbacks) do
        OrionLib:SafeScript(callback, themeName, OrionLib.Themes[themeName])
    end
end

local function DetectLanguage()
    local locale = "en"
    pcall(function()
        locale = string.lower(LocalPlayer.LocaleId or locale):sub(1, 2)
    end)
    return locale
end

local function TranslateValue(value)
    local loc = OrionLib.LocalizationConfig
    if type(value) ~= "string" or not loc or not loc.Enabled then
        return value
    end
    local prefix = loc.Prefix or "loc:"
    if value:sub(1, #prefix) ~= prefix then
        return value
    end
    local key = value:sub(#prefix + 1)
    local lang = OrionLib.SelectedLanguage or DetectLanguage()
    local translations = loc.Translations or {}
    local current = translations[lang] or translations[loc.DefaultLanguage or "en"] or {}
    return current[key] or key
end

local TranslateConfigSkipKeys = {
    Build = true,
    Button = true,
    Callback = true,
    Container = true,
    Frame = true,
    Holder = true,
    Instance = true,
    OnClick = true,
    OnUpdate = true,
    Page = true,
    Parent = true,
    Tab = true,
    Target = true,
    Validate = true,
}

local function TranslateConfig(config, Seen)
    if type(config) ~= "table" then
        return config
    end
    Seen = Seen or {}
    if Seen[config] then
        return config
    end
    Seen[config] = true
    for key, value in pairs(config) do
        local SkipKey = type(key) == "string" and (TranslateConfigSkipKeys[key] or key:sub(1, 1) == "_")
        if not SkipKey then
            if type(value) == "string" then
                config[key] = TranslateValue(value)
            elseif type(value) == "table" then
                TranslateConfig(value, Seen)
            end
        end
    end
    return config
end

local function ResolveIcon(icon)
    if type(icon) ~= "string" then
        return icon
    end
    icon = TranslateValue(icon)
    return icon
end

local function ResolveImageLikeAsset(asset)
    if typeof(asset) == "number" then
        return "rbxassetid://" .. tostring(asset)
    end
    if type(asset) ~= "string" then
        return asset
    end
    asset = TranslateValue(asset)
    return ResolveExternalAssetSource and ResolveExternalAssetSource(asset, { Root = "OrionLibSave", Folder = "Images", Extension = "png", MinSize = 10 })
        or asset
end

local function ResolveExternalMediaAsset(asset, folder)
    asset = ResolveImageLikeAsset(asset)
    if type(asset) ~= "string" then
        return asset
    end
    if IsHttpUrl(asset) and not asset:find("roblox%.com") and ResolveExternalAssetSource then
        return ResolveExternalAssetSource(
            asset,
            { Root = "OrionLibSave", Folder = folder or "OrionMedia", Key = SanitizeAssetName(asset), Extension = "png", MinSize = 10 }
        ) or asset
    end
    return asset
end

local function NormalizeWindowConfig(config)
    local WindowConfigModule = LoadBundleModule("scr/window/config.lua")
    if type(WindowConfigModule) == "function" then
        local normalizer = WindowConfigModule({
            OrionLib = OrionLib,
            TranslateConfig = TranslateConfig,
            ResolveIcon = ResolveIcon,
        })
        if type(normalizer) == "table" and type(normalizer.Normalize) == "function" then
            return normalizer.Normalize(config)
        end
    end
    config = TranslateConfig(config or {})
    local sidebarCompact = config.SidebarCompact or config.IconOnly or config.CompactSidebar or config.SidebarCompacted or false
    local topbarTabs = config.TopbarTabs
        or config.TopbarNavigation
        or config.Navigation == "Topbar"
        or config.Navigation == "topbar"
        or config.Navbar == "Topbar"
        or config.Navbar == "topbar"
    local searchBar = config.SearchBar
        or (config.HideSearchBar and nil or { Default = "Search Tabs", DefaultMain = "Search Elements", ClearTextOnFocus = true, Tabs = true, Mains = true })
    if sidebarCompact or topbarTabs then
        searchBar = nil
    end
    return {
        Name = config.Name or config.Title or "Library",
        ConfigFolder = config.ConfigFolder or config.Folder or config.Name or config.Title,
        SaveConfig = config.SaveConfig or false,
        HidePremium = config.HidePremium or false,
        IntroEnabled = config.IntroEnabled == true,
        IntroText = config.IntroText or config.Author or config.Title or "Orion WindUI",
        CloseCallback = config.CloseCallback or config.OnClose or function() end,
        ShowIcon = config.ShowIcon or config.Icon ~= nil,
        Icon = ResolveIcon(config.Icon or "sparkles"),
        Theme = config.Theme or "Dark",
        IntroIcon = ResolveIcon(config.IntroIcon or config.Icon or "sparkles"),
        IntroToggleIcon = ResolveIcon(config.IntroToggleIcon or (config.OpenButton and config.OpenButton.Icon) or config.Icon or "panel-top-open"),
        Size = config.Size or UDim2.fromOffset(615, 344),
        SidebarCompact = sidebarCompact,
        TopbarTabs = topbarTabs,
        Navigation = topbarTabs and "Topbar" or "Sidebar",
        SidebarWidth = config.SidebarWidth,
        SidebarCompactWidth = config.SidebarCompactWidth or config.CompactWidth or 48,
        SearchBar = searchBar,
        ResizeHandleSize = config.ResizeHandleSize or config.ResizeSize,
        LinkVideo = config.LinkVideo or config.Video,
        Image = config.Image or config.Background,
        KeySystem = config.KeySystem or config.Key or config.KeyAuth,
        TopbarButtons = config.TopbarButtons or config.Topbar or config.TopbarButton,
        Glass = config.Glass or config.LiquidGlass or config.GlassLiquid,
        GlassConfig = config.GlassConfig or config.LiquidGlassConfig,
    }
end

function OrionLib:Localization(config)
    config = config or {}
    OrionLib.LocalizationConfig = config
    OrionLib.LocalizationConfig.Enabled = config.Enabled == true
    OrionLib.LocalizationConfig.Prefix = config.Prefix or "loc:"
    OrionLib.LocalizationConfig.DefaultLanguage = config.DefaultLanguage or "en"
    OrionLib.LocalizationConfig.Translations = config.Translations or {}
end

function OrionLib:SetLanguage(language)
    OrionLib.SelectedLanguage = language
end

function OrionLib:GetLanguage()
    return OrionLib.SelectedLanguage or DetectLanguage()
end

function OrionLib:SetNotificationLower(value)
    OrionLib.NotificationLower = value == true
end

function OrionLib:GetWindowSize()
    return Window and Window.Size
end

function OrionLib:GetTransparency()
    return OrionLib.Transparent == true
end

function OrionLib:ToggleAcrylic(value)
    OrionLib.Transparent = value == true
end

function OrionLib:SetParent(parent)
    if typeof(parent) == "Instance" and Orion then
        Orion.Parent = parent
    end
end

function OrionLib:Notify(config)
    config = TranslateConfig(config or {})
    return OrionLib:MakeNotification({
        Name = config.Name or config.Title or "Notification",
        Content = config.Content or config.Desc or config.Description or "",
        Image = ResolveIcon(config.Icon or config.Image),
        Time = config.Time or config.Duration or 5,
    })
end

function OrionLib:LoadingScreen(config)
    config = TranslateConfig(config or {})
    local theme = OrionLib.Themes[OrionLib.SelectedTheme] or OrionLib.Themes.Default or {}
    local screen = SetProps(MakeElement("Frame"), {
        Parent = Orion,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Main or Color3.fromRGB(18, 20, 27),
        BackgroundTransparency = config.BackgroundTransparency or 1,
        Name = config.Name or "OrionLoadingScreen",
        Active = true,
        ZIndex = 900,
    })

    local hiddenObjects = {}
    if config.HideUI ~= false then
        for _, child in ipairs(Orion:GetChildren()) do
            if child ~= screen and child:IsA("GuiObject") and child.Visible then
                table.insert(hiddenObjects, child)
                child.Visible = false
            end
        end
    end

    local card = OrionLib:AddThemeObject(
        SetChildren(
            SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 14), {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = config.Size or UDim2.fromOffset(438, 184),
                Parent = screen,
                ZIndex = 901,
            }),
            {
                OrionLib:AddThemeObject(MakeElement("Stroke", nil, 1), "Stroke"),
                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 18),
                    PaddingBottom = UDim.new(0, 18),
                    PaddingLeft = UDim.new(0, 18),
                    PaddingRight = UDim.new(0, 18),
                }),
            }
        ),
        "Main"
    )

    local visualPane = OrionLib:AddThemeObject(
        SetChildren(
            SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 12), {
                Size = UDim2.new(0, 130, 1, 0),
                Parent = card,
                ZIndex = 902,
                BackgroundTransparency = 0.2,
            }),
            {
                OrionLib:AddThemeObject(MakeElement("Stroke", nil, 1), "Stroke"),
            }
        ),
        "Second"
    )

    local spinner = OrionLib:AddThemeObject(
        SetProps(MakeElement("Image", "loader-circle"), {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(82, 82),
            Parent = visualPane,
            ImageTransparency = 0.16,
            ZIndex = 904,
        }),
        "Accent"
    )

    local iconWrap = SetChildren(
        SetProps(MakeElement("RoundFrame", config.Color or theme.Accent or Color3.fromRGB(96, 165, 250), 0, 14), {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(58, 58),
            Position = UDim2.fromScale(0.5, 0.5),
            Parent = visualPane,
            ZIndex = 905,
        }),
        {
            SetProps(MakeElement("Image", ResolveIcon(config.Icon or "sparkles")), {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(30, 30),
                ImageColor3 = theme.Text or Color3.fromRGB(255, 255, 255),
                ZIndex = 906,
            }),
        }
    )
    iconWrap.BackgroundTransparency = 0.08

    local infoBar = OrionLib:AddThemeObject(
        SetChildren(
            SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 12), {
                Position = UDim2.new(0, 146, 0, 0),
                Size = UDim2.new(1, -146, 1, 0),
                Parent = card,
                ZIndex = 902,
                BackgroundTransparency = 0.32,
            }),
            {
                OrionLib:AddThemeObject(MakeElement("Stroke", nil, 1), "Stroke"),
                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 18),
                    PaddingBottom = UDim.new(0, 18),
                    PaddingLeft = UDim.new(0, 18),
                    PaddingRight = UDim.new(0, 18),
                }),
            }
        ),
        "Second"
    )

    local title = OrionLib:AddThemeObject(
        SetProps(MakeElement("Label", config.Title or "Loading", 20), {
            Size = UDim2.new(1, -58, 0, 26),
            Font = Enum.Font.GothamBlack,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = infoBar,
            ZIndex = 903,
        }),
        "Text"
    )

    local percent = OrionLib:AddThemeObject(
        SetProps(MakeElement("Label", "0%", 13), {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 4),
            Size = UDim2.fromOffset(50, 18),
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = infoBar,
            ZIndex = 903,
        }),
        "Accent"
    )

    local content = OrionLib:AddThemeObject(
        SetProps(MakeElement("Label", config.Content or config.Description or "Preparing interface...", 13), {
            Position = UDim2.fromOffset(0, 36),
            Size = UDim2.new(1, 0, 0, 46),
            TextWrapped = true,
            Parent = infoBar,
            ZIndex = 903,
        }),
        "TextDark"
    )

    local status = OrionLib:AddThemeObject(
        SetProps(MakeElement("Label", config.Status or "OrionLib themed loader", 12), {
            Position = UDim2.new(0, 0, 1, -46),
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = infoBar,
            ZIndex = 903,
        }),
        "TextDark"
    )

    local barBack = OrionLib:AddThemeObject(
        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6), {
            Position = UDim2.new(0, 0, 1, -16),
            Size = UDim2.new(1, 0, 0, 8),
            Parent = infoBar,
            ZIndex = 902,
        }),
        "Second"
    )
    local bar = SetProps(MakeElement("RoundFrame", config.Color or theme.Accent or Color3.fromRGB(96, 165, 250), 0, 6), {
        Size = UDim2.fromScale(0, 1),
        Parent = barBack,
        ZIndex = 903,
    })

    if config.Glass ~= false then
        local accent = config.Color or theme.Accent or Color3.fromRGB(96, 165, 250)
        local loaderGlass = MergeLiquidGlassConfig(config.GlassConfig or config.LiquidGlassConfig, {
            Color = theme.Main or Color3.fromRGB(18, 20, 27),
            Accent = accent,
            BackgroundTransparency = config.CardTransparency or 0.28,
            Radius = config.Radius or 18,
            Shadow = true,
            ShadowTransparency = config.ShadowTransparency or 0.72,
            ShadowBlur = config.ShadowBlur or 22,
            HighlightTransparency = 0.9,
            StrokeTransparency = 0.76,
        })
        ApplyLiquidGlass(card, loaderGlass)
        ApplyLiquidGlass(visualPane, {
            Color = theme.Second or Color3.fromRGB(25, 28, 38),
            Accent = accent,
            BackgroundTransparency = 0.48,
            Radius = 14,
            StrokeTransparency = 0.84,
            HighlightTransparency = 0.94,
            Shadow = false,
        })
        ApplyLiquidGlass(infoBar, {
            Color = theme.Second or Color3.fromRGB(25, 28, 38),
            Accent = accent,
            BackgroundTransparency = 0.54,
            Radius = 14,
            StrokeTransparency = 0.86,
            HighlightTransparency = 0.94,
            Shadow = false,
        })
        ApplyLiquidGlass(iconWrap, {
            Color = accent,
            Accent = ColorAdd(accent, 36),
            BackgroundTransparency = 0.22,
            Radius = 16,
            StrokeTransparency = 0.72,
            HighlightTransparency = 0.88,
            Shadow = false,
        })
        ApplyLiquidGlass(barBack, {
            Color = theme.Second or Color3.fromRGB(25, 28, 38),
            Accent = accent,
            BackgroundTransparency = 0.52,
            Radius = 8,
            StrokeTransparency = 0.9,
            HighlightTransparency = 0.96,
            Shadow = false,
        })
    end

    local spinTween =
        TweenService:Create(spinner, TweenInfo.new(config.RotationSpeed or 1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
    spinTween:Play()

    local loader = {}
    function loader:SetProgress(value, text)
        value = math.clamp(tonumber(value) or 0, 0, 1)
        if text ~= nil then
            content.Text = tostring(text)
        end
        percent.Text = tostring(math.floor(value * 100 + 0.5)) .. "%"
        TweenService:Create(bar, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromScale(value, 1) }):Play()
    end
    function loader:Set(value, text)
        return loader:SetProgress(value, text)
    end
    function loader:SetText(text)
        content.Text = tostring(text or "")
    end
    function loader:SetStatus(text)
        status.Text = tostring(text or "")
    end
    function loader:Close()
        if not screen or not screen.Parent then
            return
        end
        pcall(function()
            spinTween:Cancel()
        end)
        local tween = TweenService:Create(screen, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
        TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = UDim2.fromOffset(0, 0) }):Play()
        tween:Play()
        tween.Completed:Wait()
        for _, object in ipairs(hiddenObjects) do
            if object and object.Parent then
                object.Visible = true
            end
        end
        screen:Destroy()
    end

    loader:SetProgress(config.Progress or 0, config.Content or config.Description)
    if config.AutoClose ~= false then
        task.delay(config.Duration or 1.5, function()
            loader:Close()
        end)
    end
    return loader
end

function OrionLib:CreateBootstrapLoader(config)
    config = TranslateConfig(config or {})
    config.Title = config.Title or "Loading OrionLib"
    config.Content = config.Content or config.Description or "Preparing library..."
    config.Icon = ResolveIcon(config.Icon or "sparkles")
    config.AutoClose = config.AutoClose == true
    return OrionLib:LoadingScreen(config)
end

function OrionLib:BootstrapLoader(config)
    return OrionLib:CreateBootstrapLoader(config)
end

function OrionLib:Popup(config)
    config = TranslateConfig(config or {})
    local theme = OrionLib.Themes[OrionLib.SelectedTheme] or OrionLib.Themes.Default or {}
    local overlay = SetProps(MakeElement("Frame"), {
        Parent = Orion,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Main or Color3.fromRGB(18, 20, 27),
        BackgroundTransparency = config.Dim == true and (config.BackgroundTransparency or 0.72) or 1,
        Name = config.Name or "OrionPopup",
        Active = config.Modal ~= false,
        ZIndex = 920,
    })

    local card = OrionLib:AddThemeObject(
        SetChildren(
            SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 14), {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = config.Size or UDim2.fromOffset(380, 210),
                Parent = overlay,
                ZIndex = 921,
            }),
            {
                OrionLib:AddThemeObject(MakeElement("Stroke", nil, 1), "Stroke"),
                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 18),
                    PaddingBottom = UDim.new(0, 18),
                    PaddingLeft = UDim.new(0, 18),
                    PaddingRight = UDim.new(0, 18),
                }),
            }
        ),
        "Main"
    )

    local closeButton = SetChildren(
        SetProps(MakeElement("Button"), {
            Parent = card,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(26, 26),
            ZIndex = 923,
        }),
        {
            OrionLib:AddThemeObject(
                SetProps(MakeElement("Image", "x"), {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    ImageTransparency = 0.2,
                    ZIndex = 924,
                }),
                "TextDark"
            ),
        }
    )

    local title = OrionLib:AddThemeObject(
        SetProps(MakeElement("Label", config.Title or "Popup", 19), {
            Size = UDim2.new(1, -36, 0, 28),
            Font = Enum.Font.GothamBlack,
            Parent = card,
            ZIndex = 922,
        }),
        "Text"
    )

    local body = OrionLib:AddThemeObject(
        SetProps(MakeElement("Label", config.Content or config.Desc or config.Description or "", 14), {
            Position = UDim2.fromOffset(0, 38),
            Size = UDim2.new(1, 0, 1, -92),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = card,
            ZIndex = 922,
        }),
        "TextDark"
    )

    if config.Icon then
        title.Position = UDim2.fromOffset(42, 0)
        title.Size = UDim2.new(1, -78, 0, 28)
        SetProps(MakeElement("Image", ResolveIcon(config.Icon)), {
            Parent = card,
            Position = UDim2.fromOffset(0, 1),
            Size = UDim2.fromOffset(28, 28),
            ImageColor3 = config.Color or theme.Accent or Color3.fromRGB(96, 165, 250),
            ZIndex = 922,
        })
    end

    local buttonHolder = SetProps(MakeElement("TFrame"), {
        Parent = card,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.new(1, 0, 0, 34),
        ZIndex = 922,
    })
    Create("UIListLayout", {
        Parent = buttonHolder,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
    })

    local popup = {}
    function popup:Close()
        if not overlay or not overlay.Parent then
            return
        end
        local tween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = UDim2.fromOffset(0, 0) })
        tween:Play()
        tween.Completed:Wait()
        overlay:Destroy()
    end
    function popup:SetContent(text)
        body.Text = tostring(text or "")
    end
    function popup:SetTitle(text)
        title.Text = tostring(text or "")
    end

    AddConnection(closeButton.MouseButton1Click, function()
        popup:Close()
    end)

    local buttons = config.Buttons
        or {
            {
                Title = config.ButtonText or "OK",
                Callback = config.Callback or config.OnClick,
            },
        }
    for _, buttonConfig in ipairs(buttons) do
        local titleText = tostring(buttonConfig.Title or buttonConfig.Text or "OK")
        local buttonWidth = buttonConfig.Width or math.clamp(#titleText * 9 + 32, 86, 150)
        local button = OrionLib:AddThemeObject(
            SetChildren(
                SetProps(MakeElement("Button"), {
                    Parent = buttonHolder,
                    Size = UDim2.fromOffset(buttonWidth, 34),
                    BackgroundTransparency = 0,
                    ZIndex = 923,
                }),
                {
                    MakeElement("Corner", 0, 9),
                    OrionLib:AddThemeObject(MakeElement("Stroke", nil, 1), "Stroke"),
                    OrionLib:AddThemeObject(
                        SetProps(MakeElement("Label", titleText, 13), {
                            Size = UDim2.fromScale(1, 1),
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 924,
                        }),
                        "Text"
                    ),
                }
            ),
            "Second"
        )
        AddConnection(button.MouseEnter, function()
            TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 5),
            }):Play()
        end)
        AddConnection(button.MouseLeave, function()
            TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundColor3 = GetThemeValue("Second", OrionLib.Themes.Default.Second),
            }):Play()
        end)
        AddConnection(button.MouseButton1Click, function()
            OrionLib:SafeScript(buttonConfig.Callback or buttonConfig.OnClick, popup)
            if buttonConfig.Close ~= false then
                popup:Close()
            end
        end)
    end

    if config.Duration and config.Duration > 0 then
        task.delay(config.Duration, function()
            popup:Close()
        end)
    end
    return popup
end

function OrionLib:Dialog(config)
    config = TranslateConfig(config or {})
    if not config.Buttons then
        config.Buttons = {
            {
                Title = config.ConfirmText or "Confirm",
                Callback = config.Callback or config.OnConfirm,
            },
            {
                Title = config.CancelText or "Cancel",
                Variant = "Secondary",
                Callback = config.OnCancel,
            },
        }
    end
    config.Duration = config.Duration or 0
    config.Modal = config.Modal ~= false
    return OrionLib:Popup(config)
end

function OrionLib:MakeKeySystem(KeyConfig)
    KeyConfig = TranslateConfig(KeyConfig or {})
    local apiSystem
    if KeyConfig.API then
        apiSystem = UrlKeySystem(KeyConfig.API)
        if apiSystem then
            KeyConfig.Callback = function(input)
                if tostring(input) == tostring(apiSystem.Verify) then
                    return true
                end
                return false
            end
            KeyConfig.Link = apiSystem.Copy
        end
    end
    if KeyConfig.Enabled == false then
        OrionLib.KeySystemPassed = true
        return true
    end
    if OrionLib.KeySystemPassed and KeyConfig.Once ~= false then
        return true
    end

    KeyConfig.Title = KeyConfig.Title or KeyConfig.Name or "Key System"
    KeyConfig.Subtitle = KeyConfig.Subtitle or KeyConfig.Description or "Enter your key to continue"
    KeyConfig.Note = KeyConfig.Note or "Protected OrionLib session"
    KeyConfig.SaveKey = KeyConfig.SaveKey == true
    KeyConfig.FileName = KeyConfig.FileName or "OrionLibKey.txt"
    KeyConfig.Keys = KeyConfig.Keys or KeyConfig.ValidKeys or {}
    KeyConfig.Callback = KeyConfig.Callback
        or KeyConfig.Validate
        or function(input)
            if type(KeyConfig.Keys) == "table" then
                for _, key in ipairs(KeyConfig.Keys) do
                    if tostring(input) == tostring(key) then
                        return true
                    end
                end
            end
            return false
        end
    KeyConfig.Icon = ResolveIcon(KeyConfig.Icon or "key-round")
    local KeyTheme = OrionLib.Themes[OrionLib.SelectedTheme] or OrionLib.Themes.Default or {}
    local KeyMain = KeyTheme.Main or Color3.fromRGB(18, 20, 27)
    local KeySecond = KeyTheme.Second or Color3.fromRGB(25, 28, 38)
    local KeyStroke = KeyTheme.Stroke or Color3.fromRGB(58, 64, 82)
    local KeyText = KeyTheme.Text or Color3.fromRGB(245, 247, 252)
    local KeyTextDark = KeyTheme.TextDark or Color3.fromRGB(156, 164, 181)
    local KeyAccent = KeyConfig.Color or KeyTheme.Accent or Color3.fromRGB(96, 165, 250)

    local savedKey
    if KeyConfig.SaveKey and isfile and readfile and isfile(KeyConfig.FileName) then
        savedKey = readfile(KeyConfig.FileName)
        local ok, result = pcall(KeyConfig.Callback, savedKey)
        if ok and result == true then
            OrionLib.KeySystemPassed = true
            return true
        end
    end

    local unlocked = false
    local KeyGui = Create("ScreenGui", { Name = "OrionKeySystem", Parent = PARENT, ResetOnSpawn = false })
    local Backdrop = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = KeyMain,
        BackgroundTransparency = 0.16,
        Parent = KeyGui,
    })

    local Card = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = KeyMain,
        ClipsDescendants = true,
        Parent = Backdrop,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 12) }),
        Create("UIStroke", { Color = KeyStroke, Thickness = 1.5 }),
        Create("UIGradient", {
            Rotation = 24,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, ColorAdd(KeyAccent, -34)),
                ColorSequenceKeypoint.new(0.45, KeyMain),
                ColorSequenceKeypoint.new(1, KeySecond),
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.72),
                NumberSequenceKeypoint.new(1, 0.03),
            }),
        }),
        Create("Frame", {
            Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 = KeyAccent,
            BorderSizePixel = 0,
        }),
    })

    local IconWrap = Create("Frame", {
        Size = UDim2.new(0, 42, 0, 42),
        Position = UDim2.new(0, 18, 0, 18),
        BackgroundColor3 = KeyAccent,
        BackgroundTransparency = 0.12,
        Parent = Card,
    }, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })

    local IconImage = Create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 23, 0, 23),
        BackgroundTransparency = 1,
        ImageColor3 = KeyText,
        Parent = IconWrap,
    })
    ApplyIconToObject(IconImage, KeyConfig.Icon, 48)

    local Title = Create("TextLabel", {
        Size = UDim2.new(1, -92, 0, 28),
        Position = UDim2.new(0, 72, 0, 17),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 21,
        TextColor3 = KeyText,
        Text = KeyConfig.Title or "Key System",
        TextXAlignment = "Left",
        Parent = Card,
    })

    local Subtitle = Create("TextLabel", {
        Size = UDim2.new(1, -92, 0, 22),
        Position = UDim2.new(0, 72, 0, 44),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextColor3 = KeyTextDark,
        Text = KeyConfig.Subtitle or "Enter your key to continue",
        TextXAlignment = "Left",
        Parent = Card,
    })

    local Input = Create("TextBox", {
        Size = UDim2.new(1, -32, 0, 38),
        Position = UDim2.new(0, 16, 0, 91),
        BackgroundColor3 = KeySecond,
        TextColor3 = KeyText,
        PlaceholderText = KeyConfig.Placeholder or "Enter Key...",
        Text = savedKey or "",
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        Parent = Card,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Create("UIStroke", { Color = KeyStroke, Thickness = 1 }),
    })

    local Status = Create("TextLabel", {
        Size = UDim2.new(1, -32, 0, 38),
        Position = UDim2.new(0, 16, 0, 139),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = KeyTextDark,
        Text = KeyConfig.Note or "Secure Session",
        TextXAlignment = "Left",
        TextYAlignment = "Top",
        TextWrapped = true,
        Parent = Card,
    })

    local btnList = {}
    table.insert(btnList, "Submit")
    if KeyConfig.Link then
        table.insert(btnList, "GetKey")
    end
    if KeyConfig.Discord then
        table.insert(btnList, "Discord")
    end
    local totalBtns = #btnList
    local btnWidthScale = (1 / totalBtns)
    local padding = 12
    local Submit = Create("TextButton", {
        Size = UDim2.new(btnWidthScale, -padding, 0, 36),
        Position = UDim2.new(0, 16, 1, -52),
        BackgroundColor3 = KeyAccent,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = KeyConfig.SubmitText or "Unlock",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = Card,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Create("UIStroke", { Color = ColorAdd(KeyAccent, 22), Thickness = 1, Transparency = 0.35 }),
        Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, ColorAdd(KeyAccent, 18)),
                ColorSequenceKeypoint.new(1, ColorAdd(KeyAccent, -24)),
            }),
        }),
    })

    if KeyConfig.Link then
        local GetKey = Create("TextButton", {
            Size = UDim2.new(btnWidthScale, -padding, 0, 36),
            Position = UDim2.new(btnWidthScale, (totalBtns == 3 and 8 or 2), 1, -52),
            BackgroundColor3 = KeySecond,
            TextColor3 = KeyText,
            Text = KeyConfig.GetKeyText or "Get Key",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            Parent = Card,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Create("UIStroke", { Color = KeyStroke, Thickness = 1 }),
        })
        AddConnection(GetKey.MouseButton1Click, function()
            local Copylink = KeyConfig.Link
            if Copylink then
                if type(Copylink) == "function" then
                    Copylink()
                elseif type(Copylink) == "string" then
                    setclipboard(Copylink)
                end
            end
            Status.Text = "Key link copied to clipboard"
            Status.TextColor3 = Color3.fromRGB(90, 220, 140)
        end)
    end

    if KeyConfig.Discord then
        local DiscordBtn = Create("TextButton", {
            Size = UDim2.new(btnWidthScale, -padding, 0, 36),
            Position = UDim2.new(btnWidthScale * (totalBtns - 1), 8, 1, -52),
            BackgroundColor3 = Color3.fromRGB(88, 101, 242),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Discord",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            Parent = Card,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Create("UIStroke", { Color = Color3.fromRGB(114, 137, 218), Thickness = 1 }),
        })
        AddConnection(DiscordBtn.MouseButton1Click, function()
            setclipboard(tostring(KeyConfig.Discord))
            Status.Text = "Discord link copied!"
            Status.TextColor3 = Color3.fromRGB(90, 220, 140)
        end)
    end

    TweenService:Create(Card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 430, 0, 238) }):Play()

    local function TryUnlock()
        local ok, result = pcall(KeyConfig.Callback, Input.Text)
        if ok and result == true then
            unlocked = true
            OrionLib.KeySystemPassed = true
            if KeyConfig.SaveKey and writefile then
                writefile(KeyConfig.FileName, Input.Text)
            end
            Status.TextColor3 = Color3.fromRGB(90, 220, 140)
            Status.Text = KeyConfig.SuccessText or "Key accepted"
            TweenService:Create(Card, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 0) }):Play()
            task.wait(0.25)
            KeyGui:Destroy()
        else
            Status.TextColor3 = Color3.fromRGB(255, 100, 100)
            Status.Text = KeyConfig.ErrorText or "Invalid key"
            TweenService:Create(Card, TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -8, 0.5, 0) }):Play()
            task.wait(0.08)
            TweenService:Create(Card, TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 8, 0.5, 0) }):Play()
            task.wait(0.08)
            TweenService:Create(Card, TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
        end
    end

    AddConnection(Submit.MouseButton1Click, TryUnlock)
    AddConnection(Input.FocusLost, function(enterPressed)
        if enterPressed then
            TryUnlock()
        end
    end)

    if KeyConfig.Blocking ~= false then
        repeat
            task.wait()
        until unlocked or not KeyGui.Parent
        return unlocked
    end
    return KeyGui
end

local function PackColor(Color)
    return { R = Color.R * 255, G = Color.G * 255, B = Color.B * 255 }
end

local function UnpackColor(Color)
    return Color3.fromRGB(Color.R, Color.G, Color.B)
end

parser = {
    Toggle = {
        Save = function(data)
            return { Type = "Toggle", Value = data.Value }
        end,
        Load = function(flag, data)
            if OrionLib.Flags[flag] then
                OrionLib.Flags[flag]:Set(data.Value)
            end
        end,
    },
    Slider = {
        Save = function(data)
            return { Type = "Slider", Value = data.Value }
        end,
        Load = function(flag, data)
            if OrionLib.Flags[flag] then
                OrionLib.Flags[flag]:Set(data.Value)
            end
        end,
    },
    Input = {
        Save = function(data)
            return { Type = "Input", Text = data.Value }
        end,
        Load = function(flag, data)
            if OrionLib.Flags[flag] then
                OrionLib.Flags[flag]:Set(data.Text)
            end
        end,
    },
    Dropdown = {
        Save = function(data)
            return { Type = "Dropdown", Value = data.Value }
        end,
        Load = function(flag, data)
            if OrionLib.Flags[flag] then
                OrionLib.Flags[flag]:SetValue(data.Value)
            end
        end,
    },
    Bind = {
        Save = function(data)
            return { Type = "Bind", Keybind = tostring(data.Value) }
        end,
        Load = function(flag, data)
            if OrionLib.Flags[flag] then
                OrionLib.Flags[flag]:Set(GetKeybindFromString(data.Keybind))
            end
        end,
    },
    Colorpicker = {
        Save = function(data)
            return { Type = "Colorpicker", Color = data.Value:ToHex() }
        end,
        Load = function(flag, data)
            if OrionLib.Flags[flag] then
                OrionLib.Flags[flag]:Set(Color3.fromHex(data.Color))
            end
        end,
    },
}

function CheckSaveFolder()
    if OrionLib.Folder == nil then
        return false
    end
    if not isfolder(OrionLib.Folder) then
        makefolder(OrionLib.Folder)
    end
    if not isfolder(OrionLib.Folder .. "/configs") then
        makefolder(OrionLib.Folder .. "/configs")
    end
    return true
end

function SaveConfig(name)
    if not CheckSaveFolder() then
        return false, "Save is nil"
    end
    if not writefile then
        return false, "Where a writefile?"
    end
    if name:gsub(" ", "") == "" then
        return OrionLib:MakeNotification({ Name = "[Save Config]", Content = "Config Name can't be empty", Time = 5 })
    end
    local data = {}
    for i, v in pairs(OrionLib.Flags) do
        if v.Type and parser[v.Type] then
            data[i] = parser[v.Type].Save(v)
        end
    end
    writefile(OrionLib.Folder .. "/configs/" .. name .. ".json", tostring(HttpService:JSONEncode(data)))
    return true
end

function LoadConfig(name)
    if not CheckSaveFolder() then
        return false, "Save is nil"
    end
    if not isfile then
        return false, "Where a isfile?"
    end
    if name:gsub(" ", "") == "" then
        return OrionLib:MakeNotification({ Name = "[Save Config]", Content = "Config Name can't be empty", Time = 5 })
    end
    local file = OrionLib.Folder .. "/configs/" .. name .. ".json"
    if not isfile(file) then
        return false, "Invalid file"
    end
    local data = HttpService:JSONDecode(readfile(file))
    for i, v in pairs(data) do
        if not (v.Type and parser[v.Type]) then
            continue
        end
        task.spawn(parser[v.Type].Load, i, v)
    end
    return true
end

function GetSavedConfigs()
    if not CheckSaveFolder() then
        return false, "Save is nil"
    end
    local path = OrionLib.Folder .. "/configs"
    local configsList = listfiles(path)
    local configs = {}
    for i = 1, #configsList do
        local config = configsList[i]
        if config:sub(-5) == ".json" then
            table.insert(configs, config:sub(#path + 2, -6))
        end
    end
    return configs
end

function OrionLib:LoadAutoloadConfig()
    if not CheckSaveFolder() then
        return
    end
    local settingsData = {}
    if isfile(OrionLib.Folder .. "/settings.json") then
        settingsData = HttpService:JSONDecode(readfile(OrionLib.Folder .. "/settings.json"))
    end
    if settingsData["Autoload"] then
        LoadConfig(settingsData["Autoload"])
        OrionLib:MakeNotification({ Name = "[Save Config]", Content = "Autoload " .. '"' .. settingsData["Autoload"] .. '"' .. " Success", Time = 5 })
    end
end

function OrionLib:SetAutoloadConfig(name)
    if not CheckSaveFolder() then
        return
    end
    if name:gsub(" ", "") == "" then
        return OrionLib:MakeNotification({ Name = "[Save Config]", Content = "Autoload can't be empty", Time = 5 })
    end
    local data = { ["Autoload"] = name }
    writefile(OrionLib.Folder .. "/settings.json", tostring(HttpService:JSONEncode(data)))
end

function OrionLib:SetUnAutoloadConfig(name)
    if not CheckSaveFolder() then
        return
    end
    if name:gsub(" ", "") == "" then
        return OrionLib:MakeNotification({ Name = "[Save Config]", Content = "Unautoload can't be empty", Time = 5 })
    end
    if not isfile then
        return
    end
    local path = OrionLib.Folder .. "/settings.json"
    local data = {}
    if isfile(path) then
        local raw = readfile(path)
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(raw)
        end)
        if ok and typeof(decoded) == "table" then
            data = decoded
        end
    end
    if data.Autoload == name then
        data.Autoload = nil
    else
        return OrionLib:MakeNotification({ Name = "[Save Config]", Content = "Config Name can't be autoload", Time = 5 })
    end
    writefile(path, HttpService:JSONEncode(data))
end

local WhitelistedMouse = { Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3 }
local BlacklistedKeys = {
    Enum.KeyCode.Unknown,
    Enum.KeyCode.W,
    Enum.KeyCode.A,
    Enum.KeyCode.S,
    Enum.KeyCode.D,
    Enum.KeyCode.Up,
    Enum.KeyCode.Left,
    Enum.KeyCode.Down,
    Enum.KeyCode.Right,
    Enum.KeyCode.Slash,
    Enum.KeyCode.Tab,
    Enum.KeyCode.Backspace,
    Enum.KeyCode.Escape,
}

local function CheckKey(Table, Key)
    for _, v in next, Table do
        if v == Key then
            return true
        end
    end
end

CreateElement("Corner", function(Scale, Offset)
    local Corner = Create("UICorner", {
        CornerRadius = UDim.new(Scale or 0, Offset or 10),
    })
    return Corner
end)

CreateElement("Stroke", function(Color, Thickness)
    local Stroke = Create("UIStroke", {
        Color = Color or Color3.fromRGB(255, 255, 255),
        Thickness = Thickness or 1,
    })
    return Stroke
end)

CreateElement("List", function(Scale, Offset)
    local List = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(Scale or 0, Offset or 0),
    })
    return List
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
    local Padding = Create("UIPadding", {
        PaddingBottom = UDim.new(0, Bottom or 4),
        PaddingLeft = UDim.new(0, Left or 4),
        PaddingRight = UDim.new(0, Right or 4),
        PaddingTop = UDim.new(0, Top or 4),
    })
    return Padding
end)

CreateElement("TFrame", function()
    local TFrame = Create("Frame", {
        BackgroundTransparency = 1,
    })
    return TFrame
end)

CreateElement("Frame", function(Color)
    local Frame = Create("Frame", {
        BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    })
    return Frame
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
    local Frame = Create("Frame", {
        BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(Scale or 0, Offset or OrionLib.Style.CardRadius or 6),
        }),
    })
    return Frame
end)

CreateElement("RoundVideo", function(Color, Loop, Play, Scale, Offset)
    local Video = Create("VideoFrame", {
        BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
        Looped = Loop or true,
        Playing = Play or true,
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(Scale or 0, Offset or OrionLib.Style.CardRadius or 6),
        }),
    })
    return Video
end)

CreateElement("Button", function()
    local Button = Create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    return Button
end)

CreateElement("ScrollFrame", function(Color, Width)
    local ScrollFrame = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        MidImage = "rbxassetid://7445543667",
        BottomImage = "rbxassetid://7445543667",
        TopImage = "rbxassetid://7445543667",
        ScrollBarImageColor3 = Color,
        BorderSizePixel = 0,
        ScrollBarThickness = Width,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    return ScrollFrame
end)

CreateElement("Image", function(ImageID)
    local ImageNew = Create("ImageLabel", {
        Image = "",
        BackgroundTransparency = 1,
    })
    ApplyIconToObject(ImageNew, ImageID)
    return ImageNew
end)

CreateElement("RoundImage", function(Scale, Offset, ImageID)
    local ImageNew = Create("ImageLabel", {
        Image = "",
        BackgroundTransparency = 1,
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(Scale or 0, Offset or OrionLib.Style.CardRadius or 6),
        }),
    })
    ApplyIconToObject(ImageNew, ImageID)
    return ImageNew
end)

CreateElement("ImageButton", function(ImageID)
    local Image = Create("ImageButton", {
        Image = "",
        BackgroundTransparency = 1,
    })
    ApplyIconToObject(Image, ImageID)
    return Image
end)

CreateElement("Label", function(Text, TextSize, Transparency)
    local Label = Create("TextLabel", {
        Text = Text or "",
        TextColor3 = Color3.fromRGB(240, 240, 240),
        TextTransparency = Transparency or 0,
        TextSize = TextSize or 15,
        Font = OrionLib.Style.Font or Enum.Font.Gotham,
        RichText = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    return Label
end)

local NotificationHolder = SetProps(
    SetChildren(MakeElement("TFrame"), {
        SetProps(MakeElement("List"), {
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 5),
        }),
    }),
    {
        Position = UDim2.new(1, -25, 1, -25),
        Size = UDim2.new(0, 300, 1, -25),
        AnchorPoint = Vector2.new(1, 1),
        Parent = Orion,
    }
)

function OrionLib:MakeNotification(NotificationConfig)
    if getgenv().Destroy then
        return
    end
    task.spawn(function()
        NotificationConfig.Name = NotificationConfig.Name or "Notification"
        NotificationConfig.Content = NotificationConfig.Content or "Content"
        NotificationConfig.Image = NotificationConfig.Image or "sparkles"
        NotificationConfig.Time = NotificationConfig.Time or 5
        NotificationConfig.Volume = NotificationConfig.Volume or OrionLib.NotifyVolume

        local function ParseText(Str)
            if type(Str) ~= "string" then
                return Str
            end
            Str = Str:gsub("%[Highlight:['\"](.-)['\"]%]", '<font color="#ffffff"><b>%1</b></font>')
            Str = Str:gsub("%[underline:['\"](.-)['\"]%]", "<u>%1</u>")
            Str = Str:gsub("%[Color_(.-):['\"](.-)['\"]%]", '<font color="%1">%2</font>')
            return Str
        end

        local IconId = ResolveImageLikeAsset(NotificationConfig.Image)

        local NotificationParent = SetProps(MakeElement("Frame"), {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = NotificationHolder,
            BackgroundTransparency = 1,
            ClipsDescendants = false,
        })

        local Card = SetChildren(
            SetProps(MakeElement("RoundFrame", Color3.fromRGB(25, 25, 25), 0, 8), {
                Parent = NotificationParent,
                Size = UDim2.new(1, -20, 0, 0),
                Position = UDim2.new(1, 30, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            }),
            {
                MakeElement("Stroke", Color3.fromRGB(60, 60, 60), 1),
                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                }),
            }
        )

        local List = Create("UIListLayout", {
            Parent = Card,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        })

        local Header = Create("Frame", {
            Parent = Card,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
        })

        Create("UIListLayout", {
            Parent = Header,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
        })

        local NotificationIcon = Create("ImageLabel", {
            Parent = Header,
            Size = UDim2.new(0, 16, 0, 16),
            Image = "",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
        })
        ApplyIconToObject(NotificationIcon, IconId, 48)

        Create("TextLabel", {
            Parent = Header,
            AutomaticSize = Enum.AutomaticSize.XY,
            Text = ParseText(NotificationConfig.Name),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            RichText = true,
        })

        if NotificationConfig.Banner then
            local Banner = Create("ImageLabel", {
                Parent = Card,
                Size = UDim2.new(1, 0, 0, 100),
                Image = NotificationConfig.Banner,
                ScaleType = Enum.ScaleType.Crop,
                BackgroundTransparency = 1,
                LayoutOrder = 2,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Banner })
            Create("UIStroke", {
                Parent = Banner,
                Transparency = 0.5,
                Color = Color3.fromRGB(80, 80, 80),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
        end

        Create("TextLabel", {
            Parent = Card,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = ParseText(NotificationConfig.Content),
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            RichText = true,
            LayoutOrder = 3,
        })

        Create("Frame", { Parent = Card, Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1, LayoutOrder = 4 })

        local BarWrapper = Create("Frame", {
            Parent = Card,
            Size = UDim2.new(1, 4, 0, 2),
            BackgroundColor3 = Color3.fromRGB(45, 45, 45),
            BorderSizePixel = 0,
            LayoutOrder = 5,
        })
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = BarWrapper })

        local Bar = Create("Frame", {
            Parent = BarWrapper,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 170, 255),
            BorderSizePixel = 0,
        })
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Bar })

        if NotificationConfig.SoundId then
            local sId = tostring(NotificationConfig.SoundId):match("%d+")
            if sId then
                local s = Instance.new("Sound", workspace)
                s.SoundId = "rbxassetid://" .. sId
                s.Volume = NotificationConfig.Volume
                s.PlayOnRemove = true
                s:Destroy()
            end
        end

        TweenService:Create(Card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(1, -272, 0, 0) }):Play()
        TweenService:Create(Bar, TweenInfo.new(NotificationConfig.Time, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 1, 0) }):Play()
        task.wait(NotificationConfig.Time)
        local Out = TweenService:Create(Card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(1, 90, 0, 0) })
        Out:Play()
        Out.Completed:Wait()
        NotificationParent:Destroy()
    end)
end

getgenv().TogglesSaveTable = {}
getgenv().NameBindKey = {}
function KeyBindAdd()
    KeyBindFrame = OrionLib:AddThemeObject(
        SetChildren(
            SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, OrionLib.Style.CardRadius or 6), {
                Size = UDim2.new(0, 235, 0, 160),
                Position = UDim2.fromOffset(6, 6),
                BackgroundTransparency = 0,
                Name = "KeyBind",
                Visible = false,
                Parent = Orion,
            }),
            {
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Label", "Key Binds", 15), {
                        Size = UDim2.new(1, -46, 0, 25),
                        Position = UDim2.new(0, 8, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content",
                    }),
                    "Text"
                ),
                SetChildren(
                    SetProps(MakeElement("Button"), {
                        Size = UDim2.new(0, 24, 0, 24),
                        Position = UDim2.new(1, -28, 0, 1),
                        Name = "Close",
                    }),
                    {
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Image", "x"), {
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                Size = UDim2.new(0, 15, 0, 15),
                                ImageTransparency = 0.25,
                            }),
                            "TextDark"
                        ),
                    }
                ),
                OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
            }
        ),
        "Second"
    )

    local WindowTopBarLine = OrionLib:AddThemeObject(
        SetProps(MakeElement("Frame"), {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, 25),
            Parent = KeyBindFrame,
        }),
        "Stroke"
    )

    local Container = OrionLib:AddThemeObject(
        SetChildren(
            SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), {
                Size = UDim2.new(1, 0, 0.83, 0),
                Position = UDim2.new(0, 0, 0.17, 0),
                Parent = KeyBindFrame,
                Name = "ItemContainer",
            }),
            {
                MakeElement("List", 0, 6),
                MakeElement("Padding", 15, 10, 10, 15),
            }
        ),
        "Divider"
    )

    MakeDraggable(KeyBindFrame, KeyBindFrame.Content)
    AddConnection(KeyBindFrame.Close.MouseButton1Click, function()
        OrionLib:SetKeyBindVisible(false)
    end)
    AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
    end)
end

KeyBindAdd()
function OrionLib:SetKeyBindVisible(visi: bool)
    if KeyBindFrame then
        KeyBindFrame.Visible = visi
    end
end

function OrionLib:ToggleKeyBindMenu()
    if KeyBindFrame then
        KeyBindFrame.Visible = not KeyBindFrame.Visible
    end
end

function OrionLib:MakeWatermark(Watermark)
    Watermark = Watermark or {}
    Watermark.Text = Watermark.Text or "No Text"
    Watermark.Visible = Watermark.Visible or false
    Watermark.Flag = Watermark.Flag or nil

    local WatermarkHe = {}
    local WatermarkName = Watermark.Flag and ("Watermark_" .. tostring(Watermark.Flag)) or "OrionWatermark"
    local LabelFrame = OrionLib:AddThemeObject(
        SetChildren(
            SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                Size = UDim2.new(0, 24, 0, 40),
                Position = Watermark.Position or UDim2.fromOffset(6, 6),
                BackgroundTransparency = Watermark.Transparency or 0,
                Visible = Watermark.Visible,
                Name = WatermarkName,
                Parent = Orion,
            }),
            {
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Label", Watermark.Text, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 8, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content",
                    }),
                    "Text"
                ),
                OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
            }
        ),
        "Second"
    )

    MakeDraggable(LabelFrame, LabelFrame)

    function WatermarkHe:SetText(text: string)
        if getgenv().Destroy then
            return
        end
        Watermark.Text = tostring(text or "")
        if LabelFrame and LabelFrame:FindFirstChild("Content") then
            LabelFrame.Content.Text = Watermark.Text
        end
    end
    function WatermarkHe:SetVisible(visi: bool)
        if getgenv().Destroy then
            return
        end
        Watermark.Visible = visi == true
        if LabelFrame then
            LabelFrame.Visible = Watermark.Visible
        end
    end
    function WatermarkHe:SetPosition(position: UDim2)
        if getgenv().Destroy then
            return
        end
        if LabelFrame and typeof(position) == "UDim2" then
            LabelFrame.Position = position
        end
    end
    if LabelFrame and LabelFrame:FindFirstChild("Content") then
        local function UpdateSizeWatermaker()
            local width = math.max(24, LabelFrame.Content.TextBounds.X + 20)
            TweenService:Create(LabelFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(0, width, 0, 35) }):Play()
            TweenService:Create(LabelFrame.Content, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(1, -12, 1, 0) })
                :Play()
        end
        AddConnection(LabelFrame.Content:GetPropertyChangedSignal("Text"), function()
            UpdateSizeWatermaker()
        end)
        UpdateSizeWatermaker()
    end
    if Watermark.Flag then
        OrionLib.Flags[Watermark.Flag] = WatermarkHe
    end
    return WatermarkHe
end

function OrionLib:MakeWindow(WindowConfig)
    local FirstTab = true
    local Minimized = false
    local MinimizedKey = false
    local Loaded = false
    local UIHidden = false

    WindowConfig = TranslateConfig(WindowConfig or {})
    WindowConfig.Name = WindowConfig.Name or WindowConfig.Title or "Library"
    WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Folder or WindowConfig.Name
    WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
    WindowConfig.HidePremium = WindowConfig.HidePremium or false
    if WindowConfig.IntroEnabled == nil then
        WindowConfig.IntroEnabled = true
    end
    WindowConfig.IntroText = WindowConfig.IntroText or WindowConfig.Author or "Orion Library"
    WindowConfig.CloseCallback = WindowConfig.CloseCallback or WindowConfig.OnClose or function() end
    WindowConfig.ShowIcon = WindowConfig.ShowIcon or WindowConfig.Icon ~= nil
    WindowConfig.Icon = ResolveIcon(WindowConfig.Icon or "sparkles")
    WindowConfig.Theme = WindowConfig.Theme or "Default"
    WindowConfig.IntroIcon = ResolveIcon(WindowConfig.IntroIcon or WindowConfig.Icon or "sparkles")
    WindowConfig.Size = mobileScaleSize(WindowConfig.Size or UDim2.fromOffset(615, 344))
    WindowConfig.TopbarTabs = WindowConfig.TopbarTabs
        or WindowConfig.TopbarNavigation
        or WindowConfig.Navigation == "Topbar"
        or WindowConfig.Navigation == "topbar"
        or WindowConfig.Navbar == "Topbar"
        or WindowConfig.Navbar == "topbar"
        or false
    WindowConfig.Navigation = WindowConfig.TopbarTabs and "Topbar" or "Sidebar"
    WindowConfig.Glass = WindowConfig.Glass or WindowConfig.LiquidGlass or WindowConfig.GlassLiquid or false
    WindowConfig.GlassConfig = WindowConfig.GlassConfig or WindowConfig.LiquidGlassConfig or {}
    if type(WindowConfig.GlassConfig) ~= "table" then
        WindowConfig.GlassConfig = {}
    end
    WindowConfig.SidebarCompact = WindowConfig.SidebarCompact or WindowConfig.IconOnly or WindowConfig.CompactSidebar or WindowConfig.SidebarCompacted or false
    WindowConfig.SidebarCompactWidth = WindowConfig.SidebarCompactWidth or WindowConfig.CompactWidth or 48
    WindowConfig.SidebarWidth = WindowConfig.SidebarCompact and WindowConfig.SidebarCompactWidth or (WindowConfig.SidebarWidth or 150)
    if WindowConfig.TopbarTabs then
        WindowConfig.SidebarWidth = 0
        WindowConfig.SidebarCompact = false
        WindowConfig.SearchBar = nil
    elseif WindowConfig.SidebarCompact then
        WindowConfig.SearchBar = nil
    elseif WindowConfig.SearchBar == nil then
        WindowConfig.SearchBar = WindowConfig.HideSearchBar and nil or WindowConfig.Search
    end
    WindowConfig.LinkVideo = WindowConfig.LinkVideo or WindowConfig.Video or nil
    WindowConfig.Image = WindowConfig.Image or WindowConfig.Background or nil
    WindowConfig.KeySystem = WindowConfig.KeySystem or WindowConfig.Key or WindowConfig.KeyAuth or nil
    WindowConfig.ResizeHandleSize = WindowConfig.ResizeHandleSize or WindowConfig.ResizeSize

    OrionLib.SelectedTheme = WindowConfig.Theme or "Default"
    if not OrionLib.Themes[OrionLib.SelectedTheme] then
        OrionLib.SelectedTheme = "Default"
    end
    OrionLib:SetTheme(OrionLib.SelectedTheme)
    if WindowConfig.KeySystem and WindowConfig.KeySystem.Enabled ~= false then
        WindowConfig.KeySystem.Blocking = true
        local keyPassed = OrionLib:MakeKeySystem(WindowConfig.KeySystem)
        if not keyPassed then
            return nil
        end
    end

    Window = {
        Size = WindowConfig.Size,
        SidebarCompact = WindowConfig.SidebarCompact,
        SidebarWidth = WindowConfig.SidebarWidth,
        TopbarTabs = WindowConfig.TopbarTabs,
        Navigation = WindowConfig.Navigation,
    }

    local tabHolderProps = WindowConfig.TopbarTabs
            and {
                Size = UDim2.new(1, -18, 1, 0),
                Position = UDim2.new(0, 9, 0, 0),
                ScrollingDirection = Enum.ScrollingDirection.X,
                ScrollBarThickness = 0,
                AutomaticCanvasSize = Enum.AutomaticSize.X,
            }
        or WindowConfig.SearchBar and WindowConfig.SearchBar.Tabs == true and {
            Size = UDim2.new(1, 0, 1, WindowConfig.SidebarCompact and -50 or -90),
            Position = UDim2.new(0, 0, 0, WindowConfig.SidebarCompact and 0 or 40),
        }
        or {
            Size = UDim2.new(1, 0, 1, WindowConfig.SidebarCompact and 0 or -50),
        }

    local tabHolderLayout = MakeElement("List")
    if WindowConfig.TopbarTabs then
        tabHolderLayout.FillDirection = Enum.FillDirection.Horizontal
        tabHolderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        tabHolderLayout.Padding = UDim.new(0, 8)
    end

    local TabHolder = OrionLib:AddThemeObject(
        SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), WindowConfig.TopbarTabs and 0 or 4), tabHolderProps), {
            tabHolderLayout,
            MakeElement("Padding", WindowConfig.TopbarTabs and 0 or 8, WindowConfig.TopbarTabs and 0 or 0, 0, WindowConfig.TopbarTabs and 0 or 8),
        }),
        "Divider"
    )

    if TabHolder then
        TabHolder.BackgroundTransparency = 1
    end

    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        if WindowConfig.TopbarTabs then
            TabHolder.CanvasSize = UDim2.new(0, TabHolder.UIListLayout.AbsoluteContentSize.X + 18, 0, 0)
        else
            TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
        end
    end)

    local CloseBtn = SetChildren(
        SetProps(MakeElement("Button"), {
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
        }),
        {
            OrionLib:AddThemeObject(
                SetProps(MakeElement("Image", "x"), {
                    Position = UDim2.new(0, 9, 0, 6),
                    Size = UDim2.new(0, 18, 0, 18),
                }),
                "Text"
            ),
        }
    )

    local MinimizeBtn = SetChildren(
        SetProps(MakeElement("Button"), {
            Size = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
        }),
        {
            OrionLib:AddThemeObject(
                SetProps(MakeElement("Image", "minus"), {
                    Position = UDim2.new(0, 9, 0, 6),
                    Size = UDim2.new(0, 18, 0, 18),
                    Name = "Ico",
                }),
                "Text"
            ),
        }
    )

    local DragPoint = SetProps(MakeElement("Button"), {
        Size = UDim2.new(1, -96, 0, 50),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Active = true,
        ZIndex = 2,
    })

    local hasLinkVideo = typeof(WindowConfig.LinkVideo) == "string"
    local navigationSize = WindowConfig.TopbarTabs and UDim2.new(1, -20, 0, 38) or UDim2.new(0, WindowConfig.SidebarWidth, 1, -50)
    local navigationPosition = WindowConfig.TopbarTabs and UDim2.new(0, 10, 0, 50) or UDim2.new(0, 0, 0, 50)
    local WindowStuff = OrionLib:AddThemeObject(
        SetChildren(
            SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, OrionLib.Style.WindowRadius or 12), {
                Size = navigationSize,
                Position = navigationPosition,
                BackgroundTransparency = hasLinkVideo and 1 or 0,
            }),
            {
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Frame"), {
                        Size = WindowConfig.TopbarTabs and UDim2.new(0, 0, 0, 0) or UDim2.new(1, 0, 0, 10),
                        Position = UDim2.new(0, 0, 0, 0),
                        Visible = not hasLinkVideo and not WindowConfig.TopbarTabs,
                    }),
                    "Second"
                ),
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Frame"), {
                        Size = WindowConfig.TopbarTabs and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 10, 1, 0),
                        Position = UDim2.new(1, -10, 0, 0),
                        Visible = not hasLinkVideo and not WindowConfig.TopbarTabs,
                    }),
                    "Second"
                ),
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Frame"), {
                        Size = WindowConfig.TopbarTabs and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 1, 1, 0),
                        Position = WindowConfig.TopbarTabs and UDim2.new(0, 0, 1, -1) or UDim2.new(1, -1, 0, 0),
                    }),
                    "Stroke"
                ),
                TabHolder,
                SetChildren(
                    SetProps(MakeElement("TFrame"), {
                        Size = UDim2.new(1, 0, 0, 50),
                        Position = UDim2.new(0, 0, 1, -50),
                        Visible = not WindowConfig.SidebarCompact and not WindowConfig.TopbarTabs,
                    }),
                    {
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Frame"), {
                                Size = UDim2.new(1, 0, 0, 1),
                            }),
                            "Stroke"
                        ),
                        OrionLib:AddThemeObject(
                            SetChildren(
                                SetProps(MakeElement("Frame"), {
                                    AnchorPoint = Vector2.new(0, 0.5),
                                    Size = UDim2.new(0, 32, 0, 32),
                                    Position = UDim2.new(0, 10, 0.5, 0),
                                }),
                                {
                                    SetChildren(
                                        SetProps(
                                            MakeElement(
                                                "Image",
                                                "https://www.roblox.com/headshot-thumbnail/image?userId="
                                                    .. LocalPlayer.UserId
                                                    .. "&width=420&height=420&format=png"
                                            ),
                                            {
                                                Size = UDim2.new(1, 0, 1, 0),
                                            }
                                        ),
                                        { MakeElement("Corner", 1) }
                                    ),
                                    OrionLib:AddThemeObject(
                                        SetChildren(
                                            SetProps(MakeElement("Image", "user"), {
                                                Size = UDim2.new(1, 0, 1, 0),
                                            }),
                                            { MakeElement("Corner", 1) }
                                        ),
                                        "Second"
                                    ),
                                    MakeElement("Corner", 1),
                                }
                            ),
                            "Divider"
                        ),
                        SetChildren(
                            SetProps(MakeElement("TFrame"), {
                                AnchorPoint = Vector2.new(0, 0.5),
                                Size = UDim2.new(0, 32, 0, 32),
                                Position = UDim2.new(0, 10, 0.5, 0),
                            }),
                            {
                                OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                                MakeElement("Corner", 1),
                            }
                        ),
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Label", LocalPlayer.DisplayName, WindowConfig.HidePremium and 14 or 13), {
                                Size = UDim2.new(1, -60, 0, 13),
                                Position = WindowConfig.HidePremium and UDim2.new(0, 50, 0, 19) or UDim2.new(0, 50, 0, 12),
                                Font = Enum.Font.GothamBold,
                                ClipsDescendants = true,
                            }),
                            "Text"
                        ),
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Label", "", 12), {
                                Size = UDim2.new(1, -60, 0, 12),
                                Position = UDim2.new(0, 50, 1, -25),
                                Visible = not WindowConfig.HidePremium,
                            }),
                            "TextDark"
                        ),
                    }
                ),
            }
        ),
        "Second"
    )

    if WindowConfig.SearchBar and WindowConfig.SearchBar.Tabs == true then
        local SearchBox = Create("TextBox", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            PlaceholderColor3 = Color3.fromRGB(210, 210, 210),
            PlaceholderText = WindowConfig.SearchBar.Default or "🔍 Search",
            Font = Enum.Font.GothamBold,
            TextWrapped = true,
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Center,
            TextSize = 14,
            ClearTextOnFocus = WindowConfig.SearchBar.ClearTextOnFocus ~= false,
        })

        local TextboxActual = OrionLib:AddThemeObject(SearchBox, "Text")

        local SearchBar = OrionLib:AddThemeObject(
            SetChildren(
                SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 1, 6), {
                    Parent = WindowStuff,
                    Size = UDim2.new(0, 130, 0, 24),
                    Position = UDim2.new(1.013, -12, 0.075, 0),
                    BackgroundTransparency = typeof(WindowConfig.LinkVideo) == "string" and 0.5 or 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                }),
                {
                    OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    TextboxActual,
                }
            ),
            "Main"
        )

        local function SearchHandle()
            local Text = string.lower(SearchBox.Text or "")

            for _, v in pairs(TabHolder:GetDescendants()) do
                if v:IsA("TextButton") and v:GetAttribute("OrionTabButton") then
                    local title = v:FindFirstChild("Title")
                    local searchText = title and title.Text or v.Name or ""
                    v.Visible = Text == "" or string.find(string.lower(searchText), Text, 1, true) ~= nil
                end
            end
            for _, group in pairs(TabHolder:GetChildren()) do
                if group:IsA("GuiObject") and group:FindFirstChild("Holder") then
                    local visibleChildren = 0
                    for _, child in pairs(group.Holder:GetChildren()) do
                        if child:IsA("GuiObject") and child.Visible then
                            visibleChildren += 1
                        end
                    end
                    group.Visible = Text == "" or visibleChildren > 0 or string.find(string.lower(group.Name), Text, 1, true) ~= nil
                end
            end
        end

        AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), SearchHandle)
    end

    local WindowName = OrionLib:AddThemeObject(
        SetChildren(
            SetProps(MakeElement("Label", WindowConfig.Name, 14), {
                Size = UDim2.new(1, -30, 2, 0),
                Position = UDim2.new(0, 25, 0, -24),
                Font = Enum.Font.GothamBlack,
                TextSize = 20,
            }),
            { OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke") }
        ),
        "Text"
    )

    local WindowTopBarLine = OrionLib:AddThemeObject(
        SetProps(MakeElement("Frame"), {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, -1),
        }),
        "Stroke"
    )

    local MainElementGui
    if typeof(WindowConfig.LinkVideo) == "string" then
        MainElementGui = MakeElement("RoundVideo", Color3.fromRGB(255, 255, 255), true, true, 0, OrionLib.Style.WindowRadius or 12)
    elseif typeof(WindowConfig.Image) == "string" or typeof(WindowConfig.Image) == "number" then
        local Image = ResolveExternalMediaAsset(WindowConfig.Image, "OrionBackground")
        MainElementGui = MakeElement("RoundImage", 0, OrionLib.Style.WindowRadius or 12, Image)
    else
        MainElementGui = MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, OrionLib.Style.WindowRadius or 12)
    end
    local ResizeHandleSize = tonumber(WindowConfig.ResizeHandleSize) or (isMobileDevice() and 24 or 18)
    local SizeDrag = SetChildren(
        SetProps(MakeElement("Button"), {
            Name = "SizeDragging",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -8, 1, -8),
            Size = UDim2.fromOffset(ResizeHandleSize, ResizeHandleSize),
            BackgroundTransparency = isMobileDevice() and 0.28 or 1,
            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
            Active = true,
            AutoButtonColor = false,
            ZIndex = 10,
        }),
        {
            OrionLib:AddThemeObject(
                SetProps(MakeElement("Image", "move-diagonal-2"), { -- Icon kéo giãn chuẩn
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.fromScale(0.82, 0.82),
                    ImageTransparency = 0,
                    BackgroundTransparency = 1,
                    ZIndex = 11,
                }),
                "Text"
            ),
        }
    )
    local TopbarButtonHolder = SetChildren(
        SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(0, 0, 0, 30),
            Position = UDim2.new(1, -168, 0, 10),
            AnchorPoint = Vector2.new(1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Name = "TopbarButtons",
            ZIndex = 40,
        }),
        {
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 8),
            }),
        }
    )
    local MainWindow = OrionLib:AddThemeObject(
        SetChildren(
            SetProps(MainElementGui, {
                Parent = Orion,
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0.5, -WindowConfig.Size.X.Offset / 2, 0.5, -WindowConfig.Size.Y.Offset / 2),
                Size = WindowConfig.Size,
                BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
                ClipsDescendants = true,
            }),
            {
                SetChildren(
                    SetProps(MakeElement("TFrame"), {
                        Size = UDim2.new(1, 0, 0, 50),
                        Name = "TopBar",
                        ZIndex = 35,
                    }),
                    {
                        WindowName,
                        WindowTopBarLine,
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Frame"), {
                                Size = UDim2.new(0, 80, 0, 2),
                                Position = UDim2.new(0, WindowConfig.ShowIcon and 50 or 25, 1, -2),
                                BackgroundTransparency = 0.05,
                                Name = "AccentLine",
                            }),
                            "Accent"
                        ),
                        TopbarButtonHolder,
                        OrionLib:AddThemeObject(
                            SetChildren(
                                SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
                                    Size = UDim2.new(0, 70, 0, 30),
                                    BackgroundTransparency = typeof(WindowConfig.LinkVideo) == "string" and 0.2 or 0,
                                    Position = UDim2.new(1, -90, 0, 10),
                                }),
                                {
                                    OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                                    OrionLib:AddThemeObject(
                                        SetProps(MakeElement("Frame"), {
                                            Size = UDim2.new(0, 1, 1, 0),
                                            BackgroundTransparency = typeof(WindowConfig.LinkVideo) == "string" and 0.2 or 0,
                                            Position = UDim2.new(0.5, 0, 0, 0),
                                        }),
                                        "Stroke"
                                    ),
                                    CloseBtn,
                                    MinimizeBtn,
                                }
                            ),
                            "Second"
                        ),
                    }
                ),
                Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, GetThemeValue("Main", Color3.fromRGB(18, 20, 27))),
                        ColorSequenceKeypoint.new(1, GetThemeValue("Second", Color3.fromRGB(25, 28, 38))),
                    }),
                    Rotation = 90,
                }),
                DragPoint,
                SizeDrag,
                WindowStuff,
            }
        ),
        "Main"
    )

    if WindowConfig.Glass then
        ApplyLiquidGlass(
            MainWindow,
            MergeLiquidGlassConfig(WindowConfig.GlassConfig, {
                Shadow = WindowConfig.GlassConfig.Shadow ~= false,
                ShadowTransparency = WindowConfig.GlassConfig.ShadowTransparency or 0.72,
                ShadowBlur = WindowConfig.GlassConfig.ShadowBlur or 24,
                Radius = WindowConfig.GlassConfig.Radius or (OrionLib.Style.WindowRadius or 14),
            })
        )
        ApplyLiquidGlass(WindowStuff, {
            Color = WindowConfig.GlassConfig.NavColor or WindowConfig.GlassConfig.Color or GetThemeValue("Second", Color3.fromRGB(25, 28, 38)),
            Accent = WindowConfig.GlassConfig.Accent,
            BackgroundTransparency = WindowConfig.GlassConfig.NavTransparency or 0.46,
            Radius = WindowConfig.TopbarTabs and 14 or (OrionLib.Style.WindowRadius or 12),
            StrokeTransparency = WindowConfig.GlassConfig.NavStrokeTransparency or 0.8,
            HighlightTransparency = 0.92,
            Shadow = false,
        })
    end

    MakeResizable(MainWindow, SizeDrag, function()
        local size = MainWindow.AbsoluteSize
        Window.Size = UDim2.fromOffset(size.X, size.Y)
    end)

    if WindowConfig.SearchBar and WindowConfig.SearchBar.Mains == true then
        local SearchBox = Create("TextBox", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            PlaceholderColor3 = Color3.fromRGB(210, 210, 210),
            PlaceholderText = WindowConfig.SearchBar.DefaultMain or "🔍 Search",
            Font = Enum.Font.GothamBold,
            TextWrapped = true,
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Center,
            TextSize = 14,
            ClearTextOnFocus = WindowConfig.SearchBar.ClearTextOnFocus ~= false,
        })

        local TextboxActual = OrionLib:AddThemeObject(SearchBox, "Text")
        local SearchBar = OrionLib:AddThemeObject(
            SetChildren(
                SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 1, 6), {
                    Parent = WindowStuff,
                    Size = UDim2.new(1, -30, 0, 28),
                    Position = UDim2.new(0.5, 0, 0, 10),
                    BackgroundTransparency = typeof(WindowConfig.LinkVideo) == "string" and 0.5 or 0,
                    AnchorPoint = Vector2.new(0.5, 0),
                }),
                {
                    OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    TextboxActual,
                }
            ),
            "Main"
        )

        local function GetSearchableText(object)
            local parts = { object.Name or "" }
            for _, descendant in ipairs(object:GetDescendants()) do
                if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                    table.insert(parts, descendant.Text or "")
                end
            end
            return string.lower(table.concat(parts, " "))
        end

        local function SearchHandleMain()
            local Text = string.lower(SearchBox.Text or "")
            for _, v in pairs(MainWindow:GetChildren()) do
                if v.Name == "ItemContainer" and v.Visible == true then
                    for _, j in pairs(v:GetChildren()) do
                        if j:IsA("GuiObject") and not j:IsA("UIListLayout") and not j:IsA("UIPadding") then
                            j.Visible = Text == "" or string.find(GetSearchableText(j), Text, 1, true) ~= nil
                        end
                    end
                end
            end
        end
        AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), SearchHandleMain)
    end

    if WindowConfig.ShowIcon then
        WindowConfig.Icon = ResolveImageLikeAsset(WindowConfig.Icon)
        WindowName.Position = UDim2.new(0, 50, 0, -24)
        local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 25, 0, 15),
        })
        WindowIcon.Parent = MainWindow.TopBar
    end

    MakeDraggable(MainWindow, DragPoint)
    local isMobile = table.find({ Enum.Platform.IOS, Enum.Platform.Android }, UserInputService:GetPlatform())
    local MobileReopenButton = SetChildren(
        SetProps(MakeElement("Button"), {
            Parent = Orion,
            Size = UDim2.new(0, 40, 0, 40),
            Position = UDim2.new(0.5, -20, 0, 20),
            BackgroundTransparency = 0,
            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
            Visible = false,
        }),
        {
            OrionLib:AddThemeObject(
                SetProps(MakeElement("Image", WindowConfig.IntroToggleIcon or "panel-top-open"), {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0.7, 0, 0.7, 0),
                }),
                "Text"
            ),
            MakeElement("Corner", 1),
        }
    )

    MakeDraggable(MobileReopenButton, MobileReopenButton)

    local function GetCollapsedSize()
        return UDim2.new(0, math.max(WindowName.TextBounds.X + 140, 220), 0, 50)
    end

    local function SetWindowMinimized(state, fromKeybind)
        if state then
            MainWindow.ClipsDescendants = true
            MainWindow.SizeDragging.Visible = false
            WindowTopBarLine.Visible = false
            TopbarButtonHolder.Visible = false
            ApplyIconToObject(MinimizeBtn.Ico, "maximize-2", 32)
            local tween = TweenService:Create(MainWindow, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = GetCollapsedSize() })
            tween:Play()
            task.delay(0.08, function()
                if MainWindow and MainWindow.Parent then
                    WindowStuff.Visible = false
                end
            end)
        else
            MainWindow.Visible = true
            MobileReopenButton.Visible = false
            WindowStuff.Visible = true
            WindowTopBarLine.Visible = true
            TopbarButtonHolder.Visible = true
            MainWindow.SizeDragging.Visible = true
            ApplyIconToObject(MinimizeBtn.Ico, "minus", 32)
            local tween = TweenService:Create(MainWindow, TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Window.Size })
            tween:Play()
            tween.Completed:Connect(function()
                if MainWindow and MainWindow.Parent then
                    MainWindow.ClipsDescendants = false
                end
            end)
        end
        Minimized = state
        MinimizedKey = state
    end

    AddConnection(MobileReopenButton.MouseButton1Click, function()
        SetWindowMinimized(false)
    end)

    AddConnection(CloseBtn.MouseButton1Up, function()
        MainWindow.ClipsDescendants = true
        MainWindow.SizeDragging.Visible = false
        local WindowLoading = TweenService:Create(MainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
        })
        WindowLoading:Play()
        WindowLoading.Completed:Wait()
        MainWindow.Visible = false
        UIHidden = true

        if UserInputService.TouchEnabled then
            MobileReopenButton.Visible = true
        end
        OrionLib:MakeNotification({
            Name = "Hide Gui",
            Content = (isMobile and "tap the floating icon to reopen" or "Press Key " .. _currentKey.Name) .. " to reopen gui",
            Time = 5,
        })
        OrionLib:SafeScript(WindowConfig.CloseCallback)
    end)

    AddConnection(UserInputService.InputBegan, function(Input, gameProcessed)
        if gameProcessed then
            return
        end
        if Input.KeyCode == _currentKey then
            MobileReopenButton.Visible = false
            SetWindowMinimized(not MinimizedKey, true)
        end
    end)

    AddConnection(MinimizeBtn.MouseButton1Up, function()
        SetWindowMinimized(not Minimized)
    end)

    local function LoadSequence()
        MainWindow.Size = UDim2.new(0, 0, 0, 0)
        MainWindow.Visible = false
        local Blur = Create("BlurEffect", {
            Name = "IntroBlur",
            Size = 0,
            Parent = game:GetService("Lighting"),
        })

        local BaseFrame = SetProps(MakeElement("Frame"), {
            Parent = Orion,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 999,
        })

        local LoadSequenceLogo = SetChildren(
            SetProps(MakeElement("Image", ResolveImageLikeAsset(WindowConfig.IntroIcon)), {
                Parent = BaseFrame,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.4, 0),
                Size = UDim2.new(0, 0, 0, 0),
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                ImageTransparency = 1,
                Rotation = -180,
                ZIndex = 101,
            }),
            { MakeElement("Corner", 0, 5) }
        )

        local LoadSequenceGlow = SetProps(MakeElement("Image", "rbxassetid://7072706859"), {
            Parent = BaseFrame,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.45, 0),
            Size = UDim2.new(0, 0, 0, 0),
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 1,
            ZIndex = 100,
        })

        local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 22), {
            Parent = BaseFrame,
            Size = UDim2.new(0, 400, 0, 40),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.55, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.GothamBlack,
            TextTransparency = 1,
            ZIndex = 101,
        })

        TweenService:Create(Blur, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = 18 }):Play()
        task.wait(0.2)
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0.2), {
            Size = UDim2.new(0, 56, 0, 56),
            ImageTransparency = 0,
            Rotation = 0,
        }):Play()
        TweenService:Create(LoadSequenceGlow, TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0.2), {
            Size = UDim2.new(0, 140, 0, 140),
            ImageTransparency = 0.6,
        }):Play()
        task.wait(0.3)
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextTransparency = 0,
            Position = UDim2.new(0.5, 0, 0.52, 0),
        }):Play()
        task.wait(2)
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.55, 0),
        }):Play()
        task.wait(0.1)
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Rotation = 56,
        }):Play()
        TweenService:Create(LoadSequenceGlow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
        }):Play()
        local BlurTween = TweenService:Create(Blur, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 0 })
        BlurTween:Play()
        BlurTween.Completed:Wait()
        wait(0.15)
        MainWindow.Visible = true
        Blur:Destroy()
        BaseFrame:Destroy()
        TweenService:Create(MainWindow, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = Window.Size,
        }):Play()
    end

    if WindowConfig.IntroEnabled then
        LoadSequence()
    end

    if typeof(WindowConfig.LinkVideo) == "string" then
        OrionLib:SetVideoLink(WindowConfig.LinkVideo)
    end

    local Functions = {}
    local TabName = {}
    local AllTabs = {}
    function Functions:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig = TranslateConfig(TabConfig)
        TabConfig.Name = TabConfig.Name or TabConfig.Title or "Tab"
        TabConfig.Icon = ResolveIcon(TabConfig.Icon or "")
        TabConfig.Visible = TabConfig.Visible ~= false
        TabConfig.Disabled = TabConfig.Disabled == true
        TabConfig.IconOnly = WindowConfig.SidebarCompact or TabConfig.IconOnly == true
        local TabParent = TabConfig._Parent or TabHolder
        local TabIndent = tonumber(TabConfig._Indent or 0) or 0
        local TabWidthOffset = tonumber(TabConfig._WidthOffset or 0) or 0
        local topbarTabWidth = math.clamp((#tostring(TabConfig.Name) * 8) + (TabConfig.Icon and 46 or 24), 82, 168)

        local Tabs = {
            Disabled = TabConfig.Disabled,
            Visible = TabConfig.Visible,
            Type = "Tabs",
            Name = TabConfig.Name,
            Group = TabConfig._Group,
        }

        local TabFrame = SetChildren(
            SetProps(MakeElement("Button"), {
                Size = WindowConfig.TopbarTabs and UDim2.fromOffset(topbarTabWidth, 30) or UDim2.new(1, -TabWidthOffset, 0, 30),
                Parent = TabParent,
                Visible = TabConfig.Visible,
                AutoButtonColor = not TabConfig.Disabled,
                Name = TabConfig.Name,
            }),
            {
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Frame"), {
                        Size = WindowConfig.TopbarTabs and UDim2.new(0, 0, 0, 3) or UDim2.new(0, 3, 0, 0),
                        AnchorPoint = WindowConfig.TopbarTabs and Vector2.new(0.5, 1) or Vector2.new(0, 0.5),
                        Position = WindowConfig.TopbarTabs and UDim2.new(0.5, 0, 1, -2) or UDim2.new(0, 0, 0.5, 0),
                        BackgroundTransparency = 1,
                        Name = "Highlight",
                    }),
                    "Text"
                ),
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Image", TabConfig.Icon), {
                        AnchorPoint = TabConfig.IconOnly and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5),
                        Size = UDim2.new(0, TabConfig.IconOnly and 22 or 18, 0, TabConfig.IconOnly and 22 or 18),
                        Position = TabConfig.IconOnly and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, WindowConfig.TopbarTabs and 12 or 10 + TabIndent, 0.5, 0),
                        ImageTransparency = TabConfig.Disabled and 0.7 or 0.4,
                        Name = "Ico",
                    }),
                    "Text"
                ),
                OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("Label", TabConfig.Name, 14), {
                            Size = UDim2.new(1, -(35 + TabIndent), 1, 0),
                            Position = UDim2.new(0, WindowConfig.TopbarTabs and 38 or 35 + TabIndent, 0, 0),
                            Font = Enum.Font.GothamSemibold,
                            Visible = not TabConfig.IconOnly,
                            TextTransparency = TabConfig.Disabled and 0.7 or 0.4,
                            Name = "Title",
                        }),
                        { OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke") }
                    ),
                    "Text"
                ),
            }
        )
        TabFrame:SetAttribute("OrionTabButton", true)
        TabFrame:SetAttribute("IconOnly", TabConfig.IconOnly == true)
        if WindowConfig.TopbarTabs and WindowConfig.Glass then
            ApplyLiquidGlass(TabFrame, {
                Color = GetThemeValue("Second", Color3.fromRGB(25, 28, 38)),
                Accent = GetThemeValue("Accent", Color3.fromRGB(96, 165, 250)),
                BackgroundTransparency = 0.54,
                Radius = 12,
                Decorations = false,
                StrokeTransparency = 0.78,
                HighlightTransparency = 0.94,
                Shadow = false,
            })
        end

        AddItemTable(Tabs, TabConfig.Name, TabFrame)
        table.insert(AllTabs, Tabs)
        TabName[TabConfig.Name] = Tabs
        local TabBadge

        local Container = OrionLib:AddThemeObject(
            SetChildren(
                SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), {
                    Size = WindowConfig.TopbarTabs and UDim2.new(1, 0, 1, -92)
                        or UDim2.new(1, -WindowConfig.SidebarWidth, 1, (WindowConfig.SearchBar and WindowConfig.SearchBar.Mains == true) and -90 or -50),
                    Position = WindowConfig.TopbarTabs and UDim2.new(0, 0, 0, 92)
                        or UDim2.new(0, WindowConfig.SidebarWidth, 0, (WindowConfig.SearchBar and WindowConfig.SearchBar.Mains == true) and 90 or 50),
                    Parent = MainWindow,
                    Visible = false,
                    Name = "ItemContainer",
                    ZIndex = 4,
                }),
                {
                    MakeElement("List", 0, 6),
                    MakeElement("Padding", 15, 10, 10, (WindowConfig.SearchBar and WindowConfig.SearchBar.Mains == true) and 10 or 15),
                }
            ),
            "Divider"
        )
        Container:SetAttribute("OrionTabContainer", true)
        if WindowConfig.Glass then
            ApplyLiquidGlass(Container, {
                Color = WindowConfig.GlassConfig.PageColor or WindowConfig.GlassConfig.Color or GetThemeValue("Main", Color3.fromRGB(18, 20, 27)),
                Accent = WindowConfig.GlassConfig.Accent,
                BackgroundTransparency = WindowConfig.GlassConfig.PageTransparency or 0.5,
                Radius = WindowConfig.GlassConfig.PageRadius or 12,
                Decorations = false,
                StrokeTransparency = WindowConfig.GlassConfig.PageStrokeTransparency or 0.84,
                HighlightTransparency = 0.94,
                Shadow = false,
            })
        end
        Tabs.Button = TabFrame
        Tabs.Container = Container
        SetMinimumZIndex(Container, 4)
        AddConnection(Container.DescendantAdded, function(Descendant)
            if Descendant:IsA("GuiObject") then
                Descendant.ZIndex = math.max(Descendant.ZIndex, 4)
            end
        end)

        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(
                0,
                0,
                0,
                Container.UIListLayout.AbsoluteContentSize.Y + ((WindowConfig.SearchBar and WindowConfig.SearchBar.Mains == true) and 25 or 30)
            )
        end)

        local function SelectTab()
            if Tabs.Disabled then
                return
            end
            for _, Tab in next, TabHolder:GetDescendants() do
                if Tab:IsA("TextButton") and Tab:GetAttribute("OrionTabButton") and Tab:FindFirstChild("Ico") then
                    local iconOnly = Tab:GetAttribute("IconOnly") == true
                    local size = iconOnly and 22 or 18
                    TweenService:Create(
                        Tab.Ico,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { ImageTransparency = 0.4, Size = UDim2.new(0, size, 0, size) }
                    ):Play()
                    if Tab:FindFirstChild("Title") then
                        TweenService:Create(Tab.Title, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0.4 }):Play()
                    end
                    if Tab:FindFirstChild("Highlight") then
                        TweenService
                            :Create(
                                Tab.Highlight,
                                TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                                { Size = WindowConfig.TopbarTabs and UDim2.new(0, 0, 0, 3) or UDim2.new(0, 3, 0, 0), BackgroundTransparency = 1 }
                            )
                            :Play()
                    end
                end
            end
            for _, c in next, MainWindow:GetChildren() do
                if c.Name == "ItemContainer" then
                    c.Visible = false
                end
            end
            for _, tab in ipairs(AllTabs) do
                tab.Selected = false
            end
            Tabs.Selected = true
            Window.SelectedTab = Tabs
            Functions.SelectedTab = Tabs
            Container.Parent = MainWindow
            SetMinimumZIndex(Container, 4)
            TweenService:Create(
                TabFrame.Ico,
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { ImageTransparency = 0, Size = UDim2.new(0, TabConfig.IconOnly and 26 or 20, 0, TabConfig.IconOnly and 26 or 20) }
            ):Play()
            if TabFrame:FindFirstChild("Title") then
                TweenService:Create(TabFrame.Title, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
            end
            if TabFrame:FindFirstChild("Highlight") then
                TweenService:Create(
                    TabFrame.Highlight,
                    TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                    { Size = WindowConfig.TopbarTabs and UDim2.new(1, -18, 0, 3) or UDim2.new(0, 3, 0, 22), BackgroundTransparency = 0 }
                ):Play()
            end
            Container.Visible = true
        end

        AddConnection(TabFrame.MouseButton1Click, SelectTab)
        if FirstTab and TabConfig.Visible and not TabConfig.Disabled then
            FirstTab = false
            Container.Visible = true
            task.defer(function()
                if Container and Container.Parent then
                    SelectTab()
                end
            end)
        end

        function Tabs:SetDisabled(state)
            Tabs.Disabled = state
            TabFrame.AutoButtonColor = not state
            TabFrame.Ico.ImageTransparency = state and 0.7 or 0.4
            if TabFrame:FindFirstChild("Title") then
                TabFrame.Title.TextTransparency = state and 0.7 or 0.4
            end
            if state and TabFrame:FindFirstChild("Highlight") then
                TabFrame.Highlight.Size = WindowConfig.TopbarTabs and UDim2.new(0, 0, 0, 3) or UDim2.new(0, 3, 0, 0)
                TabFrame.Highlight.BackgroundTransparency = 1
            end
            if state then
                Container.Visible = false
                Tabs.Selected = false
                if Functions.SelectedTab == Tabs then
                    Functions.SelectedTab = nil
                    for _, tab in ipairs(AllTabs) do
                        if tab ~= Tabs and tab.Visible and not tab.Disabled and type(tab.Select) == "function" then
                            tab:Select()
                            break
                        end
                    end
                end
            end
        end

        function Tabs:SetVisible(state)
            Tabs.Visible = state
            TabFrame.Visible = state
            if not state then
                Container.Visible = false
                Tabs.Selected = false
                if Functions.SelectedTab == Tabs then
                    Functions.SelectedTab = nil
                    for _, tab in ipairs(AllTabs) do
                        if tab ~= Tabs and tab.Visible and not tab.Disabled and type(tab.Select) == "function" then
                            tab:Select()
                            break
                        end
                    end
                end
            elseif not Functions.SelectedTab and not Tabs.Disabled then
                SelectTab()
            end
        end

        function Tabs:Select()
            SelectTab()
        end

        function Tabs:SetTitle(title)
            if getgenv().Destroy then
                return
            end
            if TabName[Tabs.Name] == Tabs then
                TabName[Tabs.Name] = nil
            end
            Tabs.Name = tostring(title or Tabs.Name)
            TabFrame.Name = Tabs.Name
            TabName[Tabs.Name] = Tabs
            if TabFrame:FindFirstChild("Title") then
                TabFrame.Title.Text = Tabs.Name
            end
        end

        function Tabs:SetIcon(icon)
            if getgenv().Destroy then
                return
            end
            TabConfig.Icon = ResolveIcon(icon or TabConfig.Icon)
            if TabFrame:FindFirstChild("Ico") then
                ApplyIconToObject(TabFrame.Ico, TabConfig.Icon, TabConfig.IconOnly and 48 or 32)
            end
        end

        function Tabs:SetBadge(value, color)
            if getgenv().Destroy then
                return
            end
            if value == nil or value == false or tostring(value) == "" then
                if TabBadge then
                    TabBadge:Destroy()
                    TabBadge = nil
                end
                return
            end
            local text = tostring(value)
            if not TabBadge then
                TabBadge = SetChildren(
                    SetProps(MakeElement("RoundFrame", color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250)), 1, 0), {
                        Size = TabConfig.IconOnly and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 20, 0, 16),
                        Position = TabConfig.IconOnly and UDim2.new(1, -12, 0, 7) or UDim2.new(1, -30, 0.5, -8),
                        BackgroundColor3 = color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250)),
                        Parent = TabFrame,
                        Name = "Badge",
                    }),
                    {
                        SetProps(MakeElement("Label", "", 10), {
                            Size = UDim2.new(1, 0, 1, 0),
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            Visible = not TabConfig.IconOnly,
                            Name = "Value",
                        }),
                    }
                )
            end
            TabBadge.BackgroundColor3 = color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250))
            if TabBadge:FindFirstChild("Value") then
                TabBadge.Value.Text = text
                TabBadge.Size = TabConfig.IconOnly and UDim2.new(0, 8, 0, 8) or UDim2.new(0, math.max(20, TabBadge.Value.TextBounds.X + 10), 0, 16)
            end
        end

        local function GetElements(ItemParent)
            local ElementFunction = {}
            function ElementFunction:AddDivider(DividerConfig)
                DividerConfig = DividerConfig or {}
                DividerConfig.Text = DividerConfig.Text or DividerConfig.Title or DividerConfig.Name
                local HasText = type(DividerConfig.Text) == "string" and DividerConfig.Text ~= ""

                local DividerFrame = SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = ItemParent,
                    BackgroundTransparency = 1,
                })

                if HasText then
                    local Label = OrionLib:AddThemeObject(
                        SetProps(MakeElement("Label", DividerConfig.Text, 14), {
                            Size = UDim2.new(0, 0, 1, 0),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Parent = DividerFrame,
                            Font = Enum.Font.GothamBold,
                            AutomaticSize = Enum.AutomaticSize.X,
                        }),
                        "Text"
                    )

                    local LeftLine = SetChildren(
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Frame"), {
                                Size = UDim2.new(0.5, -10, 0, 1),
                                Position = UDim2.new(0, 0, 0.5, 0),
                                AnchorPoint = Vector2.new(0, 0.5),
                                Parent = DividerFrame,
                            }),
                            "Divider"
                        ),
                        {
                            Create("UIGradient", {
                                Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
                                Rotation = 180,
                            }),
                        }
                    )

                    local RightLine = SetChildren(
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Frame"), {
                                Size = UDim2.new(0.5, -10, 0, 1),
                                Position = UDim2.new(1, 0, 0.5, 0),
                                AnchorPoint = Vector2.new(1, 0.5),
                                Parent = DividerFrame,
                            }),
                            "Divider"
                        ),
                        {
                            Create("UIGradient", {
                                Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
                                Rotation = 180,
                            }),
                        }
                    )

                    AddConnection(Label:GetPropertyChangedSignal("AbsoluteSize"), function()
                        local TextSize = Label.AbsoluteSize.X + 20
                        LeftLine.Size = UDim2.new(0.5, -(TextSize / 2), 0, 1)
                        RightLine.Size = UDim2.new(0.5, -(TextSize / 2), 0, 1)
                    end)
                else
                    local Line = SetChildren(
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Frame"), {
                                Size = UDim2.new(1, 0, 0, 1),
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Parent = DividerFrame,
                            }),
                            "Divider"
                        ),
                        {
                            Create("UIGradient", {
                                Transparency = NumberSequence.new({
                                    NumberSequenceKeypoint.new(0, 1),
                                    NumberSequenceKeypoint.new(0.2, 0),
                                    NumberSequenceKeypoint.new(0.8, 0),
                                    NumberSequenceKeypoint.new(1, 1),
                                }),
                            }),
                        }
                    )
                end

                local DividerFunction = {}
                function DividerFunction:Set(NewText)
                    if getgenv().Destroy then
                        return
                    end
                    local label = DividerFrame:FindFirstChildOfClass("TextLabel")
                    if label then
                        label.Text = tostring(NewText or "")
                    end
                end
                return DividerFunction
            end
            function ElementFunction:AddLog(Text)
                local Label = MakeElement("Label", Text, 15)
                local LogFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 0.7,
                            Parent = ItemParent,
                        }),
                        {
                            OrionLib:AddThemeObject(
                                SetProps(Label, {
                                    Size = UDim2.new(1, -12, 1, 0),
                                    Position = UDim2.new(0, 12, 0, 0),
                                    TextXAlignment = Enum.TextXAlignment.Center,
                                    TextSize = 19,
                                    TextWrapped = true,
                                    Font = Enum.Font.GothamBold,
                                    Name = "Content",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        }
                    ),
                    "Second"
                )
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Frame"), {
                        Name = "Accent",
                        Size = UDim2.new(0, 4, 1, -20),
                        Position = UDim2.new(0, 0, 0, 10),
                        Parent = Card,
                        ZIndex = 4,
                    }),
                    "Accent"
                )

                local LogFunction = {}
                function LogFunction:Set(ToChange)
                    LogFrame.Content.Text = ToChange
                end
                return LogFunction
            end
            function ElementFunction:AddLabel(Text, Log)
                Log = Log or {}
                local DefaultBackground = OrionLib.Themes[OrionLib.SelectedTheme].Second
                local LabelFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(1, 0, 0, 30),
                            Parent = ItemParent,
                            BackgroundColor3 = DefaultBackground,
                        }),
                        {
                            Create("ImageLabel", {
                                Name = "Icon",
                                Size = UDim2.new(0, 18, 0, 18),
                                Position = UDim2.new(0, 8, 0.5, -9),
                                BackgroundTransparency = 1,
                                Image = "",
                                Visible = false,
                            }),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", Text, 15), {
                                    Size = UDim2.new(1, -12, 1, 0),
                                    Position = UDim2.new(0, 8, 0, 0),
                                    Font = Enum.Font.GothamBold,
                                    TextWrapped = true,
                                    Name = "Content",
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        }
                    ),
                    "Second"
                )

                AddConnection(LabelFrame.Content:GetPropertyChangedSignal("Text"), function()
                    if LabelFrame then
                        LabelFrame.Size = UDim2.new(1, 0, 0, LabelFrame.Content.TextBounds.Y + 25)
                    end
                end)

                local Icons = {
                    success = "circle-check",
                    error = "circle-x",
                    warning = "triangle-alert",
                    fail = "circle-x",
                }

                local StateColors = {
                    success = Color3.fromRGB(0, 120, 60),
                    error = Color3.fromRGB(150, 40, 40),
                    warning = Color3.fromRGB(150, 110, 0),
                    fail = Color3.fromRGB(120, 0, 0),
                }

                local function ResetState()
                    Log.Error = nil
                    Log.Warning = nil
                    Log.Success = nil
                    Log.Fail = nil

                    if LabelFrame and LabelFrame:FindFirstChild("UIStroke") then
                        LabelFrame:FindFirstChild("UIStroke"):Destroy()
                    end
                    LabelFrame.Icon.Visible = false
                    LabelFrame.Icon.Image = ""
                    LabelFrame.BackgroundTransparency = 0
                    LabelFrame.Content.Size = UDim2.new(1, -12, 1, 0)
                    LabelFrame.Content.Position = UDim2.new(0, 8, 0, 0)
                    LabelFrame.BackgroundColor3 = DefaultBackground
                end

                local LabelFunction = {}
                function LabelFunction:Set(ToChange, State)
                    if getgenv().Destroy then
                        return
                    end
                    if not LabelFrame then
                        return
                    end
                    ResetState()
                    LabelFrame.Content.Text = ToChange
                    if State then
                        State = string.lower(State)
                        if Icons[State] then
                            LabelFrame.Content.Size = UDim2.new(1, -36, 1, 0)
                            LabelFrame.Content.Position = UDim2.new(0, 30, 0, 0)
                            LabelFrame.Icon.Visible = true
                            LabelFrame.BackgroundTransparency = 0.6
                            ApplyIconToObject(LabelFrame.Icon, Icons[State], 48)
                            local Stroke = Create("UIStroke", {
                                Color = StateColors[State],
                                Thickness = 1.6,
                                Parent = LabelFrame,
                            })
                        end
                        if StateColors[State] then
                            LabelFrame.BackgroundColor3 = StateColors[State]
                        end
                        Log[State:sub(1, 1):upper() .. State:sub(2)] = true
                    end
                end
                return LabelFunction
            end
            function ElementFunction:AddParagraph(Text, Content)
                Text = Text or "Text"
                Content = Content or "Content"

                local ParagraphFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(1, 0, 0, 30),
                            BackgroundTransparency = 0.7,
                            Parent = ItemParent,
                        }),
                        {
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", Text, 15), {
                                    Size = UDim2.new(1, -12, 0, 14),
                                    Position = UDim2.new(0, 12, 0, 10),
                                    Font = Enum.Font.GothamBold,
                                    Name = "Title",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", "", 13), {
                                    Size = UDim2.new(1, -24, 0, 0),
                                    Position = UDim2.new(0, 12, 0, 26),
                                    Font = Enum.Font.GothamSemibold,
                                    Name = "Content",
                                    TextWrapped = true,
                                }),
                                "TextDark"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        }
                    ),
                    "Second"
                )

                AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
                    ParagraphFrame.Content.Size = UDim2.new(1, -24, 0, ParagraphFrame.Content.TextBounds.Y)
                    ParagraphFrame.Size = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 35)
                end)

                ParagraphFrame.Content.Text = Content

                local ParagraphFunction = {}
                function ParagraphFunction:Set(ToChange)
                    if getgenv().Destroy then
                        return
                    end
                    if ParagraphFrame and ParagraphFrame:FindFirstChild("Content") then
                        ParagraphFrame.Content.Text = ToChange
                    end
                end
                return ParagraphFunction
            end
            function ElementFunction:AddWarningBox(WarningConfig)
                WarningConfig = TranslateConfig(WarningConfig or {})
                WarningConfig.Title = WarningConfig.Title or WarningConfig.Name or "Warning"
                WarningConfig.Content = WarningConfig.Content or WarningConfig.Desc or WarningConfig.Description or ""
                WarningConfig.Icon = ResolveIcon(WarningConfig.Icon or "triangle-alert")
                WarningConfig.Color = WarningConfig.Color or Color3.fromRGB(255, 190, 80)
                WarningConfig.Visible = WarningConfig.Visible ~= false
                local Warning = { Type = "WarningBox", Visible = WarningConfig.Visible }

                local WarningFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6), {
                            Size = UDim2.new(1, 0, 0, 58),
                            Parent = ItemParent,
                            Visible = WarningConfig.Visible,
                            BackgroundTransparency = 0.2,
                        }),
                        {
                            SetProps(MakeElement("Frame"), {
                                Name = "Accent",
                                Size = UDim2.new(0, 4, 1, -12),
                                Position = UDim2.new(0, 8, 0, 6),
                                BackgroundColor3 = WarningConfig.Color,
                            }),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Image", WarningConfig.Icon), {
                                    Size = UDim2.new(0, 18, 0, 18),
                                    Position = UDim2.new(0, 20, 0, 12),
                                    ImageColor3 = WarningConfig.Color,
                                    Name = "Icon",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", WarningConfig.Title, 14), {
                                    Size = UDim2.new(1, -54, 0, 18),
                                    Position = UDim2.new(0, 44, 0, 9),
                                    Font = Enum.Font.GothamBold,
                                    Name = "Title",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", WarningConfig.Content, 12), {
                                    Size = UDim2.new(1, -54, 0, 20),
                                    Position = UDim2.new(0, 44, 0, 29),
                                    Font = Enum.Font.GothamSemibold,
                                    TextWrapped = true,
                                    Name = "Content",
                                }),
                                "TextDark"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        }
                    ),
                    "Second"
                )

                local function UpdateSize()
                    local content = WarningFrame:FindFirstChild("Content")
                    if content then
                        content.Size = UDim2.new(1, -54, 0, content.TextBounds.Y)
                        WarningFrame.Size = UDim2.new(1, 0, 0, math.max(58, content.TextBounds.Y + 40))
                    end
                end
                AddConnection(WarningFrame.Content:GetPropertyChangedSignal("Text"), UpdateSize)
                UpdateSize()

                function Warning:Set(title, content)
                    if WarningFrame and WarningFrame:FindFirstChild("Title") then
                        WarningFrame.Title.Text = title or WarningFrame.Title.Text
                    end
                    if WarningFrame and WarningFrame:FindFirstChild("Content") then
                        WarningFrame.Content.Text = content or WarningFrame.Content.Text
                    end
                    UpdateSize()
                end
                function Warning:SetVisible(state)
                    Warning.Visible = state == true
                    if WarningFrame then
                        WarningFrame.Visible = Warning.Visible
                    end
                end
                if WarningConfig.Flag then
                    OrionLib.Flags[WarningConfig.Flag] = Warning
                end
                return Warning
            end

            function ElementFunction:AddTabBox(TabBoxConfig)
                TabBoxConfig = TranslateConfig(TabBoxConfig or {})
                TabBoxConfig.Title = TabBoxConfig.Title or TabBoxConfig.Name or "Tab"
                TabBoxConfig.Description = TabBoxConfig.Description or TabBoxConfig.Desc or TabBoxConfig.Content or ""
                TabBoxConfig.Icon = ResolveIcon(TabBoxConfig.Icon or "info")
                TabBoxConfig.Color = TabBoxConfig.Color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250))
                TabBoxConfig.Visible = TabBoxConfig.Visible ~= false
                TabBoxConfig.RichText = TabBoxConfig.RichText ~= false
                local TabBox = { Type = "TabBox", Visible = TabBoxConfig.Visible }

                local TabBoxFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
                            Size = UDim2.new(1, 0, 0, 74),
                            Parent = ItemParent,
                            Visible = TabBoxConfig.Visible,
                            BackgroundTransparency = 0.14,
                            Name = "TabBox",
                        }),
                        {
                            Create("UIGradient", {
                                Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, ColorAdd(TabBoxConfig.Color, -30)),
                                    ColorSequenceKeypoint.new(1, GetThemeValue("Second", Color3.fromRGB(25, 28, 38))),
                                }),
                                Rotation = 12,
                                Transparency = NumberSequence.new({
                                    NumberSequenceKeypoint.new(0, 0.42),
                                    NumberSequenceKeypoint.new(1, 0.04),
                                }),
                            }),
                            SetProps(MakeElement("Frame", TabBoxConfig.Color), {
                                Size = UDim2.new(0, 4, 1, -16),
                                Position = UDim2.new(0, 10, 0, 8),
                                BackgroundColor3 = TabBoxConfig.Color,
                                Name = "Accent",
                            }),
                            SetChildren(
                                SetProps(MakeElement("RoundFrame", TabBoxConfig.Color, 0, 8), {
                                    Size = UDim2.fromOffset(36, 36),
                                    Position = UDim2.new(0, 24, 0, 14),
                                    BackgroundColor3 = TabBoxConfig.Color,
                                    BackgroundTransparency = 0.12,
                                    Name = "IconWrap",
                                }),
                                {
                                    OrionLib:AddThemeObject(
                                        SetProps(MakeElement("Image", TabBoxConfig.Icon), {
                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                            Position = UDim2.new(0.5, 0, 0.5, 0),
                                            Size = UDim2.fromOffset(20, 20),
                                            Name = "Icon",
                                        }),
                                        "Text"
                                    ),
                                }
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", TabBoxConfig.Title, 16), {
                                    Size = UDim2.new(1, -78, 0, 20),
                                    Position = UDim2.new(0, 70, 0, 12),
                                    Font = Enum.Font.GothamBold,
                                    Name = "Title",
                                    RichText = TabBoxConfig.RichText,
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", TabBoxConfig.Description, 12), {
                                    Size = UDim2.new(1, -82, 0, 20),
                                    Position = UDim2.new(0, 70, 0, 35),
                                    Font = Enum.Font.GothamSemibold,
                                    TextWrapped = true,
                                    TextTransparency = 0.08,
                                    Name = "Description",
                                    RichText = TabBoxConfig.RichText,
                                }),
                                "TextDark"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        }
                    ),
                    "Second"
                )
                TabBox.Frame = TabBoxFrame
                if TabBoxConfig.Glass or TabBoxConfig.LiquidGlass or WindowConfig.Glass then
                    TabBox.Glass = ApplyLiquidGlass(TabBoxFrame, TabBoxConfig.GlassConfig or {
                        Color = TabBoxConfig.GlassColor or GetThemeValue("Second", Color3.fromRGB(25, 28, 38)),
                        Accent = TabBoxConfig.Color,
                        BackgroundTransparency = 0.38,
                        Radius = 13,
                        StrokeTransparency = 0.8,
                        HighlightTransparency = 0.92,
                        Shadow = false,
                    })
                end

                local DescriptionLabel = TabBoxFrame:FindFirstChild("Description")
                local function UpdateSize()
                    if DescriptionLabel then
                        local Height = tostring(DescriptionLabel.Text or "") == "" and 0 or math.max(18, DescriptionLabel.TextBounds.Y)
                        DescriptionLabel.Visible = Height > 0
                        DescriptionLabel.Size = UDim2.new(1, -82, 0, Height)
                        TabBoxFrame.Size = UDim2.new(1, 0, 0, math.max(66, Height + 52))
                    end
                end

                AddConnection(DescriptionLabel:GetPropertyChangedSignal("TextBounds"), UpdateSize)
                task.defer(UpdateSize)

                function TabBox:Set(title, description)
                    if title ~= nil and TabBoxFrame:FindFirstChild("Title") then
                        TabBoxFrame.Title.Text = tostring(title)
                    end
                    if description ~= nil and DescriptionLabel then
                        DescriptionLabel.Text = tostring(description)
                    end
                    UpdateSize()
                end

                function TabBox:SetTitle(title)
                    TabBox:Set(title, nil)
                end

                function TabBox:SetDescription(description)
                    TabBox:Set(nil, description)
                end

                function TabBox:SetVisible(state)
                    TabBox.Visible = state == true
                    TabBoxFrame.Visible = TabBox.Visible
                end

                if TabBoxConfig.Flag then
                    OrionLib.Flags[TabBoxConfig.Flag] = TabBox
                end
                return TabBox
            end

            function ElementFunction:AddStatCard(StatConfig)
                StatConfig = TranslateConfig(StatConfig or {})
                StatConfig.Title = StatConfig.Title or StatConfig.Name or "Statistic"
                StatConfig.Description = StatConfig.Description or StatConfig.Desc or ""
                StatConfig.Value = StatConfig.Value or StatConfig.Default or "--"
                StatConfig.Icon = ResolveIcon(StatConfig.Icon or "activity")
                StatConfig.Color = StatConfig.Color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250))
                StatConfig.Visible = StatConfig.Visible ~= false
                StatConfig.Interval = tonumber(StatConfig.Interval or StatConfig.RefreshRate or 1) or 1
                StatConfig.Realtime = StatConfig.Realtime == true or type(StatConfig.Value) == "function"
                local Stat = { Type = "StatCard", Visible = StatConfig.Visible, Value = nil }

                local StatFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
                            Size = UDim2.new(1, 0, 0, 70),
                            Parent = ItemParent,
                            Visible = StatConfig.Visible,
                            BackgroundTransparency = 0.16,
                            Name = "StatCard",
                        }),
                        {
                            Create("UIGradient", {
                                Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, ColorAdd(StatConfig.Color, -24)),
                                    ColorSequenceKeypoint.new(1, GetThemeValue("Second", Color3.fromRGB(25, 28, 38))),
                                }),
                                Rotation = 0,
                                Transparency = NumberSequence.new({
                                    NumberSequenceKeypoint.new(0, 0.55),
                                    NumberSequenceKeypoint.new(1, 0.02),
                                }),
                            }),
                            SetChildren(
                                SetProps(MakeElement("RoundFrame", StatConfig.Color, 0, 8), {
                                    Size = UDim2.fromOffset(34, 34),
                                    Position = UDim2.new(0, 12, 0, 13),
                                    BackgroundColor3 = StatConfig.Color,
                                    BackgroundTransparency = 0.12,
                                    Name = "IconWrap",
                                }),
                                {
                                    OrionLib:AddThemeObject(
                                        SetProps(MakeElement("Image", StatConfig.Icon), {
                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                            Position = UDim2.new(0.5, 0, 0.5, 0),
                                            Size = UDim2.fromOffset(18, 18),
                                            Name = "Icon",
                                        }),
                                        "Text"
                                    ),
                                }
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", StatConfig.Title, 13), {
                                    Size = UDim2.new(1, -60, 0, 16),
                                    Position = UDim2.new(0, 56, 0, 10),
                                    Font = Enum.Font.GothamBold,
                                    Name = "Title",
                                }),
                                "TextDark"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", "", 21), {
                                    Size = UDim2.new(1, -62, 0, 26),
                                    Position = UDim2.new(0, 56, 0, 26),
                                    Font = Enum.Font.GothamBlack,
                                    Name = "Value",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", StatConfig.Description, 11), {
                                    Size = UDim2.new(1, -62, 0, 14),
                                    Position = UDim2.new(0, 56, 0, 51),
                                    Font = Enum.Font.GothamSemibold,
                                    TextTransparency = 0.12,
                                    Name = "Description",
                                }),
                                "TextDark"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        }
                    ),
                    "Second"
                )

                function Stat:Set(value, description)
                    Stat.Value = value
                    if StatFrame and StatFrame:FindFirstChild("Value") then
                        StatFrame.Value.Text = tostring(value)
                    end
                    if description ~= nil and StatFrame and StatFrame:FindFirstChild("Description") then
                        StatFrame.Description.Text = tostring(description)
                    end
                end

                function Stat:SetValue(value)
                    Stat:Set(value)
                end

                function Stat:Refresh()
                    local value = StatConfig.Value
                    if type(value) == "function" then
                        value = OrionLib:SafeScript(value, Stat)
                    end
                    Stat:Set(value == nil and "--" or value)
                end

                function Stat:SetVisible(state)
                    Stat.Visible = state == true
                    StatFrame.Visible = Stat.Visible
                end

                Stat:Refresh()
                if StatConfig.Realtime then
                    task.spawn(function()
                        while StatFrame and StatFrame.Parent and not getgenv().Destroy do
                            task.wait(math.max(0.15, StatConfig.Interval))
                            Stat:Refresh()
                        end
                    end)
                end

                if StatConfig.Flag then
                    OrionLib.Flags[StatConfig.Flag] = Stat
                end
                return Stat
            end

            function ElementFunction:AddTabCard(CardConfig)
                CardConfig = TranslateConfig(CardConfig or {})
                CardConfig.Title = CardConfig.Title or CardConfig.Name or CardConfig.TabTitle or "Tab Card"
                CardConfig.Description = CardConfig.Description or CardConfig.Desc or CardConfig.Content or "Open this tab"
                CardConfig.Icon = ResolveIcon(CardConfig.Icon or CardConfig.TabIcon or "layout-dashboard")
                CardConfig.Color = CardConfig.Color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250))
                CardConfig.Visible = CardConfig.Visible ~= false
                CardConfig.RichText = CardConfig.RichText ~= false
                local Card = { Type = "TabCard", Visible = CardConfig.Visible, TargetTab = nil, TargetElements = nil }

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    AutoButtonColor = false,
                    Name = "Click",
                })

                local CardFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
                            Size = UDim2.new(1, 0, 0, 86),
                            Parent = ItemParent,
                            Visible = CardConfig.Visible,
                            BackgroundTransparency = 0.1,
                            ClipsDescendants = true,
                            Name = "TabCard",
                        }),
                        {
                            Create("UIGradient", {
                                Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, ColorAdd(CardConfig.Color, -30)),
                                    ColorSequenceKeypoint.new(0.45, GetThemeValue("Second", Color3.fromRGB(25, 28, 38))),
                                    ColorSequenceKeypoint.new(1, GetThemeValue("Main", Color3.fromRGB(18, 20, 27))),
                                }),
                                Rotation = 18,
                                Transparency = NumberSequence.new({
                                    NumberSequenceKeypoint.new(0, 0.28),
                                    NumberSequenceKeypoint.new(1, 0.02),
                                }),
                            }),
                            SetProps(MakeElement("Frame", CardConfig.Color), {
                                Size = UDim2.new(0, 5, 1, -14),
                                Position = UDim2.new(0, 10, 0, 7),
                                BackgroundColor3 = CardConfig.Color,
                                Name = "Accent",
                            }),
                            SetChildren(
                                SetProps(MakeElement("RoundFrame", CardConfig.Color, 0, 10), {
                                    Size = UDim2.fromOffset(42, 42),
                                    Position = UDim2.new(0, 25, 0, 17),
                                    BackgroundColor3 = CardConfig.Color,
                                    BackgroundTransparency = 0.1,
                                    Name = "IconWrap",
                                }),
                                {
                                    OrionLib:AddThemeObject(
                                        SetProps(MakeElement("Image", CardConfig.Icon), {
                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                            Position = UDim2.new(0.5, 0, 0.5, 0),
                                            Size = UDim2.fromOffset(22, 22),
                                            Name = "Icon",
                                        }),
                                        "Text"
                                    ),
                                }
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", CardConfig.Title, 15), {
                                    Size = UDim2.new(1, -120, 0, 20),
                                    Position = UDim2.new(0, 80, 0, 16),
                                    Font = Enum.Font.GothamBold,
                                    Name = "Title",
                                    RichText = CardConfig.RichText,
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", CardConfig.Description, 12), {
                                    Size = UDim2.new(1, -128, 0, 32),
                                    Position = UDim2.new(0, 80, 0, 39),
                                    Font = Enum.Font.GothamSemibold,
                                    TextWrapped = true,
                                    TextTransparency = 0.08,
                                    Name = "Description",
                                    RichText = CardConfig.RichText,
                                }),
                                "TextDark"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Image", "arrow-right"), {
                                    AnchorPoint = Vector2.new(1, 0.5),
                                    Size = UDim2.fromOffset(18, 18),
                                    Position = UDim2.new(1, -18, 0.5, 0),
                                    ImageTransparency = 0.22,
                                    Name = "Arrow",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            Click,
                        }
                    ),
                    "Second"
                )

                local DescriptionLabel = CardFrame:FindFirstChild("Description")
                local function UpdateSize()
                    if DescriptionLabel then
                        local Height = math.max(26, DescriptionLabel.TextBounds.Y)
                        DescriptionLabel.Size = UDim2.new(1, -128, 0, Height)
                        CardFrame.Size = UDim2.new(1, 0, 0, math.max(78, Height + 56))
                    end
                end

                local function ResolveTarget()
                    if Card.TargetTab and type(Card.TargetTab.Select) == "function" then
                        return Card.TargetElements, Card.TargetTab
                    end
                    if CardConfig.UseExistingTab == true then
                        local Target = CardConfig.Tab or CardConfig.Target or CardConfig.Page
                        if type(Target) == "string" then
                            Card.TargetTab = TabName[Target]
                        elseif type(Target) == "table" then
                            if type(Target.Select) == "function" then
                                Card.TargetTab = Target
                            elseif type(Target.Tab) == "table" and type(Target.Tab.Select) == "function" then
                                Card.TargetElements = Target
                                Card.TargetTab = Target.Tab
                            end
                        end
                    end

                    if not Card.TargetTab and CardConfig.CreateTab ~= false then
                        local TargetElements, TargetTab = Functions:MakeTab({
                            Title = CardConfig.TabTitle or CardConfig.Title,
                            Icon = CardConfig.TabIcon or CardConfig.Icon,
                            Visible = CardConfig.TabVisible ~= false and CardConfig.ShowTab ~= false,
                        })
                        Card.TargetElements = TargetElements
                        Card.TargetTab = TargetTab
                        Card.Elements = TargetElements
                        Card.Tab = TargetTab
                        if TargetElements and type(TargetElements.TabBox) == "function" then
                            TargetElements:TabBox({
                                Title = CardConfig.TabBoxTitle or CardConfig.Title,
                                Description = CardConfig.TabBoxDescription or CardConfig.Description,
                                Icon = CardConfig.Icon,
                                Color = CardConfig.Color,
                            })
                        end
                        if type(CardConfig.Build) == "function" then
                            OrionLib:SafeScript(CardConfig.Build, TargetElements, TargetTab, Card)
                        end
                    end
                    return Card.TargetElements, Card.TargetTab
                end

                AddConnection(DescriptionLabel:GetPropertyChangedSignal("TextBounds"), UpdateSize)
                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(CardFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0,
                    }):Play()
                    if CardFrame:FindFirstChild("Arrow") then
                        TweenService:Create(CardFrame.Arrow, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            ImageTransparency = 0,
                            Position = UDim2.new(1, -14, 0.5, 0),
                        }):Play()
                    end
                end)
                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(CardFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.1,
                    }):Play()
                    if CardFrame:FindFirstChild("Arrow") then
                        TweenService:Create(CardFrame.Arrow, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            ImageTransparency = 0.22,
                            Position = UDim2.new(1, -18, 0.5, 0),
                        }):Play()
                    end
                end)
                AddConnection(Click.MouseButton1Click, function()
                    if type(CardConfig.Callback) == "function" then
                        OrionLib:SafeScript(CardConfig.Callback, Card)
                    end
                    Card:Select()
                end)

                function Card:Select()
                    local _, TargetTab = ResolveTarget()
                    if TargetTab and type(TargetTab.Select) == "function" then
                        TargetTab:Select()
                        return true
                    end
                    return false
                end

                function Card:Set(title, description)
                    if title ~= nil and CardFrame:FindFirstChild("Title") then
                        CardFrame.Title.Text = tostring(title)
                    end
                    if description ~= nil and DescriptionLabel then
                        DescriptionLabel.Text = tostring(description)
                    end
                    UpdateSize()
                end

                function Card:SetDescription(description)
                    Card:Set(nil, description)
                end

                function Card:SetTarget(target)
                    CardConfig.Tab = target
                    CardConfig.UseExistingTab = true
                    Card.TargetTab = nil
                    Card.TargetElements = nil
                    ResolveTarget()
                end

                function Card:GetTab()
                    ResolveTarget()
                    return Card.TargetElements, Card.TargetTab
                end

                function Card:SetVisible(state)
                    Card.Visible = state == true
                    CardFrame.Visible = Card.Visible
                end

                task.defer(UpdateSize)
                ResolveTarget()
                if CardConfig.Flag then
                    OrionLib.Flags[CardConfig.Flag] = Card
                end
                return Card
            end

            function ElementFunction:AddGraph(GraphConfig)
                GraphConfig = TranslateConfig(GraphConfig or {})
                GraphConfig.Name = GraphConfig.Name or GraphConfig.Title or "Graph"
                GraphConfig.Content = GraphConfig.Content or GraphConfig.Desc or GraphConfig.Description or GraphConfig.Text or ""
                GraphConfig.Points = GraphConfig.Points or GraphConfig.Values or GraphConfig.Data or {}
                GraphConfig.Visible = GraphConfig.Visible ~= false
                GraphConfig.RichText = GraphConfig.RichText ~= false
                GraphConfig.Height = tonumber(GraphConfig.GraphHeight or GraphConfig.Height or 88) or 88
                GraphConfig.Color = GraphConfig.Color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250))
                GraphConfig.PointColor = GraphConfig.PointColor or GraphConfig.Color
                GraphConfig.ShowStats = GraphConfig.ShowStats ~= false

                local Graph = {
                    Type = "Graph",
                    Visible = GraphConfig.Visible,
                    Points = {},
                }

                local function NormalizePoints(Points)
                    local Normalized = {}
                    if type(Points) ~= "table" then
                        return Normalized
                    end
                    for _, Value in ipairs(Points) do
                        if type(Value) == "table" then
                            Value = Value.Value or Value.Y or Value[2] or Value[1]
                        end
                        local NumberValue = tonumber(Value)
                        if NumberValue then
                            table.insert(Normalized, NumberValue)
                        end
                    end
                    return Normalized
                end

                local GraphFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6), {
                            Size = UDim2.new(1, 0, 0, 90),
                            Parent = ItemParent,
                            Visible = GraphConfig.Visible,
                            BackgroundTransparency = 0.18,
                            Name = "GraphLabel",
                        }),
                        {
                            MakeElement("Padding", 12, 12, 12, 12),
                            SetProps(MakeElement("List", 0, 8), {
                                Name = "Layout",
                            }),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", GraphConfig.Name, 15), {
                                    Size = UDim2.new(1, 0, 0, 18),
                                    Font = Enum.Font.GothamBold,
                                    Name = "Title",
                                    RichText = GraphConfig.RichText,
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", GraphConfig.Content, 13), {
                                    Size = UDim2.new(1, 0, 0, 18),
                                    Font = Enum.Font.GothamSemibold,
                                    TextWrapped = true,
                                    Name = "Content",
                                    RichText = GraphConfig.RichText,
                                }),
                                "TextDark"
                            ),
                            OrionLib:AddThemeObject(
                                SetChildren(
                                    SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6), {
                                        Size = UDim2.new(1, 0, 0, GraphConfig.Height),
                                        BackgroundTransparency = 0.35,
                                        ClipsDescendants = true,
                                        Name = "Canvas",
                                    }),
                                    {
                                        OrionLib:AddThemeObject(MakeElement("Stroke"), "Divider"),
                                    }
                                ),
                                "Main"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", "", 11), {
                                    Size = UDim2.new(1, 0, 0, 14),
                                    Font = Enum.Font.GothamSemibold,
                                    TextTransparency = 0.2,
                                    Name = "Stats",
                                    RichText = GraphConfig.RichText,
                                }),
                                "TextDark"
                            ),
                            SetChildren(
                                SetProps(MakeElement("TFrame"), {
                                    Size = UDim2.new(1, 0, 0, 0),
                                    Name = "Holder",
                                }),
                                {
                                    MakeElement("List", 0, 6),
                                }
                            ),
                        }
                    ),
                    "Second"
                )

                local ContentLabel = GraphFrame:FindFirstChild("Content")
                local GraphCanvas = GraphFrame:FindFirstChild("Canvas")
                local StatsLabel = GraphFrame:FindFirstChild("Stats")
                local Holder = GraphFrame:FindFirstChild("Holder")
                Graph.Instance = GraphFrame
                Graph.Frame = GraphFrame
                Graph.Canvas = GraphCanvas
                Graph.Holder = Holder

                local function ClearGraph()
                    if not GraphCanvas then
                        return
                    end
                    for _, Child in ipairs(GraphCanvas:GetChildren()) do
                        if Child.Name == "GraphLine" or Child.Name == "GraphDot" then
                            Child:Destroy()
                        end
                    end
                end

                local function FormatNumber(Value)
                    if math.abs(Value) >= 100 then
                        return tostring(math.floor(Value + 0.5))
                    end
                    return tostring(math.floor(Value * 10 + 0.5) / 10)
                end

                local function GetAngle(Y, X)
                    if math.atan2 then
                        return math.atan2(Y, X)
                    end
                    if X > 0 then
                        return math.atan(Y / X)
                    end
                    if X < 0 then
                        return math.atan(Y / X) + (Y >= 0 and math.pi or -math.pi)
                    end
                    return Y >= 0 and math.pi / 2 or -math.pi / 2
                end

                local function UpdateStats()
                    if not StatsLabel then
                        return
                    end
                    if not GraphConfig.ShowStats or #Graph.Points == 0 then
                        StatsLabel.Text = ""
                        StatsLabel.Visible = false
                        StatsLabel.Size = UDim2.new(1, 0, 0, 0)
                        return
                    end
                    local MinValue = Graph.Points[1]
                    local MaxValue = Graph.Points[1]
                    for _, Value in ipairs(Graph.Points) do
                        MinValue = math.min(MinValue, Value)
                        MaxValue = math.max(MaxValue, Value)
                    end
                    StatsLabel.Visible = true
                    StatsLabel.Size = UDim2.new(1, 0, 0, 14)
                    StatsLabel.Text = string.format(
                        "Last %s  •  Min %s  •  Max %s",
                        FormatNumber(Graph.Points[#Graph.Points]),
                        FormatNumber(MinValue),
                        FormatNumber(MaxValue)
                    )
                end

                local function UpdateSize()
                    if not GraphFrame then
                        return
                    end
                    if ContentLabel then
                        local HasContent = tostring(ContentLabel.Text or "") ~= ""
                        ContentLabel.Visible = HasContent
                        ContentLabel.Size = UDim2.new(1, 0, 0, HasContent and math.max(18, ContentLabel.TextBounds.Y) or 0)
                    end
                    if GraphCanvas then
                        local HasGraph = #Graph.Points > 1
                        GraphCanvas.Visible = HasGraph
                        GraphCanvas.Size = UDim2.new(1, 0, 0, HasGraph and GraphConfig.Height or 0)
                    end
                    if Holder and Holder:FindFirstChildOfClass("UIListLayout") then
                        local HolderHeight = Holder.UIListLayout.AbsoluteContentSize.Y
                        Holder.Visible = HolderHeight > 0
                        Holder.Size = UDim2.new(1, 0, 0, HolderHeight)
                    end
                    task.defer(function()
                        if GraphFrame and GraphFrame.Parent and GraphFrame:FindFirstChild("Layout") then
                            GraphFrame.Size = UDim2.new(1, 0, 0, GraphFrame.Layout.AbsoluteContentSize.Y + 24)
                        end
                    end)
                end

                local function RenderGraph()
                    ClearGraph()
                    UpdateStats()
                    UpdateSize()
                    if not GraphCanvas or #Graph.Points < 2 then
                        return
                    end

                    local Width = GraphCanvas.AbsoluteSize.X
                    if Width <= 2 and GraphFrame.AbsoluteSize.X > 24 then
                        Width = GraphFrame.AbsoluteSize.X - 24
                    end
                    Width = math.max(Width, 220)
                    local Height = GraphConfig.Height
                    local Padding = 10
                    local MinValue = Graph.Points[1]
                    local MaxValue = Graph.Points[1]
                    for _, Value in ipairs(Graph.Points) do
                        MinValue = math.min(MinValue, Value)
                        MaxValue = math.max(MaxValue, Value)
                    end
                    local Range = math.max(MaxValue - MinValue, 1)
                    local PreviousPoint

                    for Index, Value in ipairs(Graph.Points) do
                        local X = Padding + ((Index - 1) / (#Graph.Points - 1)) * (Width - Padding * 2)
                        local Y = Padding + (1 - ((Value - MinValue) / Range)) * (Height - Padding * 2)
                        local Point = Vector2.new(X, Y)

                        if PreviousPoint then
                            local Delta = Point - PreviousPoint
                            local Distance = math.sqrt(Delta.X * Delta.X + Delta.Y * Delta.Y)
                            SetChildren(
                                SetProps(MakeElement("Frame", GraphConfig.Color), {
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    Position = UDim2.fromOffset((PreviousPoint.X + Point.X) / 2, (PreviousPoint.Y + Point.Y) / 2),
                                    Size = UDim2.fromOffset(Distance, 2),
                                    Rotation = math.deg(GetAngle(Delta.Y, Delta.X)),
                                    BackgroundColor3 = GraphConfig.Color,
                                    Parent = GraphCanvas,
                                    Name = "GraphLine",
                                    ZIndex = GraphCanvas.ZIndex + 1,
                                }),
                                {
                                    Create("UICorner", {
                                        CornerRadius = UDim.new(1, 0),
                                    }),
                                }
                            )
                        end

                        SetChildren(
                            SetProps(MakeElement("RoundFrame", GraphConfig.PointColor, 1, 0), {
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Position = UDim2.fromOffset(Point.X, Point.Y),
                                Size = UDim2.fromOffset(6, 6),
                                BackgroundColor3 = GraphConfig.PointColor,
                                Parent = GraphCanvas,
                                Name = "GraphDot",
                                ZIndex = GraphCanvas.ZIndex + 2,
                            }),
                            {
                                SetProps(MakeElement("Stroke", GetThemeValue("Main", Color3.fromRGB(18, 20, 27)), 1), {
                                    Transparency = 0.1,
                                }),
                            }
                        )
                        PreviousPoint = Point
                    end
                end

                Graph.Points = NormalizePoints(GraphConfig.Points)
                AddConnection(ContentLabel:GetPropertyChangedSignal("TextBounds"), UpdateSize)
                AddConnection(GraphFrame.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), UpdateSize)
                if Holder and Holder:FindFirstChildOfClass("UIListLayout") then
                    AddConnection(Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), UpdateSize)
                end
                if GraphCanvas then
                    AddConnection(GraphCanvas:GetPropertyChangedSignal("AbsoluteSize"), RenderGraph)
                end

                function Graph:Set(title, content)
                    if getgenv().Destroy then
                        return
                    end
                    if title ~= nil and GraphFrame and GraphFrame:FindFirstChild("Title") then
                        GraphFrame.Title.Text = tostring(title)
                    end
                    if content ~= nil and ContentLabel then
                        ContentLabel.Text = tostring(content)
                    end
                    UpdateSize()
                end

                function Graph:SetTitle(title)
                    Graph:Set(title, nil)
                end

                function Graph:SetText(content)
                    Graph:Set(nil, content)
                end

                function Graph:SetContent(content)
                    Graph:SetText(content)
                end

                function Graph:SetPoints(points)
                    if getgenv().Destroy then
                        return
                    end
                    Graph.Points = NormalizePoints(points)
                    RenderGraph()
                end

                function Graph:AddPoint(value, limit)
                    if getgenv().Destroy then
                        return
                    end
                    local NumberValue = tonumber(value)
                    if not NumberValue then
                        return
                    end
                    table.insert(Graph.Points, NumberValue)
                    limit = tonumber(limit or GraphConfig.MaxPoints)
                    if limit and limit > 0 then
                        while #Graph.Points > limit do
                            table.remove(Graph.Points, 1)
                        end
                    end
                    RenderGraph()
                end

                function Graph:ClearPoints()
                    Graph.Points = {}
                    RenderGraph()
                end

                function Graph:SetColor(color, pointColor)
                    if typeof(color) == "Color3" then
                        GraphConfig.Color = color
                    end
                    if typeof(pointColor) == "Color3" then
                        GraphConfig.PointColor = pointColor
                    elseif typeof(color) == "Color3" then
                        GraphConfig.PointColor = color
                    end
                    RenderGraph()
                end

                function Graph:SetVisible(state)
                    Graph.Visible = state == true
                    if GraphFrame then
                        GraphFrame.Visible = Graph.Visible
                    end
                end

                for methodName, method in next, GetElements(Holder) do
                    Graph[methodName] = method
                end
                Graph.Button = function(_, config)
                    config = TranslateConfig(config or {})
                    config.Name = config.Name or config.Title or "Button"
                    return Graph:AddButton(config)
                end
                Graph.HighlightButton = function(_, config)
                    config = TranslateConfig(config or {})
                    config.Name = config.Name or config.Title or "Highlight Button"
                    return Graph:AddHighlightButton(config)
                end
                Graph.WarningBox = function(_, config)
                    config = TranslateConfig(config or {})
                    return Graph:AddWarningBox(config)
                end
                Graph.Toggle = function(_, config)
                    config = TranslateConfig(config or {})
                    config.Name = config.Name or config.Title or "Toggle"
                    config.Default = config.Default ~= nil and config.Default or config.Value
                    return Graph:AddToggle(config)
                end
                Graph.Slider = function(_, config)
                    config = TranslateConfig(config or {})
                    config.Name = config.Name or config.Title or "Slider"
                    config.Default = config.Default ~= nil and config.Default or config.Value
                    return Graph:AddSlider(config)
                end
                Graph.Dropdown = function(_, config)
                    config = TranslateConfig(config or {})
                    config.Name = config.Name or config.Title or "Dropdown"
                    config.Default = config.Default ~= nil and config.Default or config.Value
                    return Graph:AddDropdown(config)
                end
                Graph.Input = function(_, config)
                    config = TranslateConfig(config or {})
                    config.Name = config.Name or config.Title or "Input"
                    config.Default = config.Default ~= nil and config.Default or config.Value
                    return Graph:AddTextbox(config)
                end
                Graph.Colorpicker = function(_, config)
                    config = TranslateConfig(config or {})
                    config.Name = config.Name or config.Title or "Colorpicker"
                    config.Default = config.Default ~= nil and config.Default or config.Value
                    return Graph:AddColorpicker(config)
                end
                Graph.Paragraph = function(_, config)
                    config = TranslateConfig(config or {})
                    return Graph:AddParagraph(config.Title or config.Name or "Paragraph", config.Content or config.Desc or config.Description or "")
                end

                task.defer(RenderGraph)
                if GraphConfig.Flag then
                    OrionLib.Flags[GraphConfig.Flag] = Graph
                end
                return Graph
            end

            function ElementFunction:AddDiscordServer(DiscordConfig)
                DiscordConfig = TranslateConfig(DiscordConfig or {})
                DiscordConfig.Name = DiscordConfig.Name or DiscordConfig.Title or "Discord Server"
                DiscordConfig.Description = DiscordConfig.Description or DiscordConfig.Desc or DiscordConfig.Content or "Join the community server."
                DiscordConfig.Invite = DiscordConfig.Invite or DiscordConfig.Link or DiscordConfig.Url
                DiscordConfig.Icon = ResolveImageLikeAsset(ResolveIcon(DiscordConfig.Icon or "message-circle"))
                DiscordConfig.Thumbnail = ResolveExternalMediaAsset(DiscordConfig.Thumbnail or DiscordConfig.Banner or DiscordConfig.Image, "Discord")
                DiscordConfig.Visible = DiscordConfig.Visible ~= false

                local Discord = { Visible = DiscordConfig.Visible, Type = "DiscordServer" }
                local height = DiscordConfig.Thumbnail and 172 or 118
                local Card = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
                            Size = UDim2.new(1, 0, 0, height),
                            Parent = ItemParent,
                            Visible = DiscordConfig.Visible,
                            BackgroundTransparency = 0,
                        }),
                        {
                            OrionLib:AddThemeObject(MakeElement("Stroke", nil, 1), "Stroke"),
                            Create("UIPadding", {
                                PaddingTop = UDim.new(0, 10),
                                PaddingBottom = UDim.new(0, 10),
                                PaddingLeft = UDim.new(0, 10),
                                PaddingRight = UDim.new(0, 10),
                            }),
                        }
                    ),
                    "Second"
                )

                local contentY = 0
                if DiscordConfig.Thumbnail then
                    SetChildren(
                        SetProps(MakeElement("RoundImage", 0, 8, DiscordConfig.Thumbnail), {
                            Size = UDim2.new(1, 0, 0, 58),
                            Parent = Card,
                            ScaleType = Enum.ScaleType.Crop,
                            ZIndex = 4,
                        }),
                        {
                            OrionLib:AddThemeObject(MakeElement("Stroke", nil, 1), "Stroke"),
                        }
                    )
                    contentY = 68
                end

                local iconWrap = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", DiscordConfig.Color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250)), 0, 10), {
                            Size = UDim2.fromOffset(42, 42),
                            Position = UDim2.fromOffset(0, contentY),
                            Parent = Card,
                            BackgroundTransparency = 0.08,
                            ZIndex = 4,
                        }),
                        {
                            SetProps(MakeElement("Image", DiscordConfig.Icon), {
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Position = UDim2.fromScale(0.5, 0.5),
                                Size = UDim2.fromOffset(24, 24),
                                ZIndex = 5,
                            }),
                        }
                    ),
                    "Accent"
                )

                local title = OrionLib:AddThemeObject(
                    SetProps(MakeElement("Label", DiscordConfig.Name, 15), {
                        Position = UDim2.fromOffset(54, contentY - 1),
                        Size = UDim2.new(1, -60, 0, 20),
                        Font = Enum.Font.GothamBlack,
                        Parent = Card,
                        ZIndex = 4,
                    }),
                    "Text"
                )

                local description = OrionLib:AddThemeObject(
                    SetProps(MakeElement("Label", DiscordConfig.Description, 12), {
                        Position = UDim2.fromOffset(54, contentY + 21),
                        Size = UDim2.new(1, -60, 0, 35),
                        TextWrapped = true,
                        Parent = Card,
                        ZIndex = 4,
                    }),
                    "TextDark"
                )

                local metaText = DiscordConfig.Meta or DiscordConfig.Members or DiscordConfig.Online or (DiscordConfig.Invite and "Invite ready") or "Community"
                local meta = OrionLib:AddThemeObject(
                    SetProps(MakeElement("Label", tostring(metaText), 12), {
                        Position = UDim2.fromOffset(0, contentY + 55),
                        Size = UDim2.new(1, -190, 0, 24),
                        Font = Enum.Font.GothamSemibold,
                        Parent = Card,
                        ZIndex = 4,
                    }),
                    "TextDark"
                )

                local buttonHolder = SetProps(MakeElement("TFrame"), {
                    AnchorPoint = Vector2.new(1, 1),
                    Position = UDim2.new(1, 0, 1, 0),
                    Size = UDim2.new(0, 104, 0, 32),
                    Parent = Card,
                    ZIndex = 4,
                })
                Create("UIListLayout", {
                    Parent = buttonHolder,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDim.new(0, 8),
                })

                local copyLabel
                local function CreateCopyButton(text, icon, callback)
                    local button = OrionLib:AddThemeObject(
                        SetChildren(
                            SetProps(MakeElement("Button"), {
                                Size = UDim2.fromOffset(104, 32),
                                Parent = buttonHolder,
                                BackgroundTransparency = 0,
                                ZIndex = 5,
                            }),
                            {
                                MakeElement("Corner", 0, 8),
                                OrionLib:AddThemeObject(MakeElement("Stroke", nil, 1), "Stroke"),
                                OrionLib:AddThemeObject(
                                    SetProps(MakeElement("Image", ResolveIcon(icon)), {
                                        Position = UDim2.fromOffset(10, 8),
                                        Size = UDim2.fromOffset(16, 16),
                                        ZIndex = 6,
                                    }),
                                    "TextDark"
                                ),
                                OrionLib:AddThemeObject(
                                    SetProps(MakeElement("Label", text, 12), {
                                        Position = UDim2.fromOffset(30, 0),
                                        Size = UDim2.new(1, -34, 1, 0),
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        ZIndex = 6,
                                    }),
                                    "Text"
                                ),
                            }
                        ),
                        "Second"
                    )
                    AddConnection(button.MouseEnter, function()
                        TweenService
                            :Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
                                BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 5),
                            })
                            :Play()
                    end)
                    AddConnection(button.MouseLeave, function()
                        TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
                            BackgroundColor3 = GetThemeValue("Second", OrionLib.Themes.Default.Second),
                        }):Play()
                    end)
                    AddConnection(button.MouseButton1Click, callback)
                    copyLabel = button:FindFirstChildOfClass("TextLabel")
                    return button
                end

                local function CopyAction()
                    if DiscordConfig.Invite and type(setclipboard) == "function" then
                        setclipboard(DiscordConfig.Invite)
                    end
                    if copyLabel then
                        copyLabel.Text = DiscordConfig.CopiedText or "Copied"
                        task.delay(1.2, function()
                            if copyLabel and copyLabel.Parent then
                                copyLabel.Text = DiscordConfig.CopyText or "Copy"
                            end
                        end)
                    end
                    if type(DiscordConfig.CopyCallback or DiscordConfig.OnCopy or DiscordConfig.JoinCallback or DiscordConfig.OnJoin) == "function" then
                        OrionLib:SafeScript(DiscordConfig.CopyCallback or DiscordConfig.OnCopy or DiscordConfig.JoinCallback or DiscordConfig.OnJoin, Discord)
                    elseif DiscordConfig.Invite then
                        OrionLib:Notify({ Title = "Discord", Content = "Invite copied to clipboard.", Icon = "message-circle", Duration = 3 })
                    end
                end

                CreateCopyButton(DiscordConfig.CopyText or "Copy", DiscordConfig.CopyIcon or "copy", CopyAction)

                function Discord:SetTitle(value)
                    title.Text = tostring(value or "")
                end
                function Discord:SetDescription(value)
                    description.Text = tostring(value or "")
                end
                function Discord:SetMeta(value)
                    meta.Text = tostring(value or "")
                end
                function Discord:SetVisible(state)
                    Discord.Visible = state == true
                    Card.Visible = Discord.Visible
                end
                function Discord:Copy()
                    CopyAction()
                end
                Discord.Join = Discord.Copy
                function Discord:Leave()
                    CopyAction()
                end
                if DiscordConfig.Flag then
                    OrionLib.Flags[DiscordConfig.Flag] = Discord
                end
                return Discord
            end

            function ElementFunction:AddButton(ButtonConfig)
                ButtonConfig = ButtonConfig or {}
                ButtonConfig.Visible = ButtonConfig.Visible or true
                ButtonConfig.Disabled = ButtonConfig.Disabled or false
                ButtonConfig.Name = ButtonConfig.Name or "Button"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end
                ButtonConfig.Flag = ButtonConfig.Flag or nil
                ButtonConfig.Icon = ButtonConfig.Icon or "mouse-pointer-click"
                local Button = { Disabled = ButtonConfig.Disabled, Visible = ButtonConfig.Visible, Flag = ButtonConfig.Flag }

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                })

                local ButtonFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(1, 0, 0, 33),
                            Visible = ButtonConfig.Visible,
                            Parent = ItemParent,
                        }),
                        {
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", ButtonConfig.Name, 15), {
                                    Size = UDim2.new(1, -12, 1, 0),
                                    Position = UDim2.new(0, 12, 0, 0),
                                    Font = Enum.Font.GothamBold,
                                    Name = "Content",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Image", ButtonConfig.Icon), {
                                    Size = UDim2.new(0, 20, 0, 20),
                                    Position = UDim2.new(1, -30, 0, 7),
                                }),
                                "TextDark"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            Click,
                        }
                    ),
                    "Second"
                )
                Button.Frame = ButtonFrame
                Button.ClickArea = Click
                if ButtonConfig.Glass or ButtonConfig.LiquidGlass or WindowConfig.GlassElements then
                    Button.Glass = ApplyLiquidGlass(ButtonFrame, ButtonConfig.GlassConfig or ButtonConfig.LiquidGlassConfig or {
                        Color = ButtonConfig.Color or GetThemeValue("Second", Color3.fromRGB(25, 28, 38)),
                        Accent = ButtonConfig.Accent or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250)),
                        BackgroundTransparency = 0.36,
                        Radius = 10,
                        StrokeTransparency = 0.8,
                        HighlightTransparency = 0.92,
                        Shadow = false,
                    })
                    Click.ZIndex = 40
                end

                AddConnection(Click.MouseEnter, function()
                    if ButtonConfig.Disabled then
                        return
                    end
                    TweenService:Create(
                        ButtonFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 3) }
                    ):Play()
                end)

                AddConnection(Click.MouseLeave, function()
                    if ButtonConfig.Disabled then
                        return
                    end
                    TweenService:Create(
                        ButtonFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second }
                    ):Play()
                end)

                AddConnection(Click.MouseButton1Up, function()
                    if ButtonConfig.Disabled then
                        return
                    end
                    TweenService:Create(
                        ButtonFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 3) }
                    ):Play()
                    task.spawn(function()
                        Button:Click()
                    end)
                end)

                AddConnection(Click.MouseButton1Down, function()
                    if ButtonConfig.Disabled then
                        return
                    end
                    TweenService:Create(
                        ButtonFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 6) }
                    ):Play()
                end)

                function Button:Set(ButtonText)
                    if getgenv().Destroy or ButtonConfig.Disabled then
                        return
                    end
                    if ButtonFrame and ButtonFrame:FindFirstChild("Content") then
                        ButtonFrame.Content.Text = ButtonText
                    end
                end

                function Button:SetDisabled(state)
                    if getgenv().Destroy then
                        return
                    end
                    Button.Disabled = state
                    ButtonConfig.Disabled = state
                    if ButtonFrame then
                        TweenService:Create(ButtonFrame, TweenInfo.new(0.2), { BackgroundTransparency = state and 0.5 or 0 }):Play()
                    end
                    if Click then
                        Click.Active = not state
                        Click.AutoButtonColor = not state
                    end
                    if ButtonFrame and ButtonFrame:FindFirstChild("Content") then
                        ButtonFrame.Content.TextTransparency = state and 0.5 or 0
                    end
                end

                function Button:SetVisible(state)
                    if getgenv().Destroy then
                        return
                    end
                    if ButtonFrame then
                        ButtonFrame.Visible = state
                        Button.Visible = state
                    end
                end

                function Button:Click()
                    if ButtonConfig.Callback and not ButtonConfig.Disabled then
                        OrionLib:SafeScript(ButtonConfig.Callback)
                    end
                end

                function Button:SetCallback(callback)
                    if getgenv().Destroy or ButtonConfig.Disabled then
                        return
                    end
                    ButtonConfig.Callback = callback
                end

                function Button:AddButton(ButtonConfigClone)
                    ButtonConfigClone = ButtonConfigClone or {}
                    ButtonConfigClone.Visible = ButtonConfigClone.Visible or true
                    ButtonConfigClone.Disabled = ButtonConfigClone.Disabled or false
                    ButtonConfigClone.Name = ButtonConfigClone.Name or "Button"
                    ButtonConfigClone.Callback = ButtonConfigClone.Callback or function() end
                    ButtonConfigClone.Flag = ButtonConfigClone.Flag or nil
                    ButtonConfigClone.Icon = ButtonConfigClone.Icon or "mouse-pointer-click"
                    local ButtonClone = { Disabled = ButtonConfigClone.Disabled, Visible = ButtonConfigClone.Visible, Flag = ButtonConfigClone.Flag }

                    if ButtonFrame then
                        ButtonFrame.Size = UDim2.new(0.493, 0, 0, 33)
                        local ButtonCloneFrame = Clone(ButtonFrame, {
                            Size = UDim2.new(1, 0, 0, 33),
                            Position = UDim2.new(1.03, 0, 0, 0),
                            Parent = ButtonFrame,
                        })

                        local Click = ButtonCloneFrame and ButtonCloneFrame:FindFirstChildOfClass("TextButton")
                        AddConnection(Click.MouseEnter, function()
                            if ButtonConfigClone.Disabled then
                                return
                            end
                            TweenService:Create(
                                ButtonCloneFrame,
                                TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                                { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 3) }
                            ):Play()
                        end)

                        AddConnection(Click.MouseLeave, function()
                            if ButtonConfigClone.Disabled then
                                return
                            end
                            TweenService:Create(
                                ButtonCloneFrame,
                                TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                                { BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second }
                            ):Play()
                        end)

                        AddConnection(Click.MouseButton1Up, function()
                            if ButtonConfigClone.Disabled then
                                return
                            end
                            TweenService:Create(
                                ButtonCloneFrame,
                                TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                                { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 3) }
                            ):Play()
                            spawn(function()
                                ButtonClone:Click()
                            end)
                        end)

                        AddConnection(Click.MouseButton1Down, function()
                            if ButtonConfigClone.Disabled then
                                return
                            end
                            TweenService:Create(
                                ButtonCloneFrame,
                                TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                                { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 6) }
                            ):Play()
                        end)

                        function ButtonClone:Set(ButtonText)
                            if getgenv().Destroy or ButtonConfigClone.Disabled then
                                return
                            end
                            if ButtonCloneFrame and ButtonCloneFrame:FindFirstChild("Content") then
                                ButtonCloneFrame.Content.Text = ButtonText
                            end
                        end

                        function ButtonClone:SetDisabled(state)
                            if getgenv().Destroy then
                                return
                            end
                            ButtonClone.Disabled = state
                            ButtonConfigClone.Disabled = state
                            if ButtonCloneFrame then
                                TweenService:Create(ButtonCloneFrame, TweenInfo.new(0.2), { BackgroundTransparency = state and 0.5 or 0 }):Play()
                            end
                            if Click then
                                Click.Active = not state
                                Click.AutoButtonColor = not state
                            end
                            if ButtonCloneFrame and ButtonCloneFrame:FindFirstChild("Content") then
                                ButtonCloneFrame.Content.TextTransparency = state and 0.5 or 0
                            end
                        end

                        function ButtonClone:SetVisible(state)
                            if getgenv().Destroy then
                                return
                            end
                            if ButtonCloneFrame then
                                ButtonCloneFrame.Visible = state
                                ButtonClone.Visible = state
                                if not state and ButtonConfig.Visible then
                                    ButtonFrame.Size = UDim2.new(1, 0, 0, 33)
                                else
                                    ButtonFrame.Size = UDim2.new(0.493, 0, 0, 33)
                                end
                            end
                        end

                        function ButtonClone:Click()
                            if ButtonConfigClone.Callback and not ButtonConfigClone.Disabled then
                                OrionLib:SafeScript(ButtonConfigClone.Callback)
                            end
                        end

                        function ButtonClone:SetCallback(callback)
                            if getgenv().Destroy or ButtonConfig.Disabled then
                                return
                            end
                            ButtonConfigClone.Callback = callback
                        end
                    end

                    if ButtonConfigClone.Visible == false then
                        ButtonClone:SetVisible(ButtonConfigClone.Visible)
                    end
                    if ButtonConfigClone.Flag then
                        OrionLib.Flags[ButtonConfig.Flag][ButtonConfigClone.Flag] = ButtonClone
                    end
                    return ButtonClone
                end
                if ButtonConfig.Flag then
                    OrionLib.Flags[ButtonConfig.Flag] = Button
                end
                return Button
            end

            function ElementFunction:AddHighlightButton(ButtonConfig)
                ButtonConfig = TranslateConfig(ButtonConfig or {})
                ButtonConfig.Name = ButtonConfig.Name or ButtonConfig.Title or "Highlight Button"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end
                ButtonConfig.Visible = ButtonConfig.Visible ~= false
                ButtonConfig.Disabled = ButtonConfig.Disabled == true
                ButtonConfig.Color = ButtonConfig.Color or Color3.fromRGB(90, 140, 255)
                ButtonConfig.Icon = ResolveIcon(ButtonConfig.Icon or "mouse-pointer-click")
                local Button = { Disabled = ButtonConfig.Disabled, Visible = ButtonConfig.Visible, Highlighted = true, Type = "HighlightButton" }

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    AutoButtonColor = false,
                })

                local ButtonFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6), {
                            Size = UDim2.new(1, 0, 0, 38),
                            Visible = ButtonConfig.Visible,
                            Parent = ItemParent,
                            BackgroundTransparency = ButtonConfig.Disabled and 0.45 or 0,
                        }),
                        {
                            SetProps(MakeElement("Frame"), {
                                Name = "Accent",
                                Size = UDim2.new(0, 4, 1, -12),
                                Position = UDim2.new(0, 8, 0, 6),
                                BackgroundColor3 = ButtonConfig.Color,
                            }),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", ButtonConfig.Name, 15), {
                                    Size = UDim2.new(1, -52, 1, 0),
                                    Position = UDim2.new(0, 20, 0, 0),
                                    Font = Enum.Font.GothamBold,
                                    Name = "Content",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Image", ButtonConfig.Icon), {
                                    Size = UDim2.new(0, 20, 0, 20),
                                    Position = UDim2.new(1, -30, 0.5, -10),
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            Click,
                        }
                    ),
                    "Second"
                )

                AddConnection(Click.MouseEnter, function()
                    if Button.Disabled then
                        return
                    end
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 42) })
                        :Play()
                    TweenService:Create(
                        ButtonFrame.Accent,
                        TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { Size = UDim2.new(0, 6, 1, -8), Position = UDim2.new(0, 7, 0, 4) }
                    ):Play()
                end)

                AddConnection(Click.MouseLeave, function()
                    if Button.Disabled then
                        return
                    end
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 38) })
                        :Play()
                    TweenService:Create(
                        ButtonFrame.Accent,
                        TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { Size = UDim2.new(0, 4, 1, -12), Position = UDim2.new(0, 8, 0, 6) }
                    ):Play()
                end)

                AddConnection(Click.MouseButton1Up, function()
                    if Button.Disabled then
                        return
                    end
                    TweenService
                        :Create(ButtonFrame.Accent, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 10, 1, -6) })
                        :Play()
                    OrionLib:SafeScript(ButtonConfig.Callback)
                    task.delay(0.12, function()
                        if ButtonFrame and ButtonFrame.Parent then
                            TweenService:Create(
                                ButtonFrame.Accent,
                                TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                                { Size = UDim2.new(0, 4, 1, -12) }
                            ):Play()
                        end
                    end)
                end)

                function Button:Set(text)
                    if ButtonFrame and ButtonFrame:FindFirstChild("Content") then
                        ButtonFrame.Content.Text = text
                    end
                end

                function Button:SetColor(color)
                    if typeof(color) == "Color3" and ButtonFrame and ButtonFrame:FindFirstChild("Accent") then
                        ButtonConfig.Color = color
                        TweenService:Create(ButtonFrame.Accent, TweenInfo.new(0.2), { BackgroundColor3 = color }):Play()
                    end
                end

                function Button:SetDisabled(state)
                    Button.Disabled = state == true
                    ButtonConfig.Disabled = Button.Disabled
                    if ButtonFrame then
                        TweenService:Create(ButtonFrame, TweenInfo.new(0.2), { BackgroundTransparency = Button.Disabled and 0.45 or 0 }):Play()
                    end
                end

                function Button:SetVisible(state)
                    Button.Visible = state
                    if ButtonFrame then
                        ButtonFrame.Visible = state
                    end
                end

                function Button:SetCallback(callback)
                    if type(callback) == "function" then
                        ButtonConfig.Callback = callback
                    end
                end

                if ButtonConfig.Flag then
                    OrionLib.Flags[ButtonConfig.Flag] = Button
                end
                return Button
            end

            function ElementFunction:AddViewport(ViewportConfig)
                ViewportConfig = ViewportConfig or {}
                ViewportConfig.Object = ViewportConfig.Object or Instance.new("Part")
                ViewportConfig.Camera = ViewportConfig.Camera or Instance.new("Camera")
                ViewportConfig.Orbit = ViewportConfig.Orbit or false
                ViewportConfig.Control = ViewportConfig.Control or false
                ViewportConfig.Zoom = ViewportConfig.Zoom or false
                ViewportConfig.Size = ViewportConfig.Size or 20
                ViewportConfig.Flag = ViewportConfig.Flag or false
                ViewportConfig.Visible = ViewportConfig.Visible or true
                ViewportConfig.Padding = ViewportConfig.Padding or 8

                local Viewport = {
                    Object = ViewportConfig.Object,
                    Camera = ViewportConfig.Camera,
                    Orbit = ViewportConfig.Orbit,
                    Zoom = ViewportConfig.Zoom,
                    Control = ViewportConfig.Control,
                    Size = ViewportConfig.Size,
                    Flag = ViewportConfig.Flag,
                    Visible = ViewportConfig.Visible,
                    Distance = 20,
                    MinZoom = 5,
                    MaxZoom = 50,
                    Type = "Viewport",
                }
                local function FrameViewHeight(ViewportSize)
                    return ViewportSize + ViewportConfig.Padding * 2
                end

                local ViewportGui = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(1, 0, 0, FrameViewHeight(ViewportConfig.Size)),
                            Visible = ViewportConfig.Visible,
                            Parent = ItemParent,
                        }),
                        {
                            Create("ViewportFrame", {
                                Name = "ViewportFrame",
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Size = UDim2.new(0, ViewportConfig.Size, 0, ViewportConfig.Size),
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                BackgroundTransparency = 1,
                            }, {
                                OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            }),
                        }
                    ),
                    "Second"
                )

                ViewportObject = ViewportGui:FindFirstChild("ViewportFrame", true)
                ViewportConfig.Camera.Parent = ViewportObject
                ViewportConfig.Object.Parent = ViewportObject
                ViewportObject.CurrentCamera = Viewport.Camera
                local function updateLayout(size)
                    if getgenv().Destroy then
                        return
                    end
                    if ViewportGui then
                        ViewportGui.Size = UDim2.new(1, 0, 0, FrameViewHeight(size))
                        ViewportObject.Size = UDim2.new(0, size, 0, size)
                        ViewportObject.Position = UDim2.new(0.5, 0, 0.5, 0)
                    end
                end

                local hovering = false
                AddConnection(ViewportObject.MouseEnter, function()
                    hovering = true
                end)

                AddConnection(ViewportObject.MouseLeave, function()
                    hovering = false
                end)

                function Viewport:SetObject(obj, Properties, Children)
                    if getgenv().Destroy then
                        return
                    end
                    if not obj then
                        return
                    end
                    for _, v in pairs(ViewportObject:GetChildren()) do
                        if not v:IsA("Camera") then
                            v:Destroy()
                        end
                    end
                    local Object
                    if typeof(obj) == "Instance" then
                        Object = obj:Clone()
                    elseif type(obj) == "string" then
                        Object = Instance.new(obj)
                        for i, v in next, Properties or {} do
                            Object[i] = v
                        end
                        for _, v in next, Children or {} do
                            v.Parent = Object
                        end
                    else
                        return
                    end
                    Object.Parent = ViewportObject
                    Viewport.Object = Object
                    local cam = ViewportObject:FindFirstChildOfClass("Camera")
                    if not cam then
                        return
                    end
                    local cf, size
                    if Object:IsA("Model") then
                        cf, size = Object:GetBoundingBox()
                    elseif Object:IsA("BasePart") then
                        cf = Object.CFrame
                        size = Object.Size
                    else
                        return
                    end
                    local max = math.max(size.X, size.Y, size.Z)
                    Viewport.Distance = max * 2
                    Viewport:UpdateCamera()
                    return Object
                end

                function Viewport:UpdateCamera()
                    if not self.Object or not self.Camera then
                        return
                    end
                    local cf, size
                    if Viewport.Object:IsA("Model") then
                        cf, size = Viewport.Object:GetBoundingBox()
                    elseif Viewport.Object:IsA("BasePart") then
                        cf = Viewport.Object.CFrame
                        size = Viewport.Object.Size
                    else
                        return
                    end
                    local center = cf.Position
                    Viewport.Camera.CFrame = CFrame.new(center + Vector3.new(0, 0, Viewport.Distance), center)
                end

                function Viewport:SetVisible(ToChange: boolean)
                    if getgenv().Destroy then
                        return
                    end
                    if ViewportGui then
                        ViewportGui.Visible = ToChange
                    end
                end

                function Viewport:SetControl(ToChange: boolean)
                    if getgenv().Destroy then
                        return
                    end
                    Viewport.Control = ToChange
                end

                function Viewport:SetOrbit(ToChange: boolean)
                    if getgenv().Destroy then
                        return
                    end
                    Viewport.Orbit = ToChange
                end

                function Viewport:SetZoom(ToChange: boolean)
                    if getgenv().Destroy then
                        return
                    end
                    Viewport.Zoom = ToChange
                end

                function Viewport:SetZoomCamera(zoom)
                    if getgenv().Destroy then
                        return
                    end
                    zoom = zoom or {}
                    zoom.MaxZoom = zoom.MaxZoom or Viewport.MaxZoom
                    zoom.MinZoom = zoom.MinZoom or Viewport.MinZoom
                    zoom.Distance = zoom.Distance or Viewport.Distance

                    Viewport.MaxZoom = zoom.MaxZoom
                    Viewport.MinZoom = zoom.MinZoom
                    Viewport.Distance = zoom.Distance
                end

                local dragging = false
                local lastPos
                local lastDist
                AddConnection(ViewportObject.InputBegan, function(input)
                    if Viewport.Control and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                        dragging = true
                        lastPos = input.Position
                    end
                end)
                AddConnection(ViewportObject.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                AddConnection(UserInputService.InputChanged, function(input)
                    if dragging and Viewport.Object then
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            local delta = input.Position - lastPos
                            lastPos = input.Position
                            local cf, size
                            if Viewport.Object:IsA("Model") then
                                cf, size = Viewport.Object:GetBoundingBox()
                            elseif Viewport.Object:IsA("BasePart") then
                                cf = Viewport.Object.CFrame
                                size = Viewport.Object.Size
                            else
                                return
                            end
                            local center = cf.Position
                            local rotY = delta.X * 0.5
                            local rotX = delta.Y * 0.5
                            local distance = Viewport.Distance
                            Viewport._Yaw = (Viewport._Yaw or 0) - delta.X * 0.3
                            Viewport._Pitch = math.clamp((Viewport._Pitch or 0) - delta.Y * 0.3, -80, 80)
                            Viewport.Camera.CFrame = CFrame.new(center)
                                * CFrame.Angles(0, math.rad(Viewport._Yaw), 0)
                                * CFrame.Angles(math.rad(Viewport._Pitch), 0, 0)
                                * CFrame.new(0, 0, distance)
                        end
                    end
                end)
                AddConnection(UserInputService.InputChanged, function(input)
                    if not Viewport.Object then
                        return
                    end
                    if not hovering then
                        return
                    end
                    if Viewport.Zoom and input.UserInputType == Enum.UserInputType.MouseWheel then
                        Viewport.Distance = math.clamp(Viewport.Distance - input.Position.Z * 2, Viewport.MinZoom, Viewport.MaxZoom)
                        Viewport:UpdateCamera()
                    end
                end)
                local activeTouches = {}
                AddConnection(UserInputService.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        activeTouches[input] = input.Position
                    end
                end)
                AddConnection(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        activeTouches[input] = nil
                        lastDist = nil
                    end
                end)
                AddConnection(UserInputService.InputChanged, function(input)
                    if not hovering then
                        return
                    end
                    if not Viewport.Zoom then
                        return
                    end
                    if input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                    if activeTouches[input] then
                        activeTouches[input] = input.Position
                    end
                    local touches = {}
                    for i, v in pairs(activeTouches) do
                        table.insert(touches, v)
                    end
                    if #touches == 2 then
                        local dist = (touches[1] - touches[2]).Magnitude
                        if lastDist then
                            local delta = dist - lastDist
                            Viewport.Distance = math.clamp(Viewport.Distance - delta * 0.15, Viewport.MinZoom, Viewport.MaxZoom)
                            Viewport:UpdateCamera()
                        end
                        lastDist = dist
                    end
                end)
                AddConnection(RunService.RenderStepped, function(dt)
                    if not Viewport.Object or dragging or not Viewport.Orbit then
                        return
                    end
                    Viewport.Object:PivotTo(Viewport.Object:GetPivot() * CFrame.Angles(0, math.rad(30 * dt), 0))
                end)

                Viewport:UpdateCamera()

                if ViewportConfig.Flag then
                    OrionLib.Flags[ViewportConfig.Flag] = Viewport
                end
                return Viewport
            end
            function ElementFunction:AddImage(ImageConfig)
                ImageConfig = ImageConfig or {}
                ImageConfig.Name = ImageConfig.Name or "Image"
                ImageConfig.Icon = ImageConfig.Icon or "rbxassetid://0"
                ImageConfig.Size = ImageConfig.Size or 20
                ImageConfig.Flag = ImageConfig.Flag or false
                ImageConfig.Visible = ImageConfig.Visible or true
                ImageConfig.Padding = ImageConfig.Padding or 8

                local Image = { Default = ImageConfig.Icon, Size = ImageConfig.Size, Type = "Image" }

                local function FrameHeight(iconSize)
                    return iconSize + ImageConfig.Padding * 2
                end

                local ImageFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Name = ImageConfig.Name,
                            Size = UDim2.new(1, 0, 0, FrameHeight(ImageConfig.Size)),
                            Visible = ImageConfig.Visible,
                            Parent = ItemParent,
                        }),
                        {
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Image", ImageConfig.Icon), {
                                    Name = "Icon",
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    Size = UDim2.new(0, ImageConfig.Size, 0, ImageConfig.Size),
                                    Position = UDim2.new(0.5, 0, 0.5, 0),
                                    BackgroundTransparency = 1,
                                }),
                                "TextDark"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        }
                    ),
                    "Second"
                )

                IconImage = ImageFrame:FindFirstChild("Icon", true)
                local function updateLayout(size)
                    if getgenv().Destroy then
                        return
                    end
                    if IconImage then
                        ImageFrame.Size = UDim2.new(1, 0, 0, FrameHeight(size))
                        IconImage.Size = UDim2.new(0, size, 0, size)
                        IconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
                    end
                end

                function Image:SetIcon(iconId)
                    if getgenv().Destroy then
                        return
                    end
                    if IconImage then
                        ApplyIconToObject(IconImage, tostring(iconId), Image.Size)
                    end
                end

                function Image:SetVisible(ToChange: boolean)
                    if getgenv().Destroy then
                        return
                    end
                    if ImageFrame then
                        ImageFrame.Visible = ToChange
                    end
                end

                function Image:SetColor(ToChange: Color3)
                    if getgenv().Destroy then
                        return
                    end
                    if IconImage then
                        IconImage.ImageColor3 = ToChange
                    end
                end

                function Image:SetRectOffset(ToChange: Vector2)
                    if getgenv().Destroy then
                        return
                    end
                    if IconImage then
                        IconImage.ImageRectOffset = ToChange
                    end
                end

                function Image:SetRectSize(ToChange: Vector2)
                    if getgenv().Destroy then
                        return
                    end
                    if IconImage then
                        IconImage.ImageRectSize = ToChange
                    end
                end

                function Image:SetScaleType(ScaleType: Enum.ScaleType)
                    if getgenv().Destroy then
                        return
                    end
                    if IconImage then
                        IconImage.ScaleType = ScaleType
                    end
                end

                function Image:SetTransparency(ToChange: number)
                    if getgenv().Destroy then
                        return
                    end
                    if IconImage then
                        IconImage.ImageTransparency = ToChange
                    end
                end

                function Image:SetSize(size)
                    if getgenv().Destroy then
                        return
                    end
                    updateLayout(tonumber(size))
                end

                if ImageConfig.Flag then
                    OrionLib.Flags[ImageConfig.Flag] = Image
                end
                return Image
            end
            function ElementFunction:AddVideo(VideoConfig)
                VideoConfig = VideoConfig or {}
                VideoConfig.Name = VideoConfig.Name or "VideoFrame"
                VideoConfig.Video = VideoConfig.Video or "rbxassetid://0"
                VideoConfig.Value = VideoConfig.Value or { ["Playing"] = false, ["Loop"] = false }
                VideoConfig.Size = VideoConfig.Size or 20
                VideoConfig.Flag = VideoConfig.Flag or false
                VideoConfig.Visible = VideoConfig.Visible ~= false
                VideoConfig.Padding = VideoConfig.Padding or 8
                local Video = { Default = VideoConfig.Icon, Size = VideoConfig.Size, Type = "Video" }

                local function FrameHeight(iconSize)
                    return iconSize + VideoConfig.Padding * 2
                end

                local vidAsset = OrionLib:MakeAsset({ Icon = VideoConfig.Video }, { Root = "OrionLibSave", Folder = "OrionVideo" })
                local VideoFrameTo = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Name = VideoConfig.Name,
                            Size = UDim2.new(1, 0, 0, FrameHeight(VideoConfig.Size)),
                            Visible = VideoConfig.Visible,
                            Parent = ItemParent,
                        }),
                        {
                            OrionLib:AddThemeObject(
                                SetProps(
                                    MakeElement(
                                        "RoundVideo",
                                        Color3.fromRGB(255, 255, 255),
                                        VideoConfig.Value.Loop ~= false,
                                        VideoConfig.Value.Playing or false,
                                        0,
                                        10
                                    ),
                                    {
                                        Name = "Video",
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        Video = vidAsset.Icon,
                                        Size = UDim2.new(0, VideoConfig.Size, 0, VideoConfig.Size),
                                        Position = UDim2.new(0.5, 0, 0.5, 0),
                                        BackgroundTransparency = 1,
                                    }
                                ),
                                "TextDark"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        }
                    ),
                    "Second"
                )

                VideoFrame = VideoFrameTo:FindFirstChildWhichIsA("VideoFrame", true)
                local function updateLayout(size)
                    if getgenv().Destroy then
                        return
                    end
                    if VideoFrame then
                        VideoFrameTo.Size = UDim2.new(1, 0, 0, FrameHeight(size))
                        VideoFrame.Size = UDim2.new(0, size + 160, 0, size)
                        VideoFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                    end
                end

                function Video:SetHeight(ToChange: number)
                    if getgenv().Destroy then
                        return
                    end
                    if VideoFrame then
                        VideoFrame.Height = tonumber(ToChange)
                        updateLayout(tonumber(ToChange))
                    end
                end

                function Video:SetVideo(ToChange)
                    if getgenv().Destroy then
                        return
                    end
                    if VideoFrame then
                        VideoConfig.Video = ToChange or VideoConfig.Video
                        local VideoAsset = OrionLib:MakeAsset({ Icon = VideoConfig.Video }, { Root = "OrionLibSave", Folder = "OrionVideo" })
                        VideoFrame.Video = VideoAsset and VideoAsset.Icon or ResolveImageLikeAsset(VideoConfig.Video)
                    end
                end

                function Video:SetVisible(ToChange: boolean)
                    if getgenv().Destroy then
                        return
                    end
                    if VideoFrame then
                        VideoFrame.Visible = ToChange
                    end
                end

                function Video:SetPlay(ToChange: boolean)
                    if getgenv().Destroy then
                        return
                    end
                    if VideoFrame then
                        VideoFrame.Playing = ToChange
                    end
                end

                function Video:SetLoop(ToChange: boolean)
                    if getgenv().Destroy then
                        return
                    end
                    if VideoFrame then
                        VideoFrame.Looped = ToChange
                    end
                end

                function Video:SetVolume(ToChange: number)
                    if getgenv().Destroy then
                        return
                    end
                    if VideoFrame then
                        VideoFrame.Volume = ToChange
                    end
                end

                function Video:SetSize(size)
                    if getgenv().Destroy then
                        return
                    end
                    updateLayout(tonumber(size))
                end

                function Video:Play()
                    if getgenv().Destroy then
                        return
                    end
                    if VideoFrame then
                        VideoFrame:Play()
                    end
                end

                function Video:Stop()
                    if getgenv().Destroy then
                        return
                    end
                    if VideoFrame then
                        VideoFrame:Pause()
                    end
                end

                if VideoConfig.Flag then
                    OrionLib.Flags[VideoConfig.Flag] = Video
                end
                return Video
            end
            function ElementFunction:AddToggle(ToggleConfig)
                ToggleConfig = ToggleConfig or {}
                ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Callback = ToggleConfig.Callback or function() end
                ToggleConfig.Color = ToggleConfig.Color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250))
                ToggleConfig.Visible = ToggleConfig.Visible or true
                ToggleConfig.Disabled = ToggleConfig.Disabled or false
                ToggleConfig.Type = ToggleConfig.Type or "CheckBox"
                ToggleConfig.Flag = ToggleConfig.Flag or nil
                ToggleConfig.Save = ToggleConfig.Save or false

                local Toggle = {
                    Type = "Toggle",
                    Value = ToggleConfig.Default,
                    Save = ToggleConfig.Save,
                    Mode = ToggleConfig.Type,
                    Visible = ToggleConfig.Visible,
                    Disabled = ToggleConfig.Disabled,
                    ["__DisplayName"] = {},
                }

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                })
                local ToggleBox
                if ToggleConfig.Type == "Switch" then
                    ToggleBox = SetChildren(
                        SetProps(MakeElement("RoundFrame", GetThemeValue("Divider", OrionLib.Themes.Default.Divider), 0, 12), {
                            Size = UDim2.new(0, 40, 0, 20),
                            Position = UDim2.new(1, -8, 0.5, 0),
                            AnchorPoint = Vector2.new(1, 0.5),
                            BackgroundColor3 = GetThemeValue("Divider", OrionLib.Themes.Default.Divider),
                            Name = "Switch",
                        }),
                        {
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
                                Size = UDim2.new(0, 18, 0, 18),
                                Position = UDim2.new(0, 1, 0.48, 0),
                                AnchorPoint = Vector2.new(0, 0.5),
                                Name = "Knob",
                            }),
                        }
                    )
                else
                    ToggleBox = SetChildren(
                        SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 0, 4), {
                            Size = UDim2.new(0, 24, 0, 24),
                            Position = UDim2.new(1, -24, 0.5, 0),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundColor3 = GetThemeValue("Divider", OrionLib.Themes.Default.Divider),
                            Name = "Check",
                        }),
                        {
                            SetProps(MakeElement("Stroke"), {
                                Color = GetThemeValue("Stroke", OrionLib.Themes.Default.Stroke),
                                Name = "Stroke",
                                Transparency = 0.5,
                            }),
                            SetProps(MakeElement("Image", "check"), {
                                Size = UDim2.new(0, 8, 0, 8),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                ImageColor3 = Color3.fromRGB(255, 255, 255),
                                ImageTransparency = 1,
                                Name = "Ico",
                            }),
                        }
                    )
                end
                local ToggleFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(1, 0, 0, 38),
                            Parent = ItemParent,
                        }),
                        {
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", ToggleConfig.Name, 15), {
                                    Size = UDim2.new(1, -12, 1, 0),
                                    Position = UDim2.new(0, 12, 0, 0),
                                    Font = Enum.Font.GothamBold,
                                    Name = "Content",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            ToggleBox,
                            Click,
                        }
                    ),
                    "Second"
                )
                Toggle.Frame = ToggleFrame
                Toggle.ClickArea = Click
                if ToggleConfig.Glass or ToggleConfig.LiquidGlass or WindowConfig.GlassElements then
                    Toggle.Glass = ApplyLiquidGlass(ToggleFrame, ToggleConfig.GlassConfig or ToggleConfig.LiquidGlassConfig or {
                        Color = ToggleConfig.GlassColor or GetThemeValue("Second", Color3.fromRGB(25, 28, 38)),
                        Accent = ToggleConfig.Color,
                        BackgroundTransparency = 0.38,
                        Radius = 11,
                        StrokeTransparency = 0.8,
                        HighlightTransparency = 0.92,
                        Shadow = false,
                    })
                    ApplyLiquidGlass(ToggleBox, {
                        Color = ToggleConfig.Color,
                        Accent = ToggleConfig.Color,
                        BackgroundTransparency = 0.48,
                        Radius = ToggleConfig.Type == "Switch" and 12 or 6,
                        StrokeTransparency = 0.82,
                        HighlightTransparency = 0.93,
                        Shadow = false,
                    })
                    Click.ZIndex = 40
                end

                function Toggle:UpdateTweenKeyBindToggles(Object, bool)
                    if Object:FindFirstChild("Switch") and Object.Switch:FindFirstChild("Knob") then
                        TweenService
                            :Create(Object.Switch, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                                BackgroundColor3 = bool and ToggleConfig.Color or GetThemeValue("Divider", OrionLib.Themes.Default.Divider),
                            })
                            :Play()
                        TweenService:Create(Object.Switch.Knob, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                            Position = bool and UDim2.new(1, -19, 0.48, 0) or UDim2.new(0, 1, 0.48, 0),
                        }):Play()
                    end
                    if Object:FindFirstChild("Check") then
                        TweenService
                            :Create(Object.Check, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                                BackgroundColor3 = bool and ToggleConfig.Color or GetThemeValue("Divider", OrionLib.Themes.Default.Divider),
                            })
                            :Play()
                        TweenService
                            :Create(Object.Check.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                                Color = bool and ToggleConfig.Color or GetThemeValue("Stroke", OrionLib.Themes.Default.Stroke),
                            })
                            :Play()
                        TweenService:Create(Object.Check.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                            ImageTransparency = bool and 0 or 1,
                            Size = bool and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8),
                        }):Play()
                    end
                end

                local function GetUniqueToggleName(baseName: string)
                    getgenv().ToggleNameCount = getgenv().ToggleNameCount or {}
                    if not getgenv().ToggleNameCount[baseName] then
                        getgenv().ToggleNameCount[baseName] = 1
                        return baseName
                    else
                        getgenv().ToggleNameCount[baseName] += 1
                        return string.format("%s (%d)", baseName, getgenv().ToggleNameCount[baseName])
                    end
                end

                local function UpdateLayout()
                    local hasBind = ToggleFrame:FindFirstChild("ButtonKey")
                    if hasBind then
                        if ToggleFrame:FindFirstChild("Switch") then
                            ToggleFrame.Switch.Position = UDim2.new(1, -60, 0.5, 0)
                        end
                        if ToggleFrame:FindFirstChild("Check") then
                            ToggleFrame.Check.Position = UDim2.new(1, -50, 0.5, 0)
                        end
                    end
                end

                local function AddTogglesKeyBind(name: string)
                    local KeyBindAdd = ToggleFrame:Clone()
                    KeyBindAdd.Parent = Orion.KeyBind.ItemContainer
                    local displayName = GetUniqueToggleName(name)
                    getgenv().TogglesSaveTable[displayName] = KeyBindAdd
                    Toggle.__DisplayName = displayName
                    if KeyBindAdd then
                        if KeyBindAdd:FindFirstChild("ButtonKey") then
                            KeyBindAdd:FindFirstChild("ButtonKey"):Destroy()
                        end
                        if KeyBindAdd:FindFirstChild("TextButton") then
                            AddConnection(KeyBindAdd:FindFirstChild("TextButton").MouseButton1Up, function()
                                Toggle:Set(not Toggle.Value)
                            end)
                        end
                        if KeyBindAdd:FindFirstChild("Frame") and KeyBindAdd.Frame:FindFirstChild("Value") then
                            AddConnection(KeyBindAdd.Frame.Value:GetPropertyChangedSignal("Text"), function()
                                local width = KeyBindAdd.Frame.Value.TextBounds.X + 20
                                TweenService:Create(KeyBindAdd.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = UDim2.new(0, width, 0, 24) }):Play()
                            end)
                        end
                    end
                end

                function Toggle:Set(Value)
                    if getgenv().Destroy or ToggleConfig.Disabled then
                        return
                    end
                    Toggle.Value = Value
                    Toggle:UpdateTweenKeyBindToggles(ToggleFrame, Toggle.Value)
                    if Toggle.__DisplayName then
                        local data = getgenv().TogglesSaveTable[Toggle.__DisplayName]
                        if data then
                            Toggle:UpdateTweenKeyBindToggles(data, Toggle.Value)
                        end
                    end
                    OrionLib:SafeScript(ToggleConfig.Callback, Toggle.Value)
                end

                function Toggle:SetMode(newMode)
                    if getgenv().Destroy then
                        return
                    end
                    if not newMode then
                        return
                    end

                    Toggle.Mode = newMode
                    ToggleConfig.Type = newMode

                    if ToggleFrame:FindFirstChild("Switch") then
                        ToggleFrame.Switch:Destroy()
                    end
                    if ToggleFrame:FindFirstChild("Check") then
                        ToggleFrame.Check:Destroy()
                    end

                    if newMode == "Switch" then
                        local newSwitch = SetChildren(
                            SetProps(MakeElement("RoundFrame", GetThemeValue("Divider", OrionLib.Themes.Default.Divider), 0, 12), {
                                Size = UDim2.new(0, 40, 0, 20),
                                Position = UDim2.new(1, -8, 0.5, 0),
                                AnchorPoint = Vector2.new(1, 0.5),
                                Name = "Switch",
                                Parent = ToggleFrame,
                            }),
                            {
                                SetProps(MakeElement("RoundFrame", Color3.new(1, 1, 1), 0, 10), {
                                    Size = UDim2.new(0, 18, 0, 18),
                                    Position = UDim2.new(0, 1, 0.5, 0),
                                    AnchorPoint = Vector2.new(0, 0.5),
                                    Name = "Knob",
                                }),
                            }
                        )
                    else
                        local newCheck = SetChildren(
                            SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 0, 4), {
                                Size = UDim2.new(0, 24, 0, 24),
                                Position = UDim2.new(1, -24, 0.5, 0),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Name = "Check",
                                Parent = ToggleFrame,
                            }),
                            {
                                SetProps(MakeElement("Image", "check"), {
                                    Size = UDim2.new(0, 8, 0, 8),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    Position = UDim2.new(0.5, 0, 0.5, 0),
                                    ImageTransparency = Toggle.Value and 0 or 1,
                                    Name = "Ico",
                                }),
                            }
                        )
                    end
                    Toggle:UpdateTweenKeyBindToggles(ToggleFrame, Toggle.Value)
                    UpdateLayout()
                end

                function Toggle:SetDisabled(state)
                    if getgenv().Destroy then
                        return
                    end
                    ToggleConfig.Disabled = state
                    Toggle.Disabled = state
                    if ToggleFrame then
                        ToggleFrame.BackgroundTransparency = state and 0.6 or 0
                        if ToggleFrame:FindFirstChild("Content") then
                            ToggleFrame.Content.TextTransparency = state and 0.5 or 0
                        end
                    end
                    if Click then
                        Click.Active = not state
                        Click.AutoButtonColor = not state
                    end
                    if ToggleBox then
                        if ToggleConfig.Type == "Switch" and ToggleBox:FindFirstChild("Knob") then
                            TweenService
                                :Create(ToggleBox, TweenInfo.new(0.2), {
                                    BackgroundColor3 = state and Color3.fromRGB(120, 120, 120)
                                        or (Toggle.Value and ToggleConfig.Color or GetThemeValue("Divider", OrionLib.Themes.Default.Divider)),
                                })
                                :Play()
                        elseif ToggleBox:FindFirstChild("Stroke") then
                            TweenService
                                :Create(ToggleBox.Stroke, TweenInfo.new(0.2), {
                                    Color = state and Color3.fromRGB(120, 120, 120)
                                        or (Toggle.Value and ToggleConfig.Color or GetThemeValue("Stroke", OrionLib.Themes.Default.Stroke)),
                                })
                                :Play()
                        end
                    end
                    if Toggle.__DisplayName and getgenv().TogglesSaveTable[Toggle.__DisplayName] then
                        local data = getgenv().TogglesSaveTable[Toggle.__DisplayName]
                        if data then
                            if data:FindFirstChild("TextButton", true) then
                                data:FindFirstChild("TextButton", true).Active = not state
                                data:FindFirstChild("TextButton", true).AutoButtonColor = not state
                            end
                            data.BackgroundTransparency = state and 0.6 or 0
                            if data:FindFirstChild("Content", true) then
                                data:FindFirstChild("Content", true).TextTransparency = state and 0.5 or 0
                            end
                        end
                    end
                end

                function Toggle:SetVisible(state)
                    if getgenv().Destroy then
                        return
                    end
                    Toggle.Visible = state
                    if ToggleFrame then
                        ToggleFrame.Visible = state
                    end
                    if Toggle.__DisplayName and getgenv().TogglesSaveTable[Toggle.__DisplayName] then
                        local data = getgenv().TogglesSaveTable[Toggle.__DisplayName]
                        if data then
                            data.Visible = state
                        end
                    end
                end

                function Toggle:SetCallback(ToChange)
                    if getgenv().Destroy or ToggleConfig.Disabled then
                        return
                    end
                    ToggleConfig.Callback = ToChange
                end

                function Toggle:SetText(ToChange)
                    if getgenv().Destroy or ToggleConfig.Disabled then
                        return
                    end
                    if ToggleFrame and ToggleFrame:FindFirstChild("Content") then
                        ToggleFrame.Content.Text = ToChange
                    end
                    if Toggle.__DisplayName then
                        if getgenv().TogglesSaveTable[Toggle.__DisplayName] then
                            local FrameToHere = getgenv().TogglesSaveTable[Toggle.__DisplayName]
                            if FrameToHere and FrameToHere:FindFirstChild("Content", true) then
                                FrameToHere:FindFirstChild("Content", true).Text = ToChange
                            end
                        end
                    end
                end

                if ToggleConfig.Default == true then
                    Toggle:Set(true)
                end

                AddConnection(Click.MouseButton1Up, function()
                    if ToggleConfig.Disabled then
                        return
                    end
                    Toggle:Set(not Toggle.Value)
                end)

                function Toggle:AddBind(BindConfig)
                    BindConfig = BindConfig or {}
                    BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
                    BindConfig.Hold = BindConfig.Hold or false
                    BindConfig.Flag = BindConfig.Flag or nil
                    BindConfig.Save = BindConfig.Save or false

                    local Bind = {
                        Value = BindConfig.Default.Name or BindConfig.Default,
                        Type = "Bind",
                        Save = BindConfig.Save,
                        Binding = false,
                        Hold = BindConfig.Hold == true,
                    }
                    local Holding = false

                    local Click = SetProps(MakeElement("Button"), {
                        Size = UDim2.new(0, 30, 0, 24),
                        Position = (ToggleConfig.Type == "Switch" and UDim2.new(1, -55, 0.5, 0) or UDim2.new(1, -48, 0.5, 0)),
                        AnchorPoint = Vector2.new(1, 0.5),
                        Parent = ToggleFrame,
                        Name = "ButtonKey",
                        ZIndex = 4,
                    })

                    local BindBox = OrionLib:AddThemeObject(
                        SetChildren(
                            SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
                                Size = UDim2.new(0, 30, 0, 24),
                                Position = Click.Position,
                                AnchorPoint = Vector2.new(1, 0.5),
                                Parent = ToggleFrame,
                                ZIndex = 1,
                            }),
                            {
                                OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                                OrionLib:AddThemeObject(
                                    SetProps(MakeElement("Label", Bind.Value, 14), {
                                        Size = UDim2.new(1, 0, 1, 0),
                                        Font = Enum.Font.GothamBold,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        Name = "Value",
                                        ZIndex = 1,
                                    }),
                                    "Text"
                                ),
                            }
                        ),
                        "Main"
                    )

                    AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
                        local width = BindBox.Value.TextBounds.X + 20
                        TweenService:Create(BindBox, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = UDim2.new(0, width, 0, 24) }):Play()
                        TweenService:Create(Click, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = UDim2.new(0, width, 0, 24) }):Play()
                    end)

                    AddConnection(Click.InputEnded, function(Input)
                        if ToggleConfig.Disabled then
                            return
                        end
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                            if Bind.Binding then
                                return
                            end
                            Bind.Binding = true
                            BindBox.Value.Text = "..."
                        end
                    end)

                    AddConnection(UserInputService.InputBegan, function(Input, gp)
                        if ToggleConfig.Disabled then
                            return
                        end
                        if gp then
                            return
                        end
                        if UserInputService:GetFocusedTextBox() then
                            return
                        end
                        if Bind.Binding then
                            if Input.KeyCode ~= Enum.KeyCode.Unknown then
                                Bind.Value = Input.KeyCode.Name
                                BindBox.Value.Text = Bind.Value
                                Bind.Binding = false
                                if Toggle.__DisplayName then
                                    if getgenv().TogglesSaveTable[Toggle.__DisplayName] then
                                        local FrameToHere = getgenv().TogglesSaveTable[Toggle.__DisplayName]
                                        if FrameToHere and FrameToHere:FindFirstChild("Frame") and FrameToHere.Frame:FindFirstChild("Value") then
                                            FrameToHere.Frame:FindFirstChild("Value").Text = Input.KeyCode.Name
                                        end
                                    end
                                end
                            end
                            return
                        end
                        if Input.KeyCode.Name == Bind.Value then
                            if Bind.Hold then
                                Holding = true
                                Toggle:Set(true)
                            else
                                Toggle:Set(not Toggle.Value)
                            end
                        end
                    end)

                    AddConnection(UserInputService.InputEnded, function(Input, gp)
                        if ToggleConfig.Disabled then
                            return
                        end
                        if gp then
                            return
                        end
                        if Bind.Hold and Holding and Input.KeyCode.Name == Bind.Value then
                            Holding = false
                            Toggle:Set(false)
                        end
                    end)

                    function Bind:Set(Key)
                        if ToggleConfig.Disabled then
                            return
                        end
                        Bind.Value = Key.Name or Key
                        BindBox.Value.Text = Bind.Value
                        if Toggle.__DisplayName then
                            if getgenv().TogglesSaveTable[Toggle.__DisplayName] then
                                local FrameToHere = getgenv().TogglesSaveTable[Toggle.__DisplayName]
                                if FrameToHere and FrameToHere:FindFirstChild("Frame") and FrameToHere.Frame:FindFirstChild("Value") then
                                    FrameToHere.Frame:FindFirstChild("Value").Text = Bind.Value
                                end
                            end
                        end
                    end

                    function Bind:SetHold(state)
                        Bind.Hold = state == true
                    end

                    AddTogglesKeyBind(ToggleConfig.Name)

                    if BindConfig.Flag then
                        OrionLib.Flags[BindConfig.Flag] = Bind
                    end
                    return Bind
                end
                if ToggleConfig.Flag then
                    OrionLib.Flags[ToggleConfig.Flag] = Toggle
                end
                return Toggle
            end
            function ElementFunction:AddSlider(SliderConfig)
                SliderConfig = SliderConfig or {}
                SliderConfig.Name = SliderConfig.Name or "Slider"
                SliderConfig.Visible = SliderConfig.Visible or true
                SliderConfig.Disabled = SliderConfig.Disabled or false
                SliderConfig.Min = SliderConfig.Min or 0
                SliderConfig.Max = SliderConfig.Max or 100
                SliderConfig.Increment = SliderConfig.Increment or 1
                SliderConfig.Default = SliderConfig.Default or 50
                SliderConfig.Callback = SliderConfig.Callback or function() end
                SliderConfig.ValueName = SliderConfig.ValueName or ""
                SliderConfig.Color = SliderConfig.Color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250))
                SliderConfig.Flag = SliderConfig.Flag or nil
                SliderConfig.Save = SliderConfig.Save or false

                local Slider = {
                    Type = "Slider",
                    Value = SliderConfig.Default,
                    Save = SliderConfig.Save,
                    Disabled = SliderConfig.Disabled,
                    Visible = SliderConfig.Visible,
                }
                local Dragging = false

                local SliderDrag = SetChildren(
                    SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
                        Size = UDim2.new(0, 0, 1, 0),
                        BackgroundTransparency = 0.3,
                        ClipsDescendants = true,
                    }),
                    {
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Label", "value", 13), {
                                Size = UDim2.new(1, -12, 0, 14),
                                Position = UDim2.new(0, 12, 0, 6),
                                Font = Enum.Font.GothamBold,
                                Name = "Value",
                                TextTransparency = 0,
                            }),
                            "Text"
                        ),
                    }
                )

                local SliderBar = SetChildren(
                    SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
                        Size = UDim2.new(1, -24, 0, 26),
                        Position = UDim2.new(0, 12, 0, 30),
                        BackgroundTransparency = 0.9,
                    }),
                    {
                        SetProps(MakeElement("Stroke"), { Color = SliderConfig.Color }),
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Label", "value", 13), {
                                Size = UDim2.new(1, -12, 0, 14),
                                Position = UDim2.new(0, 12, 0, 6),
                                Font = Enum.Font.GothamBold,
                                Name = "Value",
                                TextTransparency = 0.8,
                            }),
                            "Text"
                        ),
                        SliderDrag,
                    }
                )

                local SliderFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
                            Size = UDim2.new(1, 0, 0, 65),
                            Visible = SliderConfig.Visible,
                            Parent = ItemParent,
                        }),
                        {
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", SliderConfig.Name, 15), {
                                    Size = UDim2.new(1, -12, 0, 14),
                                    Position = UDim2.new(0, 12, 0, 10),
                                    Font = Enum.Font.GothamBold,
                                    Name = "Content",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            SliderBar,
                        }
                    ),
                    "Second"
                )

                local function DraggingUi(parent)
                    parent.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                            Dragging = true
                        end
                    end)

                    parent.InputEnded:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                            Dragging = false
                        end
                    end)
                end

                DraggingUi(SliderBar)
                AddConnection(UserInputService.InputChanged, function(Input)
                    if Dragging and not Slider.Disabled then
                        local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                        Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale))
                    end
                end)

                local function Update()
                    if getgenv().Destroy then
                        return
                    end
                    TweenService:Create(
                        SliderDrag,
                        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { Size = UDim2.fromScale((Slider.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1) }
                    ):Play()
                    SliderBar.Value.Text = tostring(Slider.Value) .. " " .. SliderConfig.ValueName
                    SliderDrag.Value.Text = tostring(Slider.Value) .. " " .. SliderConfig.ValueName
                    OrionLib:SafeScript(SliderConfig.Callback, Slider.Value)
                end

                function Slider:Set(Value)
                    if getgenv().Destroy then
                        return
                    end
                    Slider.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                    Update()
                end

                function Slider:SetDisabled(state)
                    if getgenv().Destroy then
                        return
                    end
                    Slider.Disabled = state
                    SliderConfig.Disabled = state
                    if SliderFrame then
                        TweenService:Create(SliderFrame, TweenInfo.new(0.2), { BackgroundTransparency = state and 0.5 or 0 }):Play()
                    end
                    if SliderBar then
                        TweenService:Create(SliderBar, TweenInfo.new(0.2), { BackgroundTransparency = state and 0.95 or 0.9 }):Play()
                    end
                    if SliderFrame:FindFirstChild("Content") then
                        SliderFrame.Content.TextTransparency = state and 0.5 or 0
                    end
                end

                function Slider:SetVisible(state)
                    if getgenv().Destroy then
                        return
                    end
                    Slider.Visible = state
                    if SliderFrame then
                        SliderFrame.Visible = state
                    end
                end

                function Slider:SetMax(Value: number)
                    if getgenv().Destroy then
                        return
                    end
                    local MaxToFix = tonumber(Value) or 5
                    SliderConfig.Max = (MaxToFix > 0 and MaxToFix or 5)
                    Slider.Value = math.clamp(Round(Slider.Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                    Update()
                end

                function Slider:SetMin(Value: number)
                    if getgenv().Destroy then
                        return
                    end
                    SliderConfig.Min = tonumber(Value) or 5
                    Slider.Value = math.clamp(Round(Slider.Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                    Update()
                end

                function Slider:SetText(ToChange)
                    if getgenv().Destroy then
                        return
                    end
                    if SliderFrame and SliderFrame:FindFirstChild("Content") then
                        SliderFrame.Content.Text = ToChange
                    end
                end

                function Slider:SetTextValue(ToChange)
                    if getgenv().Destroy then
                        return
                    end
                    SliderConfig.ValueName = ToChange
                    SliderBar.Value.Text = tostring(Slider.Value) .. " " .. SliderConfig.ValueName
                    SliderDrag.Value.Text = tostring(Slider.Value) .. " " .. SliderConfig.ValueName
                end

                function Slider:SetCallback(ToChange)
                    if getgenv().Destroy then
                        return
                    end
                    SliderConfig.Callback = ToChange
                end

                if SliderConfig.Disabled then
                    Slider:SetDisabled(true)
                end
                if SliderConfig.Visible == false then
                    Slider:SetVisible(false)
                end

                Slider.Value = math.clamp(Slider.Value, SliderConfig.Min, SliderConfig.Max)
                TweenService:Create(
                    SliderDrag,
                    TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Size = UDim2.fromScale((Slider.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1) }
                ):Play()
                SliderBar.Value.Text = tostring(Slider.Value) .. " " .. SliderConfig.ValueName
                SliderDrag.Value.Text = tostring(Slider.Value) .. " " .. SliderConfig.ValueName

                if SliderConfig.Flag then
                    OrionLib.Flags[SliderConfig.Flag] = Slider
                end
                return Slider
            end
            function ElementFunction:AddDropdown(DropdownConfig)
                DropdownConfig = DropdownConfig or {}
                DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
                DropdownConfig.Options = DropdownConfig.Options or {}
                DropdownConfig.Multi = DropdownConfig.Multi or false
                DropdownConfig.MultiTrue = DropdownConfig.MultiTrue or false
                DropdownConfig.Default = DropdownConfig.Default or (DropdownConfig.Multi and {} or nil)
                DropdownConfig.Callback = DropdownConfig.Callback or function() end
                DropdownConfig.Flag = DropdownConfig.Flag or nil
                DropdownConfig.Save = DropdownConfig.Save or false
                DropdownConfig.Visible = DropdownConfig.Visible ~= false
                DropdownConfig.Disabled = DropdownConfig.Disabled or false

                if DropdownConfig.MultiTrue then
                    DropdownConfig.Multi = true
                end

                local Dropdown = {
                    Value = DropdownConfig.Default,
                    Multi = DropdownConfig.Multi,
                    Options = {},
                    RawOptions = DropdownConfig.Options,
                    Buttons = {},
                    Toggled = false,
                    Type = "Dropdown",
                    Save = DropdownConfig.Save,
                    Disabled = DropdownConfig.Disabled or false,
                    Visible = DropdownConfig.Visible ~= false,
                }

                local MaxElementsHeight = 250

                local function GetKeyList(tbl)
                    local keys = {}
                    for k, v in pairs(tbl) do
                        if type(k) == "string" then
                            table.insert(keys, k)
                        else
                            table.insert(keys, v)
                        end
                    end
                    return keys
                end

                Dropdown.Options = GetKeyList(DropdownConfig.Options)

                if DropdownConfig.Multi then
                    if type(Dropdown.Value) ~= "table" then
                        Dropdown.Value = {}
                    end

                    if DropdownConfig.MultiTrue then
                        for _, v in ipairs(Dropdown.Options) do
                            if Dropdown.Value[v] == nil then
                                Dropdown.Value[v] = false
                            end
                        end
                    end
                else
                    if Dropdown.Value ~= nil and not table.find(Dropdown.Options, Dropdown.Value) then
                        Dropdown.Value = nil
                    end
                end

                local DropdownList = MakeElement("List")

                local DropdownContainer = OrionLib:AddThemeObject(
                    SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(40, 40, 40), 4), { DropdownList }), {
                        Parent = ItemParent,
                        Position = UDim2.new(0, 0, 0, 38),
                        Size = UDim2.new(1, 0, 1, -38),
                        ClipsDescendants = true,
                    }),
                    "Divider"
                )

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                })

                local DropdownFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(1, 0, 0, 38),
                            Parent = ItemParent,
                            ClipsDescendants = true,
                        }),
                        {
                            DropdownContainer,
                            SetProps(
                                SetChildren(MakeElement("TFrame"), {
                                    OrionLib:AddThemeObject(
                                        SetProps(MakeElement("Label", DropdownConfig.Name, 15), {
                                            Size = UDim2.new(1, -12, 1, 0),
                                            Position = UDim2.new(0, 12, 0, 0),
                                            Font = Enum.Font.GothamBold,
                                            Name = "Content",
                                        }),
                                        "Text"
                                    ),

                                    OrionLib:AddThemeObject(
                                        SetProps(MakeElement("Image", "chevron-down"), {
                                            Size = UDim2.new(0, 20, 0, 20),
                                            AnchorPoint = Vector2.new(0, 0.5),
                                            Position = UDim2.new(1, -30, 0.5, 0),
                                            ImageColor3 = Color3.fromRGB(240, 240, 240),
                                            Name = "Ico",
                                        }),
                                        "TextDark"
                                    ),

                                    OrionLib:AddThemeObject(
                                        SetProps(MakeElement("Label", "...", 13), {
                                            Size = UDim2.new(1, -40, 1, 0),
                                            Font = Enum.Font.Gotham,
                                            Name = "Selected",
                                            TextXAlignment = Enum.TextXAlignment.Right,
                                        }),
                                        "TextDark"
                                    ),

                                    OrionLib:AddThemeObject(
                                        SetProps(MakeElement("Frame"), {
                                            Size = UDim2.new(1, 0, 0, 1),
                                            Position = UDim2.new(0, 0, 1, -1),
                                            Name = "Line",
                                            Visible = false,
                                        }),
                                        "Stroke"
                                    ),

                                    Click,
                                }),
                                {
                                    Size = UDim2.new(1, 0, 0, 38),
                                    ClipsDescendants = true,
                                    Name = "F",
                                }
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            MakeElement("Corner"),
                        }
                    ),
                    "Second"
                )

                AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                    DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
                end)

                local function AddOptions(Options)
                    for k, v in pairs(Options) do
                        local OptionVal = (type(k) == "string" and k) or v
                        local Data = (type(k) == "string" and v) or {}
                        local HasData = (type(v) == "table")

                        local TitleStr = HasData and (Data.Title or Data.title or OptionVal) or OptionVal
                        local DescStr = HasData and (Data.Desc or Data.desc or nil) or nil
                        local IconStr = HasData and (Data.Icon or Data.icon or nil) or nil
                        local ThumbStr = HasData and (Data.Thumbnail or Data.thumbnail or nil) or nil

                        local ButtonHeight = (ThumbStr and 65) or ((DescStr or IconStr) and 45) or 30

                        local Elements = {
                            MakeElement("Corner", 0, 6),
                        }

                        local TextLeftPadding = 8

                        if ThumbStr then
                            local strokeProps = {
                                Color = Color3.fromRGB(60, 60, 60),
                                Thickness = 1,
                                Transparency = 0.5,
                            }

                            table.insert(
                                Elements,
                                SetProps(
                                    SetChildren(MakeElement("Image", ThumbStr), {
                                        MakeElement("Corner", 0, 4),
                                        SetProps(MakeElement("Stroke"), strokeProps),
                                    }),
                                    {
                                        Size = UDim2.new(0, 55, 0, 55),
                                        AnchorPoint = Vector2.new(0, 0.5),
                                        Position = UDim2.new(0, 6, 0.5, 0),
                                        ImageTransparency = 0,
                                        Name = "Thumbnail",
                                        ScaleType = Enum.ScaleType.Crop,
                                        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                                    }
                                )
                            )
                            TextLeftPadding = 70
                        elseif IconStr then
                            table.insert(
                                Elements,
                                SetProps(MakeElement("Image", IconStr), {
                                    Size = UDim2.new(0, 26, 0, 26),
                                    Position = UDim2.new(0, 8, 0.5, -13),
                                    ImageTransparency = 0.4,
                                    Name = "Icon",
                                })
                            )
                            TextLeftPadding = 42
                        end

                        local TitleY = DescStr and 6 or 0
                        if ThumbStr and DescStr then
                            TitleY = 12
                        end

                        table.insert(
                            Elements,
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", TitleStr, 13, 0.4), {
                                    Position = UDim2.new(0, TextLeftPadding, 0, TitleY),
                                    Size = UDim2.new(1, -(TextLeftPadding + 10), (DescStr and 0 or 1), (DescStr and 16 or 0)),
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    Name = "Title",
                                    Font = Enum.Font.GothamBold,
                                    ClipsDescendants = true,
                                }),
                                "Text"
                            )
                        )

                        if DescStr then
                            local DescY = ThumbStr and 30 or 22
                            table.insert(
                                Elements,
                                OrionLib:AddThemeObject(
                                    SetProps(MakeElement("Label", DescStr, 11, 0.4), {
                                        Position = UDim2.new(0, TextLeftPadding, 0, DescY),
                                        Size = UDim2.new(1, -(TextLeftPadding + 10), 0, 14),
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        Name = "Desc",
                                        Font = Enum.Font.Gotham,
                                        TextColor3 = Color3.fromRGB(150, 150, 150),
                                        ClipsDescendants = true,
                                    }),
                                    "Text"
                                )
                            )
                        end

                        local OptionBtn = OrionLib:AddThemeObject(
                            SetProps(SetChildren(MakeElement("Button", Color3.fromRGB(40, 40, 40)), Elements), {
                                Parent = DropdownContainer,
                                Size = UDim2.new(1, 0, 0, ButtonHeight),
                                BackgroundTransparency = 1,
                                ClipsDescendants = true,
                            }),
                            "Divider"
                        )

                        AddConnection(OptionBtn.MouseButton1Click, function()
                            if Dropdown.Disabled then
                                return
                            end
                            Dropdown:Set(OptionVal)
                        end)

                        Dropdown.Buttons[OptionVal] = OptionBtn
                    end
                end

                function Dropdown:SetDisabled(state)
                    if getgenv().Destroy then
                        return
                    end
                    Dropdown.Disabled = state
                    DropdownConfig.Disabled = state
                    if state and Dropdown.Toggled then
                        Dropdown.Toggled = false
                        TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.15), { Rotation = 0 }):Play()
                        TweenService:Create(DropdownFrame, TweenInfo.new(0.15), {
                            Size = UDim2.new(1, 0, 0, 38),
                        }):Play()
                    end
                    if DropdownFrame then
                        TweenService:Create(DropdownFrame, TweenInfo.new(0.2), {
                            BackgroundTransparency = state and 0.5 or 0,
                        }):Play()
                    end
                    if DropdownFrame:FindFirstChild("F") and DropdownFrame.F:FindFirstChild("Content") then
                        DropdownFrame.F.Content.TextTransparency = state and 0.5 or 0
                    end
                    if DropdownFrame.F:FindFirstChild("Selected") then
                        DropdownFrame.F.Selected.TextTransparency = state and 0.5 or 0
                    end
                end

                function Dropdown:SetVisible(state)
                    if getgenv().Destroy then
                        return
                    end
                    Dropdown.Visible = state
                    DropdownConfig.Visible = state
                    if DropdownFrame then
                        DropdownFrame.Visible = state
                    end
                end

                function Dropdown:SetCallback(call)
                    if getgenv().Destroy then
                        return
                    end
                    DropdownConfig.Callback = call
                end

                function Dropdown:Refresh(Options, Delete)
                    if getgenv().Destroy then
                        return
                    end
                    if Delete then
                        for _, v in pairs(Dropdown.Buttons) do
                            v:Destroy()
                        end
                        table.clear(Dropdown.Options)
                        table.clear(Dropdown.Buttons)
                    end

                    Dropdown.RawOptions = Options
                    Dropdown.Options = GetKeyList(Options)
                    AddOptions(Options)
                end

                function Dropdown:Set(Value)
                    if getgenv().Destroy or Dropdown.Disabled then
                        return
                    end
                    if DropdownConfig.Multi then
                        if DropdownConfig.MultiTrue then
                            if Dropdown.Value[Value] ~= nil then
                                Dropdown.Value[Value] = not Dropdown.Value[Value]
                            end
                        else
                            local index = table.find(Dropdown.Value, Value)
                            if index then
                                table.remove(Dropdown.Value, index)
                            else
                                table.insert(Dropdown.Value, Value)
                            end
                        end
                        for name, btn in pairs(Dropdown.Buttons) do
                            local selected = false
                            if DropdownConfig.MultiTrue then
                                selected = Dropdown.Value[name]
                            else
                                selected = table.find(Dropdown.Value, name)
                            end
                            TweenService:Create(btn, TweenInfo.new(0.15), {
                                BackgroundTransparency = selected and 0 or 1,
                            }):Play()
                        end
                        local selectedList = {}
                        if DropdownConfig.MultiTrue then
                            for k, v in pairs(Dropdown.Value) do
                                if v then
                                    table.insert(selectedList, k)
                                end
                            end
                        else
                            selectedList = Dropdown.Value
                        end
                        if #selectedList == 0 then
                            DropdownFrame.F.Selected.Text = "..."
                        else
                            local text = table.concat(selectedList, ", ")
                            DropdownFrame.F.Selected.Text = (#text > 20) and string.sub(text, 1, 17) .. "..." or text
                        end
                        return OrionLib:SafeScript(DropdownConfig.Callback, Dropdown.Value)
                    end
                    if not table.find(Dropdown.Options, Value) then
                        Dropdown.Value = DropdownConfig.Multi and {} or nil
                        DropdownFrame.F.Selected.Text = "..."
                        return
                    end
                    if DropdownConfig.Multi then
                        local btn = Dropdown.Buttons[Value]
                        if not btn then
                            return
                        end
                        if DropdownConfig.MultiTrue then
                            Dropdown.Value[Value] = not Dropdown.Value[Value]
                        else
                            local index = table.find(Dropdown.Value, Value)
                            if index then
                                table.remove(Dropdown.Value, index)
                            else
                                table.insert(Dropdown.Value, Value)
                            end
                        end
                        return Dropdown:Set(Dropdown.Value)
                    end
                    Dropdown.Value = Value
                    DropdownFrame.F.Selected.Text = Value
                    for _, v in pairs(Dropdown.Buttons) do
                        TweenService:Create(v, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
                    end
                    local selBtn = Dropdown.Buttons[Value]
                    if selBtn then
                        TweenService:Create(selBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
                    end
                    return OrionLib:SafeScript(DropdownConfig.Callback, Dropdown.Value)
                end

                AddConnection(Click.MouseButton1Click, function()
                    if Dropdown.Disabled then
                        return
                    end
                    Dropdown.Toggled = not Dropdown.Toggled
                    DropdownFrame.F.Line.Visible = Dropdown.Toggled
                    TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.15), { Rotation = Dropdown.Toggled and 180 or 0 }):Play()

                    local currentContentSize = DropdownList.AbsoluteContentSize.Y
                    local expandSize = math.min(currentContentSize, MaxElementsHeight)
                    local sizeY = (currentContentSize > 0) and (38 + expandSize) or 38

                    TweenService:Create(DropdownFrame, TweenInfo.new(0.15), {
                        Size = Dropdown.Toggled and UDim2.new(1, 0, 0, sizeY) or UDim2.new(1, 0, 0, 38),
                    }):Play()
                end)

                Dropdown:Refresh(DropdownConfig.Options, false)
                if DropdownConfig.Disabled then
                    Dropdown:SetDisabled(true)
                end
                if DropdownConfig.Visible == false then
                    Dropdown:SetVisible(false)
                end
                if DropdownConfig.Multi then
                    if DropdownConfig.MultiTrue then
                        for k, v in pairs(Dropdown.Value) do
                            if v then
                                Dropdown:Set(k)
                            end
                        end
                    else
                        for _, v in ipairs(Dropdown.Value) do
                            Dropdown:Set(v)
                        end
                    end
                end

                if DropdownConfig.Flag then
                    OrionLib.Flags[DropdownConfig.Flag] = Dropdown
                end

                return Dropdown
            end
            function ElementFunction:AddBind(BindConfig)
                BindConfig.Name = BindConfig.Name or "Bind"
                BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
                BindConfig.Hold = BindConfig.Hold or false
                BindConfig.Callback = BindConfig.Callback or function() end
                BindConfig.Flag = BindConfig.Flag or nil
                BindConfig.Save = BindConfig.Save or false
                BindConfig.Visible = BindConfig.Visible ~= false
                BindConfig.Disabled = BindConfig.Disabled or false

                local Bind = {
                    Value,
                    Binding = false,
                    Type = "Bind",
                    Save = BindConfig.Save,
                    Visible = BindConfig.Visible,
                    Disabled = BindConfig.Disabled,
                }

                local Holding = false

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                })

                local BindBox = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
                            Size = UDim2.new(0, 24, 0, 24),
                            Position = UDim2.new(1, -12, 0.5, 0),
                            AnchorPoint = Vector2.new(1, 0.5),
                        }),
                        {
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", BindConfig.Name, 14), {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Font = Enum.Font.GothamBold,
                                    TextXAlignment = Enum.TextXAlignment.Center,
                                    Name = "Value",
                                }),
                                "Text"
                            ),
                        }
                    ),
                    "Main"
                )

                local BindFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(1, 0, 0, 38),
                            Parent = ItemParent,
                        }),
                        {
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", BindConfig.Name, 15), {
                                    Size = UDim2.new(1, -12, 1, 0),
                                    Position = UDim2.new(0, 12, 0, 0),
                                    Font = Enum.Font.GothamBold,
                                    Visible = BindConfig.Visible,
                                    Name = "Content",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            BindBox,
                            Click,
                        }
                    ),
                    "Second"
                )

                AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
                    TweenService:Create(
                        BindBox,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { Size = UDim2.new(0, BindBox.Value.TextBounds.X + 16, 0, 24) }
                    ):Play()
                end)

                AddConnection(Click.InputEnded, function(Input)
                    if Bind.Disabled then
                        return
                    end
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        if Bind.Binding then
                            return
                        end
                        Bind.Binding = true
                        BindBox.Value.Text = ""
                    end
                end)

                AddConnection(UserInputService.InputBegan, function(Input)
                    if Bind.Disabled then
                        return
                    end
                    if UserInputService:GetFocusedTextBox() then
                        return
                    end
                    if (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) and not Bind.Binding then
                        if BindConfig.Hold then
                            Holding = true
                            OrionLib:SafeScript(BindConfig.Callback, Holding)
                        else
                            OrionLib:SafeScript(BindConfig.Callback, Input)
                        end
                    elseif Bind.Binding then
                        local Key
                        pcall(function()
                            if not CheckKey(BlacklistedKeys, Input.KeyCode) then
                                Key = Input.KeyCode
                            end
                        end)
                        pcall(function()
                            if CheckKey(WhitelistedMouse, Input.UserInputType) and not Key then
                                Key = Input.UserInputType
                            end
                        end)
                        Key = Key or Bind.Value
                        Bind:Set(Key)
                    end
                end)

                AddConnection(UserInputService.InputEnded, function(Input)
                    if Bind.Disabled then
                        return
                    end
                    if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
                        if BindConfig.Hold and Holding then
                            Holding = false
                            OrionLib:SafeScript(BindConfig.Callback, Holding)
                        end
                    end
                end)

                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(
                        BindFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 3) }
                    ):Play()
                end)

                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(
                        BindFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second }
                    ):Play()
                end)

                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(
                        BindFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 3) }
                    ):Play()
                end)

                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(
                        BindFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 6) }
                    ):Play()
                end)

                function Bind:Set(Key)
                    if getgenv().Destroy or Bind.Disabled then
                        return
                    end
                    Bind.Binding = false
                    Bind.Value = Key or Bind.Value
                    Bind.Value = Bind.Value.Name or Bind.Value
                    BindBox.Value.Text = Bind.Value
                end

                function Bind:SetText(ToChange)
                    if getgenv().Destroy or Bind.Disabled then
                        return
                    end
                    if BindFrame and BindFrame:FindFirstChild("Content") then
                        BindFrame.Content.Text = ToChange
                    end
                end

                function Bind:SetCallback(ToChange)
                    if getgenv().Destroy or Bind.Disabled then
                        return
                    end
                    BindConfig.Callback = ToChange
                end

                function Bind:SetVisible(State)
                    if getgenv().Destroy then
                        return
                    end
                    Bind.Visible = State
                    if BindFrame then
                        BindFrame.Visible = State
                    end
                end

                function Bind:SetDisabled(State)
                    if getgenv().Destroy then
                        return
                    end
                    Bind.Disabled = State

                    if State then
                        TweenService:Create(BindFrame, TweenInfo.new(0.2), {
                            BackgroundTransparency = 0.5,
                        }):Play()
                    else
                        TweenService:Create(BindFrame, TweenInfo.new(0.2), {
                            BackgroundTransparency = 0,
                        }):Play()
                    end
                end

                Bind:Set(BindConfig.Default)
                if BindConfig.Flag then
                    OrionLib.Flags[BindConfig.Flag] = Bind
                end
                return Bind
            end
            function ElementFunction:AddTextbox(TextboxConfig)
                TextboxConfig = TextboxConfig or {}
                TextboxConfig.Name = TextboxConfig.Name or "Textbox"
                TextboxConfig.Finished = TextboxConfig.Finished or false
                TextboxConfig.Save = TextboxConfig.Save or false
                TextboxConfig.Numeric = TextboxConfig.Numeric or false
                TextboxConfig.Flag = TextboxConfig.Flag or nil
                TextboxConfig.Default = TextboxConfig.Default or ""
                TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
                TextboxConfig.Callback = TextboxConfig.Callback or function() end
                TextboxConfig.Visible = TextboxConfig.Visible ~= false
                TextboxConfig.Disabled = TextboxConfig.Disabled or false

                local Textbox = {
                    Value = TextboxConfig.Default,
                    Type = "Input",
                    Save = TextboxConfig.Save,
                    Visible = TextboxConfig.Visible,
                    Disabled = TextboxConfig.Disabled,
                }

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                })

                local TextboxActual = OrionLib:AddThemeObject(
                    Create("TextBox", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        PlaceholderColor3 = Color3.fromRGB(210, 210, 210),
                        PlaceholderText = "Input",
                        Text = Textbox.Value or "",
                        ClearTextOnFocus = TextboxConfig.TextDisappear,
                        Font = Enum.Font.GothamSemibold,
                        ClipsDescendants = true,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextSize = 14,
                    }),
                    "Text"
                )

                local TextContainer = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
                            Size = UDim2.new(0, 100, 0, 24),
                            Position = UDim2.new(1, -12, 0.5, 0),
                            AnchorPoint = Vector2.new(1, 0.5),
                        }),
                        {
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            TextboxActual,
                        }
                    ),
                    "Main"
                )

                local TextboxFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(1, 0, 0, 38),
                            Parent = ItemParent,
                        }),
                        {
                            OrionLib:AddThemeObject(
                                SetProps(MakeElement("Label", TextboxConfig.Name, 15), {
                                    Size = UDim2.new(1, -12, 1, 0),
                                    Position = UDim2.new(0, 12, 0, 0),
                                    Font = Enum.Font.GothamBold,
                                    Visible = TextboxConfig.Visible,
                                    Name = "Content",
                                }),
                                "Text"
                            ),
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            TextContainer,
                            Click,
                        }
                    ),
                    "Second"
                )

                local function SetValue()
                    if Textbox.Disabled then
                        return
                    end
                    if TextboxConfig.Numeric then
                        if #TextboxActual.Text > 0 and not tonumber(TextboxActual.Text) then
                            TextboxActual.Text = TextboxActual.Text:match("%d+") or ""
                        end
                    end
                    Textbox.Value = TextboxActual.Text
                    OrionLib:SafeScript(TextboxConfig.Callback, TextboxActual.Text)
                end

                if TextboxConfig.Finished then
                    AddConnection(TextboxActual.FocusLost, function()
                        SetValue()
                    end)
                else
                    AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
                        SetValue()
                    end)
                end

                function Textbox:SetText(ToChange)
                    if getgenv().Destroy or Textbox.Disabled then
                        return
                    end
                    if TextboxActual then
                        TextboxActual.Text = ToChange
                        if TextboxConfig.Finished == false then
                            SetValue()
                        end
                    end
                end

                function Textbox:SetLabel(ToChange)
                    if getgenv().Destroy or Textbox.Disabled then
                        return
                    end
                    if TextboxFrame and TextboxFrame:FindFirstChild("Content") then
                        TextboxFrame.Content.Text = ToChange
                    end
                end

                function Textbox:SetCallback(ToChange)
                    if getgenv().Destroy or Textbox.Disabled then
                        return
                    end
                    TextboxConfig.Callback = ToChange
                end

                function Textbox:SetVisible(State)
                    if getgenv().Destroy then
                        return
                    end
                    Textbox.Visible = State
                    if TextboxFrame then
                        TextboxFrame.Visible = State
                    end
                end

                function Textbox:SetDisabled(State)
                    if getgenv().Destroy then
                        return
                    end
                    Textbox.Disabled = State
                    if State then
                        TweenService:Create(TextboxFrame, TweenInfo.new(0.2), {
                            BackgroundTransparency = 0.5,
                        }):Play()
                    else
                        TweenService:Create(TextboxFrame, TweenInfo.new(0.2), {
                            BackgroundTransparency = 0,
                        }):Play()
                    end
                    if TextboxActual then
                        TextboxActual.TextEditable = not State
                    end
                end

                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(
                        TextboxFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 3) }
                    ):Play()
                end)

                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(
                        TextboxFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second }
                    ):Play()
                end)

                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(
                        TextboxFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 3) }
                    ):Play()
                    TextboxActual:CaptureFocus()
                end)

                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(
                        TextboxFrame,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 6) }
                    ):Play()
                end)

                if TextboxConfig.Flag then
                    OrionLib.Flags[TextboxConfig.Flag] = Textbox
                end
                return Textbox
            end
            function ElementFunction:AddColorpicker(ColorpickerConfig)
                ColorpickerConfig = ColorpickerConfig or {}
                ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
                ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255, 255, 255)
                ColorpickerConfig.DefaultAlpha = ColorpickerConfig.DefaultAlpha or 0
                ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
                ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
                ColorpickerConfig.Save = ColorpickerConfig.Save or false
                ColorpickerConfig.Alpha = ColorpickerConfig.Alpha or false

                local ColorH, ColorS, ColorV = 1, 1, 1
                local AlphaValue = ColorpickerConfig.DefaultAlpha
                local Colorpicker = {
                    Value = ColorpickerConfig.Default,
                    Alpha = AlphaValue,
                    Toggled = false,
                    Type = "Colorpicker",
                    Save = ColorpickerConfig.Save,
                    RecentColors = {},
                }

                local function RGBToHex(c)
                    return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
                end

                local function HexToRGB(hex)
                    hex = hex:gsub("#", "")
                    return Color3.fromRGB(tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)))
                end

                local ColorSelection = Create("ImageLabel", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                    ScaleType = Enum.ScaleType.Fit,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=4805639000",
                })

                local HueSelection = Create("ImageLabel", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0.5, 0, 1 - select(1, Color3.toHSV(Colorpicker.Value))),
                    ScaleType = Enum.ScaleType.Fit,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=4805639000",
                })

                local AlphaSelection = Create("ImageLabel", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0.5, 0, 1 - AlphaValue, 0),
                    ScaleType = Enum.ScaleType.Fit,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=4805639000",
                })

                local ColorP = Create("ImageLabel", {
                    Size = UDim2.new(1, -50, 0, 150),
                    Visible = false,
                    Image = "rbxassetid://4155801252",
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    ColorSelection,
                })

                local Hue = Create("Frame", {
                    Size = UDim2.new(0, 20, 0, 150),
                    Position = UDim2.new(1, -45, 0, 0),
                    Visible = false,
                }, {
                    Create("UIGradient", {
                        Rotation = 90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0.00, Color3.fromHSV(1, 1, 1)),
                            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.83, 1, 1)),
                            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.67, 1, 1)),
                            ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.5, 1, 1)),
                            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.33, 1, 1)),
                            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.17, 1, 1)),
                            ColorSequenceKeypoint.new(1.00, Color3.fromHSV(0, 1, 1)),
                        }),
                    }),
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    HueSelection,
                })

                local AlphaFrame = Create("Frame", {
                    Size = UDim2.new(0, 20, 0, 150),
                    Position = UDim2.new(1, -20, 0, 0),
                    Visible = false,
                }, {
                    Create("ImageLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        Image = "rbxassetid://3885141947",
                        ScaleType = Enum.ScaleType.Tile,
                        TileSize = UDim2.new(0, 10, 0, 10),
                        BackgroundTransparency = 0.5,
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    }),
                    Create("Frame", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        Name = "GradientHolder",
                    }, {
                        Create("UIGradient", {
                            Rotation = 90,
                            Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0),
                                NumberSequenceKeypoint.new(1, 1),
                            }),
                        }),
                        Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    }),
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    AlphaSelection,
                })

                if not ColorpickerConfig.Alpha then
                    ColorP.Size = UDim2.new(1, -25, 0, 150)
                    Hue.Position = UDim2.new(1, -20, 0, 0)
                    AlphaFrame.Visible = false
                end

                local Inputs = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0, 160),
                    BackgroundTransparency = 1,
                    Visible = false,
                }, {
                    Create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 5),
                    }),
                })

                local HexBox = Create("TextBox", {
                    Size = UDim2.new(0, 70, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Text = RGBToHex(Colorpicker.Value),
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    PlaceholderText = "HEX",
                }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })

                local RBox = Create("TextBox", {
                    Size = UDim2.new(0, 40, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    TextColor3 = Color3.new(1, 0, 0),
                    Text = math.floor(Colorpicker.Value.R * 255),
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
                local GBox = Create("TextBox", {
                    Size = UDim2.new(0, 40, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    TextColor3 = Color3.new(0, 1, 0),
                    Text = math.floor(Colorpicker.Value.G * 255),
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
                local BBox = Create("TextBox", {
                    Size = UDim2.new(0, 40, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    TextColor3 = Color3.new(0.3, 0.3, 1),
                    Text = math.floor(Colorpicker.Value.B * 255),
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })

                local EyedropperBtn = Create("TextButton", {
                    Size = UDim2.new(0, 30, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    Text = "",
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    Create("ImageLabel", {
                        Size = UDim2.new(0, 16, 0, 16),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Image = "rbxassetid://6031256372",
                        BackgroundTransparency = 1,
                    }),
                })

                HexBox.Parent = Inputs
                RBox.Parent = Inputs
                GBox.Parent = Inputs
                BBox.Parent = Inputs
                EyedropperBtn.Parent = Inputs

                local RecentFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 0, 0, 195),
                    BackgroundTransparency = 1,
                    Visible = false,
                }, {
                    Create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 6),
                    }),
                })

                local ColorpickerContainer = Create("Frame", {
                    Position = UDim2.new(0, 0, 0, 38),
                    Size = UDim2.new(1, 0, 1, -38),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                }, {
                    Hue,
                    ColorP,
                    AlphaFrame,
                    Inputs,
                    RecentFrame,
                    Create("UIPadding", {
                        PaddingLeft = UDim.new(0, 10),
                        PaddingRight = UDim.new(0, 10),
                        PaddingBottom = UDim.new(0, 10),
                        PaddingTop = UDim.new(0, 10),
                    }),
                })

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                })

                local ColorpickerBox = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
                            Size = UDim2.new(0, 24, 0, 24),
                            Position = UDim2.new(1, -12, 0.5, 0),
                            AnchorPoint = Vector2.new(1, 0.5),
                        }),
                        {
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        }
                    ),
                    "Main"
                )

                local ColorpickerFrame = OrionLib:AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(1, 0, 0, 38),
                            Parent = ItemParent,
                        }),
                        {
                            SetProps(
                                SetChildren(MakeElement("TFrame"), {
                                    OrionLib:AddThemeObject(
                                        SetProps(MakeElement("Label", ColorpickerConfig.Name, 15), {
                                            Size = UDim2.new(1, -12, 1, 0),
                                            Position = UDim2.new(0, 12, 0, 0),
                                            Font = Enum.Font.GothamBold,
                                            Name = "Content",
                                        }),
                                        "Text"
                                    ),
                                    ColorpickerBox,
                                    Click,
                                    OrionLib:AddThemeObject(
                                        SetProps(MakeElement("Frame"), {
                                            Size = UDim2.new(1, 0, 0, 1),
                                            Position = UDim2.new(0, 0, 1, -1),
                                            Name = "Line",
                                            Visible = false,
                                        }),
                                        "Stroke"
                                    ),
                                }),
                                {
                                    Size = UDim2.new(1, 0, 0, 38),
                                    ClipsDescendants = true,
                                    Name = "F",
                                }
                            ),
                            ColorpickerContainer,
                            OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        }
                    ),
                    "Second"
                )
                Colorpicker.Frame = ColorpickerFrame
                Colorpicker.Preview = ColorpickerBox
                if ColorpickerConfig.Glass or ColorpickerConfig.LiquidGlass or ColorpickerConfig.GlassMorph or WindowConfig.GlassElements then
                    Colorpicker.Glass = ApplyLiquidGlass(ColorpickerFrame, ColorpickerConfig.GlassConfig or ColorpickerConfig.LiquidGlassConfig or {
                        Color = ColorpickerConfig.GlassColor or GetThemeValue("Second", Color3.fromRGB(25, 28, 38)),
                        Accent = Colorpicker.Value,
                        BackgroundTransparency = 0.38,
                        Radius = 12,
                        StrokeTransparency = 0.8,
                        HighlightTransparency = 0.92,
                        Shadow = false,
                    })
                    ApplyLiquidGlass(ColorpickerBox, {
                        Color = Colorpicker.Value,
                        Accent = Colorpicker.Value,
                        BackgroundTransparency = 0.28,
                        Radius = 7,
                        StrokeTransparency = 0.78,
                        HighlightTransparency = 0.9,
                        Shadow = false,
                    })
                    ApplyLiquidGlass(ColorP, {
                        Color = Colorpicker.Value,
                        Accent = Colorpicker.Value,
                        BackgroundTransparency = 0.2,
                        Radius = 10,
                        Decorations = false,
                        StrokeTransparency = 0.78,
                        HighlightTransparency = 0.9,
                        Shadow = false,
                    })
                    Click.ZIndex = 40
                end

                local function AddRecentColor(Col)
                    local found = false
                    for _, v in ipairs(Colorpicker.RecentColors) do
                        if v == Col then
                            found = true
                        end
                    end
                    if not found then
                        table.insert(Colorpicker.RecentColors, 1, Col)
                        if #Colorpicker.RecentColors > 5 then
                            table.remove(Colorpicker.RecentColors, 6)
                        end
                    end

                    for _, child in pairs(RecentFrame:GetChildren()) do
                        if child:IsA("ImageButton") then
                            child:Destroy()
                        end
                    end

                    for _, rc in ipairs(Colorpicker.RecentColors) do
                        local cBtn = Create("ImageButton", {
                            Size = UDim2.new(0, 20, 0, 20),
                            BackgroundColor3 = rc,
                            AutoButtonColor = false,
                        }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
                        cBtn.Parent = RecentFrame
                        AddConnection(cBtn.MouseButton1Click, function()
                            Colorpicker:Set(rc)
                        end)
                    end
                end

                local function UpdateInputDisplays()
                    local col = Colorpicker.Value
                    HexBox.Text = RGBToHex(col)
                    RBox.Text = tostring(math.floor(col.R * 255))
                    GBox.Text = tostring(math.floor(col.G * 255))
                    BBox.Text = tostring(math.floor(col.B * 255))
                    AlphaFrame.GradientHolder.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                end

                local function UpdateColorPicker(BlockCallback)
                    ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                    ColorP.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)

                    Colorpicker.Value = ColorpickerBox.BackgroundColor3
                    if Colorpicker.Glass and type(Colorpicker.Glass.SetTint) == "function" then
                        Colorpicker.Glass:SetTint(ColorAdd(Colorpicker.Value, -80))
                    end

                    if not BlockCallback then
                        OrionLib:SafeScript(ColorpickerConfig.Callback, Colorpicker.Value, AlphaValue)
                    end

                    UpdateInputDisplays()
                end

                ColorH, ColorS, ColorV = Color3.toHSV(Colorpicker.Value)

                AddConnection(Click.MouseButton1Click, function()
                    Colorpicker.Toggled = not Colorpicker.Toggled
                    local sizeH = ColorpickerConfig.Alpha and 270 or 270
                    TweenService:Create(
                        ColorpickerFrame,
                        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { Size = Colorpicker.Toggled and UDim2.new(1, 0, 0, sizeH) or UDim2.new(1, 0, 0, 38) }
                    ):Play()
                    ColorP.Visible = Colorpicker.Toggled
                    Hue.Visible = Colorpicker.Toggled
                    AlphaFrame.Visible = Colorpicker.Toggled and ColorpickerConfig.Alpha
                    Inputs.Visible = Colorpicker.Toggled
                    RecentFrame.Visible = Colorpicker.Toggled
                    ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
                    if not Colorpicker.Toggled then
                        AddRecentColor(Colorpicker.Value)
                    end
                end)

                AddConnection(EyedropperBtn.MouseButton1Click, function()
                    local mouse = game.Players.LocalPlayer:GetMouse()
                    local pickerConnect
                    pickerConnect = AddConnection(game:GetService("RunService").RenderStepped, function()
                        local target = mouse.Target
                        if target and target:IsA("BasePart") then
                            EyedropperBtn.BackgroundColor3 = target.Color
                            EyedropperBtn.Text = ""
                        else
                            EyedropperBtn.BackgroundColor3 = Color3.new(0, 0, 0)
                            EyedropperBtn.Text = "?"
                        end
                    end)

                    local clickConnect
                    clickConnect = AddConnection(game:GetService("UserInputService").InputBegan, function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            local target = mouse.Target
                            if target and target:IsA("BasePart") then
                                Colorpicker:Set(target.Color)
                            end
                            pickerConnect:Disconnect()
                            clickConnect:Disconnect()
                            EyedropperBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        end
                    end)
                end)

                AddConnection(HexBox.FocusLost, function()
                    pcall(function()
                        local nC = HexToRGB(HexBox.Text)
                        Colorpicker:Set(nC)
                    end)
                end)

                local function UpdateRGB()
                    local r, g, b = tonumber(RBox.Text) or 0, tonumber(GBox.Text) or 0, tonumber(BBox.Text) or 0
                    Colorpicker:Set(Color3.fromRGB(r, g, b))
                end
                AddConnection(RBox.FocusLost, UpdateRGB)
                AddConnection(GBox.FocusLost, UpdateRGB)
                AddConnection(BBox.FocusLost, UpdateRGB)

                AddConnection(ColorP.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if ColorInput then
                            ColorInput:Disconnect()
                        end
                        ColorInput = AddConnection(RunService.RenderStepped, function()
                            local ColorX = (math.clamp(Mouse.X - ColorP.AbsolutePosition.X, 0, ColorP.AbsoluteSize.X) / ColorP.AbsoluteSize.X)
                            local ColorY = (math.clamp(Mouse.Y - ColorP.AbsolutePosition.Y, 0, ColorP.AbsoluteSize.Y) / ColorP.AbsoluteSize.Y)
                            ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
                            ColorS = ColorX
                            ColorV = 1 - ColorY
                            UpdateColorPicker()
                        end)
                    end
                end)

                AddConnection(ColorP.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if ColorInput then
                            ColorInput:Disconnect()
                        end
                    end
                end)

                AddConnection(Hue.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if HueInput then
                            HueInput:Disconnect()
                        end
                        HueInput = AddConnection(RunService.RenderStepped, function()
                            local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
                            HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
                            ColorH = 1 - HueY
                            UpdateColorPicker()
                        end)
                    end
                end)

                AddConnection(Hue.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if HueInput then
                            HueInput:Disconnect()
                        end
                    end
                end)

                AddConnection(AlphaFrame.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if AlphaInput then
                            AlphaInput:Disconnect()
                        end
                        AlphaInput = AddConnection(RunService.RenderStepped, function()
                            local AY = (math.clamp(Mouse.Y - AlphaFrame.AbsolutePosition.Y, 0, AlphaFrame.AbsoluteSize.Y) / AlphaFrame.AbsoluteSize.Y)
                            AlphaSelection.Position = UDim2.new(0.5, 0, AY, 0)
                            AlphaValue = 1 - AY
                            OrionLib:SafeScript(ColorpickerConfig.Callback, Colorpicker.Value, AlphaValue)
                        end)
                    end
                end)

                AddConnection(AlphaFrame.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if AlphaInput then
                            AlphaInput:Disconnect()
                        end
                    end
                end)

                function Colorpicker:Set(Value, Alpha)
                    if getgenv().Destroy then
                        return
                    end
                    if typeof(Value) == "Color3" then
                        Colorpicker.Value = Value
                        local h, s, v = Color3.toHSV(Value)
                        ColorH, ColorS, ColorV = h, s, v
                        ColorSelection.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
                        HueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
                        UpdateColorPicker(true)
                    end
                    if Alpha then
                        AlphaValue = Alpha
                        AlphaSelection.Position = UDim2.new(0.5, 0, 1 - AlphaValue, 0)
                        OrionLib:SafeScript(ColorpickerConfig.Callback, Colorpicker.Value, AlphaValue)
                    end
                end

                Colorpicker:Set(Colorpicker.Value, AlphaValue)
                if ColorpickerConfig.Flag then
                    OrionLib.Flags[ColorpickerConfig.Flag] = Colorpicker
                end
                return Colorpicker
            end
            return ElementFunction
        end

        local ElementFunction = {}
        function ElementFunction:AddSection(SectionConfig)
            SectionConfig = SectionConfig or {}
            SectionConfig.Name = SectionConfig.Name or "Section"
            SectionConfig.Flag = SectionConfig.Flag or nil
            local Section = { Type = "Section" }

            local SectionFrame = SetChildren(
                SetProps(MakeElement("TFrame"), {
                    Size = UDim2.new(1, 0, 0, 26),
                    Parent = Container,
                }),
                {
                    OrionLib:AddThemeObject(
                        SetProps(MakeElement("Label", SectionConfig.Name, 14), {
                            Size = UDim2.new(1, -12, 0, 16),
                            Position = UDim2.new(0, 0, 0, 3),
                            Font = Enum.Font.GothamSemibold,
                        }),
                        "TextDark"
                    ),
                    SetChildren(
                        SetProps(MakeElement("TFrame"), {
                            AnchorPoint = Vector2.new(0, 0),
                            Size = UDim2.new(1, 0, 1, -24),
                            Position = UDim2.new(0, 0, 0, 23),
                            Name = "Holder",
                        }),
                        {
                            MakeElement("List", 0, 6),
                        }
                    ),
                }
            )

            function Section:Set(ToChange)
                if getgenv().Destroy then
                    return
                end
                if SectionFrame and SectionFrame:FindFirstChildOfClass("TextLabel") then
                    SectionFrame:FindFirstChildOfClass("TextLabel").Text = ToChange
                end
            end

            function Section:SetTextSize(ToChange: number)
                if getgenv().Destroy then
                    return
                end
                if SectionFrame and SectionFrame:FindFirstChildOfClass("TextLabel") then
                    SectionFrame:FindFirstChildOfClass("TextLabel").TextSize = ToChange
                end
            end

            AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
                SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
            end)

            local SectionFunction = {}
            for i, v in next, GetElements(SectionFrame.Holder) do
                SectionFunction[i] = v
            end
            SectionFunction.Button = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Button"
                return SectionFunction:AddButton(config)
            end
            SectionFunction.HighlightButton = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Highlight Button"
                return SectionFunction:AddHighlightButton(config)
            end
            SectionFunction.Toggle = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Toggle"
                config.Default = config.Default ~= nil and config.Default or config.Value
                return SectionFunction:AddToggle(config)
            end
            SectionFunction.Slider = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Slider"
                config.Default = config.Default ~= nil and config.Default or config.Value
                return SectionFunction:AddSlider(config)
            end
            SectionFunction.Dropdown = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Dropdown"
                config.Default = config.Default ~= nil and config.Default or config.Value
                return SectionFunction:AddDropdown(config)
            end
            SectionFunction.Input = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Input"
                config.Default = config.Default ~= nil and config.Default or config.Value
                return SectionFunction:AddTextbox(config)
            end
            SectionFunction.Paragraph = function(_, config)
                config = TranslateConfig(config or {})
                return SectionFunction:AddParagraph(config.Title or config.Name or "Paragraph", config.Content or config.Desc or config.Description or "")
            end
            SectionFunction.TabBox = function(_, config)
                config = TranslateConfig(config or {})
                return SectionFunction:AddTabBox(config)
            end
            SectionFunction.StatCard = function(_, config)
                config = TranslateConfig(config or {})
                return SectionFunction:AddStatCard(config)
            end
            SectionFunction.Stat = SectionFunction.StatCard
            SectionFunction.Metric = SectionFunction.StatCard
            SectionFunction.TabCard = function(_, config)
                config = TranslateConfig(config or {})
                return SectionFunction:AddTabCard(config)
            end
            SectionFunction.Graph = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Graph"
                return SectionFunction:AddGraph(config)
            end
            SectionFunction.RichLabel = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Rich Label"
                return SectionFunction:AddGraph(config)
            end
            SectionFunction.AdvancedLabel = SectionFunction.RichLabel
            for methodName, method in next, SectionFunction do
                Section[methodName] = method
            end

            function SectionFunction:WarningBox(config)
                config = TranslateConfig(config or {})
                return SectionFunction:AddWarningBox(config)
            end

            if SectionConfig.Flag then
                OrionLib.Flags[SectionConfig.Flag] = Section
            end
            return Section
        end

        for i, v in next, GetElements(Container) do
            ElementFunction[i] = v
        end

        function ElementFunction:AddGroupBox(GroupConfig)
            GroupConfig = TranslateConfig(GroupConfig or {})
            GroupConfig.Name = GroupConfig.Name or GroupConfig.Title or "GroupBox"
            GroupConfig.Visible = GroupConfig.Visible ~= false
            local Group = { Type = "GroupBox", Visible = GroupConfig.Visible }
            local GroupFrame = OrionLib:AddThemeObject(
                SetChildren(
                    SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6), {
                        Size = UDim2.new(1, 0, 0, 36),
                        Parent = Container,
                        Visible = GroupConfig.Visible,
                        BackgroundTransparency = 0.25,
                    }),
                    {
                        OrionLib:AddThemeObject(
                            SetProps(MakeElement("Label", GroupConfig.Name, 14), {
                                Size = UDim2.new(1, -24, 0, 20),
                                Position = UDim2.new(0, 12, 0, 8),
                                Font = Enum.Font.GothamBold,
                                Name = "Title",
                            }),
                            "Text"
                        ),
                        SetChildren(
                            SetProps(MakeElement("TFrame"), {
                                Name = "Holder",
                                Size = UDim2.new(1, -20, 0, 0),
                                Position = UDim2.new(0, 10, 0, 34),
                            }),
                            { MakeElement("List", 0, 6) }
                        ),
                        OrionLib:AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    }
                ),
                "Second"
            )
            Group.Frame = GroupFrame
            if GroupConfig.Glass or GroupConfig.LiquidGlass or WindowConfig.Glass then
                Group.Glass = ApplyLiquidGlass(GroupFrame, GroupConfig.GlassConfig or {
                    Color = GroupConfig.GlassColor or GetThemeValue("Second", Color3.fromRGB(25, 28, 38)),
                    Accent = GroupConfig.Color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250)),
                    BackgroundTransparency = 0.42,
                    Radius = 12,
                    StrokeTransparency = 0.82,
                    HighlightTransparency = 0.92,
                    Shadow = false,
                })
            end
            AddConnection(GroupFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                GroupFrame.Holder.Size = UDim2.new(1, -20, 0, GroupFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
                GroupFrame.Size = UDim2.new(1, 0, 0, GroupFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 46)
            end)
            for methodName, method in next, GetElements(GroupFrame.Holder) do
                Group[methodName] = method
            end
            Group.Button = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Button"
                return Group:AddButton(config)
            end
            Group.GlassButton = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Glass Button"
                config.Glass = true
                config.LiquidGlass = config.LiquidGlass ~= false
                return Group:AddButton(config)
            end
            Group.ButtonGlass = Group.GlassButton
            Group.LiquidButton = Group.GlassButton
            Group.ButtonGlassLiquid = Group.GlassButton
            Group.HighlightButton = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Highlight Button"
                return Group:AddHighlightButton(config)
            end
            Group.WarningBox = function(_, config)
                config = TranslateConfig(config or {})
                return Group:AddWarningBox(config)
            end
            Group.Toggle = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Toggle"
                config.Default = config.Default ~= nil and config.Default or config.Value
                return Group:AddToggle(config)
            end
            Group.GlassToggle = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Glass Toggle"
                config.Default = config.Default ~= nil and config.Default or config.Value
                config.Type = config.Type or "Switch"
                config.Glass = true
                config.LiquidGlass = config.LiquidGlass ~= false
                return Group:AddToggle(config)
            end
            Group.ToggleGlass = Group.GlassToggle
            Group.LiquidToggle = Group.GlassToggle
            Group.ToggleGlassLiquid = Group.GlassToggle
            Group.Slider = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Slider"
                config.Default = config.Default ~= nil and config.Default or config.Value
                return Group:AddSlider(config)
            end
            Group.Dropdown = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Dropdown"
                config.Default = config.Default ~= nil and config.Default or config.Value
                return Group:AddDropdown(config)
            end
            Group.Input = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Input"
                config.Default = config.Default ~= nil and config.Default or config.Value
                return Group:AddTextbox(config)
            end
            Group.GlassColorpicker = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Glass Colorpicker"
                config.Default = config.Default ~= nil and config.Default or config.Value
                config.Glass = true
                config.GlassMorph = true
                return Group:AddColorpicker(config)
            end
            Group.GlassColorPicker = Group.GlassColorpicker
            Group.ColorpickerGlass = Group.GlassColorpicker
            Group.ColorPickerGlass = Group.GlassColorpicker
            Group.Paragraph = function(_, config)
                config = TranslateConfig(config or {})
                return Group:AddParagraph(config.Title or config.Name or "Paragraph", config.Content or config.Desc or config.Description or "")
            end
            Group.TabBox = function(_, config)
                config = TranslateConfig(config or {})
                return Group:AddTabBox(config)
            end
            Group.StatCard = function(_, config)
                config = TranslateConfig(config or {})
                return Group:AddStatCard(config)
            end
            Group.Stat = Group.StatCard
            Group.Metric = Group.StatCard
            Group.TabCard = function(_, config)
                config = TranslateConfig(config or {})
                return Group:AddTabCard(config)
            end
            Group.Graph = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Graph"
                return Group:AddGraph(config)
            end
            Group.RichLabel = function(_, config)
                config = TranslateConfig(config or {})
                config.Name = config.Name or config.Title or "Rich Label"
                return Group:AddGraph(config)
            end
            Group.AdvancedLabel = Group.RichLabel
            function Group:SetVisible(state)
                Group.Visible = state == true
                GroupFrame.Visible = Group.Visible
            end
            if GroupConfig.Flag then
                OrionLib.Flags[GroupConfig.Flag] = Group
            end
            return Group
        end

        local function NormalizeElementConfig(config, defaultName)
            config = TranslateConfig(config or {})
            config.Name = config.Name or config.Title or defaultName
            config.Text = config.Text or config.Title or config.Name
            config.Content = config.Content or config.Desc or config.Description or config.Content
            config.Default = config.Default ~= nil and config.Default or config.Value
            config.Icon = ResolveIcon(config.Icon or config.Image)
            return config
        end

        function ElementFunction:Button(config)
            config = NormalizeElementConfig(config, "Button")
            return ElementFunction:AddButton(config)
        end

        function ElementFunction:GlassButton(config)
            config = NormalizeElementConfig(config, "Glass Button")
            config.Glass = true
            config.LiquidGlass = config.LiquidGlass ~= false
            return ElementFunction:AddButton(config)
        end

        ElementFunction.ButtonGlass = ElementFunction.GlassButton
        ElementFunction.LiquidButton = ElementFunction.GlassButton
        ElementFunction.ButtonGlassLiquid = ElementFunction.GlassButton

        function ElementFunction:WarningBox(config)
            config = NormalizeElementConfig(config, "Warning")
            return ElementFunction:AddWarningBox(config)
        end

        function ElementFunction:GroupBox(config)
            config = NormalizeElementConfig(config, "GroupBox")
            return ElementFunction:AddGroupBox(config)
        end

        function ElementFunction:HighlightButton(config)
            config = NormalizeElementConfig(config, "Highlight Button")
            return ElementFunction:AddHighlightButton(config)
        end

        function ElementFunction:Toggle(config)
            config = NormalizeElementConfig(config, "Toggle")
            return ElementFunction:AddToggle(config)
        end

        function ElementFunction:GlassToggle(config)
            config = NormalizeElementConfig(config, "Glass Toggle")
            config.Type = config.Type or "Switch"
            config.Glass = true
            config.LiquidGlass = config.LiquidGlass ~= false
            return ElementFunction:AddToggle(config)
        end

        ElementFunction.ToggleGlass = ElementFunction.GlassToggle
        ElementFunction.LiquidToggle = ElementFunction.GlassToggle
        ElementFunction.ToggleGlassLiquid = ElementFunction.GlassToggle

        function ElementFunction:Slider(config)
            config = NormalizeElementConfig(config, "Slider")
            return ElementFunction:AddSlider(config)
        end

        function ElementFunction:Dropdown(config)
            config = NormalizeElementConfig(config, "Dropdown")
            return ElementFunction:AddDropdown(config)
        end

        function ElementFunction:Input(config)
            config = NormalizeElementConfig(config, "Input")
            config.Finished = config.Finished ~= false
            return ElementFunction:AddTextbox(config)
        end

        function ElementFunction:Colorpicker(config)
            config = NormalizeElementConfig(config, "Colorpicker")
            return ElementFunction:AddColorpicker(config)
        end

        ElementFunction.ColorPicker = ElementFunction.Colorpicker

        function ElementFunction:GlassColorpicker(config)
            config = NormalizeElementConfig(config, "Glass Colorpicker")
            config.Glass = true
            config.GlassMorph = true
            return ElementFunction:AddColorpicker(config)
        end

        ElementFunction.GlassColorPicker = ElementFunction.GlassColorpicker
        ElementFunction.ColorpickerGlass = ElementFunction.GlassColorpicker
        ElementFunction.ColorPickerGlass = ElementFunction.GlassColorpicker

        function ElementFunction:Paragraph(config)
            config = NormalizeElementConfig(config, "Paragraph")
            return ElementFunction:AddParagraph(config.Title or config.Name or config.Text, config.Content or config.Desc or config.Description or "")
        end

        function ElementFunction:TabBox(config)
            config = NormalizeElementConfig(config, "TabBox")
            return ElementFunction:AddTabBox(config)
        end

        function ElementFunction:StatCard(config)
            config = NormalizeElementConfig(config, "Statistic")
            return ElementFunction:AddStatCard(config)
        end

        function ElementFunction:Stat(config)
            return ElementFunction:StatCard(config)
        end

        function ElementFunction:Metric(config)
            return ElementFunction:StatCard(config)
        end

        function ElementFunction:TabCard(config)
            config = NormalizeElementConfig(config, "Tab Card")
            return ElementFunction:AddTabCard(config)
        end

        function ElementFunction:Graph(config)
            config = NormalizeElementConfig(config, "Graph")
            return ElementFunction:AddGraph(config)
        end

        function ElementFunction:DiscordServer(config)
            config = NormalizeElementConfig(config, "Discord Server")
            return ElementFunction:AddDiscordServer(config)
        end

        function ElementFunction:Discord(config)
            return ElementFunction:DiscordServer(config)
        end

        function ElementFunction:ServerCard(config)
            return ElementFunction:DiscordServer(config)
        end

        function ElementFunction:RichLabel(config)
            config = NormalizeElementConfig(config, "Rich Label")
            return ElementFunction:AddGraph(config)
        end

        function ElementFunction:AdvancedLabel(config)
            return ElementFunction:RichLabel(config)
        end

        function ElementFunction:Section(config)
            config = NormalizeElementConfig(config, "Section")
            return ElementFunction:AddSection(config)
        end

        function ElementFunction:Divider(config)
            return ElementFunction:AddDivider(config)
        end

        function ElementFunction:Space(config)
            config = config or {}
            local columns = tonumber(config.Columns or config.Size or 1) or 1
            local frame = SetProps(MakeElement("Frame"), {
                Size = UDim2.new(1, 0, 0, math.max(6, columns * 10)),
                BackgroundTransparency = 1,
                Parent = Container,
            })
            return {
                Instance = frame,
                Destroy = function()
                    frame:Destroy()
                end,
            }
        end

        function ElementFunction:Image(config)
            config = NormalizeElementConfig(config, "Image")
            return ElementFunction:AddImage({ Icon = config.Image or config.Icon, Size = config.Size or config.Height or 160, Visible = config.Visible })
        end

        ElementFunction.Tab = Tabs
        ElementFunction.Select = function()
            return Tabs:Select()
        end
        ElementFunction.SetTitle = function(_, title)
            return Tabs:SetTitle(title)
        end
        ElementFunction.SetIcon = function(_, icon)
            return Tabs:SetIcon(icon)
        end
        ElementFunction.SetBadge = function(_, value, color)
            return Tabs:SetBadge(value, color)
        end
        ElementFunction.SetDisabled = function(_, state)
            return Tabs:SetDisabled(state)
        end
        ElementFunction.SetVisible = function(_, state)
            return Tabs:SetVisible(state)
        end

        if TabConfig.PremiumOnly then
            for i, v in next, ElementFunction do
                ElementFunction[i] = function() end
            end
            Container:FindFirstChild("UIListLayout"):Destroy()
            Container:FindFirstChild("UIPadding"):Destroy()
            SetChildren(
                SetProps(MakeElement("TFrame"), {
                    Size = UDim2.new(1, 0, 1, 0),
                    Parent = ItemParent,
                }),
                {
                    OrionLib:AddThemeObject(
                        SetProps(MakeElement("Image", "lock-keyhole"), {
                            Size = UDim2.new(0, 18, 0, 18),
                            Position = UDim2.new(0, 15, 0, 15),
                            ImageTransparency = 0.4,
                        }),
                        "Text"
                    ),
                    OrionLib:AddThemeObject(
                        SetProps(MakeElement("Label", "Unauthorised Access", 14), {
                            Size = UDim2.new(1, -38, 0, 14),
                            Position = UDim2.new(0, 38, 0, 18),
                            TextTransparency = 0.4,
                        }),
                        "Text"
                    ),
                    OrionLib:AddThemeObject(
                        SetProps(MakeElement("Image", "crown"), {
                            Size = UDim2.new(0, 56, 0, 56),
                            Position = UDim2.new(0, 84, 0, 110),
                        }),
                        "Text"
                    ),
                    OrionLib:AddThemeObject(
                        SetProps(MakeElement("Label", "Premium Features", 14), {
                            Size = UDim2.new(1, -150, 0, 14),
                            Position = UDim2.new(0, 150, 0, 112),
                            Font = Enum.Font.GothamBold,
                        }),
                        "Text"
                    ),
                    OrionLib:AddThemeObject(
                        SetProps(
                            MakeElement(
                                "Label",
                                "This part of the script is locked to Sirius Premium users. Purchase Premium in the Discord server (discord.gg/sirius)",
                                12
                            ),
                            {
                                Size = UDim2.new(1, -200, 0, 14),
                                Position = UDim2.new(0, 150, 0, 138),
                                TextWrapped = true,
                                TextTransparency = 0.4,
                            }
                        ),
                        "Text"
                    ),
                }
            )
        end
        return ElementFunction, Tabs
    end

    function Functions:TabGroup(GroupConfig)
        GroupConfig = TranslateConfig(GroupConfig or {})
        GroupConfig.Name = GroupConfig.Name or GroupConfig.Title or "Group"
        GroupConfig.Icon = ResolveIcon(GroupConfig.Icon or "folder")
        GroupConfig.Visible = GroupConfig.Visible ~= false
        GroupConfig.Collapsed = GroupConfig.Collapsed == true
        if WindowConfig.TopbarTabs then
            local TopbarGroup = {
                Name = GroupConfig.Name,
                Visible = GroupConfig.Visible,
                Tabs = {},
                Type = "TabGroup",
            }
            function TopbarGroup:Tab(TabConfig)
                TabConfig = TranslateConfig(TabConfig or {})
                TabConfig._Group = TopbarGroup
                local Elements, Tab = Functions:MakeTab(TabConfig)
                table.insert(TopbarGroup.Tabs, Tab)
                return Elements, Tab
            end
            function TopbarGroup:SetCollapsed() end
            function TopbarGroup:SetVisible(state)
                TopbarGroup.Visible = state == true
                for _, tab in ipairs(TopbarGroup.Tabs) do
                    if type(tab.SetVisible) == "function" then
                        tab:SetVisible(TopbarGroup.Visible)
                    end
                end
            end
            function TopbarGroup:SetTitle(title)
                TopbarGroup.Name = tostring(title or TopbarGroup.Name)
            end
            function TopbarGroup:SetIcon(icon)
                GroupConfig.Icon = ResolveIcon(icon or GroupConfig.Icon)
            end
            return TopbarGroup
        end
        local Group = {
            Name = GroupConfig.Name,
            Collapsed = GroupConfig.Collapsed,
            Visible = GroupConfig.Visible,
            Tabs = {},
            Type = "TabGroup",
        }

        local HeaderClick = SetProps(MakeElement("Button"), {
            Size = UDim2.new(1, 0, 0, 30),
            AutoButtonColor = false,
            Name = "Header",
        })

        local GroupFrame = SetChildren(
            SetProps(MakeElement("TFrame"), {
                Size = UDim2.new(1, 0, 0, 30),
                Parent = TabHolder,
                Visible = Group.Visible,
                Name = Group.Name,
            }),
            {
                HeaderClick,
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Image", GroupConfig.Icon), {
                        AnchorPoint = WindowConfig.SidebarCompact and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5),
                        Size = UDim2.new(0, WindowConfig.SidebarCompact and 22 or 16, 0, WindowConfig.SidebarCompact and 22 or 16),
                        Position = WindowConfig.SidebarCompact and UDim2.new(0.5, 0, 0, 15) or UDim2.new(0, 10, 0, 15),
                        ImageTransparency = 0.35,
                        Name = "GroupIcon",
                    }),
                    "TextDark"
                ),
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Label", Group.Name, 12), {
                        Size = UDim2.new(1, -52, 0, 30),
                        Position = UDim2.new(0, 32, 0, 0),
                        Font = Enum.Font.GothamBold,
                        TextTransparency = 0.25,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Visible = not WindowConfig.SidebarCompact,
                        Name = "Title",
                    }),
                    "TextDark"
                ),
                OrionLib:AddThemeObject(
                    SetProps(MakeElement("Image", "chevron-down"), {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(0, 16, 0, 16),
                        Position = UDim2.new(1, -10, 0, 15),
                        ImageTransparency = 0.35,
                        Visible = not WindowConfig.SidebarCompact,
                        Name = "Chevron",
                    }),
                    "TextDark"
                ),
                SetChildren(
                    SetProps(MakeElement("TFrame"), {
                        Size = UDim2.new(1, 0, 0, 0),
                        Position = UDim2.new(0, 0, 0, 30),
                        Visible = not Group.Collapsed,
                        Name = "Holder",
                    }),
                    {
                        MakeElement("List", 0, 2),
                    }
                ),
            }
        )

        local Holder = GroupFrame.Holder
        local function UpdateGroupSize()
            local contentHeight = Holder.UIListLayout.AbsoluteContentSize.Y
            Holder.Visible = not Group.Collapsed
            Holder.Size = UDim2.new(1, 0, 0, contentHeight)
            GroupFrame.Size = UDim2.new(1, 0, 0, 30 + (Group.Collapsed and 0 or contentHeight))
            if GroupFrame:FindFirstChild("Chevron") then
                TweenService:Create(GroupFrame.Chevron, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
                    Rotation = Group.Collapsed and -90 or 0,
                }):Play()
            end
        end

        AddConnection(Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), UpdateGroupSize)
        AddConnection(HeaderClick.MouseButton1Click, function()
            Group:SetCollapsed(not Group.Collapsed)
        end)

        function Group:Tab(TabConfig)
            TabConfig = TranslateConfig(TabConfig or {})
            TabConfig._Parent = Holder
            TabConfig._Indent = WindowConfig.SidebarCompact and 0 or 10
            TabConfig._Group = Group
            local Elements, Tab = Functions:MakeTab(TabConfig)
            table.insert(Group.Tabs, Tab)
            UpdateGroupSize()
            return Elements, Tab
        end

        function Group:SetCollapsed(state)
            Group.Collapsed = state == true
            UpdateGroupSize()
        end

        function Group:SetVisible(state)
            Group.Visible = state == true
            GroupFrame.Visible = Group.Visible
        end

        function Group:SetTitle(title)
            Group.Name = tostring(title or Group.Name)
            GroupFrame.Name = Group.Name
            if GroupFrame:FindFirstChild("Title") then
                GroupFrame.Title.Text = Group.Name
            end
        end

        function Group:SetIcon(icon)
            GroupConfig.Icon = ResolveIcon(icon or GroupConfig.Icon)
            if GroupFrame:FindFirstChild("GroupIcon") then
                ApplyIconToObject(GroupFrame.GroupIcon, GroupConfig.Icon, 32)
            end
        end

        UpdateGroupSize()
        if GroupConfig.Flag then
            OrionLib.Flags[GroupConfig.Flag] = Group
        end
        return Group
    end

    function Functions:GroupTab(GroupConfig)
        return Functions:TabGroup(GroupConfig)
    end

    function Functions:TabSection(GroupConfig)
        return Functions:TabGroup(GroupConfig)
    end

    function Functions:Tab(TabConfig)
        return Functions:MakeTab(TabConfig)
    end

    function Functions:MakeDashboard(DashboardConfig)
        DashboardConfig = TranslateConfig(DashboardConfig or {})
        DashboardConfig.Title = DashboardConfig.Title or DashboardConfig.Name or "Dashboard"
        DashboardConfig.Description = DashboardConfig.Description
            or DashboardConfig.Desc
            or DashboardConfig.Content
            or "Track live hub state and open feature pages from cards."
        DashboardConfig.Icon = ResolveIcon(DashboardConfig.Icon or "layout-dashboard")
        DashboardConfig.Color = DashboardConfig.Color or GetThemeValue("Accent", Color3.fromRGB(96, 165, 250))

        local Dashboard, DashboardTab = Functions:MakeTab({
            Title = DashboardConfig.Title,
            Icon = DashboardConfig.Icon,
            Visible = DashboardConfig.Visible ~= false,
            Disabled = DashboardConfig.Disabled == true,
        })

        Dashboard:TabBox({
            Title = DashboardConfig.Title,
            Description = DashboardConfig.Description,
            Icon = DashboardConfig.Icon,
            Color = DashboardConfig.Color,
        })

        if type(DashboardConfig.Stats) == "table" then
            for _, StatConfig in ipairs(DashboardConfig.Stats) do
                Dashboard:StatCard(StatConfig)
            end
        end

        if type(DashboardConfig.Cards) == "table" then
            for _, CardConfig in ipairs(DashboardConfig.Cards) do
                Dashboard:TabCard(CardConfig)
            end
        end

        if type(DashboardConfig.Build) == "function" then
            OrionLib:SafeScript(DashboardConfig.Build, Dashboard, DashboardTab)
        end

        Dashboard.DashboardTab = DashboardTab
        return Dashboard, DashboardTab
    end

    function Functions:Dashboard(DashboardConfig)
        return Functions:MakeDashboard(DashboardConfig)
    end

    function Functions:DashBoard(DashboardConfig)
        return Functions:MakeDashboard(DashboardConfig)
    end

    function Functions:SelectTab(tab)
        if type(tab) == "string" then
            tab = TabName[tab]
        end
        if type(tab) == "table" and type(tab.Select) == "function" then
            tab:Select()
            return true
        end
        return false
    end

    function Functions:RefreshPages()
        if
            Functions.SelectedTab
            and Functions.SelectedTab.Visible
            and not Functions.SelectedTab.Disabled
            and type(Functions.SelectedTab.Select) == "function"
        then
            Functions.SelectedTab:Select()
            return true
        end
        for _, tab in ipairs(AllTabs) do
            if tab.Visible and not tab.Disabled and type(tab.Select) == "function" then
                tab:Select()
                return true
            end
        end
        return false
    end

    function Functions:GetTabs()
        local tabs = {}
        for _, tab in ipairs(AllTabs) do
            table.insert(tabs, tab)
        end
        return tabs
    end

    function Functions:SetTitle(title)
        WindowConfig.Name = tostring(title or WindowConfig.Name)
        WindowName.Text = WindowConfig.Name
    end

    function Functions:SetIcon(icon)
        WindowConfig.Icon = ResolveImageLikeAsset(ResolveIcon(icon or WindowConfig.Icon))
        local topBar = MainWindow:FindFirstChild("TopBar")
        if topBar then
            for _, child in ipairs(topBar:GetChildren()) do
                if child:IsA("ImageLabel") and child.Name ~= "Ico" then
                    ApplyIconToObject(child, WindowConfig.Icon, 32)
                    break
                end
            end
        end
    end

    function Functions:AddTopbarButton(ButtonConfig)
        ButtonConfig = TranslateConfig(ButtonConfig or {})
        local width = ButtonConfig.Width or (ButtonConfig.Title and 104 or 30)
        local button = OrionLib:AddThemeObject(
            SetChildren(
                SetProps(MakeElement("Button"), {
                    Parent = TopbarButtonHolder,
                    Size = UDim2.fromOffset(width, 30),
                    BackgroundTransparency = ButtonConfig.Transparency or 0,
                    LayoutOrder = ButtonConfig.Order or #TopbarButtonHolder:GetChildren(),
                    Name = ButtonConfig.Name or ButtonConfig.Title or "TopbarButton",
                    Active = true,
                    AutoButtonColor = false,
                    ZIndex = 41,
                }),
                {
                    MakeElement("Corner", 0, 8),
                    OrionLib:AddThemeObject(MakeElement("Stroke", nil, 1), "Stroke"),
                }
            ),
            "Second"
        )

        local iconImage
        if ButtonConfig.Icon or not ButtonConfig.Title then
            iconImage = OrionLib:AddThemeObject(
                SetProps(MakeElement("Image", ResolveIcon(ButtonConfig.Icon or "sparkles")), {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, ButtonConfig.Title and 10 or 7, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    ImageTransparency = 0.08,
                    Parent = button,
                    Name = "Ico",
                    ZIndex = 42,
                }),
                "Text"
            )
        end

        local label
        if ButtonConfig.Title then
            label = OrionLib:AddThemeObject(
                SetProps(MakeElement("Label", ButtonConfig.Title, 12), {
                    Size = UDim2.new(1, iconImage and -32 or -16, 1, 0),
                    Position = UDim2.new(0, iconImage and 32 or 8, 0, 0),
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = button,
                    Name = "Title",
                    ZIndex = 42,
                }),
                "Text"
            )
        end

        local api = { Button = button }
        function api:SetVisible(state)
            button.Visible = state == true
        end
        function api:SetIcon(icon)
            if iconImage then
                ApplyIconToObject(iconImage, ResolveIcon(icon), 32)
            end
        end
        function api:SetTitle(title)
            if label then
                label.Text = tostring(title or "")
            end
        end
        function api:Destroy()
            button:Destroy()
        end
        function api:SetTarget(target)
            ButtonConfig.Tab = target
            ButtonConfig.Target = target
        end

        AddConnection(button.MouseEnter, function()
            TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
                BackgroundColor3 = ColorAdd(GetThemeValue("Second", OrionLib.Themes.Default.Second), 5),
            }):Play()
        end)
        AddConnection(button.MouseLeave, function()
            TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
                BackgroundColor3 = GetThemeValue("Second", OrionLib.Themes.Default.Second),
            }):Play()
        end)
        AddConnection(button.MouseButton1Click, function()
            local target = ButtonConfig.Tab or ButtonConfig.Target or ButtonConfig.Page
            if target ~= nil then
                Functions:SelectTab(target)
            end
            local callback = ButtonConfig.Callback or ButtonConfig.OnClick
            if type(callback) == "function" then
                OrionLib:SafeScript(callback, api)
            end
        end)
        return api
    end

    function Functions:TopbarButton(ButtonConfig)
        return Functions:AddTopbarButton(ButtonConfig)
    end

    function Functions:Popup(config)
        return OrionLib:Popup(config)
    end

    function Functions:Dialog(config)
        return OrionLib:Dialog(config)
    end

    function Functions:LoadingScreen(config)
        return OrionLib:LoadingScreen(config)
    end

    function Functions:CreateBootstrapLoader(config)
        return OrionLib:CreateBootstrapLoader(config)
    end

    function Functions:SetKeyBindMenuVisible(state)
        OrionLib:SetKeyBindVisible(state == true)
    end

    function Functions:ToggleKeyBindMenu()
        OrionLib:ToggleKeyBindMenu()
    end

    function Functions:Open()
        MainWindow.Visible = true
        MobileReopenButton.Visible = false
    end

    function Functions:Close()
        MainWindow.Visible = false
        if UserInputService.TouchEnabled then
            MobileReopenButton.Visible = true
        end
    end

    function Functions:Toggle()
        MainWindow.Visible = not MainWindow.Visible
        MobileReopenButton.Visible = not MainWindow.Visible and UserInputService.TouchEnabled
    end

    function Functions:SetToggleKey(key)
        OrionLib:SetKeyToggleUI(key)
    end

    function Functions:SetUIScale(scale)
        scale = tonumber(scale) or 1
        local existing = MainWindow:FindFirstChildOfClass("UIScale")
        if not existing then
            existing = Create("UIScale", { Parent = MainWindow })
        end
        existing.Scale = scale
    end

    function Functions:SetPanelBackground(visible)
        WindowStuff.BackgroundTransparency = visible == false and 1 or 0
    end

    function Functions:SetBackgroundImage(image)
        OrionLib:SetVideoLink(image)
    end

    function Functions:SetBackgroundImageTransparency(transparency)
        if MainWindowVideo then
            MainWindowVideo.BackgroundTransparency = transparency or 0
        end
    end

    function Functions:Tag(TagConfig)
        TagConfig = TranslateConfig(TagConfig or {})
        local tag = OrionLib:MakeWatermark({ Text = (TagConfig.Title or TagConfig.Name or "Tag"), Visible = true })
        return tag
    end

    function Functions:OnOpen(callback)
        if type(callback) == "function" then
            AddConnection(MainWindow:GetPropertyChangedSignal("Visible"), function()
                if MainWindow.Visible then
                    OrionLib:SafeScript(callback)
                end
            end)
        end
    end

    function Functions:OnClose(callback)
        if type(callback) == "function" then
            AddConnection(MainWindow:GetPropertyChangedSignal("Visible"), function()
                if not MainWindow.Visible then
                    OrionLib:SafeScript(callback)
                end
            end)
        end
    end

    function Functions:OnDestroy(callback)
        OrionLib:OnDestroy(callback)
    end

    function Functions:MakeSettingsTab(SettingsConfig)
        SettingsConfig = TranslateConfig(SettingsConfig or {})
        SettingsConfig.Name = SettingsConfig.Name or SettingsConfig.Title or "Settings"
        SettingsConfig.Icon = SettingsConfig.Icon or "settings"
        local tab = Functions:MakeTab(SettingsConfig)
        OrionLib:BuildSettings(tab)
        return tab
    end

    function Functions:SettingsTab(SettingsConfig)
        return Functions:MakeSettingsTab(SettingsConfig)
    end

    function Functions:Destroy()
        for _, Connection in next, OrionLib.Connections do
            Connection:Disconnect()
        end
        MainWindow:Destroy()
        MobileIcon:Destroy()
    end
    if type(WindowConfig.TopbarButtons) == "table" then
        if WindowConfig.TopbarButtons.Title or WindowConfig.TopbarButtons.Icon then
            Functions:AddTopbarButton(WindowConfig.TopbarButtons)
        else
            for _, buttonConfig in ipairs(WindowConfig.TopbarButtons) do
                Functions:AddTopbarButton(buttonConfig)
            end
        end
    end
    return Functions
end

function OrionLib:CreateWindow(WindowConfig)
    return OrionLib:MakeWindow(NormalizeWindowConfig(WindowConfig))
end

function OrionLib:Window(WindowConfig)
    return OrionLib:CreateWindow(WindowConfig)
end

function OrionLib:BuildSettings(Tab: table)
    Tab:AddToggle({
        Name = "Toggle Keybind",
        Default = false,
        Callback = function(Value)
            OrionLib:SetKeyBindVisible(Value)
        end,
    })

    local function WatermarkFound()
        for i, v in pairs(Orion:GetChildren()) do
            if v:IsA("Frame") and v.Name:lower():find("watermark") then
                return v
            end
        end
        return nil
    end

    local ThemeList = {}
    for i in pairs(OrionLib.Themes) do
        table.insert(ThemeList, i)
    end

    local FoundWatermark = WatermarkFound()
    if FoundWatermark then
        Tab:AddToggle({
            Name = "Toggle Watermark",
            Default = FoundWatermark.Visible,
            Callback = function(Value)
                for i, v in pairs(Orion:GetChildren()) do
                    if v:IsA("Frame") and v.Name:lower():find("watermark") then
                        v.Visible = Value
                    end
                end
            end,
        })
    end

    Tab:AddSlider({
        Name = "Notify Volume",
        Min = 0,
        Max = 10,
        Increment = 0.5,
        Value = OrionLib.NotifyVolume,
        Color = Color3.fromRGB(255, 255, 255),
        ValueName = "Volume",
        Callback = function(value)
            OrionLib.NotifyVolume = value
        end,
    })

    Tab:AddButton({
        Name = "Destroy Orion",
        Callback = function()
            OrionLib:Destroy()
        end,
    })

    local configName = Tab:AddTextbox({
        Name = "Config Name",
    })

    local configList = Tab:AddDropdown({
        Name = "Configs List",
        Options = GetSavedConfigs(),
    })

    Tab:AddDivider()
    Tab:AddButton({
        Name = "Create Config",
        Callback = function()
            local name = configName.Value
            if name:gsub(" ", "") == "" then
                return
            end
            local success, error = SaveConfig(name)
            if success then
                OrionLib:MakeNotification({ Name = "[Save Config]", Content = string.format("Created config: %s", name), Time = 5 })
            else
                OrionLib:MakeNotification({ Name = "[Save Config]", Content = string.format("Failed to create config: %s", name), Time = 5 })
            end
            configList:Refresh(GetSavedConfigs(), true)
        end,
    })

    Tab:AddButton({
        Name = "Load Config",
        Callback = function()
            local name = configList.Value
            if not name then
                return OrionLib:MakeNotification({ Name = "[Save Config]", Content = "Select a config to load", Time = 5 })
            end
            local success, error = LoadConfig(name)
            if success then
                OrionLib:MakeNotification({ Name = "[Save Config]", Content = string.format("Loaded config: %s", name), Time = 5 })
            else
                OrionLib:MakeNotification({ Name = "[Save Config]", Content = string.format("Failed to load config: %s\nError: %s", name, error), Time = 5 })
            end
        end,
    })

    Tab:AddButton({
        Name = "Overwrite Config",
        DoubleClick = true,
        Callback = function()
            local name = configList.Value
            if not name then
                return OrionLib:MakeNotification({ Name = "[Save Config]", Content = "Select a config to load", Time = 5 })
            end
            local success, error = SaveConfig(name)
            if success then
                OrionLib:MakeNotification({ Name = "[Save Config]", Content = string.format("Overwrote config: %s", name), Time = 5 })
            else
                OrionLib:MakeNotification({ Name = "[Save Config]", Content = string.format("Failed to overwrite config: %s", name), Time = 5 })
            end
        end,
    })

    Tab:AddButton({
        Name = "Set as Autoload",
        Callback = function()
            local name = configList.Value
            if not name then
                return OrionLib:MakeNotification({ Name = "[Save Config]", Content = "Select a config to autoload", Time = 5 })
            end
            OrionLib:SetAutoloadConfig(name)
            OrionLib:MakeNotification({ Name = "[Save Config]", Content = string.format('Set "%s" to autoload', name), Time = 5 })
        end,
    })

    Tab:AddButton({
        Name = "Set as Unautoload",
        Callback = function()
            local name = configList.Value
            if not name then
                return OrionLib:MakeNotification({ Name = "[Save Config]", Content = "Select a config to Unautoload", Time = 5 })
            end
            OrionLib:SetUnAutoloadConfig(name)
            OrionLib:MakeNotification({ Name = "[Save Config]", Content = string.format('Set "%s" to Unautoload', name), Time = 5 })
        end,
    })

    Tab:AddButton({
        Name = "Refresh List",
        Callback = function()
            configList:Refresh(GetSavedConfigs(), true)
        end,
    })

    Tab:AddDivider()
    local themeList = Tab:AddDropdown({
        Name = "Theme List",
        Options = ThemeList,
    })

    Tab:AddButton({
        Name = "Refresh List",
        Callback = function()
            local ThemeList = {}
            for i in pairs(OrionLib.Themes) do
                table.insert(ThemeList, i)
            end
            themeList:Refresh(ThemeList, true)
        end,
    })

    Tab:AddButton({
        Name = "Set Theme",
        Callback = function()
            OrionLib:SetTheme(themeList.Value)
        end,
    })

    if Orion and Orion:FindFirstChildWhichIsA("VideoFrame") then
        Tab:AddDivider()

        local VideoLink = Tab:AddTextbox({
            Name = "Video Link",
        })

        Tab:AddButton({
            Name = "Set Video Main",
            Callback = function()
                OrionLib:SetVideoLink(VideoLink.Value)
            end,
        })
    end
end

function OrionLib:Destroy()
    for _, fn in next, OrionLib.OnDestroyTo do
        pcall(fn)
    end
    for _, conn in next, OrionLib.Connections do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    if Orion then
        Orion:Destroy()
    end
    getgenv().Destroy = true
end

function OrionLib:OnDestroy(fn)
    if type(fn) == "function" then
        table.insert(OrionLib.OnDestroyTo, fn)
    end
end

return OrionLib
