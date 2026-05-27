return function(context)
    local OrionLib = context.OrionLib
    local TranslateConfig = context.TranslateConfig
    local ResolveIcon = context.ResolveIcon

    local WindowConfig = {}

    function WindowConfig.Normalize(config)
        config = TranslateConfig(config or {})
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
            Theme = config.Theme or OrionLib.SelectedTheme or "Default",
            IntroIcon = ResolveIcon(config.IntroIcon or config.Icon or "sparkles"),
            IntroToggleIcon = ResolveIcon(config.IntroToggleIcon or (config.OpenButton and config.OpenButton.Icon) or config.Icon or "panel-top-open"),
            Size = config.Size or UDim2.fromOffset(615, 344),
            SidebarCompact = config.SidebarCompact or config.IconOnly or config.CompactSidebar or config.SidebarCompacted or false,
            SidebarWidth = config.SidebarWidth,
            SidebarCompactWidth = config.SidebarCompactWidth or config.CompactWidth or 48,
            SearchBar = config.SearchBar or (config.HideSearchBar and nil or {Default = "Search Tabs", DefaultMain = "Search Elements", ClearTextOnFocus = true, Tabs = true, Mains = true}),
            LinkVideo = config.LinkVideo or config.Video,
            Image = config.Image or config.Background,
            KeySystem = config.KeySystem or config.Key or config.KeyAuth,
        }
    end

    return WindowConfig
end
