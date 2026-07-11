-- src/blocks.lua
local State = require("src.state")
local runtime = require("src.runtime")

local M = {}

local CAT_COLORS = {
    event = {0.82, 0.34, 0.15},
    motion = {0.20, 0.56, 0.80},
    looks = {0.41, 0.21, 0.72},
    sound = {0.24, 0.72, 0.44},
    control = {0.96, 0.58, 0.39},
    variables = {0.80, 0.18, 0.18},
    pen = {0.12, 0.80, 0.28},
    text = {1, 1, 1},
    sensing = {0.55, 0.55, 0.55},
    cloud = {0.12, 0.47, 0.80},
}

local CATEGORY_BLOCKS = {
    events = {
        {type="event", name="start", label="when start", category="event"},
        {type="event", name="tap", label="on tap", category="event"},
        {type="event", name="release", label="on release", category="event"},
        {type="event", name="touch", label="on touch", category="event"},
    },
    motion = {
        {type="action", name="changeX", label="change X by", param=10, category="motion"},
        {type="action", name="changeY", label="change Y by", param=10, category="motion"},
        {type="action", name="setX", label="set X to", param=200, category="motion"},
        {type="action", name="setY", label="set Y to", param=200, category="motion"},
        {type="action", name="turn", label="turn by", param=15, category="motion"},
    },
    looks = {
        {type="action", name="showCube", label="show cube", category="looks"},
        {type="action", name="showSphere", label="show sphere", category="looks"},
        {type="action", name="showImage", label="show sprite", category="looks"},
        {type="action", name="hide", label="hide object", category="looks"},
        {type="action", name="show", label="show object", category="looks"},
        {type="action", name="setColor", label="set color", param="green", category="looks"},
        {type="action", name="setSize", label="set size", param=50, category="looks"},
    },
    pen = {
        {type="action", name="penDown", label="pen down", category="pen"},
        {type="action", name="penUp", label="pen up", category="pen"},
        {type="action", name="penClear", label="clear pen", category="pen"},
        {type="action", name="penColor", label="pen color", param="green", category="pen"},
        {type="action", name="penSize", label="pen size", param=2, category="pen"},
    },
    sound = {
        {type="action", name="playSound", label="play sound", param="", category="sound"},
    },
    control = {
        {type="control", name="repeat", label="repeat", param=3, category="control"},
        {type="control", name="forever", label="forever", category="control"},
        {type="control", name="if", label="if", param="", category="control"},
        {type="control", name="ifElse", label="if else", param="", category="control"},
    },
    variables = {
        {type="action", name="setVar", label="set variable", param="", category="variables"},
        {type="action", name="changeVar", label="change variable by", param="", category="variables"},
        {type="action", name="showVar", label="show variable", param="", category="variables"},
    },
    text = {
        {type="action", name="printText", label="print text", param="Hello!", category="text"},
    },
    sensing = {
        {type="action", name="mouseX", label="mouse X", category="sensing"},
        {type="action", name="mouseY", label="mouse Y", category="sensing"},
        {type="action", name="touchX", label="touch X", category="sensing"},
        {type="action", name="touchY", label="touch Y", category="sensing"},
    },
}

function M.drawBlock(block, x, y, isDragging, highlight)
    local color = CAT_COLORS[block.category] or {0.4, 0.4, 0.8}
    local w = State.blockWidth or 160
    local h = State.blockHeight or 34
    local r = 8
    
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", x + 3, y + 3, w, h, r)
    
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, w, h, r)
    
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("fill", x + 4, y + 2, w - 8, 4, 2)
    
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("line", x, y, w, h, r)
    
    love.graphics.setColor(1, 1, 1)
    local label = block.label or block.name or "block"
    love.graphics.print(label, x + 12, y + 8)
    
    if block.param ~= nil then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("fill", x + w - 50, y + 4, 44, h - 8, 4)
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.print(tostring(block.param), x + w - 44, y + 8)
    end
    
    if highlight then
        love.graphics.setColor(1, 1, 0, 0.5)
        love.graphics.rectangle("line", x - 2, y - 2, w + 4, h + 4, r + 2)
    end
end

function M.drawPalette()
    local w = State.paletteWidth or 200
    local h = love.graphics.getHeight()
    local topBar = 56
    
    love.graphics.setColor(0.06, 0.06, 0.12)
    love.graphics.rectangle("fill", 0, topBar, w, h - topBar)
    
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Blocks", 8, topBar + 8)
    
    love.graphics.setScissor(0, topBar + 30, w, h - topBar - 30)
    
    local y = topBar + 32 - State.paletteScrollY
    local lastCat = nil
    
    for _, b in ipairs(State.paletteBlocks) do
        if b.category ~= lastCat then
            love.graphics.setColor(0.4, 0.5, 0.7)
            love.graphics.print(b.category:upper(), 8, y)
            y = y + 22
            lastCat = b.category
        end
        if y + State.blockHeight > topBar + 30 and y < h then
            M.drawBlock(b, 6, y)
        end
        y = y + State.blockHeight + 4
    end
    
    love.graphics.setScissor()
end

function M.drawCategoryBlocks(category)
    local blocks_list = CATEGORY_BLOCKS[category] or {}
    local w = State.paletteWidth or 200
    local h = love.graphics.getHeight()
    local topBar = 56
    
    love.graphics.setColor(0.06, 0.06, 0.12)
    love.graphics.rectangle("fill", 0, topBar, w, h - topBar)
    
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Category: " .. category, 8, topBar + 8)
    
    love.graphics.setScissor(0, topBar + 30, w, h - topBar - 30)
    
    local y = topBar + 32 - State.paletteScrollY
    
    for _, b in ipairs(blocks_list) do
        if y + State.blockHeight > topBar + 30 and y < h then
            M.drawBlock(b, 6, y)
        end
        y = y + State.blockHeight + 4
    end
    
    love.graphics.setScissor()
end

function M.drawWorkspace()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local topBar = 106
    local paletteW = State.paletteWidth or 200
    
    love.graphics.setColor(0.03, 0.03, 0.06)
    love.graphics.rectangle("fill", paletteW, topBar, w - paletteW, h - topBar)
    
    love.graphics.setScissor(paletteW, topBar, w - paletteW, h - topBar)
    
    local y = topBar + 6 - State.workspaceScrollY
    for i, b in ipairs(State.workspaceBlocks) do
        local bx = paletteW + 16
        if y + State.blockHeight > topBar and y < h then
            local highlight = (State.editingBlock == b)
            M.drawBlock(b, bx, y, false, highlight)
        end
        y = y + State.blockHeight + State.blockSpacing
        if b.children and #b.children > 0 then
            y = M.drawBlockTree(b.children, paletteW + 16 + 20, y, 0, State.workspaceScrollY)
        end
    end
    
    if State.draggingBlock then
        local mx, my = love.mouse.getPosition()
        M.drawBlock(State.draggingBlock, mx - State.blockWidth/2, my - State.blockHeight/2, true, false)
    end
    
    love.graphics.setScissor()
end

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

function M.updateWorkspace()
    if State.project and State.project.scenes[State.currentSceneIdx] then
        State.workspaceBlocks = State.project.scenes[State.currentSceneIdx].blocks or {}
    else
        State.workspaceBlocks = {}
    end
    M.calculateHeights()
end

function M.saveSceneBlocks()
    if State.project and State.project.scenes[State.currentSceneIdx] then
        State.project.scenes[State.currentSceneIdx].blocks = State.workspaceBlocks
    end
end

function M.calculateHeights()
    local y = 10
    local lastCat = nil
    for _, b in ipairs(State.paletteBlocks) do
        if b.category ~= lastCat then y = y + 22; lastCat = b.category end
        y = y + State.blockHeight + 4
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
    local maxPal = math.max(0, State.paletteContentHeight - love.graphics.getHeight() + 106)
    State.paletteScrollY = math.max(0, math.min(State.paletteScrollY, maxPal))
    local maxWs = math.max(0, State.workspaceContentHeight - love.graphics.getHeight() + 106)
    State.workspaceScrollY = math.max(0, math.min(State.workspaceScrollY, maxWs))
end

function M.paletteClick(x, y)
    local yPal = 106 + 32 - State.paletteScrollY
    local lastCat = nil
    for _, b in ipairs(State.paletteBlocks) do
        if b.category ~= lastCat then yPal = yPal + 22; lastCat = b.category end
        if x >= 6 and x <= 6 + State.blockWidth and y >= yPal and y <= yPal + State.blockHeight then
            State.paletteTapBlock = b
            State.paletteTapTime = love.timer.getTime()
            State.paletteMoved = false
            return
        end
        yPal = yPal + State.blockHeight + 4
    end
end

function M.categoryBlockClick(x, y)
    local category = State.selectedCategory
    local blocks_list = CATEGORY_BLOCKS[category] or {}
    local topBar = 56
    local yPos = topBar + 32 - State.paletteScrollY
    
    for _, b in ipairs(blocks_list) do
        if x >= 6 and x <= 6 + State.blockWidth and y >= yPos and y <= yPos + State.blockHeight then
            local nb = {
                type = b.type,
                name = b.name,
                label = b.label,
                param = b.param,
                category = b.category,
                children = (b.type == "control") and {} or nil,
                elseChildren = (b.name == "ifElse") and {} or nil
            }
            table.insert(State.workspaceBlocks, nb)
            M.saveSceneBlocks()
            M.calculateHeights()
            runtime.compileScript()
            table.insert(State.messages, "Added block: " .. b.label)
            return
        end
        yPos = yPos + State.blockHeight + 4
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
            M.saveSceneBlocks()
            M.calculateHeights()
            runtime.compileScript()
        end
        State.paletteTapBlock = nil
    end
end

function M.workspaceClick(x, y)
    if State.editingBlock or State.inputMode then return end
    
    local idx = nil
    local currentY = State.workspaceStartY - State.workspaceScrollY
    for i, b in ipairs(State.workspaceBlocks) do
        local bx = State.workspaceStartX
        if x >= bx and x <= bx + State.blockWidth and y >= currentY and y <= currentY + State.blockHeight then
            idx = i
            break
        end
        currentY = currentY + State.blockHeight + State.blockSpacing
    end
    if idx then
        State.longPressBlockIdx = idx
        State.longPressStartTime = love.timer.getTime()
        State.longPressMoved = false
    end
end

function M.workspaceRelease()
    if State.longPressBlockIdx then
        local elapsed = love.timer.getTime() - State.longPressStartTime
        if not State.longPressMoved and elapsed < 0.5 then
            local block = State.workspaceBlocks[State.longPressBlockIdx]
            if block and block.param ~= nil then
                State.editingBlock = block
                State.editingText = tostring(block.param or "")
                love.keyboard.setTextInput(true)
                table.insert(State.messages, "Editing parameter... (Enter - confirm, Esc - cancel)")
            else
                table.insert(State.messages, "This block has no editable parameter")
            end
        end
        State.longPressBlockIdx = nil
    end
    
    if State.draggingBlock then
        table.insert(State.workspaceBlocks, State.draggingBlock)
        M.saveSceneBlocks()
        M.calculateHeights()
        runtime.compileScript()
        State.draggingBlock = nil
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
            M.saveSceneBlocks()
            State.longPressBlockIdx = nil
        end
    elseif x <= State.paletteWidth then
        State.paletteScrollY = State.paletteScrollY - dy
    else
        State.workspaceScrollY = State.workspaceScrollY - dy
    end
end

function M.handleWheel(x, y)
    State.paletteTapBlock = nil
    if x <= State.paletteWidth then
        State.paletteScrollY = State.paletteScrollY - y * 30
    else
        State.workspaceScrollY = State.workspaceScrollY - y * 30
    end
end

function M.deleteBlockByIndex(idx)
    if idx and idx >= 1 and idx <= #State.workspaceBlocks then
        table.remove(State.workspaceBlocks, idx)
        M.saveSceneBlocks()
        M.calculateHeights()
        runtime.compileScript()
        State.editingBlock = nil
        State.editingText = ""
        love.keyboard.setTextInput(false)
        return true
    end
    return false
end

return M
