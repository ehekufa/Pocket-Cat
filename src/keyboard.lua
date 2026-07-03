-- src/keyboard.lua
local State = require("src.state")

local M = {}

-- Ничего не рисуем
function M.drawKeyboard()
    -- пусто
end

-- Обработка ввода текста (вызывается из love.textinput)
function M.handleTextInput(t)
    if State.editingBlock then
        State.editingText = State.editingText .. t
    end
end

-- Обработка нажатий клавиш (Enter, Esc, Backspace)
function M.handleKeyPressed(key)
    if not State.editingBlock then return end

    if key == "return" or key == "kpenter" then
        -- Сохраняем параметр
        State.editingBlock.param = State.editingText
        require("src.runtime").compileScript()
        table.insert(State.messages, "Parameter updated: " .. State.editingText)
        State.editingBlock = nil
        State.editingText = ""
        love.keyboard.setTextInput(false)
    elseif key == "escape" then
        -- Отменяем редактирование
        State.editingBlock = nil
        State.editingText = ""
        love.keyboard.setTextInput(false)
    elseif key == "backspace" then
        State.editingText = State.editingText:sub(1, -2)
    end
end

-- Заглушки для совместимости
function M.handleTouch(x, y) return false end
function M.updatePos() end
function M.clearButtons() end

return M
