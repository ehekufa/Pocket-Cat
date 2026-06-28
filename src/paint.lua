-- src/paint.lua
local State = require("src.state")
local utils = require("src.utils")
local project = require("src.project")

local M = {}

function M.init()
    State.paintCanvas = love.graphics.newCanvas(State.paintWidth, State.paintHeight)
    love.graphics.setCanvas(State.paintCanvas)
    love.graphics.clear()
    love.graphics.setCanvas()
    State.paintCanvas:setFilter("linear", "linear")
    M.recalcScale()
end

function M.recalcScale()
    local maxW = 340
    local maxH = 400
    State.paintScale = math.min(maxW / State.paintWidth, maxH / State.paintHeight)
end

function M.resizeCanvas(w, h)
    w = math.max(1, math.min(1024, w))
    h = math.max(1, math.min(1024, h))
    State.paintWidth, State.paintHeight = w, h
    State.paintCanvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(State.paintCanvas)
    love.graphics.clear()
    love.graphics.setCanvas()
    M.recalcScale()
end

function M.drawPaint()
    if not State.paintMode then return end
    love.graphics.setCanvas()
    love.graphics.setColor(0.1,0.1,0.1,0.95)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    local cx, cy = 20, 50
    local pw = State.paintWidth * State.paintScale
    local ph = State.paintHeight * State.paintScale
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", cx, cy, pw, ph)
    love.graphics.draw(State.paintCanvas, cx, cy, 0, State.paintScale, State.paintScale)
    local px = cx + pw + 30
    love.graphics.setColor(0.2,0.2,0.2)
    love.graphics.rectangle("fill", px-10, 50, 140, 500, 8)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Tools:", px, 60)
    for i, tool in ipairs(State.paintTools) do
        local y = 90 + (i-1)*32
        if State.paintCurrentTool == tool then
            love.graphics.setColor(0.4,0.6,1)
        else
            love.graphics.setColor(0.3,0.3,0.3)
        end
        love.graphics.rectangle("fill", px, y, 120, 26, 5)
        love.graphics.setColor(1,1,1)
        love.graphics.print(tool, px+5, y+5)
    end
    love.graphics.print("Size:", px, 340)
    for i, sz in ipairs(State.paintSizes) do
        local sx = px + (i-1)*35
        if State.paintSize == sz then
            love.graphics.setColor(0.4,0.6,1)
        else
            love.graphics.setColor(0.3,0.3,0.3)
        end
        love.graphics.rectangle("fill", sx, 360, 30, 30, 5)
        love.graphics.setColor(1,1,1)
        love.graphics.print(sz, sx+10, 368)
    end
    love.graphics.print("Canvas:", px, 410)
    local py = 430
    for i, psz in ipairs(State.paintPresetSizes) do
        local sx = px + ((i-1)%3) * 55
        local sy = py + math.floor((i-1)/3) * 30
        love.graphics.setColor(0.3,0.3,0.3)
        love.graphics.rectangle("fill", sx, sy, 50, 24, 5)
        love.graphics.setColor(1,1,1)
        love.graphics.print(psz[1].."x"..psz[2], sx+4, sy+4)
    end
    local customY = py + 60
    love.graphics.setColor(0.5,0.5,0.5)
    love.graphics.rectangle("fill", px, customY, 120, 26, 5)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Custom...", px+10, customY+5)
    if State.paintCustomStep > 0 then
        love.graphics.setColor(0.2,0.2,0.2)
        love.graphics.rectangle("fill", px, customY+32, 120, 26)
        love.graphics.setColor(1,1,1)
        if State.paintCustomStep == 1 then
            love.graphics.print("X: " .. State.paintCustomInputText, px+5, customY+37)
        else
            love.graphics.print("Y: " .. State.paintCustomInputText, px+5, customY+37)
        end
    end
    love.graphics.setColor(1,1,1)
    love.graphics.print("Custom Color:", px, customY+70)
    local hsvX, hsvY = px, customY+90
    local hsvSize = 60
    for dx = 0, hsvSize-1 do
        for dy = 0, hsvSize-1 do
            local hue = dx / hsvSize
            local sat = 1 - dy / hsvSize
            local r,g,b = utils.hsvToRGB(hue, sat, 1)
            love.graphics.setColor(r,g,b)
            love.graphics.rectangle("fill", hsvX+dx, hsvY+dy, 1, 1)
        end
    end
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", hsvX, hsvY, hsvSize, hsvSize)
    local mx = hsvX + State.paintHue * hsvSize
    local my = hsvY + (1 - State.paintSaturation) * hsvSize
    love.graphics.setColor(0,0,0)
    love.graphics.circle("line", mx, my, 3)
    love.graphics.setColor(1,1,1)
    love.graphics.circle("line", mx+1, my+1, 3)
    local vX, vY = px, hsvY + hsvSize + 10
    for i = 0, 119 do
        local val = i / 119
        local r,g,b = utils.hsvToRGB(State.paintHue, State.paintSaturation, val)
        love.graphics.setColor(r,g,b)
        love.graphics.rectangle("fill", vX+i, vY, 1, 10)
    end
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", vX, vY, 120, 10)
    local vm = vX + State.paintValue * 119
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", vm-1, vY-1, 3, 12)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", vm-1, vY-1, 3, 12)
    love.graphics.setColor(0.3,0.8,0.3)
    love.graphics.rectangle("fill", px, vY+20, 120, 30, 5)
    love.graphics.print("Save", px+40, vY+28)
    love.graphics.setColor(0.8,0.3,0.3)
    love.graphics.rectangle("fill", px, vY+60, 120, 30, 5)
    love.graphics.print("Close", px+40, vY+68)
end

function M.handleTouch(x, y, isDown)
    if not State.paintMode then return false end
    local cx, cy = 20, 50
    local pw = State.paintWidth * State.paintScale
    local ph = State.paintHeight * State.paintScale
    local px = cx + pw + 30

    -- Save button
    if y > 550 and y < 590 and x > px and x < px+120 then
        love.graphics.setCanvas()
        local obj = project.getCurrentObject()
        if obj then
            local imgData = State.paintCanvas:newImageData()
            local filename = "obj_" .. State.currentSceneIdx .. "_" .. State.currentObjectIdx .. ".png"
            imgData:encode("png", filename)
            obj.image = filename
        end
        State.paintMode = false
        State.paintCustomStep = 0
        State.paintCustomInputText = ""
        return true
    end
    -- Close button
    if y > 590 and y < 630 and x > px and x < px+120 then
        love.graphics.setCanvas()
        State.paintMode = false
        State.paintCustomStep = 0
        State.paintCustomInputText = ""
        return true
    end

    -- Tools
    for i, tool in ipairs(State.paintTools) do
        local ty = 90 + (i-1)*32
        if x > px and x < px+120 and y > ty and y < ty+26 then
            State.paintCurrentTool = tool
            if tool == "fill" then
                love.graphics.setCanvas(State.paintCanvas)
                love.graphics.setColor(State.paintBrushColor)
                love.graphics.rectangle("fill", 0, 0, State.paintWidth, State.paintHeight)
                love.graphics.setCanvas()
            end
            return true
        end
    end

    -- Sizes
    for i, sz in ipairs(State.paintSizes) do
        local sx = px + (i-1)*35
        if x > sx and x < sx+30 and y > 360 and y < 390 then
            State.paintSize = sz
            return true
        end
    end

    -- Preset canvas sizes
    local py = 430
    for i, psz in ipairs(State.paintPresetSizes) do
        local sx = px + ((i-1)%3) * 55
        local sy = py + math.floor((i-1)/3) * 30
        if x > sx and x < sx+50 and y > sy and y < sy+24 then
            M.resizeCanvas(psz[1], psz[2])
            State.paintCustomStep = 0
            State.paintCustomInputText = ""
            return true
        end
    end

    -- Custom button
    local customBtnY = py + 60
    if x > px and x < px+120 and y > customBtnY and y < customBtnY+26 then
        State.paintCustomStep = 1
        State.paintCustomInputText = ""
        State.editingBlockIdx = nil
        State.editingText = ""
        State.keyboardVisible = true
        return true
    end

    -- HSV picker
    local hsvX, hsvY = px, customBtnY+90
    local hsvSize = 60
    if x >= hsvX and x <= hsvX+hsvSize and y >= hsvY and y <= hsvY+hsvSize then
        State.paintHue = (x - hsvX) / hsvSize
        State.paintSaturation = 1 - (y - hsvY) / hsvSize
        local r,g,b = utils.hsvToRGB(State.paintHue, State.paintSaturation, State.paintValue)
        State.paintBrushColor = {r,g,b}
        return true
    end

    -- Value slider
    local vX, vY = px, hsvY + hsvSize + 10
    if x >= vX and x <= vX+119 and y >= vY and y <= vY+10 then
        State.paintValue = (x - vX) / 119
        local r,g,b = utils.hsvToRGB(State.paintHue, State.paintSaturation, State.paintValue)
        State.paintBrushColor = {r,g,b}
        return true
    end

    -- Drawing on canvas
    if x >= cx and x <= cx+pw and y >= cy and y <= cy+ph and isDown then
        local pxc = math.floor((x - cx) / State.paintScale) + 1
        local pyc = math.floor((y - cy) / State.paintScale) + 1
        if pxc >= 1 and pxc <= State.paintWidth and pyc >= 1 and pyc <= State.paintHeight then
            love.graphics.setCanvas(State.paintCanvas)
            local brushSize = State.paintSize or 1
            if State.paintCurrentTool == "brush" or State.paintCurrentTool == "eraser" then
                local alpha = (State.paintCurrentTool == "eraser") and 0 or 1
                for dx = -brushSize, brushSize do
                    for dy = -brushSize, brushSize do
                        local dist = math.sqrt(dx*dx + dy*dy)
                        if dist <= brushSize then
                            local a = (1 - dist/brushSize) * alpha
                            if a > 0 then
                                love.graphics.setColor(State.paintBrushColor[1], State.paintBrushColor[2], State.paintBrushColor[3], a)
                                love.graphics.rectangle("fill", pxc+dx-1, pyc+dy-1, 1, 1)
                            end
                        end
                    end
                end
                love.graphics.setCanvas()
            elseif State.paintCurrentTool == "line" then
                if not State.lineStart then
                    State.lineStart = {pxc, pyc}
                else
                    love.graphics.setColor(State.paintBrushColor)
                    love.graphics.setLineWidth(State.paintSize or 1)
                    love.graphics.line(State.lineStart[1], State.lineStart[2], pxc, pyc)
                    love.graphics.setCanvas()
                    State.lineStart = nil
                end
            elseif State.paintCurrentTool == "rect" then
                if not State.rectStart then
                    State.rectStart = {pxc, pyc}
                else
                    love.graphics.setColor(State.paintBrushColor)
                    local w = pxc - State.rectStart[1]
                    local h = pyc - State.rectStart[2]
                    love.graphics.rectangle("fill", State.rectStart[1], State.rectStart[2], w, h)
                    love.graphics.setCanvas()
                    State.rectStart = nil
                end
            elseif State.paintCurrentTool == "ellipse" then
                if not State.ellipseStart then
                    State.ellipseStart = {pxc, pyc}
                else
                    love.graphics.setColor(State.paintBrushColor)
                    local w = pxc - State.ellipseStart[1]
                    local h = pyc - State.ellipseStart[2]
                    love.graphics.ellipse("fill", State.ellipseStart[1], State.ellipseStart[2], w, h)
                    love.graphics.setCanvas()
                    State.ellipseStart = nil
                end
            elseif State.paintCurrentTool == "picker" then
                love.graphics.setCanvas()
                local imgData = State.paintCanvas:newImageData()
                local r,g,b,a = imgData:getPixel(pxc-1, pyc-1)
                State.paintBrushColor = {r,g,b}
                State.paintCurrentTool = "brush"
            else
                love.graphics.setCanvas()
            end
            return true
        end
    end
    return false
end

return M
