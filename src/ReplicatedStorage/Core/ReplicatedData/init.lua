local Players : Players = game:GetService('Players')
local RunService : RunService = game:GetService('RunService')
local HttpService : HttpService = game:GetService('HttpService')

local ReplicatedStorage : ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules : table = require(ReplicatedStorage:WaitForChild('Modules'))
local ReplicatedUtility : table = ReplicatedModules.Utility

local StringCompression : table = ReplicatedUtility.String.Compression

local DataRemote : RemoteEvent = ReplicatedModules.Services.RemoteService:GetRemote('DataRemote', 'RemoteEvent', false)

local Module : table = {}

warn(string.format('[%s] Replicated Data', RunService:IsServer() and 'Server' or 'Client'))

if RunService:IsServer() then

    local print = function(...)
       --print(...)
    end
    local warn = function(...)
        --warn(table.concat({...}))
    end

    local onDataUpdated = ReplicatedModules.Classes.Signal.New("onDataUpdated")
    Module.OnDataUpdated = onDataUpdated

    local debounceCache : table = {}

    local comparisonCache : table = {
        Private = {},
        Collections = {},
        Shared = {},
    }

    local activeReplications : table = {
        Private = {},
        Collections = {},
        Shared = {},
    }

    Module.SharedCache = activeReplications

    -- Send Data to the client, compressing data if its pass a certain length.
    local replicateBlacklist : table = {"Tags"}
    function Module:SendData(Category : string, Data : table, LocalPlayer : Player?)
        task.defer(function()
            local didCompression : boolean = false
            if typeof(Data) == "table" then
                -- REMOVE BLACKLISTED
                Data = ReplicatedUtility.Table:DeepCopy(Data)
                for _, blacklistTag : string in ipairs(replicateBlacklist) do
                    Data[blacklistTag] = nil
                end
                -- JSON ENCODE
                Data = HttpService:JSONEncode(Data)
                -- COMPRESS (if > 200 characters)
                if #Data > 200 then
                    print('Compress Data')
                    didCompression = true
                    Data = StringCompression.Zlib.Compress(Data)
                end
            end
            if LocalPlayer then
                DataRemote:FireClient(LocalPlayer, Category, Data, didCompression)
            else
                DataRemote:FireAllClients(Category, Data, didCompression)
            end
        end)
    end

    function Module:GetData(Category : string, LocalPlayer : Player?) : table?
        print(string.format("Get %s Data: %s", LocalPlayer and "Private" or "Public", Category))
        if LocalPlayer then
            -- Private Data
            return activeReplications.Private[Category] and activeReplications.Private[Category][LocalPlayer]
        end
        -- Shared Data
        return activeReplications.Shared[Category] and activeReplications.Shared[Category][LocalPlayer]
    end

    function Module:GetCollection(Category : string)
        print(string.format("Get Collection: ", Category))
        for i : number, t : table in ipairs(activeReplications.Collections) do
			if t.Category == Category then
				return t, i
			end
		end
		return nil
    end

    function Module:SetData(Category : string, Data : table, LocalPlayer : Player?)
        print(Category, Data, LocalPlayer)
        if LocalPlayer then
            -- Private
            if not activeReplications.Private[Category] then
                activeReplications.Private[Category] = {}
            end
            activeReplications.Private[Category][LocalPlayer] = Data
            Module:SendData(Category, Data, LocalPlayer)
        else
            -- Shared
            if not activeReplications.Shared[Category] then
                activeReplications.Shared[Category] = {}
            end
            activeReplications.Shared[Category] = Data
            Module:SendData(Category, Data)
        end
    end

    function Module:AddCollectionData(Category : string?, Data : table?, PlayerWhitelist : table?, UUID : string?)
        print(string.format('Add Collection Data | %s \n %s', Category, Data))
        table.insert(activeReplications.Collections, {
            UUID = UUID or HttpService:GenerateGUID(false),
            Category = Category,
            Data = Data,
            Players = PlayerWhitelist
        })
		for _ : number, LocalPlayer : Player in ipairs(PlayerWhitelist) do
            Module:SendData(Category, Data, LocalPlayer)
		end
    end

    function Module:RemoveCollectionData(Category : string?, UUID : string?) : nil
        for index : number, t : table in ipairs(activeReplications.Collections) do
			if t.UUID == UUID and t.Category == Category then
				table.remove(activeReplications.Collections, index)
			end
		end
	end

    DataRemote.OnServerEvent:Connect(function(LocalPlayer : Player)
		if debounceCache[LocalPlayer] then
			return false
		end
		debounceCache[LocalPlayer] = true
		for privCategory : string, tbl : table in pairs(activeReplications.Private) do
			for activePlayer : Player, plrData : table in pairs(tbl) do
                if activePlayer == LocalPlayer then
				    Module:SendData(privCategory, plrData, LocalPlayer)
				end
			end
		end
		for publicCategory : string, tbl : table in pairs(activeReplications.Shared) do
			Module:SendData(publicCategory, tbl, LocalPlayer)
		end
		for _ : number, tbl : table in ipairs(activeReplications.Collections) do
			for _ : number, activePlayer : Player in ipairs(tbl.Players) do
                if activePlayer == LocalPlayer then
				    Module:SendData(tbl.Category, tbl.Data, LocalPlayer)
				end
			end
		end
		task.wait(0.5) -- delay manual data requests
		debounceCache[LocalPlayer] = nil
	end)

    function Module:Update(LocalPlayer : Player?)
        for privCategory : string, tbl : table in pairs(activeReplications.Private) do
            for activePlayer : Player, plrData : table in pairs(tbl) do
				if (LocalPlayer and LocalPlayer ~= activePlayer) then
					continue
				end
				if not comparisonCache.Private[activePlayer] then
					comparisonCache.Private[activePlayer] = {}
				end
				local newCompare : string = HttpService:JSONEncode(plrData)
				if comparisonCache.Private[activePlayer][privCategory] ~= newCompare then
					comparisonCache.Private[activePlayer][privCategory] = newCompare
					print('private data update: ', activePlayer or "Shared")
                    onDataUpdated:Fire(privCategory, tbl)
					Module:SendData(privCategory, plrData, activePlayer)
				end
            end
        end
        for publicCategory : string, tbl : table in pairs(activeReplications.Shared) do
			local newCompare : string = HttpService:JSONEncode(tbl)
			if comparisonCache.Public[publicCategory] ~= newCompare then
				comparisonCache.Public[publicCategory] = newCompare
				print('public data update')
				Module:SendToClient(publicCategory, tbl, LocalPlayer)
			end
		end
		for _ : number, tbl : table in ipairs(activeReplications.Collections) do
			local newCompare : string = HttpService:JSONEncode(tbl)
			if comparisonCache.Collections[tbl.UUID] ~= newCompare then
				comparisonCache.Collections[tbl.UUID] = newCompare
				print('collection data update: ', tbl.UUID, tbl.Category)
				for _ : number, activePlayer : Player in ipairs(tbl.Players) do
					Module:SendToClient(tbl.Category, tbl.Data, activePlayer)
				end
			end
		end
    end

    function Module:PlayerAdded(LocalPlayer : Player)
        LocalPlayer.CharacterAdded:Connect(function()
            Module:Update(LocalPlayer)
        end)
        task.defer(function()
            Module:Update(LocalPlayer)
        end)
    end

    function Module:Init( _ ) : nil
		for _ : number , LocalPlayer : Player in ipairs(Players:GetPlayers()) do
            Module:PlayerAdded(LocalPlayer)
        end

        Players.PlayerAdded:Connect(function(LocalPlayer : Player)
			Module:PlayerAdded(LocalPlayer)
		end)

		ReplicatedModules.Classes.Timer.New({Interval = 0.25, Name = 'DataReplicateUpdate'}).Signal:Connect(function()
			Module:Update()
		end)
	end

else
    local print = function(...)
       --print(...)
    end
    local warn = function(...)
       --warn(table.concat({...}))
    end

    local LocalPlayer : Player = Players.LocalPlayer
    local activeCache : table = { }
    Module.Cache = activeCache

    function Module:Init( e ) end

    function Module:GetData(Category : string?, Yield : boolean?) : table?
		if Yield then
			repeat task.wait(0.1) until activeCache[Category]
		end
		return activeCache[Category]
	end

    local OnDataUpdate = ReplicatedModules.Classes.Signal.New('DataUpdate')
    Module.OnUpdate = OnDataUpdate

    DataRemote.OnClientEvent:Connect(function(Category : string, Data : table, DidCompress : boolean?)
		if DidCompress then
			print('Got Compressed Data')
			Data = StringCompression.Zlib.Decompress(Data)
		end
		Data = HttpService:JSONDecode(Data)
		if activeCache[Category] then
			for k,v in pairs(Data) do
				activeCache[Category][k] = v
			end
		else
			activeCache[Category] = Data
		end
		Module.OnUpdate:Fire(Category, Data)
	end)

	task.defer(function()
        repeat task.wait(0.5)
            print("Request")
            DataRemote:FireServer()
        until Module:GetData('PlayerData')
        Module.OnUpdate:Fire('PlayerData', Module:GetData('PlayerData'))
	end)

end

return Module