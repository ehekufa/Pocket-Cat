-- src/keyboard.lua
local State = require("src.state")
local utils = require("src.utils")
local blocks = require("src.blocks")

local M = {}

-- Режимы: "digits" (цифры, +, -, .) и "abc" (буквы)
function M.updatePos()
    local keys = (State.keyboardMode == "digits" and M.digitsKeys or M.abcKeys)
    local cols = #keys[1]
    local totalWidth = cols * (State.keyW + State.keySpacing) + State.keySpacing
    State.keyboardPosX = love.graphics.getWidth()/2 - totalWidth/2
    State.keyboardPosY = love.graphics.getHeight() - State.keyboardHeight - 20
end

-- Раскладки
M.digitsKeys = {
    {"7","8","9"},
    {"4","5","6"},
    {"1","2","3"},
    {"0",".","-","+"}  -- точка, минус, плюс
}

M.abcKeys = {
    {"a","b","c","d","e","f","g","h"},
    {"i","j","k","l","m","n","o","p"},
    {"q","r","s","t","u","v","w","x"},
    {"y","z"}   -- короткий ряд
}

function M.drawKeyboard()
    if not State.keyboardVisible then return end
    M.updatePos()
    local kx, ky = State.keyboardPosX, State.keyboardPosY

    local keys = (State.keyboardMode == "digits" and M.digitsKeys or M.abcKeys)
    local rows = #keys
    local cols = #keys[1]
    local kw = cols * (State.keyW + State.keySpacing) + State.keySpacing
    local kh = rows * (State.keyH + State.keySpacing) + State.keySpacing + 80  -- + место для кнопок внизу

    -- Фон
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", kx, ky, kw, kh, 10)

    -- Поле ввода (слева)
    local inputY = ky + 10
    local inputW = kw - 80  -- оставляем место для Done
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", kx + 10, inputY, inputW, 30, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", kx + 10, inputY, inputW, 30, 5)
    love.graphics.setColor(1, 1, 1)
    local displayText = State.editingText or ""
    if #displayText > 20 then displayText = displayText:sub(1, 20) .. "…"
    love.graphics.print(utils.safeUTF8(displayText), kx + 15, inputY + 8)

    -- Кнопка "Done" справа от поля
    local doneX = kx + 10 + inputW + 10
    love.graphics.setColor(0.2, 0.6, 0.2)
    love.graphics.rectangle("fill", doneX, inputY, 60, 30, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Done", doneX, inputY + 8, 60, "center")
    State.keyboardDoneButton = {x = doneX, y = inputY, w = 60, h = 30}

    -- Клавиши
    local keyStartY = ky + 60
    for i, row in ipairs(keys) do
        for j, char in ipairs(row) do
            local bx = kx + State.keySpacing + (j - 1) * (State.keyW + State.keySpacing)
            local by = keyStartY + (i - 1) * (State.keyH + State.keySpacing)
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", bx, by, State.keyW, State.keyH, 6)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", bx, by, State.keyW, State.keyH, 6)
            love.graphics.printf(char, bx, by + State.keyH / 2 - 8, State.keyW, "center")
        end
    end

    -- Кнопки внизу: "Back" и "ABC/123"
    local bottomY = keyStartY + rows * (State.keyH + State.keySpacing) + 10
    local backW = 70
    local abcW = 70
    local gap = 20
    local totalBottomW = backW + gap + abcW
    local startX = kx + (kw - totalBottomW) / 2

    -- Backspace
    love.graphics.setColor(0.6, 0.2, 0.2)
    love.graphics.rectangle("fill", startX, bottomY, backW, 30, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Back", startX, bottomY + 8, backW, "center")
    State.keyboardBackButton = {x = startX, y = bottomY, w = backW, h = 30}

    -- Переключатель ABC/123
    local abcX = startX + backW + gap
    love.graphics.setColor(0.2, 0.4, 0.8)
    love.graphics.rectangle("fill", abcX, bottomY, abcW, 30, 6)
    love.graphics.setColor(1, 1, 1)
    local modeLabel = (State.keyboardMode == "digits") and "ABC" or "123"
    love.graphics.printf(modeLabel, abcX, bottomY + 8, abcW, "center")
    State.keyboardModeButton = {x = abcX, y = bottomY, w = abcW, h = 30}

    -- Кнопка закрытия (крестик) – справа вверху
    local closeX = kx + kw + 5
    local closeY = ky - 10
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", closeX, closeY, 30, 30, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("X", closeX + 8, closeY + 5)
    State.keyboardCloseButton = {x = closeX, y = closeY, w = 30, h = 30}
end

function M.handleTouch(x, y)
    if not State.keyboardVisible then return false end

    local kx, ky = State.keyboardPosX, State.keyboardPosY
    local keys = (State.keyboardMode == "digits" and M.digitsKeys or M.abcKeys)
    local rows = #keys
    local cols = #keys[1]
    local kw = cols * (State.keyW + State.keySpacing) + State.keySpacing
    local keyStartY = ky + 60

    -- Закрытие (крестик)
    if State.keyboardCloseButton then
        local cb = State.keyboardCloseButton
        if x >= cb.x and x <= cb.x + cb.w and y >= cb.y and y <= cb.y + cb.h then
            State.keyboardVisible = false
            State.editingBlock = nil
            State.editingText = ""
            M.clearButtons()
            return true
        end
    end

    -- Done
    if State.keyboardDoneButton then
        local db = State.keyboardDoneButton
        if x >= db.x and x <= db.x + db.w and y >= db.y and y <= db.y + db.h then
            if State.editingBlock then
                State.editingBlock.param = State.editingText
                require("src.runtime").compileScript()
                table.insert(State.messages, "Parameter updated: " .. State.editingText)
            end
            State.editingBlock = nil
            State.editingText = ""
            State.keyboardVisible = false
            M.clearButtons()
            return true
        end
    end

    -- Back
    if State.keyboardBackButton then
        local bb = State.keyboardBackButton
        if x >= bb.x and x <= bb.x + bb.w and y >= bb.y and y <= bb.y + bb.h then
            State.editingText = State.editingText:sub(1, -2)
            return true
        end
    end

    -- Переключатель режима
    if State.keyboardModeButton then
        local mb = State.keyboardModeButton
        if x >= mb.x and x <= mb.x + mb.w and y >= mb.y and y <= mb.y + mb.h then
            if State.keyboardMode == "digits" then
                State.keyboardMode = "abc"
            else
                State.keyboardMode = "digits"
            end
            return true
        end
    end

    -- Клавиши с символами
    for i, row in ipairs(keys) do
        for j, char in ipairs(row) do
            local bx = kx + State.keySpacing + (j - 1) * (State.keyW + State.keySpacing)
            local by = keyStartY + (i - 1) * (State.keyH + State.keySpacing)
            if x >= bx and x <= bx + State.keyW and y >= by and y <= by + State.keyH then
                State.editingText = State.editingText .. char
                return true
            end
        end
    end

    -- Клик вне клавиатуры закрывает
    if y < ky then
        State.keyboardVisible = false
        State.editingBlock = nil
        State.editingText = ""
        M.clearButtons()
        return true
    end

    return false
end

function M.clearButtons()
    State.keyboardCloseButton = nil
    State.keyboardDoneButton = nil
    State.keyboardBackButton = nil
    State.keyboardModeButton = nil
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
            M.clearButtons()
        elseif key == "escape" then
            State.editingBlock = nil
            State.editingText = ""
            State.keyboardVisible = false
            M.clearButtons()
        elseif key == "backspace" then
            State.editingText = State.editingText:sub(1, -2)
        end
    else
        if key == "f5" then
            require("src.runtime").runProject()
        elseif key == "f2" then
            require("src.project").saveProject("project.cat")
        end
    end
end

-- Инициализация режима (по умолчанию digits)
State.keyboardMode = State.keyboardMode or "digits"

return M
