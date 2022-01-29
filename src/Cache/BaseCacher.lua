

local txt : string = game:GetService('RunService'):IsServer() and "Server" or "Client"
local function SplitName(Parent : Instance, subNumber : number?) : string
    local split : table = string.split(Parent:GetFullName(), ".")
    return split[subNumber or 1].."/"..split[#split]
end

do
    --warn(string.format('[%s] %s Initialised', txt, SplitName(script, 2)))
end

-- warn([[
--
--     .oooooo..o ooooooooo.     .oooooo.     .oooooo.   oooo    oooo             oooooooooooo ooooooo  ooooo oooooooooooo 
--     d8P'    `Y8 `888   `Y88.  d8P'  `Y8b   d8P'  `Y8b  `888   .8P'              `888'     `8  `8888    d8'  `888'     `8 
--     Y88bo.       888   .d88' 888      888 888      888  888  d8'                 888            Y888..8P     888         
--      `"Y8888o.   888ooo88P'  888      888 888      888  88888[                   888oooo8        `8888'      888oooo8    
--          `"Y88b  888         888      888 888      888  888`88b.                 888    "       .8PY888.     888    "    
--     oo     .d8P  888         `88b    d88' `88b    d88'  888  `88b.               888       o   d8'  `888b    888       o 
--     8""88888P'  o888o         `Y8bood8P'   `Y8bood8P'  o888o  o888o ooooooooooo o888ooooood8 o888o  o88888o o888ooooood8 
--                                                                                                                                                                                                                                              
-- ]])

local Cache : table = {}

local Class : table = {}
Class.__index = Class
Class.__newindex = function(...)
	error(script:GetFullName()..' is locked.')
end

local function hasInit(tbl : table) : boolean
    return tbl.Init or (getmetatable(tbl) and getmetatable(tbl).Init)
end

local function Preload(Parent : Instance, subNumber : number?) : table
    if not Cache[Parent] then
        Cache[Parent] = {}
        --warn(string.format("[%s] Module Directory: %s", txt, SplitName(Parent, subNumber)))
        for i : number, ModuleScript : ModuleScript in ipairs(Parent:GetChildren()) do
            --print(ModuleScript.Name)
            Cache[Parent][ModuleScript.Name] = require(ModuleScript)
        end
        setmetatable(Cache[Parent], Class)
        for preLoadedName : string, preLoaded : table in pairs(Cache[Parent]) do
            if preLoaded.Initialised or not hasInit(preLoaded) then
                continue
            end
            local accessibles : table = { ParentSystems = Cache[Parent.Parent] }
            for otherLoadedName : string, differentLoaded : table in pairs(Cache[Parent]) do
                if preLoadedName ~= otherLoadedName then
                    accessibles[otherLoadedName] = differentLoaded
                end
            end
            preLoaded.Initialised = true
            preLoaded:Init(accessibles)
            --warn('Initialised ', preLoadedName)
        end
        Parent.ChildAdded:Connect(function(ModuleScript : ModuleScript)
            if ModuleScript:IsA("ModuleScript") then
                Cache[Parent][ModuleScript.Name] = require(ModuleScript)
                if hasInit( Cache[Parent][ModuleScript.Name] ) then
                    local accessibles : table = { ParentSystems = Cache[Parent.Parent] }
                    for otherLoadedName : string, differentLoaded : table in pairs(Cache[Parent]) do
                        if ModuleScript.Name ~= otherLoadedName then
                            accessibles[otherLoadedName] = differentLoaded
                        end
                    end
                    Cache[Parent][ModuleScript.Name]:Init(accessibles)
                end
            end
        end)
    end
    return Cache[Parent]
end

function Class.New(Parent : Instance, subNumber : number?) : table
    return Cache[Parent] or Preload(Parent, subNumber)
end

task.delay(2, function()
    warn("Anything past this point (which errors / warns) is considered a bug/problem. Please report it to the developers via discord!")
end)

return Class
