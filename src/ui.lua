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

    -- Поле ввода
    local inputY = ky + 10
    local inputW = kw - 20
    love.graphics.setColor(0.2,0.2,0.2)
    love.graphics.rectangle("fill", kx+10, inputY, inputW, 30, 5)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", kx+10, inputY, inputW, 30, 5)
    love.graphics.setColor(1,1,1)
    local displayText = State.editingText or ""
    if #displayText > 20 then displayText = displayText:sub(1,20).."…" end
    love.graphics.print(utils.safeUTF8(displayText), kx+15, inputY+8)

    -- Клавиши
    for i, row in ipairs(keys) do
        for j, char in ipairs(row) do
            local bx = kx + State.keySpacing + (j-1)*(State.keyW + State.keySpacing)
            local by = ky + State.keySpacing + (i-1)*(State.keyH + State.keySpacing) + 50
            love.graphics.setColor(0.3,0.3,0.3)
            love.graphics.rectangle("fill", bx, by, State.keyW, State.keyH, 6)
            love.graphics.setColor(1,1,1)
            love.graphics.rectangle("line", bx, by, State.keyW, State.keyH, 6)
            love.graphics.printf(char, bx, by+State.keyH/2-8, State.keyW, "center")
        end
    end

    -- Кнопки режимов
    local swY = ky + rows*(State.keyH + State.keySpacing) + State.keySpacing + 50
    local modes = {{"123","digits"},{"АБВ","ru"},{"ABC","en"}}
    for i, m in ipairs(modes) do
        local bx = kx + State.keySpacing + (i-1)*(55 + State.keySpacing)
        love.graphics.setColor(0.3,0.3,0.3)
        love.graphics.rectangle("fill", bx, swY, 55, 30, 6)
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("line", bx, swY, 55, 30, 6)
        love.graphics.printf(m[1], bx, swY+8, 55, "center")
    end

    -- Кнопки "Paste" и "Done"
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

    -- Кнопка закрытия (красный крестик)
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
    local rows = #keys

    -- Кнопка закрытия
    local closeX = kx + kw + 5
    local closeY = ky - 10
    if x >= closeX and x <= closeX+30 and y >= closeY and y <= closeY+30 then
        State.keyboardVisible = false
        State.editingBlock = nil
        State.editingText = ""
        return true
    end

    -- Клавиши
    for i, row in ipairs(keys) do
        for j, char in ipairs(row) do
            local bx = kx + State.keySpacing + (j-1)*(State.keyW + State.keySpacing)
            local by = ky + State.keySpacing + (i-1)*(State.keyH + State.keySpacing) + 50
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

    -- Кнопки режимов
    local swY = ky + rows*(State.keyH + State.keySpacing) + State.keySpacing + 50
    local modes = {{"123","digits"},{"АБВ","ru"},{"ABC","en"}}
    for i, m in ipairs(modes) do
        local bx = kx + State.keySpacing + (i-1)*(55 + State.keySpacing)
        if x >= bx and x <= bx+55 and y >= swY and y <= swY+30 then
            State.keyboardMode = m[2]
            return true
        end
    end

    -- Кнопка Paste
    local doneX = kx + kw - 70
    local pasteX = doneX - 75
    if x >= pasteX and x <= pasteX+65 and y >= swY and y <= swY+30 then
        local clip = love.system.getClipboardText()
        if clip then State.editingText = State.editingText .. utils.safeUTF8(clip) end
        return true
    end

    -- Кнопка Done
    if x >= doneX and x <= doneX+60 and y >= swY and y <= swY+30 then
        if State.editingBlock then
            State.editingBlock.param = State.editingText
            require("src.runtime").compileScript()
            table.insert(State.messages, "Parameter updated")
        end
        State.editingBlock = nil
        State.editingText = ""
        State.keyboardVisible = false
        return true
    end

    return false
end

function M.textInput(t)
    if State.keyboardVisible then
        State.editingText = State.editingText .. t
    end
end

function M.keyPressed(key)
    if State.keyboardVisible then
        if key == "return" or key == "kpenter" then
            if State.editingBlock then
                State.editingBlock.param = State.editingText
                require("src.runtime").compileScript()
            end
            State.editingBlock = nil
            State.editingText = ""
            State.keyboardVisible = false
        elseif key == "escape" then
            State.editingBlock = nil
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
            if State.editingBlock then
                -- Удаление блока через клавишу Delete
                for i, b in ipairs(State.workspaceBlocks) do
                    if b == State.editingBlock then
                        blocks.deleteBlockByIndex(i)
                        break
                    end
                end
                State.editingBlock = nil
                State.editingText = ""
                State.keyboardVisible = false
            end
        end
    end
end

return M
