export type userdataTypes = (CFrame | Vector3 | Color3)
export type userdataArray = { [number] : userdataTypes }

-- // Module // --
local Module = {}

function Module:GetUserDataBezier( arrayTable : userdataArray, alpha : number ) : userdataTypes
	local pointsTable : userdataArray = arrayTable
	repeat task.wait()
		local ntb : userdataArray = {}
		for k : number, v : userdataTypes in ipairs(pointsTable) do
			if k ~= 1 then
				ntb[k-1] = pointsTable[k-1]:Lerp(v, alpha)
			end
		end
		pointsTable = ntb
	until #pointsTable == 1
	return pointsTable[1]
end

return Module
