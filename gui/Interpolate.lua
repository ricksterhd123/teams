--[[
    I wanted to test
]]

_guiCreateWindow = guiCreateWindow

local e = {}

function guiCreateWindow(x, y, width, height, titleBarText, relative)
    local tick = getTickCount()
    local screenW, screenH = guiGetScreenSize()
    local start = {screenW/2-(width/2), 0}
    local length = 1000
    local window = _guiCreateWindow(start[1], start[2], width, height, titleBarText,relative)

    e[window] = {start, {x, y}, tick, length, relative}

    return window
end

function renderBounce()
    for window, params in pairs(e) do
        if isElement(window) then
            local tick = getTickCount()
            local progress = math.min(1, (tick-params[3])/params[4])
            local x, y = interpolateBetween(params[1][1], params[1][2], 0, params[2][1], params[2][2], 0, progress, "OutElastic")
            
            guiSetPosition(window, x, y, params[5])

            if progress >= 1 then
                e[window] = nil
            end
        else
            e[window] = nil
        end
    end
end

addEventHandler("onClientRender", root, renderBounce)