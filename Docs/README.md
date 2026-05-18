# OrionLib Modded — Orion x WindUI

This repo now keeps the main library source in [`scr/Orion.lua`](../scr/Orion.lua) so contributors and AI tools can read the implementation without digging through example/bootstrap code. The root [`Orion.lua`](../Orion.lua) is a small compatibility entrypoint that loads the source file when `readfile`/`loadstring` are available.

## Quick start

`scr/Orion.lua` now returns the library only; it does not auto-create a demo window. This is important for key systems because the protected window is not built until the key check passes.

```lua
local OrionLib = loadstring(readfile("scr/Orion.lua"))()

local Window = OrionLib:CreateWindow({
    Title = "Demo UI",
    Theme = "Dark",
    Icon = "sparkles",
    SidebarCompact = true,
    SidebarCompactWidth = 48,
    KeySystem = {
        Enabled = true,
        Keys = {"MY-KEY"},
        SaveKey = true,
        FileName = "DemoKey.txt"
    }
})

local Main = Window:Tab({ Title = "Main", Icon = "home" })
local IconTab = Window:Tab({ Title = "Fast", Icon = "zap" })

Main:HighlightButton({
    Title = "Run Action",
    Icon = "play",
    Color = Color3.fromRGB(90, 140, 255),
    Callback = function()
        OrionLib:Notify({ Title = "Done", Content = "Action completed" })
    end
})

Main:Dropdown({
    Title = "Mode",
    Options = {"Normal", "Fast", "Safe"},
    Default = "Normal",
    Callback = print
})
```

## Project structure

- `scr/Orion.lua` — main library implementation.
- `Orion.lua` — compatibility loader for older scripts.
- `example.lua` — full WindUI-style usage sample.
- `Docs/README.md` — this documentation.

## New WindUI-style additions

### Window API

- `OrionLib:CreateWindow(config)` / `OrionLib:Window(config)` are aliases around Orion's `MakeWindow`.
- Window config accepts `Title`, `Author`, `Folder`, `Icon`, `Video`, `Background`, and `HideSearchBar` in addition to existing Orion fields.
- Window methods include `Tab`, `Open`, `Close`, `Toggle`, `SetToggleKey`, `SetUIScale`, `SetPanelBackground`, `SetBackgroundImage`, `OnOpen`, `OnClose`, and `OnDestroy`.

### Tabs

Tabs now support animated selection and a left-side highlight marker. Use `SidebarCompact = true` on the window to make every tab icon-only like Obsidian's compact sidebar. The default compact width is `48`, matching Obsidian's `SidebarCompactWidth`; per-tab `IconOnly = true` still works for one-off cases.

```lua
Window:Tab({ Title = "Main", Icon = "home" })
Window:Tab({ Title = "Only Icon", Icon = "zap" }) -- text hidden when SidebarCompact = true
```



### GroupBox and WarningBox

`GroupBox` creates an Obsidian-style framed group that can contain regular elements. `WarningBox` creates a page-style callout with a Lucide warning icon.

```lua
local Group = Main:GroupBox({ Title = "GroupBox" })
Group:Button({ Title = "Inside Group", Icon = "box" })

Main:WarningBox({
    Title = "Heads up",
    Desc = "This page uses Lucide icons only."
})
```

### Settings tab

Use `Window:SettingsTab()` to add Orion's built-in settings page with a Lucide settings icon; in compact sidebar mode it renders as an icon-only settings tab.

```lua
Window:SettingsTab({ Title = "Settings", Icon = "settings" })
```

### Mobile support

The window clamps to the current viewport on mobile, the top bar uses a touch-friendly drag handle, and the resize control is larger on touch devices. Minimize/restore now hides the resize button while collapsed and uses shorter tweens for smoother mobile behavior.

### Elements

WindUI-style element aliases are available on tabs and sections:

- `Button`
- `HighlightButton`
- `WarningBox`
- `GroupBox`
- `Toggle`
- `Slider`
- `Dropdown`
- `Input`
- `Colorpicker`
- `Paragraph`
- `Section`
- `Divider`
- `Space`
- `Image`

`HighlightButton` adds an animated accent bar and color customization:

```lua
Main:HighlightButton({
    Title = "Important",
    Color = Color3.fromRGB(255, 180, 80),
    Callback = function() print("clicked") end
})
```

### Key system

The key system can be enabled or disabled from the window config. When enabled, it opens before the main UI is built.

```lua
local Window = OrionLib:CreateWindow({
    Title = "Protected UI",
    KeySystem = {
        Enabled = true,
        Title = "Access Required",
        Subtitle = "Paste your key to continue",
        Keys = {"ABC-123", "DEV-KEY"},
        SaveKey = true,
        FileName = "ProtectedUIKey.txt",
        Link = "https://example.com/get-key"
    }
})
```

You can also provide custom validation:

```lua
KeySystem = {
    Enabled = true,
    Callback = function(input)
        return input == "custom-key"
    end
}
```

Set `Enabled = false` to turn the key system off without removing the config.

## Lucide icons

OrionLib resolves icons through a Lucide-compatible provider first, using the same `GetAsset(iconName, size)` shape as `lucide-roblox` / Obsidian-style Lucide ports. The library auto-loads `deividcomsono/lucide-roblox-direct` (the Lucide source used by Obsidian-style ports) and no longer falls back to Orion/Feather icons.

```lua
-- Optional: plug in a Lucide provider/module before creating windows.
OrionLib:SetLucideProvider(Lucide)

local asset = OrionLib:GetIcon("home", 48)
-- asset.Image / asset.ImageRectOffset / asset.ImageRectSize are applied automatically
-- by OrionLib-created Image, RoundImage, and ImageButton instances.
```

Supported icon names are normalized, so values like `lucide-home`, `lucide:home`, `home`, and some WindUI-style names resolve consistently.

## Themes and localization

```lua
OrionLib:AddTheme({
    Name = "Custom",
    Main = Color3.fromRGB(20, 20, 28),
    Second = Color3.fromRGB(30, 30, 40),
    Stroke = Color3.fromRGB(70, 70, 90),
    Divider = Color3.fromRGB(70, 70, 90),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(170, 170, 185)
})

OrionLib:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        en = { start = "Start" },
        vi = { start = "Bắt đầu" }
    }
})
```

## Troubleshooting

### `attempt to concatenate string with nil` when creating a window

If you use a Lucide icon name such as `"sparkles"` or `"home"` for `Icon`/`IntroIcon`, OrionLib now routes it through the shared icon resolver instead of forcing a numeric Roblox asset id. This means all of these are valid:

```lua
Icon = "sparkles"
Icon = "rbxassetid://14229447778"
Icon = 14229447778
```

The same resolver is used for notification icons and window intro icons, so Lucide names with digits like `"trash-2"` will no longer be mistaken for Roblox asset id `2`.
