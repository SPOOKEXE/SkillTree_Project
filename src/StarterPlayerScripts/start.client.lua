do
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    require(ReplicatedStorage:WaitForChild('Modules'))
    require(ReplicatedStorage:WaitForChild('Core'))
    local LocalScripts = script.Parent
    require(LocalScripts:WaitForChild('Modules'))
    require(LocalScripts:WaitForChild('Core'))
end