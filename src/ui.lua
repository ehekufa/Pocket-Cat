-- src/ui.lua
local State = require("src.state")
local project = require("src.project")
local blocks = require("src.blocks")
local runtime = require("src.runtime")
local utils = require("src.utils")

local M = {}

local COLORS = {
    primary_dark = {0, 0.18, 0.33},
    primary_blue = {0, 0.30, 0.50},
    bg_dark = {0, 0.12, 0.22},
    accent_yellow = {1, 0.65, 0},
    text_light = {1, 1, 1},
    text_gray = {0.69, 0.77, 0.87},
}

function M.drawTopBar(title)
    local w = love.graphics.getWidth()
    local h = 56
    
    love.graphics.setColor(COLORS.primary_dark)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", 0, h - 4, w, 4)
    
    love.graphics.setColor(COLORS.accent_yellow)
    love.graphics.rectangle("fill", 16, 12, 32, 32, 6)
    love.graphics.setColor(COLORS.primary_dark)
    love.graphics.print("C", 26, 18, 0, 1.2)
    
    love.graphics.setColor(COLORS.text_light)
    love.graphics.setFont(State.font)
    love.graphics.print(title or "NewCatroid", 56, h/2 - 10)
    
    if State.currentScreen ~= "main" then
        local btnX = w - 45
        love.graphics.setColor(COLORS.text_light)
        love.graphics.circle("fill", btnX, h/2, 18)
        love.graphics.setColor(COLORS.primary_dark)
        love.graphics.print("≡", btnX - 6, h/2 - 10, 0, 1.2)
        
        -- Кнопка назад
        love.graphics.setColor(COLORS.text_light)
        love.graphics.print("<", 10, h/2 - 10, 0, 1.2)
    end
    
    State.topBarHeight = h
end

function M.drawFAB()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    local playX = w - 70
    local playY = h - 160
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", playX + 2, playY + 2, 28)
    love.graphics.setColor(0.2, 0.8, 0.3)
    love.graphics.circle("fill", playX, playY, 28)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("▶", playX - 8, playY - 12, 0, 1.5)
    State.playButton = {x = playX, y = playY, r = 28}
    
    local addX = w - 70
    local addY = h - 80
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", addX + 2, addY + 2, 28)
    love.graphics.setColor(COLORS.accent_yellow)
    love.graphics.circle("fill", addX, addY, 28)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("+", addX - 10, addY - 14, 0, 2)
    State.addButton = {x = addX, y = addY, r = 28}
end

function M.drawMessages()
    local msgY = 70
    local maxMessages = 5
    local startIdx = math.max(1, #State.messages - maxMessages + 1)
    
    for i = startIdx, #State.messages do
        local msg = State.messages[i]
        if msgY < love.graphics.getHeight() - 20 then
            love.graphics.setColor(0, 0, 0, 0.6)
            local tw = love.graphics.getFont():getWidth(utils.safeUTF8(msg)) + 20
            love.graphics.rectangle("fill", 10, msgY - 2, math.min(tw, love.graphics.getWidth() - 40), 26, 8)
            
            love.graphics.setColor(0.8, 0.9, 1)
            love.graphics.print(utils.safeUTF8(msg), 18, msgY + 2)
            msgY = msgY + 32
        end
    end
end

function M.handleTopBarClick(x, y)
    if y > (State.topBarHeight or 56) then return false end
    
    if x < 40 and State.currentScreen ~= "main" then
        State.currentScreen = "main"
        return true
    end
    
    return false
end

function M.handleFABClick(x, y)
    if State.playButton then
        local b = State.playButton
        if (x - b.x)^2 + (y - b.y)^2 <= (b.r + 5)^2 then
            runtime.runProject()
            table.insert(State.messages, "Project started!")
            return true
        end
    end
    
    if State.addButton then
        local b = State.addButton
        if (x - b.x)^2 + (y - b.y)^2 <= (b.r + 5)^2 then
            if State.currentScreen == "main" then
                State.showCreateProject = true
                State.newProjectName = ""
                love.keyboard.setTextInput(true)
            else
                table.insert(State.messages, "Add actor or object")
            end
            return true
        end
    end
    
    return false
end

function M.handleClick(x, y)
    return false
end

function M.updateLongPress(dt)
    if State.longPressBlockIdx and not State.longPressMoved then
        if love.timer.getTime() - State.longPressStartTime > 0.5 then
            if blocks.deleteBlockByIndex(State.longPressBlockIdx) then
                table.insert(State.messages, "Block deleted")
            end
            State.longPressBlockIdx = nil
            State.editingBlock = nil
            State.editingText = ""
            love.keyboard.setTextInput(false)
        end
    end
end

return M
