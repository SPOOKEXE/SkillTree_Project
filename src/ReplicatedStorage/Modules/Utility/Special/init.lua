


local Module = {}

function Module:SetProperties(object : Instance, properties : table?) : Instance?
    if typeof(properties) == "table" then
        for k, v in pairs(properties) do
            pcall(function()
                object[k] = v
            end)
        end
    end
    return object
end

function Module:CreateClass(ClassName : string, Properties : table?) : Instance
    return Module:SetProperties(Instance.new(ClassName), Properties)
end

function Module:FindNameAndClassOrCreate(InstanceName : string, InstanceClass : string, Parent : Instance) : Instance
    for _ : number, Inst : Instance in ipairs( Parent:GetChildren() ) do
        if Inst.Name == InstanceName and Inst.ClassName == InstanceClass then
            return Inst
        end
    end
    local _Obj : Instance = Instance.new(InstanceClass)
    _Obj.Name = InstanceName
    _Obj.Parent = Parent
    return _Obj
end

return Module
