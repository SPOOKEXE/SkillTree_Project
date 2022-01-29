
local Players : Players = game:GetService('Players')

local ServerStorage : ServerStorage = game:GetService('ServerStorage')
local ServerAssets : Folder = ServerStorage:WaitForChild("Assets")
local ServerModules : table = require(ServerStorage:WaitForChild("Modules"))
local ServerDefinitions : table = ServerModules.Definitions
local ServerServices : table = ServerModules.Services
local ServerClasses : table = ServerModules.Classes
local ServerUtility : table = ServerModules.Utility

local ReplicatedStorage : ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedAssets : Folder = ReplicatedStorage:WaitForChild("Assets")
local ReplicatedSystems : table = require(ReplicatedStorage:WaitForChild('Core'))
local ReplicatedModules : table = require(ReplicatedStorage:WaitForChild('Modules'))
local ReplicatedServices : table = ReplicatedModules.Services
local ReplicatedDefinitions : table = ReplicatedModules.Definitions
local ReplicatedClasses : table = ReplicatedModules.Classes
local ReplicatedUtility : table = ReplicatedModules.Utility

local ReplicatedData : table = ReplicatedSystems.ReplicatedData
local ProfileService : table = ServerUtility.ProfileService

local Template : table = require(script.Template)

local ProfileCache : table = {}
local Loading : table = {}

local SystemsContainer : table = { }

-- Configuration
local DebugMode : boolean = false
local SaveData : boolean = false

local LeaderstatReplicationValues : table = { }

-- // Module // --
local GameProfileStore : table = ProfileService.GetProfileStore('Data1', Template.New())
if not SaveData then
	GameProfileStore = GameProfileStore.Mock
end

local Module : table = { TemplateData = Template.New(), Cache = ProfileCache }

function Module:GetPlayerKey(Id : string?) : string?
	return tostring(Id)
end

-- Wipes a player's progress
function Module:WipePlayerProgress(LocalPlayer : Player) : nil
	GameProfileStore:WipeProfileAsync(Module:GetPlayerKey(LocalPlayer.UserId))
end

-- Write custom data to the player's data.
-- Can be used to "reconcile" custom data for specific players using the tag table (or metatags).
function Module:CustomPlayerDataWrite(LocalPlayer : Player, Profile) : nil

end

-- Get the player's profile if it is available (unless yielded)
function Module:GetProfileFromPlayer(LocalPlayer : Player?, Yield : boolean?)
	if Yield then
		local s : number = tick()
		repeat task.wait(0.1) until ProfileCache[LocalPlayer.UserId] or tick()-s > 10
	end
	return ProfileCache[LocalPlayer.UserId]
end

-- Load the profile from the given ID (will prevent more requests via a lock mechanism)
function Module:LoadProfileFromId(Id : string | number)
	if Loading[Id] then
		repeat task.wait(0.1) until not Loading[Id]
	end
	if ProfileCache[Id] then
		return ProfileCache[Id]
	end
	Loading[Id] = true
	local profile = GameProfileStore:LoadProfileAsync(tonumber(Id) and Module:GetPlayerKey(Id) or Id, "ForceLoad")
	ProfileCache[Id] = profile
	Loading[Id] = nil
	return profile
end

function Module:LoadPlayerProfile(LocalPlayer : Player?)
	local profile = Module:LoadProfileFromId(LocalPlayer.UserId)
	if profile then
		profile:Reconcile()
		profile:ListenToRelease(function()
			ProfileCache[LocalPlayer.UserId] = nil
			if not profile.Data.Banned then
				LocalPlayer:Kick('Profile loaded on a different server.')
			end
		end)
		if LocalPlayer:IsDescendantOf(Players) then
			local s : boolean, e : string? = pcall(function()
				Module:CustomPlayerDataWrite(LocalPlayer, profile)
			end)
			if not s then
				warn(e)
				warn('Continued to Load.')
			end
			if profile.Data.Banned then
				profile:Release()
				LocalPlayer:Kick('You are banned. '..(profile.Data.Banned.Reason or 'No Reason Given.'))
				return false
			end
			ProfileCache[LocalPlayer.UserId] = profile
		else
			profile:Release()
			ProfileCache[LocalPlayer.UserId] = nil
		end
	end
	return profile
end

function Module:OnPlayerAdded(LocalPlayer : Player)

	local playerProfile = Module:LoadPlayerProfile(LocalPlayer)
	if not playerProfile then
		warn('PlayerData did not load: ', LocalPlayer.Name)
		return
	end

	ReplicatedData:SetData('PlayerData', playerProfile.Data, LocalPlayer)

	do
		local leaderstatsStrValues : table = {}
		local leaderstats : Folder = Instance.new('Folder')
		leaderstats.Name = 'leaderstats'
		leaderstats.Parent = LocalPlayer
		for _ : number, str : string in ipairs(LeaderstatReplicationValues) do
			local strV : StringValue = Instance.new('StringValue')
			strV.Name = str
			strV.Value = playerProfile.Data[str]
			strV.Parent = leaderstats
			leaderstatsStrValues[str] = strV
		end
		ReplicatedClasses.Timer.New({Interval = 0.25}).Signal:Connect(function()
			for s : string, v : number in pairs(leaderstatsStrValues) do
				v.Value = ReplicatedUtility.Numbers:NumberSuffix(playerProfile.Data[s])
			end
		end)
	end

	return playerProfile

end

function Module:Init(otherSystems : table) : nil

	for moduleName : string, otherLoaded : table in pairs(otherSystems) do
		SystemsContainer[moduleName] = otherLoaded
	end

	Players.PlayerRemoving:Connect(function(LocalPlayer : Player)
		local Profile = ProfileCache[LocalPlayer.UserId]
		if Profile then
			Profile:Release()
			ProfileCache[LocalPlayer.UserId] = nil
		end
	end)

	task.delay(1, function()
		for _ : number, LocalPlayer : Player in ipairs(Players:GetPlayers()) do
			task.defer(function()
				Module:OnPlayerAdded(LocalPlayer)
			end)
		end
		Players.PlayerAdded:Connect(function(LocalPlayer : Player)
			Module:OnPlayerAdded(LocalPlayer)
		end)
	end)

end

return Module
