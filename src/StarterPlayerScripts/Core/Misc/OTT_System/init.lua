
--local containerFolder = Instance.new('Folder', workspace)
--containerFolder.Name = LocalPlayer.Name
--ReplicatedModules.Utility.Table:TableToObject(baseData, containerFolder)

local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage.Modules)
local ReplicatedSystems = require(ReplicatedStorage.Core)
local ReplicatedData = ReplicatedSystems.ReplicatedData

-- // Module // --
local Module = {}

function Module:OnNewData(category)

	--print(category)

	local Data = ReplicatedData:GetData(category)
	if (not Data) then
		return
	end

	--print(Data)

	local Folder = workspace:FindFirstChild(category..'_')
	if not Folder then
		Folder = Instance.new('Folder')
		Folder.Name = category..'_'
		Folder.Parent = workspace
	end
	Folder:ClearAllChildren()
	ReplicatedModules.Utility.Table:TableToObject(Data, Folder)

end

function Module:Init(otherModules) end

-- Data Updated
ReplicatedData.OnUpdate:Connect(function(Category, NewData)
	--print(Category)
	Module:OnNewData(Category)
end)
task.defer(function()
	for category, _ in pairs( ReplicatedData.Cache ) do
		Module:OnNewData(category)
	end
end)

return Module
