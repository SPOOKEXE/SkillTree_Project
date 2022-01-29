



local TweenService : TweenService = game:GetService('TweenService')

local ReplicatedStorage : ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules : table = require(ReplicatedStorage:WaitForChild('Modules'))
local TableUtility : table = ReplicatedModules.Utility.Table

local _DefaultProperties : table = { Position = UDim2.fromScale(-0.5, 0.5) }
local _ActiveProperties : table = { Position = UDim2.fromScale(0.5, 0.5) }

local function setProperties( tbl : table, properties : table? ) : nil
    if typeof(properties) == "table" then
        for k : string, v : any in pairs(properties) do
            tbl[k] = v
        end
    end
end

-- // Class // --
local Class : table = { }
Class.__index = Class

function Class.New( Frame : Frame, DefaultProperties : table?, ActiveProperties : table? ) : table

    local self = {
        Frame = Frame,
        Active = false,
        DefaultProperties = TableUtility:DeepCopy(_DefaultProperties),
        ActiveProperties = TableUtility:DeepCopy(_ActiveProperties),
        ValidateForEffect = nil,
		TweenInfo = TweenInfo.new(0.95, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        _Updated = ReplicatedModules.Classes.Signal.New(),
        _Maid = ReplicatedModules.Classes.Maid.New(),
    }

    Frame.Visible = true

    setProperties( self.DefaultProperties, DefaultProperties )
    setProperties( self.ActiveProperties, ActiveProperties )

    self._Maid:Give(self._Updated)
    self._Maid:Give(self.Frame)
    self._Maid:Give(self.Frame.Destroying:Connect(function()
        self:Destroy()
    end))

    setmetatable(self, Class)

    self:Toggle(false)

    return self

end

function Class:Toggle( forced : boolean ) : nil
    if self.ValidateForEffect and self.ValidateForEffect(self) then
		return
	end
    if typeof(forced) == "boolean" then
        self.Active = forced
    else
        self.Active = not self.Active
    end
    self:Update()
end

function Class:Update() : nil
    local FinalProperties : UDim2 = self.DefaultProperties
	if self.Active then
		FinalProperties = self.ActiveProperties
	end
	TweenService:Create(self.Frame, self.TweenInfo, FinalProperties):Play()
    self._Updated:Fire()
end

function Class:Destroy() : nil
    self._Maid:Cleanup()
    self._Maid = nil
    setmetatable(self, nil)
end

return Class