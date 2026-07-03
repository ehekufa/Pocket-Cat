-- src/keyboard.lua
local State = require("src.state")
local project = require("src.project")

local M = {}

-- Ничего не рисуем (виртуальная клавиатура отключена)
function M.drawKeyboard()
    -- пусто
end

-- Обработка ввода текста (вызывается из love.textinput)
function M.handleTextInput(t)
    if State.editingBlock or State.inputMode then
        State.editingText = State.editingText .. t
    end
end

-- Обработка нажатий клавиш (Enter, Esc, Backspace, Ctrl+V)
function M.handleKeyPressed(key)
    -- Если не в режиме редактирования – выходим
    if not State.editingBlock and not State.inputMode then
        return
    end

    -- Ctrl+V (вставка из буфера обмена)
    if key == "v" and love.keyboard.isDown("ctrl") then
        local clip = love.system.getClipboardText()
        if clip then
            State.editingText = State.editingText .. clip
        end
        return
    end

    if key == "return" or key == "kpenter" then
        if State.editingBlock then
            -- Сохраняем параметр блока
            State.editingBlock.param = State.editingText
            require("src.runtime").compileScript()
            table.insert(State.messages, "Parameter updated: " .. State.editingText)
            State.editingBlock = nil
            State.editingText = ""
            love.keyboard.setTextInput(false)
        elseif State.inputMode == "save" then
            -- Сохраняем проект
            local name = State.editingText
            if name and name ~= "" then
                project.saveProject(name)
            else
                table.insert(State.messages, "Canceled")
            end
            State.inputMode = nil
            State.editingText = ""
            love.keyboard.setTextInput(false)
        elseif State.inputMode == "load" then
            local name = State.editingText
            if name and name ~= "" then
                project.loadProject(name)
            else
                table.insert(State.messages, "Canceled")
            end
            State.inputMode = nil
            State.editingText = ""
            love.keyboard.setTextInput(false)
        end
    elseif key == "escape" then
        -- Отменяем любое редактирование
        State.editingBlock = nil
        State.inputMode = nil
        State.editingText = ""
        love.keyboard.setTextInput(false)
        table.insert(State.messages, "Editing canceled")
    elseif key == "backspace" then
        State.editingText = State.editingText:sub(1, -2)
    end
end

-- Заглушки для совместимости
function M.handleTouch(x, y) return false end
function M.updatePos() end
function M.clearButtons() end

return M
