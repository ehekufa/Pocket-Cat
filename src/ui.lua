-- src/ui.lua
local State = require("src.state")
local project = require("src.project")
local blocks = require("src.blocks")
local runtime = require("src.runtime")
local utils = require("src.utils")

local M = {}

function M.calculateHeights()
    blocks.calculateHeights()
end

function M.drawTabs()
    love.graphics.setColor(0.1,0.1,0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 70)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Scenes:", 5, 5)
    local sx = 70
    for i, sc in ipairs(State.project.scenes) do
        local w = love.graphics.getFont():getWidth(sc.name) + 15
        love.graphics.setColor(State.currentSceneIdx == i and {0.4,0.7,1} or {0.3,0.3,0.3})
        love.graphics.rectangle("fill", sx, 5, w, 25)
        love.graphics.setColor(1,1,1)
        love.graphics.print(sc.name, sx+5, 10)
        sx = sx + w + 5
    end
    love.graphics.setColor(0.3,0.7,0.3)
    love.graphics.rectangle("fill", sx, 5, 25, 25)
    love.graphics.print("+", sx+5, 8)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Objects:", 5, 35)
    local ox = 70
    local scene = project.getCurrentScene()
    if scene then
        for i, obj in ipairs(scene.objects) do
            local w = love.graphics.getFont():getWidth(obj.name) + 15
            love.graphics.setColor(State.currentObjectIdx == i and {0.9,0.9,0.2} or {0.3,0.3,0.3})
            love.graphics.rectangle("fill", ox, 35, w, 25)
            love.graphics.setColor(1,1,1)
            love.graphics.print(obj.name, ox+5, 40)
            love.graphics.setColor(0.8,0.6,0.2)
            love.graphics.rectangle("fill", ox+w+5, 35, 25, 25)
            love.graphics.print("P", ox+w+7, 38)
            love.graphics.setColor(0.4,0.5,1.0)
            love.graphics.rectangle("fill", ox+w+35, 35, 25, 25)
            love.graphics.print("F", ox+w+37, 38)
            ox = ox + w + 65
        end
        love.graphics.setColor(0.3,0.7,0.3)
        love.graphics.rectangle("fill", ox, 35, 25, 25)
        love.graphics.print("+", ox+5, 38)
    end
end

function M.drawButtons()
    -- Кнопка запуска (зелёный круг с ">")
    local rx = love.graphics.getWidth() - 50
    love.graphics.setColor(0,1,0)
    love.graphics.circle("fill", rx, 15, 22)
    love.graphics.setColor(1,1,1)
    love.graphics.print(">", rx-8, 5, 0, 1.6)
    State.runButton = {x = rx, y = 15, r = 22}

    local btnY = 50
    -- Save .cat
    love.graphics.setColor(0.2,0.5,1.0)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 140, 30)
    love.graphics.print("Save .cat", love.graphics.getWidth()-145, btnY+8)
    btnY = btnY + 35
    -- Load .cat
    love.graphics.setColor(0.2,0.5,1.0)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 140, 30)
    love.graphics.print("Load .cat", love.graphics.getWidth()-145, btnY+8)
    btnY = btnY + 35
    -- Export .cat (сохранить с уникальным именем в Documents)
    love.graphics.setColor(0.8,0.6,0.2)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 140, 30)
    love.graphics.print("Export .cat", love.graphics.getWidth()-145, btnY+8)
    btnY = btnY + 35
    -- Copy/Paste
    love.graphics.setColor(0.7,0.7,0.2)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 68, 25)
    love.graphics.print("Copy", love.graphics.getWidth()-145, btnY+5)
    love.graphics.rectangle("fill", love.graphics.getWidth()-78, btnY, 68, 25)
    love.graphics.print("Paste", love.graphics.getWidth()-73, btnY+5)
    btnY = btnY + 35
    -- Variables
    love.graphics.setColor(0.9,0.5,0.1)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 140, 30)
    love.graphics.print("Variables", love.graphics.getWidth()-145, btnY+8)
end

function M.drawMessages()
    local msgY = State.workspaceStartY + 20 - State.workspaceScrollY
    for _, msg in ipairs(State.messages) do
        if msgY > 0 and msgY < love.graphics.getHeight() then
            love.graphics.setColor(1,1,1)
            love.graphics.print(utils.safeUTF8(msg), State.workspaceStartX, msgY)
        end
        msgY = msgY + State.fontSize + 4
    end
end

function M.handleClick(x, y)
    -- Верхние вкладки
    if y <= 60 then
        if y >= 5 and y <= 30 then
            local sx = 70
            for i, sc in ipairs(State.project.scenes) do
                local w = love.graphics.getFont():getWidth(sc.name) + 15
                if x >= sx and x <= sx+w then
                    State.currentSceneIdx = i
                    State.currentObjectIdx = 1
                    blocks.updateWorkspace()
                    runtime.compileScript()
                    return true
                end
                sx = sx + w + 5
            end
            if x >= sx and x <= sx+25 then
                project.addScene()
                return true
            end
        elseif y >= 35 and y <= 60 then
            local ox = 70
            local scene = project.getCurrentScene()
            if scene then
                for i, obj in ipairs(scene.objects) do
                    local w = love.graphics.getFont():getWidth(obj.name) + 15
                    if x >= ox and x <= ox+w then
                        State.currentObjectIdx = i
                        blocks.updateWorkspace()
                        runtime.compileScript()
                        return true
                    end
                    if x >= ox+w+5 and x <= ox+w+30 then
                        State.paintMode = true
                        return true
                    end
                    if x >= ox+w+35 and x <= ox+w+60 then
                        -- файловый диалог через love.filedropped
                        table.insert(State.messages, "Перетащите файл в окно для импорта")
                        return true
                    end
                    ox = ox + w + 65
                end
                if x >= ox and x <= ox+25 then
                    project.addObject()
                    return true
                end
            end
        end
    else
        -- Кнопка запуска
        if State.runButton then
            local bx, by, br = State.runButton.x, State.runButton.y, State.runButton.r
            if (x - bx)^2 + (y - by)^2 <= br^2 then
                runtime.runProject()
                return true
            end
        end

        local btnY = 50
        -- Save .cat (стандартное сохранение в корень)
        if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+30 then
            project.saveProject("project.cat")
            table.insert(State.messages, "Project saved as project.cat")
            return true
        end
        btnY = btnY + 35
        -- Load .cat (загрузка из корня)
        if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+30 then
            local loaded = project.loadProject("project.cat")
            if loaded then
                table.insert(State.messages, "Project loaded from project.cat")
            else
                table.insert(State.messages, "Load failed")
            end
            return true
        end
        btnY = btnY + 35
        -- Export .cat (сохранить в Documents с уникальным именем)
        if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+30 then
            local timestamp = os.date("%Y%m%d_%H%M%S")
            local filename = "pocketcat_" .. timestamp .. ".cat"
            -- Сохраняем в DocumentsDirectory
            local path = system.pathForFile(filename, system.DocumentsDirectory)
            if path then
                project.saveProject(path)
                table.insert(State.messages, "Exported to: " .. path)
            else
                table.insert(State.messages, "Export failed")
            end
            return true
        end
        btnY = btnY + 35
        -- Copy/Paste
        if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-82 and y >= btnY and y <= btnY+25 then
            blocks.copyBlock()
            return true
        end
        if x >= love.graphics.getWidth()-78 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+25 then
            blocks.pasteBlock()
            return true
        end
        btnY = btnY + 35
        -- Variables
        if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+30 then
            local msg = "Variables: "
            for k,v in pairs(State.vars) do msg = msg .. k .. "=" .. tostring(v) .. " " end
            table.insert(State.messages, msg)
            return true
        end
    end
    return false
end

function M.updateLongPress(dt)
    if State.longPressBlockIdx and not State.longPressMoved then
        if love.timer.getTime() - State.longPressStartTime > 0.5 then
            blocks.deleteBlockByIndex(State.longPressBlockIdx)
            State.longPressBlockIdx = nil
            State.editingBlock = nil
            State.editingText = ""
            State.keyboardVisible = false
            table.insert(State.messages, "Block deleted")
        end
    end
end

return M
