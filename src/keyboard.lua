-- src/keyboard.lua
local State = require("src.state")
local utils = require("src.utils")
local blocks = require("src.blocks")

local M = {}

function M.updatePos()
    local keys = (State.keyboardMode == "digits" and State.digitsKeys or
                  State.keyboardMode == "ru" and State.ruKeys or
                  State.enKeys)
    local cols = 0
    for _, row in ipairs(keys) do if #row > cols then cols = #row end end
    State.keyboardPosX = love.graphics.getWidth()/2 - (cols * (State.keyW + State.keySpacing) + State.keySpacing)/2
    State.keyboardPosY = love.graphics.getHeight() - State.keyboardHeight
end

function M.drawKeyboard()
    if not State.keyboardVisible then return end
    M.updatePos()
    local kx, ky = State.keyboardPosX, State.keyboardPosY
    local keys = (State.keyboardMode == "digits" and State.digitsKeys or
                  State.keyboardMode == "ru" and State.ruKeys or
                  State.enKeys)
    local rows, cols = #keys, 0
    for _, row in ipairs(keys) do if #row > cols then cols = #row end end
    local kw = cols * (State.keyW + State.keySpacing) + State.keySpacing
    local kh = rows * (State.keyH + State.keySpacing) + State.keySpacing + 80
    love.graphics.setColor(0.1,0.1,0.1,0.95)
    love.graphics.rectangle("fill", kx, ky, kw, kh, 10)
    for i, row in ipairs(keys) do
        for j, char in ipairs(row) do
            local bx = kx + State.keySpacing + (j-1)*(State.keyW + State.keySpacing)
            local by = ky + State.keySpacing + (i-1)*(State.keyH + State.keySpacing)
            love.graphics.setColor(0.3,0.3,0.3)
            love.graphics.rectangle("fill", bx, by, State.keyW, State.keyH, 6)
            love.graphics.setColor(1,1,1)
            love.graphics.rectangle("line", bx, by, State.keyW, State.keyH, 6)
            love.graphics.printf(char, bx, by+State.keyH/2-8, State.keyW, "center")
        end
    end
    local swY = ky + rows*(State.keyH + State.keySpacing) + State.keySpacing + 10
    local modes = {{"123","digits"},{"АБВ","ru"},{"ABC","en"}}
    for i, m in ipairs(modes) do
        local bx = kx + State.keySpacing + (i-1)*(55 + State.keySpacing)
        love.graphics.setColor(0.3,0.3,0.3)
        love.graphics.rectangle("fill", bx, swY, 55, 30, 6)
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("line", bx, swY, 55, 30, 6)
        love.graphics.printf(m[1], bx, swY+8, 55, "center")
    end
    local doneX = kx + kw - 70
    local pasteX = doneX - 75
    love.graphics.setColor(0.4,0.5,1.0)
    love.graphics.rectangle("fill", pasteX, swY, 65, 30, 6)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", pasteX, swY, 65, 30, 6)
    love.graphics.printf("Paste", pasteX, swY+8, 65, "center")
    love.graphics.setColor(0.2,0.6,0.2)
    love.graphics.rectangle("fill", doneX, swY, 60, 30, 6)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", doneX, swY, 60, 30, 6)
    love.graphics.printf("Done", doneX, swY+8, 60, "center")
    -- Close button
    local closeX = kx + kw + 5
    local closeY = ky - 10
    love.graphics.setColor(1,0,0)
    love.graphics.rectangle("fill", closeX, closeY, 30, 30, 5)
    love.graphics.setColor(1,1,1)
    love.graphics.print("X", closeX+8, closeY+5)
end

function M.handleTouch(x, y)
    if not State.keyboardVisible then return false end
    local kx, ky = State.keyboardPosX, State.keyboardPosY
    local keys = (State.keyboardMode == "digits" and State.digitsKeys or
                  State.keyboardMode == "ru" and State.ruKeys or
                  State.enKeys)
    local cols = 0
    for _, row in ipairs(keys) do if #row > cols then cols = #row end end
    local kw = cols * (State.keyW + State.keySpacing) + State.keySpacing
    local closeX = kx + kw + 5
    local closeY = ky - 10
    if x >= closeX and x <= closeX+30 and y >= closeY and y <= closeY+30 then
        State.keyboardVisible = false
        State.editingBlockIdx = nil
        State.editingText = ""
        State.paintCustomStep = 0
        State.paintCustomInputText = ""
        return true
    end
    for i, row in ipairs(keys) do
        for j, char in ipairs(row) do
            local bx = kx + State.keySpacing + (j-1)*(State.keyW + State.keySpacing)
            local by = ky + State.keySpacing + (i-1)*(State.keyH + State.keySpacing)
            if x >= bx and x <= bx+State.keyW and y >= by and y <= by+State.keyH then
                if char == "⌫" then
                    State.editingText = State.editingText:sub(1, -2)
                else
                    State.editingText = State.editingText .. char
                end
                return true
            end
        end
    end
    local rows = #keys
    local swY = ky + rows*(State.keyH + State.keySpacing) + State.keySpacing + 10
    local modes = {{"123","digits"},{"АБВ","ru"},{"ABC","en"}}
    for i, m in ipairs(modes) do
        local bx = kx + State.keySpacing + (i-1)*(55 + State.keySpacing)
        if x >= bx and x <= bx+55 and y >= swY and y <= swY+30 then
            State.keyboardMode = m[2]
            return true
        end
    end
    local doneX = kx + kw - 70
    local pasteX = doneX - 75
    if x >= pasteX and x <= pasteX+65 and y >= swY and y <= swY+30 then
        local clip = love.system.getClipboardText()
        if clip then State.editingText = State.editingText .. utils.safeUTF8(clip) end
        return true
    end
    if x >= doneX and x <= doneX+60 and y >= swY and y <= swY+30 then
        if State.editingBlockIdx then
            local block = State.workspaceBlocks[State.editingBlockIdx]
            local val = utils.safeUTF8(State.editingText)
            if tonumber(val) then block.param = tonumber(val) else block.param = val end
        end
        State.editingBlockIdx = nil
        State.editingText = ""
        State.keyboardVisible = false
        return true
    end
    if y < ky then
        State.editingBlockIdx = nil
        State.editingText = ""
        State.keyboardVisible = false
        return true
    end
    return false
end

function M.textInput(t)
    if State.paintCustomStep > 0 and State.keyboardVisible then
        State.paintCustomInputText = State.paintCustomInputText .. t
        State.editingText = State.paintCustomInputText
    elseif State.editingBlockIdx and State.paintCustomStep == 0 then
        State.editingText = State.editingText .. t
    end
end

function M.keyPressed(key)
    if State.paintCustomStep > 0 and State.keyboardVisible then
        if key == "return" or key == "kpenter" then
            if State.paintCustomStep == 1 then
                local val = tonumber(State.paintCustomInputText)
                if val then
                    State.paintCustomX = val
                    State.paintCustomStep = 2
                    State.paintCustomInputText = ""
                    State.editingText = ""
                end
            else
                local val = tonumber(State.paintCustomInputText)
                if val and State.paintCustomX then
                    require("src.paint").resizeCanvas(State.paintCustomX, val)
                    State.paintCustomStep = 0
                    State.paintCustomInputText = ""
                    State.editingText = ""
                    State.keyboardVisible = false
                end
            end
        elseif key == "escape" then
            State.paintCustomStep = 0
            State.paintCustomInputText = ""
            State.editingText = ""
            State.keyboardVisible = false
        elseif key == "backspace" then
            State.paintCustomInputText = State.paintCustomInputText:sub(1, -2)
            State.editingText = State.paintCustomInputText
        end
    elseif State.editingBlockIdx and not State.paintCustomStep then
        if key == "return" or key == "kpenter" then
            local block = State.workspaceBlocks[State.editingBlockIdx]
            local val = utils.safeUTF8(State.editingText)
            if tonumber(val) then block.param = tonumber(val) else block.param = val end
            State.editingBlockIdx = nil
            State.editingText = ""
            State.keyboardVisible = false
        elseif key == "escape" then
            State.editingBlockIdx = nil
            State.editingText = ""
            State.keyboardVisible = false
        elseif key == "backspace" then
            State.editingText = State.editingText:sub(1, -2)
        end
    else
        if key == "f5" then
            require("src.runtime").runProject()
        elseif key == "f2" then
            require("src.project").saveProject("project.cat")
        elseif key == "delete" then
            if State.editingBlockIdx then
                table.remove(State.workspaceBlocks, State.editingBlockIdx)
                State.editingBlockIdx = nil
                State.editingText = ""
                State.keyboardVisible = false
                blocks.calculateHeights()
                require("src.runtime").compileScript()
            end
        end
    end
end

return M
