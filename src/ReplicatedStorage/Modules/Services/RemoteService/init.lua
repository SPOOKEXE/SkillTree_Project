

local RunService : RunService = game:GetService('RunService')
local ReplicatedStorage : ReplicatedStorage = game:GetService('ReplicatedStorage')

local remoteContainerName : string = '_remotes'

local function GetOrCreateFolder(Parent : Instance?) : Folder
	local Folder : Folder? = Parent and Parent:FindFirstChild(remoteContainerName)
	if not Folder then
		Folder = Instance.new('Folder')
		Folder.Name = remoteContainerName
		Folder.Parent = Parent
	end
	return Folder
end

local function SearchForNameAndClass(Name : string, Class : string, Parent : Instance) : Instance?
	for _, item : Instance in pairs(Parent:GetChildren()) do
		if (item.Name == Name) and (item.ClassName == Class) then
			return item
		end
	end
	return nil
end

-- // Module // --
local Module : table = {}

if RunService:IsServer() then

	local clientRemoteFolder : Folder = GetOrCreateFolder(ReplicatedStorage)
	local serverRemoteFolder : Folder = GetOrCreateFolder(game:GetService('ServerStorage'))

	function Module:GetRemote(remoteName : string, remoteType : string, isClientBased : boolean?) : Instance
		local targetParent : Folder = (isClientBased and serverRemoteFolder or clientRemoteFolder)
		local remoteObject : Instance = SearchForNameAndClass(remoteName, remoteType, targetParent)
		if not remoteObject then
			remoteObject = Instance.new(remoteType)
			remoteObject.Name = remoteName
			remoteObject.Parent = targetParent
		end
		return remoteObject
	end

else

	local ClientRemotes : Folder = ReplicatedStorage:WaitForChild(remoteContainerName)

	function Module:GetRemote(remoteName : string, remoteType : string, isClientBased : boolean)
		if isClientBased then
			local Remote : Instance = SearchForNameAndClass(remoteName, remoteType, ReplicatedStorage)
			if not Remote then
				Remote = Instance.new(remoteType)
				Remote.Name = remoteName
				Remote.Parent = ClientRemotes
			end
			return Remote
		else
			local Remote : Instance? = nil
			repeat task.wait(0.1)
				Remote = SearchForNameAndClass(remoteName, remoteType, ClientRemotes)
			until Remote
			return Remote
		end
	end

end

return Module
