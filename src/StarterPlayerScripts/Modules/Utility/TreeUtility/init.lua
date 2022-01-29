
local Module = { Segments = 3 }

local baseLine = Instance.new('Frame')
baseLine.AnchorPoint = Vector2.new(0.5, 0.5)
baseLine.BackgroundColor3 = Color3.new(1,1,1)
baseLine.BorderSizePixel = 0
baseLine.ZIndex = 0
function Module:CreateLine( startVector2 : Vector2, endVector2 : Vector2, lineThickness : number, customProperties )

    local direction : Vector2 = endVector2 - startVector2
    local rotation : number = math.deg( math.atan( direction.Y / direction.X ) )
    local lineSize : UDim2 = UDim2.fromOffset( (startVector2-endVector2).Magnitude / Module.Segments, math.clamp( lineThickness or 3, 1, 5 ) )

    local segments = { } do
        for i = 1, Module.Segments do
            local midPoint : Vector2 = startVector2:Lerp(endVector2, i/Module.Segments)
            local lineFrame = baseLine:Clone()
            lineFrame.Size = lineSize + UDim2.fromOffset(2, 0)
            lineFrame.Position = UDim2.fromOffset(midPoint.X, midPoint.Y)
            lineFrame.Rotation = rotation
            if typeof(customProperties) == "table" then
                for k,v in pairs(customProperties) do
                    lineFrame[k] = v
                end
            end
            table.insert(segments, lineFrame)
        end
    end

    return segments

end

return Module
