# OrionLib Modded — Orion x WindUI

This repo now keeps the main library source in [`scr/Orion.lua`](../scr/Orion.lua) so contributors and AI tools can read the implementation without digging through example/bootstrap code. The root [`Orion.lua`](../Orion.lua) is a small compatibility entrypoint that loads the source file when `readfile`/`loadstring` are available.

## Quick start

`scr/Orion.lua` now returns the library only; it does not auto-create a demo window. This is important for key systems because the protected window is not built until the key check passes.

```lua
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/tanhoangviet/OrionLib-Modded/main/scr/Orion.lua?cache=" .. tostring(os.time())))()

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

- `scr/Orion.lua` — runtime bundle entrypoint and main implementation.
- `scr/theme/palette.lua` — built-in themes and shared style tokens.
- `scr/component/factory.lua` — reusable UI creation, layout, color, and hover helpers.
- `scr/window/config.lua` — public window config alias normalizer.
- `scr/README.md` — contributor layout notes for the source bundle.
- `Orion.lua` — compatibility loader for older scripts.
- `example.lua` — full WindUI-style usage sample.
- `Docs/README.md` — this documentation.

## New WindUI-style additions

### Window API

- `OrionLib:CreateWindow(config)` / `OrionLib:Window(config)` are aliases around Orion's `MakeWindow`.
- Window config accepts `Title`, `Author`, `Folder`, `Icon`, `Video`, `Background`, `TopbarButtons`, and `HideSearchBar` in addition to existing Orion fields.
- Window methods include `Dashboard`, `Tab`, `TabGroup`, `SelectTab`, `GetTabs`, `AddTopbarButton`, `Popup`, `Dialog`, `LoadingScreen`, `CreateBootstrapLoader`, `Open`, `Close`, `Toggle`, `SetToggleKey`, `SetUIScale`, `SetPanelBackground`, `SetBackgroundImage`, `ToggleKeyBindMenu`, `OnOpen`, `OnClose`, and `OnDestroy`.

### Loading, popup, dialog, and topbar buttons

`OrionLib:LoadingScreen()` / `OrionLib:CreateBootstrapLoader()` can be shown before creating the window. Loading hides the existing Orion UI by default, uses a rotating loader icon, and keeps the background transparent. `Popup` and `Dialog` use the same OrionLib theme objects, rounded cards, strokes, icons, and resized Orion-style buttons as the main UI; pass `Dim = true` only if you want a darkened backdrop. Topbar buttons can be configured up front or added later.

```lua
local Loader = OrionLib:CreateBootstrapLoader({ Title = "Loading", AutoClose = false })
Loader:SetProgress(0.5, "Building UI")

local Window = OrionLib:CreateWindow({
    Title = "Demo",
    TopbarButtons = {
        { Icon = "bell", Callback = function() OrionLib:Popup({ Title = "Popup", Description = "Hello" }) end }
    }
})

Window:AddTopbarButton({
    Icon = "layout-dashboard",
    Title = "Dash",
    Tab = "Dashboard" -- or use Callback = function() ... end
})

Loader:SetProgress(1, "Ready")
Loader:Close()
```

### Tabs

Tabs now support animated selection and a left-side highlight marker. Use `SidebarCompact = true` on the window to make every tab icon-only like Obsidian's compact sidebar. The default compact width is `48`, matching Obsidian's `SidebarCompactWidth`; per-tab `IconOnly = true` still works for one-off cases.

```lua
Window:Tab({ Title = "Main", Icon = "home" })
Window:Tab({ Title = "Only Icon", Icon = "zap" }) -- text hidden when SidebarCompact = true
```

### Tab groups

`TabGroup` adds collapsible sidebar groups while each grouped tab keeps the normal tab API. `GroupTab` and `TabSection` are aliases.

```lua
local Gameplay = Window:TabGroup({ Title = "Gameplay", Icon = "folder" })
local Combat = Gameplay:Tab({ Title = "Combat", Icon = "sword" })

Combat:SetBadge("2")
Window:SelectTab("Combat")
```

### Dashboard and TabCard

`Dashboard` creates a first-class overview tab with a `TabBox`, live `StatCard`s, and gradient `TabCard`s. By default, every `TabCard` creates its own dedicated tab and inserts a matching `TabBox`.

```lua
local Dashboard = Window:Dashboard({
    Title = "Dashboard",
    Description = "Hub overview and live status.",
    Stats = {
        { Title = "Players", Icon = "solar:users-group-rounded-bold-duotone", Value = function() return #game:GetService("Players"):GetPlayers() end, Interval = 2 },
        { Title = "Uptime", Icon = "solar:clock-circle-bold-duotone", Value = function() return tostring(os.time()) end, Interval = 1 }
    }
})

Dashboard:TabCard({
    Title = "Combat",
    Description = "Creates a dedicated combat card page.",
    Icon = "solar:sword-bold-duotone",
    Color = Color3.fromRGB(248, 113, 113),
    Build = function(Tab)
        Tab:Button({ Title = "Card Combat Button", Icon = "tabler:sword" })
    end
})
```

To intentionally route a card into an existing tab, pass `UseExistingTab = true` with `Tab`, `Target`, or `Page`.

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
- `TabBox`
- `TabCard`
- `StatCard`
- `DiscordServer`
- `Graph`
- `RichLabel`
- `AdvancedLabel`
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

`Graph` / `RichLabel` creates a RichText card that can also contain nested controls:

```lua
local Graph = Main:Graph({
    Title = "Stats",
    Content = '<b>RichText</b> label with <font color="#38BDF8">accent text</font>.',
    Points = {12, 24, 18, 34, 29, 46},
    GraphHeight = 82
})

Graph:Button({ Title = "Refresh", Callback = function() Graph:AddPoint(math.random(10, 60), 10) end })
Graph:Toggle({ Title = "Enabled", Value = true })
```

`DiscordServer` creates a highlighted themed server card with thumbnail, icon, and a GroupBox-style copy button:

```lua
Main:DiscordServer({
    Title = "Community",
    Description = "Join the hub Discord server.",
    Invite = "https://discord.gg/example",
    Thumbnail = "https://example.com/banner.png",
    Icon = "message-circle",
    CopyCallback = function() print("copied") end
})
```

### Key system

The key system can be enabled or disabled from the window config. When enabled, it opens before the main UI is built.
The key screen uses the same Orion x WindUI theme colors, rounded card, accent gradient, Lucide icon, and matching input/buttons.

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

### KeyBind menu

Toggle binds can be mirrored in the floating KeyBind menu. `Hold = true` turns the key into press-and-hold behavior.

```lua
Main:Toggle({ Title = "Sprint" }):AddBind({
    Default = Enum.KeyCode.F,
    Hold = true,
    Flag = "SprintBind"
})

Window:ToggleKeyBindMenu()
```

## Icons

OrionLib resolves icons through a Lucide-compatible provider first, using the same `GetAsset(iconName, size)` shape as `lucide-roblox` / Obsidian-style Lucide ports. The library auto-loads `deividcomsono/lucide-roblox-direct` (the Lucide source used by Obsidian-style ports) and no longer falls back to Orion/Feather icons.
It also supports Iconify icon-set prefixes from Icônes/Iconify, including `solar`, `tabler`, `ph`, `mdi`, `ri`, `heroicons`, `material-symbols`, and other `prefix:name` sets.

```lua
-- Optional: plug in a Lucide provider/module before creating windows.
OrionLib:SetLucideProvider(Lucide)

local asset = OrionLib:GetIcon("home", 48)
local solar = OrionLib:GetIcon("solar:home-2-bold-duotone", 48)
local tabler = OrionLib:GetIcon("tabler:settings", 48)
-- asset.Image / asset.ImageRectOffset / asset.ImageRectSize are applied automatically
-- by OrionLib-created Image, RoundImage, and ImageButton instances.
```

Supported icon names are normalized, so values like `lucide-home`, `lucide:home`, `home`, and some WindUI-style names resolve consistently. Use `OrionLib:SetIconSet("solar")` to make unprefixed names load from another Iconify set by default.

External HTTP images and Iconify icons are cached through `writefile`/`readfile` and then passed through `getcustomasset`/`getsynasset` when the executor supports those APIs. Iconify SVGs are requested through a PNG render proxy first because Roblox `ImageLabel` does not render raw SVG files reliably. Local file paths are also accepted directly:

```lua
local cached = OrionLib:ResolveAsset("https://example.com/icon.png", {
    Root = "OrionLibSave",
    Folder = "Images",
    Key = "example_icon"
})

Window:SetIcon(cached)
Main:Image({ Icon = "OrionLibSave/Images/example_icon.png" })
```

## Themes, style, and localization

```lua
OrionLib:AddTheme({
    Name = "Custom",
    Main = Color3.fromRGB(20, 20, 28),
    Second = Color3.fromRGB(30, 30, 40),
    Stroke = Color3.fromRGB(70, 70, 90),
    Divider = Color3.fromRGB(70, 70, 90),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(170, 170, 185),
    Accent = Color3.fromRGB(96, 165, 250),
    AccentDark = Color3.fromRGB(37, 99, 235)
})

OrionLib:SetStyle({
    WindowRadius = 12,
    CardRadius = 7,
    ElementHeight = 40
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
