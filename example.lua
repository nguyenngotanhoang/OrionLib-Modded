-- OrionLib x WindUI style example
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/tanhoangviet/OrionLib-Modded/main/scr/Orion.lua?cache=" .. tostring(os.time())))()

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

local StartedAt = os.clock()
local Window = OrionLib:CreateWindow({
    Title = "Orion x WindUI Demo",
    Author = "Open source UI example",
    Theme = "Midnight",
    Icon = "sparkles",
    Size = UDim2.fromOffset(650, 390),
    SidebarCompact = true,
    SidebarCompactWidth = 48,
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
})

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
