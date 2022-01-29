

local Module : table = {}

function Module:Get() : number
    return os.time(os.date('!*t'))
end

return Module