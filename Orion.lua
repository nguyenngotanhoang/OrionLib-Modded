-- OrionLib compatibility entrypoint.
-- Main source lives in scr/Orion.lua so the project is easier to read and extend.
local sourcePath = "scr/Orion.lua"

if readfile and loadstring and isfile and isfile(sourcePath) then
    return loadstring(readfile(sourcePath), "OrionLib")()
end

warn("OrionLib source moved to scr/Orion.lua. Load that file directly in environments without readfile/loadstring.")
return getgenv and getgenv().OrionLib or nil
