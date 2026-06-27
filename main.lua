function handlePaintTouch(x, y, isDown)
    if not State.paintMode then return false end
    local cx, cy = 20, 50
    local pw = State.paintWidth * State.paintScale
    local ph = State.paintHeight * State.paintScale
    local px = cx + pw + 30
    local customY = 430 + 60 + 32 + 60 + 10
    if y > 550 and y < 590 and x > px and x < px+120 then
        love.graphics.setCanvas()
        local obj = getCurrentObject()
        if obj then
            local imgData = State.paintCanvas:newImageData()
            local filename = "obj_" .. State.currentSceneIdx .. "_" .. State.currentObjectIdx .. ".png"
            imgData:encode("png", filename)
            obj.image = filename
        end
        State.paintMode = false; State.paintCustomStep = 0; State.paintCustomInputText = ""; return true
    end
    if y > 590 and y < 630 and x > px and x < px+120 then
        love.graphics.setCanvas()
        State.paintMode = false; State.paintCustomStep = 0; State.paintCustomInputText = ""; return true
    end
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
    for i, sz in ipairs(State.paintSizes) do
        local sx = px + (i-1)*35
        if x > sx and x < sx+30 and y > 360 and y < 390 then
            State.paintSize = sz; return true
        end
    end
    local py = 430
    for i, psz in ipairs(State.paintPresetSizes) do
        local sx = px + ((i-1)%3) * 55
        local sy = py + math.floor((i-1)/3) * 30
        if x > sx and x < sx+50 and y > sy and y < sy+24 then
            resizePaintCanvas(psz[1], psz[2])
            State.paintCustomStep = 0; State.paintCustomInputText = ""
            return true
        end
    end
    local customBtnY = py + 60
    if x > px and x < px+120 and y > customBtnY and y < customBtnY+26 then
        State.paintCustomStep = 1
        State.paintCustomInputText = ""
        State.editingBlockIdx = nil
        State.editingText = ""
        State.keyboardVisible = true
        return true
    end
    if State.paintCustomStep > 0 and x > px and x < px+120 and y > customBtnY+32 and y < customBtnY+58 then
        State.editingBlockIdx = nil
        State.editingText = State.paintCustomInputText
        State.keyboardVisible = true
        return true
    end
    local hsvX, hsvY2 = px, customBtnY+90
    local hsvSize = 60
    if x >= hsvX and x <= hsvX+hsvSize and y >= hsvY2 and y <= hsvY2+hsvSize then
        State.paintHue = (x - hsvX) / hsvSize
        State.paintSaturation = 1 - (y - hsvY2) / hsvSize
        local r,g,b = hsvToRGB(State.paintHue, State.paintSaturation, State.paintValue)
        State.paintBrushColor = {r,g,b}
        return true
    end
    local vX, vY = px, hsvY2 + hsvSize + 10
    if x >= vX and x <= vX+119 and y >= vY and y <= vY+10 then
        State.paintValue = (x - vX) / 119
        local r,g,b = hsvToRGB(State.paintHue, State.paintSaturation, State.paintValue)
        State.paintBrushColor = {r,g,b}
        return true
    end
    if x >= cx and x <= cx+pw and y >= cy and y <= cy+ph and isDown then
        local pxc = math.floor((x - cx) / State.paintScale) + 1
        local pyc = math.floor((y - cy) / State.paintScale) + 1
        if pxc >= 1 and pxc <= State.paintWidth and pyc >= 1 and pyc <= State.paintHeight then
            love.graphics.setCanvas(State.paintCanvas)
            local brushSize = State.paintSize  -- <-- ВОТ ЭТА СТРОКА БЫЛА ПОТЕРЯНА
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
                    love.graphics.setLineWidth(State.paintSize)
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
