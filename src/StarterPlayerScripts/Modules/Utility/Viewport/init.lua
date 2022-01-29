
local ReplicatedStorage : ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedAssets : Folder = ReplicatedStorage:WaitForChild('Assets')

-- // Module // --
local Module : table = {}

function Module:SetupModelForViewport( ClonedModel : Instance ) : nil
	local Humanoid : Humanoid? = ClonedModel:FindFirstChildOfClass("Humanoid")
	if Humanoid then
		Humanoid.HealthDisplayDistance = Enum.HumanoidHealthDisplayType.AlwaysOff
		Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	if ClonedModel:IsA("Model") and ClonedModel.PrimaryPart then
		ClonedModel.PrimaryPart.Anchored = true
	end
end

function Module:SetupModelViewport(Viewport : ViewportFrame, Model : Instance, CameraCFrame : CFrame, ModelCFrame : CFrame) : (Instance?, Camera?)
	if not Model then
		return
	end
	Model = Model:Clone()
	Module:SetupModelForViewport( Model )
	Model:SetPrimaryPartCFrame( ModelCFrame )
	Model.Parent = Viewport
	local Camera : Camera = Module:ViewportCamera(Viewport)
	Camera.CFrame = CameraCFrame
	return Camera
end

function Module:ViewportCamera(ViewportFrame) : Camera
	local Camera : Camera? = ViewportFrame:FindFirstChildOfClass('Camera')
	if not Camera then
		Camera = Instance.new('Camera')
		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = CFrame.new()
		Camera.Parent = ViewportFrame
		ViewportFrame.CurrentCamera = Camera
	end
	return Camera
end

function Module:ClearViewport(ViewportFrame : ViewportFrame) : nil
	for _, item : Instance in ipairs(ViewportFrame:GetChildren()) do
		if not item:IsA('Camera') then
			item:Destroy()
		end
	end
end

return Module
