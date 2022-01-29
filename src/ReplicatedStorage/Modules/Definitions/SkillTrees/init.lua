
-- // Module // --
local Module = { }

Module.SquareIcon = "rbxassetid://6070678376"

Module.Nodes = {
    {
        ID = "TAILORING_1",
        Icon = 'rbxassetid://6082867387',
        Icon_Size = UDim2.fromScale(0.85, 0.85),
        MaxLevel = 1,
        Display = {
            Title = {
                Text = "Leather Tailoring",
                TextColor3 = Color3.new(1, 1, 1),
            },
            Description = {
                Text = "Learn the ability to tailor with leather. Unlock leather recipes for crafting.",
                TextColor3 = Color3.new(1, 1, 1),
            },
        },
    },
    {
        ID = "ARMOR_FITTING",
        Icon = 'rbxassetid://6082866591',
        Icon_Size = UDim2.fromScale(0.85, 0.85),
        MaxLevel = 1,
        Display = {
            Title = {
                Text = "Armor Fitting",
                TextColor3 = Color3.new(1, 1, 1),
            },
            Description = {
                Text = "Minor increase to all produced armor benefits by well fitting them to the users.",
                TextColor3 = Color3.new(1, 1, 1),
            },
        },
    },
    {
        ID = "ANVIL_CRAFTING_1",
        Icon = 'rbxassetid://6070699281',
        Icon_Size = UDim2.fromScale(0.85, 0.85),
        MaxLevel = 2,
        Display = {
            Title = {
                Text = "Anvil Crafting",
                TextColor3 = Color3.new(1, 1, 1),
            },
            Description = {
                Text = "Improve your knowledge from leather and unlocks the more advanced anvil recipes.",
                TextColor3 = Color3.new(1, 1, 1),
            },
        },
    },
    {
        ID = "PROTECTION_QUALITY",
        Icon = 'rbxassetid://8670162423',
        Icon_Size = UDim2.fromScale(0.85, 0.85),
        MaxLevel = 3,
        Display = {
            Title = {
                Text = "Protection Quality",
                TextColor3 = Color3.new(1, 1, 1),
            },
            Description = {
                Text = "Improve your knowledge and improve all armor items protection quality.",
                TextColor3 = Color3.new(1, 1, 1),
            },
        },
    },
}

Module.Trees = {
    {
        ID = "PRODUCTION_TREE",
        Icon = "rbxassetid://6070699281",
        Nodes = {
            {
                ID = "TAILORING_1",
                Position = UDim2.fromOffset(70, 65), -- Offset Values
                Size = UDim2.fromOffset(65, 65), -- Offset Values
                Draw_Req_Lines = true,
                Req_Line_Thickness = 3,
                Reqs = { },
            },
            {
                ID = "ARMOR_FITTING",
                Position = UDim2.fromOffset(170, 65), -- Offset Values
                Size = UDim2.fromOffset(65, 65), -- Offset Values
                Draw_Req_Lines = true,
                Req_Line_Thickness = 3,
                Reqs = { TAILORING_1 = 1 },
            },
            {
                ID = "ANVIL_CRAFTING_1",
                Position = UDim2.fromOffset(70, 140), -- Offset Values
                Size = UDim2.fromOffset(65, 65), -- Offset Values
                Draw_Req_Lines = true,
                Req_Line_Thickness = 3,
                Reqs = { TAILORING_1 = 1 },
            },
            {
                ID = "PROTECTION_QUALITY",
                Position = UDim2.fromOffset(170, 140), -- Offset Values
                Size = UDim2.fromOffset(65, 65), -- Offset Values
                Draw_Req_Lines = true,
                Req_Line_Thickness = 3,
                Reqs = { ANVIL_CRAFTING_1 = 1 },
            },
        },
    }
}

function Module:GetTreeFromID( treeID : string? )
    for i : number, treeData in ipairs( Module.Trees ) do
        if treeData.ID == treeID then
            return treeData, i
        end
    end
    return nil, nil
end

function Module:GetNodeFromID( nodeID : string )
    for i : number, nodeData in ipairs( Module.Nodes ) do
        if nodeData.ID == nodeID then
            return nodeData, i
        end
    end
    return nil, nil
end

return Module
