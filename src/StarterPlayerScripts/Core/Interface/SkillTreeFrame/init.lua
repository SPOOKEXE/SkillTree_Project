

local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local LocalAssets = LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Assets')
local LocalModules = require(LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Modules'))

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))
local ReplicatedCore = require(ReplicatedStorage:WaitForChild('Core'))

local Interface : ScreenGui = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('Interface')
local SkillTreeFrame = Interface:WaitForChild('SkillTreeFrame')

local SkillTreesDef = ReplicatedModules.Definitions.SkillTrees

local SystemsContainer = { }

local MapFrames = { }

-- // Module // --
local Module = { }

function Module:UDim2OffsetToScale( convertUDim2 : UDim2 )
    local absoluteSize : Vector2 = Interface.AbsoluteSize
    return UDim2.fromScale(
        (convertUDim2.X.Offset / absoluteSize.X) + convertUDim2.X.Scale,
        (convertUDim2.Y.Offset / absoluteSize.Y) + convertUDim2.Y.Scale
    )
end

function Module:UDim2ScaleToOffset( convertUDim2 : UDim2 )
    local absoluteSize : Vector2 = Interface.AbsoluteSize
    return UDim2.fromScale(
        (convertUDim2.X.Scale * absoluteSize.X) + convertUDim2.X.Offset,
        (convertUDim2.Y.Scale * absoluteSize.Y) + convertUDim2.Y.Offset
    )
end

function Module:CountDictonary( dictionary ) : number
    local counter : number = 0
    for k, v in pairs( dictionary ) do
        counter += 1
    end
    return counter
end

function Module:SetupTree( ParentFrame, Data )

    local nodesFrameCache = { }

    for i : number, nodeData in ipairs( Data.Nodes ) do

        local nodeConfig = SkillTreesDef:GetNodeFromID( nodeData.ID )
        if not nodeConfig then
            continue
        end

        local nodePoint = LocalAssets.UI.TemplateNode:Clone()
        nodePoint.Name = nodeData.ID
        --nodePoint.Label.Text = nodeData.ID
        nodePoint.Position = nodeData.Position --Module:UDim2OffsetToScale( nodeData.Position )
        nodePoint.Size = nodeData.Size --Module:UDim2OffsetToScale( nodeData.Size )
        nodePoint.Icon.Image = nodeConfig.Icon
        nodePoint.Icon.Size = nodeConfig.Icon_Size
        nodePoint.Parent = ParentFrame

        nodesFrameCache[ nodeData.ID ] = {nodePoint, nodeData}

    end

    for nodeID : string, nodeInfo in pairs( nodesFrameCache ) do
        local Frame : Frame, nodeData = unpack( nodeInfo )
        if Module:CountDictonary( nodeData.Reqs ) == 0 then
            Frame.Icon.ImageColor3 = Color3.new(1, 1, 1)
            continue
        else
            for preReq, minimumLevel in pairs( nodeData.Reqs ) do
                Frame.Icon.ImageColor3 = Color3.new(0.28, 0.28, 0.28)
                local targetFrame : Vector2 = nodesFrameCache[ preReq ][1]
                LocalModules.Utility.TreeUtility:CreateLine(
                    (Frame.AbsolutePosition - ParentFrame.AbsolutePosition) + (Frame.AbsoluteSize / 2),
                    (targetFrame.AbsolutePosition - ParentFrame.AbsolutePosition) + (targetFrame.AbsoluteSize / 2),
                    nodeData.Req_Line_Thickness,
                    { Parent = ParentFrame }
                )
            end
        end
    end

end

function Module:Init( otherSystems )

    SystemsContainer = otherSystems

    LocalAssets.UI.TemplateNode.Back.Image = SkillTreesDef.SquareIcon

    for i : number, treeData in ipairs( SkillTreesDef.Trees ) do

        local TreeMapFrame : Frame = LocalAssets.UI.TemplateTreeMapFrame:Clone()
        TreeMapFrame.Name = treeData.ID
        TreeMapFrame.LayoutOrder = i
        TreeMapFrame.Label.Text = treeData.ID
        TreeMapFrame.Icon.Image = treeData.Icon
        TreeMapFrame.Parent = SkillTreeFrame.Trees

        local TreeMap : Frame = LocalAssets.UI.TemplateTreeMap:Clone()
        TreeMap.Name = treeData.ID
        TreeMap.LayoutOrder = i
        TreeMap.Visible = false
        TreeMap.Parent = SkillTreeFrame

        local Button = LocalModules.Utility.GuiButton:CreateActionButton()
        Button.Activated:Connect(function()
            for _ : number, Frame : Frame in ipairs( MapFrames ) do
                Frame.Visible = (Frame == TreeMap) and (not Frame.Visible)
            end
        end)
        Button.Parent = TreeMapFrame

        table.insert(MapFrames, TreeMap)

        Module:SetupTree( TreeMap, treeData )

    end

end

return Module
