local searchObjects : table = {'Humanoid', 'HumanoidRootPart', 'Head'}

local Module : table = {}

function Module:WaitForChildOfProperties(Parent : Instance, Properties : table) : Instance

	local Ignore : table = { }
	local function MatchesProperties(Inst : Instance?) : boolean
		for propName : string, propValue : any in pairs(Properties) do
			local success : boolean, _ : string? = pcall(function()
				if Inst[propName] ~= propValue then
					error("invalid")
				end
			end)
			if not success then
				return false
			end
		end
		return true
	end

	for _ : number, Obj : Instance in ipairs( Parent:GetChildren() ) do
		if MatchesProperties(Obj) then
			return Obj
		end
		table.insert(Ignore, Obj)
	end
	local Object : Instance? = nil
	local Yielder = Instance.new("BindableEvent")
	local addedConnection : RBXScriptConnection
	addedConnection = Parent.ChildAdded:Connect(function(Obj : Instance)
		if not table.find(Ignore, Obj) then
			if MatchesProperties(Obj) then
				addedConnection:Disconnect()
				addedConnection = nil
				Object = Obj
				Yielder:Fire()
			end
			table.insert(Ignore, Obj)
		end
	end)
	if not Object then
		Yielder.Event:Wait()
	end
	return Object
end

function Module:WaitForChildOfClass(Parent : Instance, class : string) : Instance
	local Result : Instance = nil
	task.delay(5, function()
		if not Result then
			warn("Infinite WaitForChildOfClass : ", class, " inside ", Parent:GetFullName())
		end
	end)
	Result = Module:WaitForChildOfProperties(Parent, {ClassName = class})
	return Result
end

function Module:WaitForChildOfNameAndClass(Parent : Instance, name : string, class : string) : Instance
	local Result : Instance = nil
	task.delay(5, function()
		if not Result then
			warn("Infinite WaitForChildOfNameAndClass : ", name, class, " inside ", Parent:GetFullName())
		end
	end)
	Result = Module:WaitForChildOfProperties(Parent, {Name = name, ClassName = class})
	return Result
end

function Module:FindFirstDescendant(Parent : Instance, descendantName : string) : Instance?
	for _ : number , item : Instance in ipairs(Parent:GetChildren()) do
		if item.Name == descendantName then
			return item
		end
	end
	for _ : number, child : Instance in ipairs(Parent:GetChildren()) do
		local target : Instance? = Module:FindFirstDescendant(child, descendantName)
		if target then
			return target
		end
	end
	return nil
end

function Module:FindFirstDescendantOfClass(Parent : Instance, className : string) : Instance?
	for _ : number, Part : Instance in ipairs(Parent:GetDescendants()) do
		if Part:IsA(className) then
			return Part
		end
	end
	return nil
end

function Module:FindDescendantOfNameAndClass(Parent : Instance, descendantName : string, descendantClass : string) : Instance?
	for _ : number, item : Instance in ipairs(Parent:GetDescendants()) do
		if item.Name == descendantName and item.ClassName == descendantClass then
			return item
		end
	end
	return nil
end

function Module:GetHumanoidModelData(Character : Instance) : table
	local Objects : table = {}
	for _ : number, str : string in ipairs(searchObjects) do
		local obj : Instance = Character:FindFirstChild(str)
		if obj then
			Objects[obj.Name] = obj
		end
	end
	return Objects
end

-- Get Character CFrame
function Module:GetCharacterCFrame(Character : Instance?) : CFrame?
	local HumanoidRootPart : BasePart? = Character and Character:FindFirstChild('HumanoidRootPart')
	return HumanoidRootPart and HumanoidRootPart.CFrame
end

function Module:GetPlayerCFrame(LocalPlayer : Player?) : CFrame?
	return LocalPlayer and Module:GetCharacterCFrame(LocalPlayer.Character)
end

-- Get Character Position
function Module:GetCharacterPosition(Character : Instance?) : Vector3?
	local CF : CFrame? = Module:GetCharacterCFrame(Character)
	return CF and CF.Position
end

function Module:GetPlayerPosition(LocalPlayer : Player?) : Vector3?
	local CF : CFrame? = Module:GetPlayerCFrame(LocalPlayer)
	return CF and CF.Position
end

function Module:ScaleModel(Model : Instance, scale : number)
	local primary : BasePart? = Model and Model.PrimaryPart
	if not primary then
		warn("No Primary Part Set.")
		return
	end
	local primaryCF : CFrame = primary.CFrame
	for _ : number, v : Instance in pairs(Model:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Size *= scale
			if (v == primary) then
				continue
			end
			v.CFrame = (primaryCF + (primaryCF:Inverse() * v.Position * scale))
		end
	end
end

function Module:CallbackDescendantBaseParts(Model : Instance, Callback : (BasePart)) : nil
	for _ : number, Part : Instance in ipairs(Model:GetDescendants()) do
		if Part:IsA('BasePart') then
			task.defer(Callback, Part)
		end
	end
end

function Module:SetModelNonCollidable(Model : Instance?) : nil
	Module:CallbackDescendantBaseParts(Model, function(BasePart : BasePart)
		BasePart.CanCollide = false
	end)
end

function Module:WeldConstraint(WeldMe : BasePart, ToThis : BasePart) : WeldConstraint
	local constraint : WeldConstraint = Instance.new('WeldConstraint')
	constraint.Part0 = WeldMe
	constraint.Part1 = ToThis
	constraint.Parent = ToThis
	return constraint
end

local TweenService : TweenService = game:GetService('TweenService')
local tweenCache : table = {}
function Module:TweenModel(Model : Instance, endCFrame : CFrame, tweenInfo : TweenInfo?, Yield : boolean?) : nil

	local cfValue : CFrameValue = Instance.new('CFrameValue')
	cfValue.Value = Model:GetPrimaryPartCFrame()
	cfValue.Changed:Connect(function()
		Model:SetPrimaryPartCFrame(cfValue.Value)
	end)

	local Tween : Tween = tweenCache[Model]
	if Tween then
		Tween:Cancel()
		tweenCache[Model] = nil
	end

	Tween = TweenService:Create(cfValue, tweenInfo or TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Value = endCFrame})

	Tween.Completed:Connect(function()
		if tweenCache[Model] == Tween then
			tweenCache[Model] = nil
		end
		cfValue:Destroy()
	end)

	Tween:Play()

	if Yield then
		Tween.Completed:Wait()
	end

end

return Module
