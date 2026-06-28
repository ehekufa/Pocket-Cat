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
    local rx = love.graphics.getWidth() - 50
    love.graphics.setColor(0,1,0)
    love.graphics.circle("fill", rx, 15, 22)
    love.graphics.setColor(1,1,1)
    love.graphics.print(">", rx-8, 5, 0, 1.6)
    local btnY = 50
    love.graphics.setColor(0.2,0.5,1.0)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 140, 30)
    love.graphics.print("Save .cat", love.graphics.getWidth()-145, btnY+8)
    btnY = btnY + 35
    love.graphics.setColor(0.2,0.5,1.0)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 140, 30)
    love.graphics.print("Load .cat", love.graphics.getWidth()-145, btnY+8)
    btnY = btnY + 35
    love.graphics.setColor(0.7,0.7,0.2)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 68, 25)
    love.graphics.print("Copy", love.graphics.getWidth()-145, btnY+5)
    love.graphics.rectangle("fill", love.graphics.getWidth()-78, btnY, 68, 25)
    love.graphics.print("Paste", love.graphics.getWidth()-73, btnY+5)
end

function M.drawMessages()
    local msgY = State.workspaceStartY + #State.workspaceBlocks*(State.blockHeight+State.blockSpacing) + 20 - State.workspaceScrollY
    for _, msg in ipairs(State.messages) do
        if msgY > 0 and msgY < love.graphics.getHeight() then
            love.graphics.setColor(1,1,1)
            love.graphics.print(utils.safeUTF8(msg), State.workspaceStartX, msgY)
        end
        msgY = msgY + State.fontSize + 4
    end
end

function M.handleClick(x, y)
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
                        -- Открыть выбор файла (имитация для ПК, в реальности можно использовать love.filedropped)
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
        -- Buttons
        local rx = love.graphics.getWidth() - 50
        if math.sqrt((x-rx)^2 + (y-15)^2) <= 22 then
            runtime.runProject()
            return true
        end
        local btnY = 50
        if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+30 then
            project.saveProject("project.cat")
            table.insert(State.messages, "Project saved")
            return true
        end
        btnY = btnY + 35
        if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+30 then
            local loaded = project.loadProject("project.cat")
            if loaded then
                State.project = loaded
                blocks.updateWorkspace()
                runtime.compileScript()
                table.insert(State.messages, "Project loaded")
            else
                table.insert(State.messages, "Load failed")
            end
            return true
        end
        btnY = btnY + 35
        if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-82 and y >= btnY and y <= btnY+25 then
            blocks.copyBlock()
            return true
        end
        if x >= love.graphics.getWidth()-78 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+25 then
            blocks.pasteBlock()
            return true
        end
    end
    return false
end

function M.updateLongPress(dt)
    if State.longPressBlockIdx and not State.longPressMoved then
        if love.timer.getTime() - State.longPressStartTime > 0.5 then
            table.remove(State.workspaceBlocks, State.longPressBlockIdx)
            if State.editingBlockIdx == State.longPressBlockIdx then
                State.editingBlockIdx = nil
                State.editingText = ""
                State.keyboardVisible = false
            end
            State.longPressBlockIdx = nil
            blocks.calculateHeights()
            runtime.compileScript()
        end
    end
end

return M
