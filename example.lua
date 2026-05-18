-- OrionLib x WindUI style example
-- Load from scr/Orion.lua while developing locally, or load Orion.lua for compatibility.
local OrionLib = loadstring(readfile("scr/Orion.lua"))()

OrionLib:AddTheme({
    Name = "Ocean",
    Main = Color3.fromRGB(10, 18, 30),
    Second = Color3.fromRGB(16, 30, 48),
    Stroke = Color3.fromRGB(66, 120, 170),
    Divider = Color3.fromRGB(45, 80, 120),
    Text = Color3.fromRGB(245, 250, 255),
    TextDark = Color3.fromRGB(160, 180, 205)
})

local Window = OrionLib:CreateWindow({
    Title = "Orion x WindUI Demo",
    Author = "Open source UI example",
    Theme = "Ocean",
    Icon = "sparkles",
    Size = UDim2.fromOffset(650, 390),
    SidebarCompact = true,
    SidebarCompactWidth = 48,
    KeySystem = {
        Enabled = true,
        Title = "Demo Key System",
        Subtitle = "Enter the demo key before loading the UI",
        Note = "Demo key: ORION-DEMO",
        Keys = {"ORION-DEMO"},
        SaveKey = false,
        Link = "https://github.com/Footagesus/WindUI"
    }
})

local Main = Window:Tab({
    Title = "Main",
    Icon = "home"
})

local Combat = Window:Tab({
    Title = "Combat",
    Icon = "sword"
})

Main:HighlightButton({
    Title = "Highlighted Action",
    Icon = "zap",
    Color = Color3.fromRGB(90, 140, 255),
    Callback = function()
        OrionLib:Notify({
            Title = "Highlight",
            Content = "The new highlight button was clicked.",
            Duration = 4
        })
    end
})


Main:WarningBox({
    Title = "Mobile ready",
    Desc = "SidebarCompact uses Lucide icons only and keeps the sidebar at 48px."
})

local SafeGroup = Main:GroupBox({
    Title = "GroupBox"
})

SafeGroup:Button({
    Title = "Grouped Button",
    Icon = "box",
    Callback = function()
        print("Grouped button clicked")
    end
})

Main:Dropdown({
    Title = "Mode Dropdown",
    Options = {"Normal", "Fast", "Legit", "Rage"},
    Default = "Normal",
    Callback = function(value)
        print("Dropdown value:", value)
    end
})

Main:Toggle({
    Title = "Enable Feature",
    Value = false,
    Callback = function(enabled)
        print("Toggle:", enabled)
    end
})

Main:Slider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 100,
    Value = 30,
    Increment = 1,
    Callback = function(value)
        print("Slider:", value)
    end
})

Combat:Paragraph({
    Title = "Icon-only tab",
    Desc = "This window uses SidebarCompact = true, so all tabs render icon-only with the animated highlight marker."
})

Combat:Button({
    Title = "Normal Button",
    Icon = "mouse-pointer-click",
    Callback = function()
        print("Combat button clicked")
    end
})

Window:SettingsTab({ Title = "Settings", Icon = "settings" })
