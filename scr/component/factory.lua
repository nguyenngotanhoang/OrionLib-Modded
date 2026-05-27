return function(context)
    local OrionLib = context.OrionLib
    local TweenService = context.TweenService
    local Color3 = context.Color3

    local Factory = {}

    function Factory.Create(name, properties, children)
        local object = Instance.new(name)
        for property, value in next, properties or {} do
            object[property] = value
        end
        for _, child in next, children or {} do
            child.Parent = object
        end
        return object
    end

    function Factory.SetProps(element, props)
        for property, value in pairs(props or {}) do
            element[property] = value
        end
        return element
    end

    function Factory.SetChildren(element, children)
        for _, child in pairs(children or {}) do
            child.Parent = element
        end
        return element
    end

    function Factory.Round(number, factor)
        local decimals = tostring(factor):match("%.(%d+)")
        decimals = decimals and #decimals or 0
        local result = math.floor(number / factor + 0.5) * factor
        return tonumber(string.format("%." .. decimals .. "f", result))
    end

    function Factory.ColorAdd(color, amount)
        return Color3.fromRGB(
            math.clamp(color.R * 255 + amount, 0, 255),
            math.clamp(color.G * 255 + amount, 0, 255),
            math.clamp(color.B * 255 + amount, 0, 255)
        )
    end

    function Factory.ThemeValue(name, fallback)
        local theme = OrionLib.Themes[OrionLib.SelectedTheme] or OrionLib.Themes.Default or {}
        return theme[name] or fallback
    end

    function Factory.Hover(object, normalColor, hoverAmount, pressAmount)
        local baseColor = normalColor or Factory.ThemeValue("Second", Color3.fromRGB(32, 32, 32))
        return {
            Enter = function()
                TweenService:Create(object, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Factory.ColorAdd(baseColor, hoverAmount or 4),
                }):Play()
            end,
            Leave = function()
                TweenService:Create(object, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = baseColor,
                }):Play()
            end,
            Press = function()
                TweenService:Create(object, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Factory.ColorAdd(baseColor, pressAmount or 8),
                }):Play()
            end,
        }
    end

    return Factory
end
