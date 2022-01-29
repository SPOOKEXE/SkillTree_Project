local ReplicatedStorage : ReplicatedStorage = game:GetService('ReplicatedStorage')
local CacheFolder : Folder = ReplicatedStorage:WaitForChild('Cache')
local BaseCacher : ModuleScript = CacheFolder:WaitForChild('BaseCacher')
return require(BaseCacher).New(script, 2)