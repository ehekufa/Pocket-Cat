-- src/blocks.lua
local State = require("src.state")
local utils = require("src.utils")
local constants = require("src.constants")

local M = {}

function M.drawBlock(block, x, y, isDragging, highlight)
    local color = State.catColors[block.category] or {0.4,0.4,0.8}
    love.graphics.setColor(0,0,0,0.3)
    love.graphics.rectangle("fill", x+2, y+2, State.blockWidth, State.blockHeight, 10)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, State.blockWidth, State.blockHeight, 10)
    love.graphics.setColor(color)
    love.graphics.circle("fill", x + State.blockWidth/2, y, 8)
    love.graphics.setColor(State.bgColor)
    love.graphics.circle("fill", x + State.blockWidth/2, y + State.blockHeight, 8)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", x, y, State.blockWidth, State.blockHeight, 10)
    love.graphics.setColor(1,1,1)
    love.graphics.print(block.label or block.name, x+14, y+10)
    if highlight then
        love.graphics.setColor(1,1,0)
        love.graphics.rectangle("line", x-1, y-1, State.blockWidth+2, State.blockHeight+2, 12)
    end
end

function M.drawPalette()
    love.graphics.setScissor(0, 0, State.paletteWidth, love.graphics.getHeight())
    love.graphics.setColor(0.15,0.15,0.15)
    love.graphics.rectangle("fill", 0, 0, State.paletteWidth, love.graphics.getHeight())
    local y = 10 - State.paletteScrollY
    local lastCat = nil
    for _, b in ipairs(State.paletteBlocks) do
        if b.category ~= lastCat then
            love.graphics.setColor(1,1,1)
            love.graphics.print(b.category, 5, y)
            y = y + 20
            lastCat = b.category
        end
        if y + State.blockHeight > 0 and y < love.graphics.getHeight() then
            M.drawBlock(b, 5, y)
        end
        y = y + State.blockHeight + 6
    end
    love.graphics.setScissor()
end

function M.drawWorkspace()
    love.graphics.setScissor(State.paletteWidth, 0, love.graphics.getWidth()-State.paletteWidth, love.graphics.getHeight())
    love.graphics.setColor(0.1,0.1,0.1)
    love.graphics.rectangle("fill", State.paletteWidth, 0, love.graphics.getWidth()-State.paletteWidth, love.graphics.getHeight())
    love.graphics.setColor(1,1,1)
    love.graphics.print("Workspace", State.workspaceStartX, 10 - State.workspaceScrollY)
    for i, b in ipairs(State.workspaceBlocks) do
        local bx = State.workspaceStartX
        local by = State.workspaceStartY + (i-1)*(State.blockHeight + State.blockSpacing) - State.workspaceScrollY
        local highlight = (State.editingBlockIdx == i)
        if not (State.draggingBlock == b and not State.dragFromPalette) then
            if by + State.blockHeight > 0 and by < love.graphics.getHeight() then
                M.drawBlock(b, bx, by, false, highlight)
            end
        end
    end
    if State.draggingBlock then
        local mx, my = love.mouse.getPosition()
        M.drawBlock(State.draggingBlock, mx-State.blockWidth/2, my-State.blockHeight/2, true, false)
    end
    love.graphics.setScissor()
end

function M.updateWorkspace()
    local obj = require("src.project").getCurrentObject()
    State.workspaceBlocks = obj and obj.blocks or {}
    M.calculateHeights()
end

function M.calculateHeights()
    local y = 10
    local lastCat = nil
    for _, b in ipairs(State.paletteBlocks) do
        if b.category ~= lastCat then y = y + 20; lastCat = b.category end
        y = y + State.blockHeight + 6
    end
    State.paletteContentHeight = y
    State.workspaceContentHeight = State.workspaceStartY + #State.workspaceBlocks * (State.blockHeight + State.blockSpacing) + 100
end

function M.updateScrolling(dt)
    local maxPal = math.max(0, State.paletteContentHeight - love.graphics.getHeight())
    State.paletteScrollY = math.max(0, math.min(State.paletteScrollY, maxPal))
    local maxWs = math.max(0, State.workspaceContentHeight - love.graphics.getHeight())
    State.workspaceScrollY = math.max(0, math.min(State.workspaceScrollY, maxWs))
end

function M.paletteClick(x, y)
    local yPal = 10 - State.paletteScrollY
    local lastCat = nil
    for _, b in ipairs(State.paletteBlocks) do
        if b.category ~= lastCat then yPal = yPal + 20; lastCat = b.category end
        if x >= 5 and x <= 5+State.blockWidth and y >= yPal and y <= yPal+State.blockHeight then
            State.paletteTapBlock = b
            State.paletteTapTime = love.timer.getTime()
            State.paletteMoved = false
            return
        end
        yPal = yPal + State.blockHeight + 6
    end
end

function M.paletteRelease()
    if State.paletteTapBlock and not State.paletteMoved then
        local elapsed = love.timer.getTime() - State.paletteTapTime
        if elapsed < 0.4 then
            local nb = {
                type = State.paletteTapBlock.type,
                name = State.paletteTapBlock.name,
                label = State.paletteTapBlock.label,
                param = State.paletteTapBlock.param,
                category = State.paletteTapBlock.category
            }
            table.insert(State.workspaceBlocks, nb)
            M.calculateHeights()
            require("src.runtime").compileScript()
        end
        State.paletteTapBlock = nil
    end
end

function M.workspaceClick(x, y)
    for i, b in ipairs(State.workspaceBlocks) do
        local bx = State.workspaceStartX
        local by = State.workspaceStartY + (i-1)*(State.blockHeight + State.blockSpacing) - State.workspaceScrollY
        if x >= bx and x <= bx+State.blockWidth and y >= by and y <= by+State.blockHeight then
            State.longPressBlockIdx = i
            State.longPressStartTime = love.timer.getTime()
            State.longPressMoved = false
            return
        end
    end
end

function M.workspaceRelease()
    if State.longPressBlockIdx and not State.longPressMoved then
        local elapsed = love.timer.getTime() - State.longPressStartTime
        if elapsed < 0.5 then
            State.editingBlockIdx = State.longPressBlockIdx
            State.editingText = tostring(State.workspaceBlocks[State.longPressBlockIdx].param or "")
            State.keyboardVisible = true
        end
        State.longPressBlockIdx = nil
    end
end

function M.handleTouchMove(x, y, dx, dy)
    if State.paletteTapBlock then
        if math.abs(dx) > 3 or math.abs(dy) > 3 then State.paletteMoved = true end
    end
    if State.longPressBlockIdx then
        if math.abs(dx) > 5 or math.abs(dy) > 5 then
            State.longPressMoved = true
            State.draggingBlock = State.workspaceBlocks[State.longPressBlockIdx]
            table.remove(State.workspaceBlocks, State.longPressBlockIdx)
            State.longPressBlockIdx = nil
        end
    elseif x <= State.paletteWidth then
        State.paletteScrollY = State.paletteScrollY - dy
    else
        State.workspaceScrollY = State.workspaceScrollY - dy
    end
end

function M.handleWheel(x, y)
    if x <= State.paletteWidth then
        State.paletteScrollY = State.paletteScrollY - y * 30
    else
        State.workspaceScrollY = State.workspaceScrollY - y * 30
    end
end

function M.copyBlock()
    if State.editingBlockIdx then
        local block = State.workspaceBlocks[State.editingBlockIdx]
        State.clipboard = {
            type = block.type,
            name = block.name,
            label = block.label,
            param = block.param,
            category = block.category
        }
        table.insert(State.messages, "Block copied")
    else
        table.insert(State.messages, "Select a block first")
    end
end

function M.pasteBlock()
    if State.clipboard then
        table.insert(State.workspaceBlocks, State.clipboard)
        M.calculateHeights()
        require("src.runtime").compileScript()
        table.insert(State.messages, "Block pasted")
    else
        table.insert(State.messages, "Clipboard is empty")
    end
end

return M
