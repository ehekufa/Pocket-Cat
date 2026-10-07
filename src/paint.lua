-- src/paint.lua
-- Редактор рисования образов (открывается по «Нарисовать»)
local State = require("src.state")
local theme = require("src.theme")
local utils = require("src.utils")

local M = {}

function M.openFor(onSave)
    State.paintMode = true
    State.paintOnSave = onSave
    State.paintWidth, State.paintHeight = 96, 96
    State.paintCanvas = love.graphics.newCanvas(96, 96)
    love.graphics.setCanvas(State.paintCanvas)
    love.graphics.clear()
    love.graphics.setCanvas()
    State.paintCurrentTool = "brush"
    State.paintSize = 2
    State.paintBrushColor = {1, 1, 1}
    State.paintHue, State.paintSaturation, State.paintValue = 0, 1, 1
    State.paintCustomStep = 0
    State.paintCustomInputText = ""
    State.lineStart, State.rectStart, State.ellipseStart = nil, nil, nil
    M.recalcScale()
end

function M.recalcScale()
    local maxW = math.min(360, love.graphics.getWidth() - 40)
    local maxH = love.graphics.getHeight() - 220
    State.paintScale = math.min(maxW / State.paintWidth, maxH / State.paintHeight)
end

local TOOLS = {
    {"brush", "кисть"}, {"eraser", "ластик"}, {"fill", "заливка"},
    {"picker", "пипетка"}, {"line", "линия"}, {"rect", "прямоуг."}, {"ellipse", "овал"},
}

function M.drawPaint()
    if not State.paintMode then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setCanvas()
    love.graphics.setColor(0.08, 0.08, 0.1, 0.97)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setFont(State.fontBig)
    theme.setColor(theme.text)
    love.graphics.print("Редактор образа", 16, 12)

    -- холст
    local cx, cy = 16, 48
    local pw = State.paintWidth * State.paintScale
    local ph = State.paintHeight * State.paintScale
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", cx - 4, cy - 4, pw + 8, ph + 8, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(State.paintCanvas, cx, cy, 0, State.paintScale, State.paintScale)

    -- панель инструментов
    local px = cx + pw + 24
    local py = 48
    love.graphics.setFont(State.font)
    theme.setColor(theme.textDim)
    love.graphics.print("Инструменты:", px, py)
    for i, t in ipairs(TOOLS) do
        local y = py + 24 + (i - 1) * 30
        theme.setColor(State.paintCurrentTool == t[1] and theme.accent or {0.25, 0.25, 0.28})
        love.graphics.rectangle("fill", px, y, 110, 26, 5, 5)
        theme.setColor(theme.text)
        love.graphics.print(t[2], px + 8, y + 5)
    end

    local sizeY = py + 24 + #TOOLS * 30 + 8
    theme.setColor(theme.textDim)
    love.graphics.print("Толщина:", px, sizeY)
    for i, sz in ipairs({1, 2, 4, 8}) do
        local sx = px + (i - 1) * 32
        theme.setColor(State.paintSize == sz and theme.accent or {0.25, 0.25, 0.28})
        love.graphics.rectangle("fill", sx, sizeY + 22, 28, 28, 5, 5)
        theme.setColor(theme.text)
        love.graphics.print(tostring(sz), sx + 10, sizeY + 28)
    end

    -- палитра HSV
    local hsvX, hsvY = px, sizeY + 64
    local hsvSize = 80
    for dx = 0, hsvSize - 1, 2 do
        for dy = 0, hsvSize - 1, 2 do
            local r, g, b = utils.hsvToRGB(dx / hsvSize, 1 - dy / hsvSize, 1)
            love.graphics.setColor(r, g, b)
            love.graphics.rectangle("fill", hsvX + dx, hsvY + dy, 2, 2)
        end
    end
    local mx = hsvX + State.paintHue * hsvSize
    local my = hsvY + (1 - State.paintSaturation) * hsvSize
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("line", mx, my, 4)

    local vX, vY = hsvX, hsvY + hsvSize + 8
    for i = 0, 100 do
        local r, g, b = utils.hsvToRGB(State.paintHue or 0, State.paintSaturation or 1, i / 100)
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", vX + i, vY, 1, 10)
    end

    -- кнопки
    local btnY = h - 64
    theme.setColor({0.3, 0.7, 0.3})
    love.graphics.rectangle("fill", 16, btnY, 140, 44, 8, 8)
    theme.setColor(theme.text)
    love.graphics.setFont(State.fontBig)
    love.graphics.print("Сохранить", 34, btnY + 11)

    theme.setColor({0.5, 0.5, 0.5})
    love.graphics.rectangle("fill", 172, btnY, 120, 44, 8, 8)
    theme.setColor(theme.text)
    love.graphics.print("Закрыть", 190, btnY + 11)
end

function M.handleTouch(x, y, isDown)
    if not State.paintMode then return false end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local cx, cy = 16, 48
    local pw = State.paintWidth * State.paintScale
    local ph = State.paintHeight * State.paintScale
    local px = cx + pw + 24
    local py = 48
    local sizeY = py + 24 + #TOOLS * 30 + 8
    local hsvX, hsvY = px, sizeY + 64
    local hsvSize = 80
    local vX, vY = hsvX, hsvY + hsvSize + 8
    local btnY = h - 64

    -- Сохранить
    if x >= 16 and x <= 156 and y >= btnY and y <= btnY + 44 then
        local imgData = State.paintCanvas:newImageData()
        love.filesystem.createDirectory("sprites")
        local filename = "sprites/look_" .. tostring(math.floor(love.timer.getTime() * 1000)) .. ".png"
        pcall(function() imgData:encode("png", filename) end)
        if State.paintOnSave then State.paintOnSave(filename) end
        State.paintMode = false
        State.paintOnSave = nil
        State.toast("Образ сохранён")
        return true
    end
    -- Закрыть
    if x >= 172 and x <= 292 and y >= btnY and y <= btnY + 44 then
        State.paintMode = false
        State.paintOnSave = nil
        return true
    end

    -- инструменты
    for i, t in ipairs(TOOLS) do
        local ty = py + 24 + (i - 1) * 30
        if x >= px and x <= px + 110 and y >= ty and y <= ty + 26 then
            State.paintCurrentTool = t[1]
            if t[1] == "fill" then
                love.graphics.setCanvas(State.paintCanvas)
                love.graphics.setColor(State.paintBrushColor)
                love.graphics.rectangle("fill", 0, 0, State.paintWidth, State.paintHeight)
                love.graphics.setCanvas()
            end
            return true
        end
    end
    -- толщина
    for i, sz in ipairs({1, 2, 4, 8}) do
        local sx = px + (i - 1) * 32
        if x >= sx and x <= sx + 28 and y >= sizeY + 22 and y <= sizeY + 50 then
            State.paintSize = sz
            return true
        end
    end
    -- палитра
    if x >= hsvX and x <= hsvX + hsvSize and y >= hsvY and y <= hsvY + hsvSize then
        State.paintHue = (x - hsvX) / hsvSize
        State.paintSaturation = 1 - (y - hsvY) / hsvSize
        local r, g, b = utils.hsvToRGB(State.paintHue, State.paintSaturation, State.paintValue or 1)
        State.paintBrushColor = {r, g, b}
        return true
    end
    if x >= vX and x <= vX + 100 and y >= vY and y <= vY + 10 then
        State.paintValue = (x - vX) / 100
        local r, g, b = utils.hsvToRGB(State.paintHue or 0, State.paintSaturation or 1, State.paintValue)
        State.paintBrushColor = {r, g, b}
        return true
    end

    -- рисование
    if isDown and x >= cx and x <= cx + pw and y >= cy and y <= cy + ph then
        local pxc = math.floor((x - cx) / State.paintScale) + 1
        local pyc = math.floor((y - cy) / State.paintScale) + 1
        if pxc >= 1 and pxc <= State.paintWidth and pyc >= 1 and pyc <= State.paintHeight then
            love.graphics.setCanvas(State.paintCanvas)
            local bs = State.paintSize or 1
            if State.paintCurrentTool == "brush" or State.paintCurrentTool == "eraser" then
                local alpha = State.paintCurrentTool == "eraser" and 0 or 1
                if alpha == 0 then love.graphics.setBlendMode("replace") end
                for dx = -bs, bs do
                    for dy = -bs, bs do
                        if math.sqrt(dx * dx + dy * dy) <= bs then
                            if alpha > 0 then
                                love.graphics.setColor(State.paintBrushColor[1], State.paintBrushColor[2], State.paintBrushColor[3], 1)
                            else
                                love.graphics.setColor(0, 0, 0, 0)
                            end
                            local xx, yy = pxc + dx - 1, pyc + dy - 1
                            if xx >= 0 and yy >= 0 and xx < State.paintWidth and yy < State.paintHeight then
                                love.graphics.rectangle("fill", xx, yy, 1, 1)
                            end
                        end
                    end
                end
                love.graphics.setBlendMode("alpha")
            elseif State.paintCurrentTool == "line" then
                if not State.lineStart then
                    State.lineStart = {pxc, pyc}
                else
                    love.graphics.setColor(State.paintBrushColor)
                    love.graphics.setLineWidth(bs)
                    love.graphics.line(State.lineStart[1], State.lineStart[2], pxc, pyc)
                    State.lineStart = nil
                end
            elseif State.paintCurrentTool == "rect" then
                if not State.rectStart then
                    State.rectStart = {pxc, pyc}
                else
                    love.graphics.setColor(State.paintBrushColor)
                    love.graphics.rectangle("fill", State.rectStart[1], State.rectStart[2],
                        pxc - State.rectStart[1], pyc - State.rectStart[2])
                    State.rectStart = nil
                end
            elseif State.paintCurrentTool == "ellipse" then
                if not State.ellipseStart then
                    State.ellipseStart = {pxc, pyc}
                else
                    love.graphics.setColor(State.paintBrushColor)
                    love.graphics.ellipse("fill", State.ellipseStart[1], State.ellipseStart[2],
                        (pxc - State.ellipseStart[1]) / 2, (pyc - State.ellipseStart[2]) / 2)
                    State.ellipseStart = nil
                end
            elseif State.paintCurrentTool == "picker" then
                love.graphics.setCanvas()
                local imgData = State.paintCanvas:newImageData()
                local r, g, b = imgData:getPixel(pxc - 1, pyc - 1)
                State.paintBrushColor = {r, g, b}
                State.paintCurrentTool = "brush"
            end
            love.graphics.setCanvas()
            return true
        end
    end
    return true -- поглощаем всё, пока открыт редактор
end

return M
