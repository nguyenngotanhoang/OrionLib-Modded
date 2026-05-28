-- OrionLib x WindUI style example
local TweenService = game:GetService("TweenService")
local BootstrapGui = Instance.new("ScreenGui")
BootstrapGui.Name = "OrionBootstrapLoader"
BootstrapGui.ResetOnSpawn = false
BootstrapGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
BootstrapGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local BootstrapBackdrop = Instance.new("Frame")
BootstrapBackdrop.Size = UDim2.fromScale(1, 1)
BootstrapBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BootstrapBackdrop.BackgroundTransparency = 0.25
BootstrapBackdrop.Parent = BootstrapGui

local BootstrapCard = Instance.new("Frame")
BootstrapCard.AnchorPoint = Vector2.new(0.5, 0.5)
BootstrapCard.Position = UDim2.fromScale(0.5, 0.5)
BootstrapCard.Size = UDim2.fromOffset(320, 112)
BootstrapCard.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
BootstrapCard.BorderSizePixel = 0
BootstrapCard.Parent = BootstrapBackdrop
Instance.new("UICorner", BootstrapCard).CornerRadius = UDim.new(0, 14)

local BootstrapTitle = Instance.new("TextLabel")
BootstrapTitle.BackgroundTransparency = 1
BootstrapTitle.Position = UDim2.fromOffset(18, 18)
BootstrapTitle.Size = UDim2.new(1, -36, 0, 24)
BootstrapTitle.Font = Enum.Font.GothamBlack
BootstrapTitle.Text = "Loading OrionLib"
BootstrapTitle.TextColor3 = Color3.fromRGB(245, 247, 252)
BootstrapTitle.TextSize = 18
BootstrapTitle.TextXAlignment = Enum.TextXAlignment.Left
BootstrapTitle.Parent = BootstrapCard

local BootstrapStatus = Instance.new("TextLabel")
BootstrapStatus.BackgroundTransparency = 1
BootstrapStatus.Position = UDim2.fromOffset(18, 46)
BootstrapStatus.Size = UDim2.new(1, -36, 0, 20)
BootstrapStatus.Font = Enum.Font.Gotham
BootstrapStatus.Text = "Fetching library source..."
BootstrapStatus.TextColor3 = Color3.fromRGB(156, 164, 181)
BootstrapStatus.TextSize = 13
BootstrapStatus.TextXAlignment = Enum.TextXAlignment.Left
BootstrapStatus.Parent = BootstrapCard

local BootstrapBarBack = Instance.new("Frame")
BootstrapBarBack.Position = UDim2.new(0, 18, 1, -24)
BootstrapBarBack.Size = UDim2.new(1, -36, 0, 7)
BootstrapBarBack.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
BootstrapBarBack.BorderSizePixel = 0
BootstrapBarBack.Parent = BootstrapCard
Instance.new("UICorner", BootstrapBarBack).CornerRadius = UDim.new(1, 0)

local BootstrapBar = Instance.new("Frame")
BootstrapBar.Size = UDim2.fromScale(0.35, 1)
BootstrapBar.BackgroundColor3 = Color3.fromRGB(96, 165, 250)
BootstrapBar.BorderSizePixel = 0
BootstrapBar.Parent = BootstrapBarBack
Instance.new("UICorner", BootstrapBar).CornerRadius = UDim.new(1, 0)
TweenService:Create(BootstrapBar, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.65, 1) }):Play()

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/tanhoangviet/OrionLib-Modded/main/scr/Orion.lua?cache=" .. tostring(os.time())))()
BootstrapStatus.Text = "Library loaded"
TweenService:Create(BootstrapBar, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromScale(1, 1) }):Play()
task.delay(0.2, function()
    BootstrapGui:Destroy()
end)

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

local Loader = OrionLib:LoadingScreen({
    Title = "Loading Orion",
    Content = "Caching icons and preparing UI...",
    Icon = "solar:stars-bold-duotone",
    AutoClose = false,
})
Loader:SetProgress(0.25, "Resolving local/custom assets")

local StartedAt = os.clock()
local Window = OrionLib:CreateWindow({
    Title = "Orion x WindUI Demo",
    Author = "Open source UI example",
    Theme = "Midnight",
    Icon = "sparkles",
    Size = UDim2.fromOffset(650, 390),
    SidebarCompact = true,
    SidebarCompactWidth = 48,
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
    Desc = "SidebarCompact uses Lucide icons only and keeps the sidebar at 48px.",
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

Window:SettingsTab({ Title = "Settings", Icon = "settings" })
Window:RefreshPages()

Window:AddTopbarButton({
    Icon = "layout-dashboard",
    Title = "Dash",
    Width = 76,
    Callback = function()
        Window:SelectTab(Dashboard)
    end,
})

Loader:SetProgress(1, "Ready")
task.delay(0.35, function()
    Loader:Close()
end)
