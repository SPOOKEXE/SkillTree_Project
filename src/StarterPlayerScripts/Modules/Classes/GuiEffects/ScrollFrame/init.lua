


local RunService : RunService = game:GetService('RunService')

local ReplicatedStorage : ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules : table = require(ReplicatedStorage:WaitForChild('Modules'))

local _DefaultProperties : table = { Position = UDim2.fromScale(-0.5, 0.5) }
local _ActiveProperties : table = { Position = UDim2.fromScale(0.5, 0.5) }

local function setProperties( tbl : table, properties : table? ) : nil
    if typeof(properties) == "table" then
        for k : string, v : any in pairs(properties) do
            tbl[k] = v
        end
    end
end

local AutoUpdateScrollClasses : table = {} do
    ReplicatedModules.Classes.Timer.New({Interval = (1 / 5), Name = 'ScrollFrameUpdater'}).Signal:Connect(function()
        for index : number, self : table in ipairs(AutoUpdateScrollClasses) do
            if (not self.Frame) or (not self.Frame.Parent) then
                table.remove(AutoUpdateScrollClasses, index)
                break
            end
            if self._hasChanged then
                self._hasChanged = false
                self:Update()
            end
        end
    end)
end

-- // Class // --
local Class : table = { }
Class.__index = Class

function Class.New( Properties : table ) : table

    local self = {
        Frame = false,

        CountPerRow = 3,
        IsVertical = false,

        UIGridLayout = false,
		UIPadding = false,

        _hasChanged = false,

        _Updated = ReplicatedModules.Classes.Timer.New(),
        _Maid = ReplicatedModules.Classes.Maid.New(),
    }

    setProperties(self, Properties)

    setmetatable(self, Class)

    return self

end

function Class:Update() : nil
    assert(typeof(self.UIGridLayout) == "Instance", "No UIGridLayout Supplied")
    assert(typeof(self.UIPadding) == "Instance", "No UIPadding Supplied.")
    local deltaItemDecimal : number = (1 / self.CountPerRow)
    if self.IsVertical then
        -- vertical boxes
    else
        self.UIGridLayout.CellSize = UDim2.new(deltaItemDecimal, -self.UIGridLayout.CellPadding.X.Offset, 1, 0)
        local spacePerItem : number = math.ceil(1 / self.UIGridLayout.CellSize.X.Scale)
        local rowCount : number = 1 + math.floor((#self.Frame:GetChildren() - 1) / spacePerItem)
        local cellSize : number = self.UIGridLayout.AbsoluteCellSize.Y
        local totalPad : number = ((rowCount - 1) * self.UIGridLayout.CellPadding.Y.Offset) + self.UIPadding.PaddingTop.Offset + self.UIPadding.PaddingBottom.Offset
        self.Frame.CanvasSize = UDim2.fromOffset(0, totalPad + (rowCount * cellSize))
    end
    self._Updated:Fire()
end

function Class:Setup( autoUpdate : boolean ) : nil

    assert(typeof(self.Frame) == "Instance" and self.Frame:IsA("ScrollingFrame"), "No ScrollingFrame Supplied")
    assert(typeof(self.UIGridLayout) == "Instance", "No UIGridLayout Supplied")
    assert(typeof(self.UIPadding) == "Instance", "No UIPadding Supplied.")

    self.UIGridLayout = self.UIGridLayout or self.Frame:FindFirstChildOfClass('UIGridLayout')
    self.UIPadding = self.UIPadding or self.Frame:FindFirstChildOfClass('UIPadding')
    assert(typeof(self.UIGridLayout) == "Instance", "No UIGridLayout Supplied")
    assert(typeof(self.UIPadding) == "Instance", "No UIPadding Supplied.")

    self._Maid:Give(self.Frame.Destroying:Connect(function()
        self._Maid:Cleanup()
    end))

    if autoUpdate then
        self._hasChanged = false
        self._Maid:Give(self.Frame.ChildAdded:Connect(function()
			self._hasChanged = true
		end))
		self._Maid:Give(self.Frame.ChildRemoved:Connect(function()
			self._hasChanged = true
		end))
		self._Maid:Give(self.Frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
			self._hasChanged = true
		end))
		table.insert(AutoUpdateScrollClasses, self)
    end

    task.spawn(function()
        self:Update()
    end)

end

function Class:Destroy() : nil
    self._Maid:Cleanup()
    self._Maid = nil
    setmetatable(self, nil)
end

return Class
