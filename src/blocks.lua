-- src/blocks.lua
local State = require("src.state")
local utils = require("src.utils")
local constants = require("src.constants")

local M = {}

-- Рекурсивная отрисовка дерева блоков
function M.drawBlockTree(blocks, startX, startY, indent, scrollY)
    local y = startY - scrollY
    for _, b in ipairs(blocks) do
        local x = startX + indent * 20
        if y + State.blockHeight > 0 and y < love.graphics.getHeight() then
            local highlight = (State.editingBlock == b)
            M.drawBlock(b, x, y, false, highlight)
        end
        y = y + State.blockHeight + State.blockSpacing
        if b.children and #b.children > 0 then
            y = M.drawBlockTree(b.children, startX, y, indent + 1, scrollY)
        end
    end
    return y
end

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
    M.drawBlockTree(State.workspaceBlocks, State.workspaceStartX, State.workspaceStartY, 0, State.workspaceScrollY)
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
    local function calcTreeHeight(blocks, indent)
        local h = 0
        for _, b in ipairs(blocks) do
            h = h + State.blockHeight + State.blockSpacing
            if b.children then h = h + calcTreeHeight(b.children, indent+1) end
        end
        return h
    end
    State.workspaceContentHeight = State.workspaceStartY + calcTreeHeight(State.workspaceBlocks, 0) + 100
end

function M.updateScrolling(dt)
    local maxPal = math.max(0, State.paletteContentHeight - love.graphics.getHeight())
    State.paletteScrollY = math.max(0, math.min(State.paletteScrollY, maxPal))
    local maxWs = math.max(0, State.workspaceContentHeight - love.graphics.getHeight())
    State.workspaceScrollY = math.max(0, math.min(State.workspaceScrollY, maxWs))
end

-- Клик по палитре (добавление блока)
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
                category = State.paletteTapBlock.category,
                children = (State.paletteTapBlock.type == "control") and {} or nil,
                elseChildren = (State.paletteTapBlock.name == "ifElse") and {} or nil
            }
            table.insert(State.workspaceBlocks, nb)
            M.calculateHeights()
            require("src.runtime").compileScript()
        end
        State.paletteTapBlock = nil
    end
end

-- Клик по рабочей области (запоминаем блок для долгого нажатия)
function M.workspaceClick(x, y)
    local idx = nil
    local currentY = State.workspaceStartY - State.workspaceScrollY
    -- Ищем блок в корневом списке (без учёта вложенности для простоты)
    for i, b in ipairs(State.workspaceBlocks) do
        local bx = State.workspaceStartX
        if x >= bx and x <= bx+State.blockWidth and y >= currentY and y <= currentY+State.blockHeight then
            idx = i
            break
        end
        currentY = currentY + State.blockHeight + State.blockSpacing
        -- Пропускаем вложенные (упрощённо)
    end
    if idx then
        State.longPressBlockIdx = idx
        State.longPressStartTime = love.timer.getTime()
        State.longPressMoved = false
        State.dragSourceParent = nil
        State.dragSourceIndex = nil
    end
end

function M.workspaceRelease()
    if State.longPressBlockIdx and not State.longPressMoved then
        local elapsed = love.timer.getTime() - State.longPressStartTime
        if elapsed < 0.5 then
            -- Короткое нажатие → открываем редактирование параметра
            local block = State.workspaceBlocks[State.longPressBlockIdx]
            State.editingBlock = block
            State.editingText = tostring(block.param or "")
            State.keyboardVisible = true
            State.keyboardMode = "digits"  -- или "en", по желанию
        end
        State.longPressBlockIdx = nil
    end
    -- Перетаскивание (если было)
    if State.draggingBlock then
        table.insert(State.workspaceBlocks, State.draggingBlock)
        State.draggingBlock = nil
        M.calculateHeights()
        require("src.runtime").compileScript()
    end
end

function M.handleTouchMove(x, y, dx, dy)
    if State.paletteTapBlock then
        if math.abs(dx) > 3 or math.abs(dy) > 3 then
            State.paletteMoved = true
            State.draggingBlock = {
                type = State.paletteTapBlock.type,
                name = State.paletteTapBlock.name,
                label = State.paletteTapBlock.label,
                param = State.paletteTapBlock.param,
                category = State.paletteTapBlock.category,
                children = (State.paletteTapBlock.type == "control") and {} or nil,
                elseChildren = (State.paletteTapBlock.name == "ifElse") and {} or nil
            }
            State.dragFromPalette = true
        end
    end
    if State.longPressBlockIdx and not State.longPressMoved then
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
    if State.editingBlock then
        State.clipboard = {
            type = State.editingBlock.type,
            name = State.editingBlock.name,
            label = State.editingBlock.label,
            param = State.editingBlock.param,
            category = State.editingBlock.category,
            children = State.editingBlock.children and {} or nil
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

-- Удаление блока (вызывается из ui.updateLongPress)
function M.deleteBlockByIndex(idx)
    if idx and idx >= 1 and idx <= #State.workspaceBlocks then
        table.remove(State.workspaceBlocks, idx)
        M.calculateHeights()
        require("src.runtime").compileScript()
        State.editingBlock = nil
        State.editingText = ""
        State.keyboardVisible = false
        return true
    end
    return false
end

return M
