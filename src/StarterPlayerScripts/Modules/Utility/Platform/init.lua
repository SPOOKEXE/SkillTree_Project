
local GuiService : GuiService = game:GetService('GuiService')
local UserInputService : UserInputService = game:GetService('UserInputService')

local Module = { }

function Module:GetPlatform()
    if (GuiService:IsTenFootInterface()) then
        return "Console"
    elseif (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) then
        return "Mobile"
    else
        return "Desktop"
    end
end

return Module

