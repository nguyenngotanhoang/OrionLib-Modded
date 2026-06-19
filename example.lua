-- OrionLib x WindUI style example
local OrionSource = game:HttpGet("https://raw.githubusercontent.com/tanhoangviet/OrionLib-Modded/main/scr/Orion.lua?cache=" .. tostring(os.time()))
local OrionLib = loadstring(OrionSource, "OrionLib")()

OrionLib:AddTheme({
    Name = "Ocean",
    Main = Color3.fromRGB(10, 18, 30),
    Second = Color3.fromRGB(16, 30, 48),
    Stroke = Color3.fromRGB(66, 120, 170),
    Divider = Color3.fromRGB(45, 80, 120),
    Text = Color3.fromRGB(245, 250, 255),
    TextDark = Color3.fromRGB(160, 180, 205),
    Accent = Color3.fromRGB(56, 189, 248),
    AccentDark = Color3.fromRGB(2, 132, 199),
})

OrionLib:SetStyle({
    WindowRadius = 12,
    CardRadius = 7,
    ElementHeight = 40,
})

local Loader = OrionLib:CreateBootstrapLoader({
    Title = "Loading Orion",
    Content = "Caching icons and preparing Orion UI...",
    Icon = "solar:stars-bold-duotone",
    AutoClose = false,
    GlassConfig = {
        BackgroundTransparency = 0.3,
        StrokeTransparency = 0.78,
        ShadowTransparency = 0.72,
        ShadowBlur = 22,
    },
})
Loader:SetProgress(0.25, "Resolving local/custom assets")

local StartedAt = os.clock()
local Window = OrionLib:CreateWindow({
    Title = "Orion x WindUI Demo",
    Author = "Open source UI example",
    Theme = "Midnight",
    Icon = "sparkles",
    Size = UDim2.fromOffset(690, 430),
    TopbarTabs = true,
    Glass = true,
    GlassConfig = {
        BackgroundTransparency = 0.32,
        PageTransparency = 0.5,
        NavTransparency = 0.48,
        StrokeTransparency = 0.76,
        PageStrokeTransparency = 0.84,
        NavStrokeTransparency = 0.8,
        ShadowTransparency = 0.72,
        ShadowBlur = 24,
        Radius = 14,
        Accent = Color3.fromRGB(125, 211, 252),
    },
    TopbarButtons = {
        {
            Icon = "bell",
            Callback = function()
                OrionLib:Popup({
                    Title = "Topbar Popup",
                    Description = "This popup came from an optional topbar button.",
                    Icon = "bell",
                    Duration = 4,
                })
            end,
        },
    },
    --[[
    KeySystem = {
        Enabled = true,
        Title = "Demo Key System",
        Subtitle = "Enter the demo key before loading the UI",
        Note = "Demo key: ORION-DEMO",
        Icon = "key-round",
        Keys = { "ORION-DEMO" },
        SaveKey = false,
        Link = "https://github.com/Footagesus/WindUI",
    },
    ]]
    --
})

Loader:SetProgress(0.55, "Building window and dashboard")

local Dashboard = Window:Dashboard({
    Title = "Dashboard",
    Description = "Overview cards can open feature tabs, while stat cards update in real time.",
    Icon = "solar:widget-5-bold-duotone",
    Stats = {
        {
            Title = "Players",
            Icon = "solar:users-group-rounded-bold-duotone",
            Value = function()
                return #game:GetService("Players"):GetPlayers()
            end,
            Interval = 2,
        },
        {
            Title = "Uptime",
            Icon = "solar:clock-circle-bold-duotone",
            Value = function()
                return tostring(math.floor(os.clock() - StartedAt)) .. "s"
            end,
            Interval = 1,
        },
    },
})

local Main = Window:Tab({
    Title = "Main",
    Icon = "home",
})

local Gameplay = Window:TabGroup({
    Title = "Gameplay",
    Icon = "folder",
})

local Combat = Gameplay:Tab({
    Title = "Combat",
    Icon = "sword",
})

local Farming = Gameplay:Tab({
    Title = "Farming",
    Icon = "zap",
})

local GlassLab = Window:Tab({
    Title = "Glass Lab",
    Icon = "droplets",
})

pcall(function()
    Combat:SetBadge("2")
end)

Dashboard:TabCard({
    Title = "Main Controls",
    Description = "Creates a dedicated card tab instead of jumping into the existing Main tab.",
    Icon = "solar:home-2-bold-duotone",
    TabIcon = "solar:home-2-bold-duotone",
    Build = function(Tab)
        Tab:Paragraph({
            Title = "Dedicated TabCard Page",
            Desc = "This tab was created by the Dashboard card and includes its own TabBox automatically.",
        })
    end,
})

Dashboard:TabCard({
    Title = "Combat",
    Description = "Creates a dedicated combat card page with its own header.",
    Icon = "solar:sword-bold-duotone",
    TabIcon = "solar:sword-bold-duotone",
    Color = Color3.fromRGB(248, 113, 113),
    Build = function(Tab)
        Tab:Button({
            Title = "Card Combat Button",
            Icon = "tabler:sword",
            Callback = function()
                print("Card combat button clicked")
            end,
        })
    end,
})

Dashboard:TabCard({
    Title = "Farming",
    Description = "Creates a dedicated farming card page and demonstrates another icon set.",
    Icon = "ph:plant-duotone",
    TabIcon = "ph:plant-duotone",
    Color = Color3.fromRGB(52, 211, 153),
    Build = function(Tab)
        Tab:WarningBox({
            Title = "Farming Card",
            Desc = "This page was auto-created by TabCard.",
            Icon = "mdi:sprout",
        })
    end,
})

Main:TabBox({
    Title = "Main Controls",
    Description = "This page was opened from a Dashboard TabCard and uses the new TabBox header.",
    Icon = "house",
})

Main:HighlightButton({
    Title = "Highlighted Action",
    Icon = "zap",
    Color = Color3.fromRGB(90, 140, 255),
    Callback = function()
        OrionLib:Notify({
            Title = "Highlight",
            Content = "The new highlight button was clicked.",
            Duration = 4,
        })
    end,
})

Main:Button({
    Title = "Open Dialog",
    Icon = "message-circle-question",
    Callback = function()
        OrionLib:Dialog({
            Title = "Confirm Action",
            Description = "Dialog uses the same Orion theme and supports custom buttons.",
            Icon = "circle-help",
            ConfirmText = "Run",
            CancelText = "Cancel",
            OnConfirm = function()
                OrionLib:Notify({
                    Title = "Dialog",
                    Content = "Confirmed from dialog.",
                    Icon = "check",
                })
            end,
        })
    end,
})

Main:Button({
    Title = "Open Popup",
    Icon = "panel-top-open",
    Callback = function()
        Window:Popup({
            Title = "Popup",
            Description = "Popup can auto-close or stay until a button is pressed.",
            Icon = "sparkles",
            Duration = 5,
        })
    end,
})

Main:WarningBox({
    Title = "Mobile ready",
    Desc = "TopbarTabs keeps pages compact while Liquid Glass styling is applied to the window and pages.",
})

Main:DiscordServer({
    Title = "Orion Community",
    Description = "Highlighted server card with a GroupBox-style copy button.",
    Invite = "https://discord.gg/orionlib",
    Icon = "message-circle",
    Thumbnail = "https://images.unsplash.com/photo-1614680376593-902f74cf0d41?auto=format&fit=crop&w=900&q=80",
    Meta = "Public Discord server",
    CopyCallback = function()
        print("Discord invite copied")
    end,
})

local StatsGraph = Main:Graph({
    Title = "Rich Graph Label",
    Content = '<b>RichText</b> works here: <font color="#38BDF8">blue text</font>, live stats, and nested controls.',
    Points = { 12, 24, 18, 34, 29, 46, 40 },
    GraphHeight = 82,
    MaxPoints = 10,
})

StatsGraph:Button({
    Title = "Add Random Point",
    Icon = "plus",
    Callback = function()
        StatsGraph:AddPoint(math.random(10, 60), 10)
    end,
})

StatsGraph:Toggle({
    Title = "Graph Toggle Inside Label",
    Value = true,
    Callback = function(enabled)
        print("Graph nested toggle:", enabled)
    end,
})

local SafeGroup = Main:GroupBox({
    Title = "GroupBox",
})

SafeGroup:Button({
    Title = "Grouped Button",
    Icon = "box",
    Callback = function()
        print("Grouped button clicked")
    end,
})

Main:Dropdown({
    Title = "Mode Dropdown",
    Options = { "Normal", "Fast", "Legit", "Rage" },
    Default = "Normal",
    Callback = function(value)
        print("Dropdown value:", value)
    end,
})

Main:Toggle({
    Title = "Enable Feature",
    Value = false,
    Callback = function(enabled)
        print("Toggle:", enabled)
    end,
}):AddBind({
    Default = Enum.KeyCode.F,
    Hold = true,
    Flag = "FeatureHoldBind",
})

Main:Slider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 100,
    Value = 30,
    Increment = 1,
    Callback = function(value)
        print("Slider:", value)
    end,
})

Combat:Paragraph({
    Title = "Icon-only tab",
    Desc = "This window uses SidebarCompact = true, so all tabs render icon-only with the animated highlight marker.",
})

Combat:Button({
    Title = "Normal Button",
    Icon = "mouse-pointer-click",
    Callback = function()
        print("Combat button clicked")
    end,
})

Farming:Paragraph({
    Title = "Grouped tab",
    Desc = "This tab lives inside Window:TabGroup and can still use every normal element.",
})

GlassLab:TabBox({
    Title = "Liquid Glass Elements",
    Description = "GlassButton, GlassToggle, and GlassColorpicker use layered gradients, soft strokes, and translucent cards inspired by Roblox glassmorphism patterns.",
    Icon = "droplets",
    Glass = true,
    Color = Color3.fromRGB(125, 211, 252),
})

GlassLab:GlassButton({
    Title = "Liquid Glass Button",
    Icon = "sparkles",
    Color = Color3.fromRGB(56, 189, 248),
    Callback = function()
        OrionLib:Notify({
            Title = "Glass Button",
            Content = "Liquid glass button clicked.",
            Icon = "droplets",
            Duration = 3,
        })
    end,
})

GlassLab:GlassToggle({
    Title = "Liquid Glass Toggle",
    Value = true,
    Color = Color3.fromRGB(52, 211, 153),
    Callback = function(enabled)
        print("Glass toggle:", enabled)
    end,
})

GlassLab:GlassColorpicker({
    Title = "Glass Morph Color Picker",
    Default = Color3.fromRGB(125, 211, 252),
    Alpha = true,
    Callback = function(color, alpha)
        print("Glass color:", color, alpha)
    end,
})

local GlassGroup = GlassLab:GroupBox({
    Title = "Glass GroupBox",
    Glass = true,
})

GlassGroup:GlassButton({
    Title = "Nested Glass Action",
    Icon = "wand-sparkles",
    Callback = function()
        print("Nested glass action")
    end,
})

GlassGroup:GlassToggle({
    Title = "Nested Glass Toggle",
    Value = false,
})

Window:SettingsTab({ Title = "Settings", Icon = "settings" })
Window:RefreshPages()

Window:AddTopbarButton({
    Icon = "layout-dashboard",
    Title = "Dash",
    Width = 76,
    Tab = Dashboard,
})

Loader:SetProgress(1, "Ready")
task.delay(0.35, function()
    Loader:Close()
end)
