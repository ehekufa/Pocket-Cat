-- Pocket Cat 2.0 – всё в одном main.lua
-- Сцены, объекты, Paint, кастомная клавиатура, сохранение/загрузка, выполнение

-- ======================== ГЛОБАЛЬНОЕ СОСТОЯНИЕ ========================
State = {
    -- проект
    project = nil,
    currentSceneIdx = 1,
    currentObjectIdx = 1,

    -- блоки
    catColors = {
        event    = {0.9, 0.6, 0.2},
        motion   = {0.2, 0.6, 0.9},
        looks    = {0.7, 0.3, 0.9},
        sound    = {0.3, 0.9, 0.4},
        control  = {1.0, 0.8, 0.2},
        variables= {0.9, 0.2, 0.2},
        draw     = {0.2, 0.8, 0.8},
        text     = {1.0, 1.0, 1.0},
        sensing  = {0.7, 0.7, 0.7},
    },
    paletteBlocks = {
        {type="event", name="start",   label="при старте",           category="event"},
        {type="event", name="tap",     label="при нажатии",          category="event"},
        {type="event", name="release", label="при отпускании",       category="event"},
        {type="event", name="touch",   label="при касании",          category="event"},
        {type="action", name="changeX",label="изменить X на",        param=10, category="motion"},
        {type="action", name="changeY",label="изменить Y на",        param=10, category="motion"},
        {type="action", name="setX",   label="установить X в",       param=200, category="motion"},
        {type="action", name="setY",   label="установить Y в",       param=200, category="motion"},
        {type="action", name="turn",   label="повернуть на",         param=15, category="motion"},
        {type="action", name="showCube",   label="показать куб",      category="looks"},
        {type="action", name="showSphere", label="показать сферу",    category="looks"},
        {type="action", name="hide",   label="скрыть объект",         category="looks"},
        {type="action", name="show",   label="показать объект",       category="looks"},
        {type="action", name="setColor",   label="установить цвет",  param="green", category="looks"},
        {type="action", name="setSize",    label="установить размер", param=50, category="looks"},
        {type="action", name="wait",   label="ждать",                 param=1, category="control"},
        {type="action", name="repeat", label="повторить 3 раза",      param=3, category="control"},
        {type="action", name="ifTap",  label="если нажато",           category="control"},
        {type="action", name="stopAll",label="остановить всё",        category="control"},
        {type="action", name="printText",label="вывести текст",       param="Привет!", category="text"},
    },

    -- рабочее пространство
    workspaceBlocks = {},
    paletteWidth = 200,
    paletteScrollY = 0,
    paletteContentHeight = 0,
    workspaceStartX = 210,
    workspaceStartY = 80,
    blockWidth = 175,
    blockHeight = 34,
    blockSpacing = 8,
    workspaceScrollY = 0,
    workspaceContentHeight = 0,

    -- перетаскивание
    draggingBlock = nil,
    dragFromPalette = false,

    -- долгое нажатие
    longPressBlockIdx = nil,
    longPressStartTime = 0,
    longPressMoved = false,

    -- редактирование
    editingBlockIdx = nil,
    editingText = "",

    -- кастомная клавиатура
    keyboardMode = "digits",
    keyboardVisible = false,
    keyboardHeight = 220,
    keyboardPosX = 0,
    keyboardPosY = 0,
    keyW = 44,
    keyH = 44,
    keySpacing = 4,
    digitsKeys = {{"1","2","3"},{"4","5","6"},{"7","8","9"},{".","0","⌫"}},
    ruKeys = {{"й","ц","у","к","е","н","г","ш","щ","з","х","ъ"},{"ф","ы","в","а","п","р","о","л","д","ж","э"},{"я","ч","с","м","и","т","ь","б","ю","ё"}},
    enKeys = {{"q","w","e","r","t","y","u","i","o","p"},{"a","s","d","f","g","h","j","k","l"},{"z","x","c","v","b","n","m"}},

    -- сцены и объекты (инициализация позже)
    -- paint
    paintMode = false,
    paintCanvas = nil,
    paintSize = 32,
    paintScale = 10,
    paintBrushColor = {1,1,1},
    paintCurrentTool = "brush",

    -- куб/сфера
    showCube = false,
    showSphere = false,
    cubeX = 200, cubeY = 300,
    sphereX = 400, sphereY = 300,
    objectAngle = 0,
    objectColor = {0.2, 0.8, 0.4},
    objectSize = 50,
    cubeVertices = {{-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},{-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1}},
    cubeEdges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}},

    -- выполнение
    eventHandlers = {},
    stopAll = false,
    waitTimer = 0,
    isTapped = false,
    isReleased = false,
    touchActive = false,

    -- рисование и текст
    penColor = {1,0,0},
    drawCommands = {},
    messages = {},
    vars = {},
    font = nil,
    fontSize = 16,
}

-- ======================== ПРОЕКТ (сцены/объекты) ========================
function defaultProject()
    return {
        scenes = {
            {
                name = "Сцена 1",
                bgColor = {0.2, 0.2, 0.4},
                objects = {
                    {
                        name = "Объект 1",
                        image = nil,
                        blocks = {
                            {type="event", name="start", label="при старте", category="event"},
                            {type="action", name="showCube", label="показать куб", category="looks"},
                        }
                    }
                }
            }
        }
    }
end

function getCurrentScene()
    if not State.project then return nil end
    return State.project.scenes[State.currentSceneIdx]
end

function getCurrentObject()
    local scene = getCurrentScene()
    if not scene then return nil end
    return scene.objects[State.currentObjectIdx]
end

function updateWorkspaceBlocks()
    local obj = getCurrentObject()
    State.workspaceBlocks = obj and obj.blocks or {}
    calculateHeights()
end

-- ======================== ПАЛИТРА И РАБОЧАЯ ОБЛАСТЬ ========================
function calculateHeights()
    local y = 10
    local lastCat = nil
    for _, b in ipairs(State.paletteBlocks) do
        if b.category ~= lastCat then
            y = y + 20
            lastCat = b.category
        end
        y = y + State.blockHeight + 6
    end
    State.paletteContentHeight = y
    State.workspaceContentHeight = State.workspaceStartY + #State.workspaceBlocks * (State.blockHeight + State.blockSpacing) + 100
end

function drawBlock(block, x, y, isDragging, highlight)
    local color = State.catColors[block.category] or {0.4,0.4,0.8}
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, State.blockWidth, State.blockHeight, 6)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", x, y, State.blockWidth, State.blockHeight, 6)
    if highlight then
        love.graphics.setColor(1,1,0)
        love.graphics.rectangle("line", x, y, State.blockWidth, State.blockHeight, 6)
    end
    love.graphics.setColor(1,1,1)
    love.graphics.print(block.label or block.name, x+8, y+8)
    if isDragging then
        love.graphics.setColor(1,1,1,0.6)
        love.graphics.rectangle("line", x, y, State.blockWidth, State.blockHeight, 6)
    end
    love.graphics.setColor(1,1,1)
end

function drawPalette()
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
            drawBlock(b, 5, y, false, false)
        end
        y = y + State.blockHeight + 6
    end
    love.graphics.setScissor()
end

function drawWorkspace()
    love.graphics.setScissor(State.paletteWidth, 0, love.graphics.getWidth()-State.paletteWidth, love.graphics.getHeight())
    love.graphics.setColor(0.1,0.1,0.1)
    love.graphics.rectangle("fill", State.paletteWidth, 0, love.graphics.getWidth()-State.paletteWidth, love.graphics.getHeight())
    love.graphics.setColor(1,1,1)
    love.graphics.print("Рабочая область", State.workspaceStartX, 10 - State.workspaceScrollY)

    for i, b in ipairs(State.workspaceBlocks) do
        local bx = State.workspaceStartX
        local by = State.workspaceStartY + (i-1)*(State.blockHeight + State.blockSpacing) - State.workspaceScrollY
        local highlight = (State.editingBlockIdx == i)
        if not (State.draggingBlock == b and not State.dragFromPalette) then
            if by + State.blockHeight > 0 and by < love.graphics.getHeight() then
                drawBlock(b, bx, by, false, highlight)
            end
        end
    end

    if State.draggingBlock then
        local mx, my = love.mouse.getPosition()
        drawBlock(State.draggingBlock, mx-State.blockWidth/2, my-State.blockHeight/2, true, false)
    end
    love.graphics.setScissor()
end

-- ======================== КНОПКА ЗАПУСКА ========================
function drawRunButton()
    local rx = love.graphics.getWidth() - 50
    local ry = 15
    love.graphics.setColor(0,1,0)
    love.graphics.circle("fill", rx, ry, 22)
    love.graphics.setColor(1,1,1)
    love.graphics.print("▶", rx-12, ry-10, 0, 1.6)
end

-- ======================== ВЫПОЛНЕНИЕ БЛОКОВ ========================
function compileScript()
    State.eventHandlers = {}
    local currentEvent = nil
    for _, block in ipairs(State.workspaceBlocks) do
        if block.type == "event" then
            currentEvent = block.name
            State.eventHandlers[currentEvent] = State.eventHandlers[currentEvent] or {}
        elseif block.type == "action" and currentEvent then
            table.insert(State.eventHandlers[currentEvent], block)
        end
    end
end

function executeActions(actions)
    if not actions then return false end
    local i = 1
    while i <= #actions and not State.stopAll do
        local act = actions[i]
        local p = act.param
        if act.name == "changeX" then State.cubeX = State.cubeX + (tonumber(p) or 10)
        elseif act.name == "changeY" then State.cubeY = State.cubeY + (tonumber(p) or 10)
        elseif act.name == "setX" then State.cubeX = tonumber(p) or 200
        elseif act.name == "setY" then State.cubeY = tonumber(p) or 200
        elseif act.name == "turn" then State.objectAngle = State.objectAngle + (tonumber(p) or 15)
        elseif act.name == "showCube" then State.showCube = true
        elseif act.name == "showSphere" then State.showSphere = true
        elseif act.name == "hide" then State.showCube, State.showSphere = false, false
        elseif act.name == "show" then State.showCube, State.showSphere = true, true
        elseif act.name == "setColor" then
            if p == "green" then State.objectColor = {0.2,0.8,0.4}
            elseif p == "red" then State.objectColor = {0.9,0.2,0.2}
            elseif p == "blue" then State.objectColor = {0.2,0.4,1.0}
            end
        elseif act.name == "setSize" then State.objectSize = tonumber(p) or 50
        elseif act.name == "wait" then State.waitTimer = tonumber(p) or 1; return true
        elseif act.name == "repeat" then
        elseif act.name == "ifTap" then
            if not State.isTapped then return true end
        elseif act.name == "stopAll" then State.stopAll = true; return true
        elseif act.name == "printText" then table.insert(State.messages, tostring(p or "Привет!"))
        end
        i = i + 1
    end
    return false
end

function runProject()
    State.stopAll = false
    State.drawCommands = {}
    State.messages = {}
    State.vars = {}
    State.waitTimer = 0
    compileScript()
    if State.eventHandlers["start"] then
        executeActions(State.eventHandlers["start"])
    end
end

-- ======================== РЕДАКТОР И КЛАВИАТУРА ========================
function updateKeyboardPosition()
    local keys = (State.keyboardMode == "digits" and State.digitsKeys or
                  State.keyboardMode == "ru" and State.ruKeys or State.enKeys)
    local cols = 0
    for _, row in ipairs(keys) do if #row > cols then cols = #row end end
    local totalW = cols * (State.keyW + State.keySpacing) + State.keySpacing
    State.keyboardPosX = love.graphics.getWidth()/2 - totalW/2
    State.keyboardPosY = love.graphics.getHeight() - State.keyboardHeight
end

function drawKeyboard()
    if not State.keyboardVisible then return end
    updateKeyboardPosition()
    local kx = State.keyboardPosX
    local ky = State.keyboardPosY
    local keys = (State.keyboardMode == "digits" and State.digitsKeys or
                  State.keyboardMode == "ru" and State.ruKeys or State.enKeys)
    local rows = #keys
    local cols = 0
    for _, row in ipairs(keys) do if #row > cols then cols = #row end end
    local kw = cols * (State.keyW + State.keySpacing) + State.keySpacing
    local kh = rows * (State.keyH + State.keySpacing) + State.keySpacing + 45
    love.graphics.setColor(0.1,0.1,0.1,0.95)
    love.graphics.rectangle("fill", kx, ky, kw, kh, 10)

    for i, row in ipairs(keys) do
        for j, char in ipairs(row) do
            local bx = kx + State.keySpacing + (j-1)*(State.keyW + State.keySpacing)
            local by = ky + State.keySpacing + (i-1)*(State.keyH + State.keySpacing)
            love.graphics.setColor(0.3,0.3,0.3)
            love.graphics.rectangle("fill", bx, by, State.keyW, State.keyH, 6)
            love.graphics.setColor(1,1,1)
            love.graphics.rectangle("line", bx, by, State.keyW, State.keyH, 6)
            love.graphics.printf(char, bx, by+State.keyH/2-8, State.keyW, "center")
        end
    end

    local swY = ky + rows*(State.keyH + State.keySpacing) + State.keySpacing + 5
    local swW = 55
    local modes = {{"123","digits"},{"АБВ","ru"},{"ABC","en"}}
    for i, m in ipairs(modes) do
        local bx = kx + State.keySpacing + (i-1)*(swW + State.keySpacing)
        love.graphics.setColor(0.3,0.3,0.3)
        love.graphics.rectangle("fill", bx, swY, swW, 30, 6)
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("line", bx, swY, swW, 30, 6)
        love.graphics.printf(m[1], bx, swY+8, swW, "center")
    end
    local doneX = kx + kw - 70
    love.graphics.setColor(0.2,0.6,0.2)
    love.graphics.rectangle("fill", doneX, swY, 60, 30, 6)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", doneX, swY, 60, 30, 6)
    love.graphics.printf("Готово", doneX, swY+8, 60, "center")
end

function handleKeyboardTouch(x, y)
    if not State.keyboardVisible then return false end
    local kx = State.keyboardPosX
    local ky = State.keyboardPosY
    local keys = (State.keyboardMode == "digits" and State.digitsKeys or
                  State.keyboardMode == "ru" and State.ruKeys or State.enKeys)
    for i, row in ipairs(keys) do
        for j, char in ipairs(row) do
            local bx = kx + State.keySpacing + (j-1)*(State.keyW + State.keySpacing)
            local by = ky + State.keySpacing + (i-1)*(State.keyH + State.keySpacing)
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
    local rows = #keys
    local swY = ky + rows*(State.keyH + State.keySpacing) + State.keySpacing + 5
    local swW = 55
    local modes = {{"123","digits"},{"АБВ","ru"},{"ABC","en"}}
    for i, m in ipairs(modes) do
        local bx = kx + State.keySpacing + (i-1)*(swW + State.keySpacing)
        if x >= bx and x <= bx+swW and y >= swY and y <= swY+30 then
            State.keyboardMode = m[2]
            return true
        end
    end
    local cols = 0
    for _, row in ipairs(keys) do if #row > cols then cols = #row end end
    local totalW = cols * (State.keyW + State.keySpacing) + State.keySpacing
    local doneX = kx + totalW - 70
    if x >= doneX and x <= doneX+60 and y >= swY and y <= swY+30 then
        if State.editingBlockIdx then
            local block = State.workspaceBlocks[State.editingBlockIdx]
            local val = State.editingText
            if tonumber(val) then block.param = tonumber(val) else block.param = val end
        end
        State.editingBlockIdx = nil
        State.editingText = ""
        State.keyboardVisible = false
        return true
    end
    if y < State.keyboardPosY then
        State.editingBlockIdx = nil
        State.editingText = ""
        State.keyboardVisible = false
        return true
    end
    return false
end

-- ======================== СЦЕНЫ И ОБЪЕКТЫ (вкладки) ========================
function drawTabs()
    love.graphics.setColor(0.1,0.1,0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 70)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Сцены:", 5, 5)
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
    love.graphics.print("Объекты:", 5, 35)
    local ox = 70
    local scene = getCurrentScene()
    if scene then
        for i, obj in ipairs(scene.objects) do
            local w = love.graphics.getFont():getWidth(obj.name) + 15
            love.graphics.setColor(State.currentObjectIdx == i and {0.9,0.9,0.2} or {0.3,0.3,0.3})
            love.graphics.rectangle("fill", ox, 35, w, 25)
            love.graphics.setColor(1,1,1)
            love.graphics.print(obj.name, ox+5, 40)
            ox = ox + w + 5
        end
        love.graphics.setColor(0.3,0.7,0.3)
        love.graphics.rectangle("fill", ox, 35, 25, 25)
        love.graphics.print("+", ox+5, 38)
    end
end

function handleTabsClick(x, y)
    if y >= 5 and y <= 30 then
        local sx = 70
        for i, sc in ipairs(State.project.scenes) do
            local w = love.graphics.getFont():getWidth(sc.name) + 15
            if x >= sx and x <= sx+w then
                State.currentSceneIdx = i
                State.currentObjectIdx = 1
                updateWorkspaceBlocks()
                return true
            end
            sx = sx + w + 5
        end
        if x >= sx and x <= sx+25 then
            addScene()
            return true
        end
    elseif y >= 35 and y <= 60 then
        local ox = 70
        local scene = getCurrentScene()
        if scene then
            for i, obj in ipairs(scene.objects) do
                local w = love.graphics.getFont():getWidth(obj.name) + 15
                if x >= ox and x <= ox+w then
                    State.currentObjectIdx = i
                    updateWorkspaceBlocks()
                    return true
                end
                ox = ox + w + 5
            end
            if x >= ox and x <= ox+25 then
                addObject()
                return true
            end
        end
    end
    return false
end

function addScene()
    table.insert(State.project.scenes, {
        name = "Сцена " .. #State.project.scenes+1,
        bgColor = {0.2, 0.2, 0.4},
        objects = {{ name = "Объект 1", image = nil, blocks = {} }}
    })
    State.currentSceneIdx = #State.project.scenes
    State.currentObjectIdx = 1
    updateWorkspaceBlocks()
end

function addObject()
    local scene = getCurrentScene()
    if not scene then return end
    table.insert(scene.objects, {
        name = "Объект " .. #scene.objects+1,
        image = nil,
        blocks = {}
    })
    State.currentObjectIdx = #scene.objects
    updateWorkspaceBlocks()
end

-- ======================== PAINT ========================
function initPaint()
    State.paintCanvas = love.graphics.newCanvas(State.paintSize, State.paintSize)
    love.graphics.setCanvas(State.paintCanvas)
    love.graphics.clear()
    love.graphics.setCanvas()
end

function drawPaint()
    if not State.paintMode then return end
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1,1,1)
    love.graphics.print("Paint (32x32) – рисуй мышью/пальцем", 10, 10)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", 50, 50, State.paintSize*State.paintScale, State.paintSize*State.paintScale)
    love.graphics.draw(State.paintCanvas, 50, 50, 0, State.paintScale, State.paintScale)
    love.graphics.print("Инструмент: " .. (State.paintCurrentTool == "brush" and "Кисть" or "Ластик"), 10, 400)
    love.graphics.print("Цвет:", 10, 430)
    love.graphics.setColor(State.paintBrushColor)
    love.graphics.rectangle("fill", 60, 430, 20, 20)
    love.graphics.setColor(0.3,0.8,0.3)
    love.graphics.rectangle("fill", 120, 400, 100, 30)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Сохранить", 135, 407)
    love.graphics.setColor(0.8,0.3,0.3)
    love.graphics.rectangle("fill", 230, 400, 100, 30)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Закрыть", 245, 407)
end

function handlePaintTouch(x, y, isDown)
    if not State.paintMode then return false end
    -- кнопки
    if y > 390 and y < 430 then
        if x > 120 and x < 220 then
            -- сохранить
            local scene = getCurrentScene()
            local obj = getCurrentObject()
            if scene and obj then
                local imgData = State.paintCanvas:newImageData()
                local filename = "obj_" .. State.currentSceneIdx .. "_" .. State.currentObjectIdx .. ".png"
                imgData:encode("png", filename)
                obj.image = filename
            end
            State.paintMode = false
            return true
        elseif x > 230 and x < 330 then
            State.paintMode = false
            return true
        end
    end
    local cx, cy = 50, 50
    local pw = State.paintSize * State.paintScale
    local ph = pw
    if x >= cx and x <= cx+pw and y >= cy and y <= cy+ph then
        local px = math.floor((x - cx) / State.paintScale) + 1
        local py = math.floor((y - cy) / State.paintScale) + 1
        if px >= 1 and px <= State.paintSize and py >= 1 and py <= State.paintSize then
            if isDown then
                love.graphics.setCanvas(State.paintCanvas)
                if State.paintCurrentTool == "brush" then
                    love.graphics.setColor(State.paintBrushColor)
                else
                    love.graphics.setColor(0,0,0,0)
                end
                love.graphics.rectangle("fill", px-1, py-1, 1, 1)
                love.graphics.setCanvas()
            end
            return true
        end
    end
    return false
end

-- ======================== СОХРАНЕНИЕ / ЗАГРУЗКА ========================
function saveProject(filename)
    local lines = {"scenes:"}
    for si, scene in ipairs(State.project.scenes) do
        table.insert(lines, "  - name: " .. scene.name)
        table.insert(lines, "    bgColor: [" .. table.concat(scene.bgColor, ",") .. "]")
        table.insert(lines, "    objects:")
        for oi, obj in ipairs(scene.objects) do
            table.insert(lines, "      - name: " .. obj.name)
            if obj.image then table.insert(lines, "        image: " .. obj.image) end
            table.insert(lines, "        blocks:")
            for _, block in ipairs(obj.blocks) do
                table.insert(lines, "          - type: " .. block.type)
                table.insert(lines, "            name: " .. block.name)
                if block.param then table.insert(lines, "            param: " .. tostring(block.param)) end
                if block.category then table.insert(lines, "            category: " .. block.category) end
            end
        end
    end
    love.filesystem.write(filename, table.concat(lines, "\n"))
end

function loadProject(filename)
    local info = love.filesystem.getInfo(filename)
    if not info then return nil end
    local contents = love.filesystem.read(filename)
    local project = {scenes = {}}
    local currentScene, currentObject, currentBlock = nil, nil, nil
    for line in contents:gmatch("[^\r\n]+") do
        if line:match("^  %- name: (.+)") then
            local name = line:match("name: (.+)")
            currentScene = {name = name, bgColor = {0.2,0.2,0.4}, objects = {}}
            table.insert(project.scenes, currentScene)
        elseif line:match("^    bgColor: %[(.+)%]") then
            local vals = line:match("bgColor: %[(.+)%]")
            if currentScene then
                local r,g,b = vals:match("([%d.]+),([%d.]+),([%d.]+)")
                currentScene.bgColor = {tonumber(r), tonumber(g), tonumber(b)}
            end
        elseif line:match("^      %- name: (.+)") then
            local name = line:match("name: (.+)")
            currentObject = {name = name, image = nil, blocks = {}}
            table.insert(currentScene.objects, currentObject)
        elseif line:match("^        image: (.+)") then
            if currentObject then currentObject.image = line:match("image: (.+)") end
        elseif line:match("^          %- type: (.+)") then
            local typ = line:match("type: (%w+)")
            currentBlock = {type = typ}
            table.insert(currentObject.blocks, currentBlock)
        elseif line:match("^            name: (.+)") then
            if currentBlock then currentBlock.name = line:match("name: (.+)") end
        elseif line:match("^            param: (.+)") then
            if currentBlock then
                local p = line:match("param: (.+)")
                p = p:gsub("^%s*(.-)%s*$", "")
                if tonumber(p) then p = tonumber(p) end
                currentBlock.param = p
            end
        elseif line:match("^            category: (.+)") then
            if currentBlock then currentBlock.category = line:match("category: (.+)") end
        end
    end
    return project
end

-- ======================== ОТРИСОВКА СЦЕНЫ ========================
function drawSceneObjects()
    if State.showCube then
        love.graphics.push()
        love.graphics.translate(State.cubeX, State.cubeY)
        love.graphics.rotate(math.rad(State.objectAngle))
        local s = State.objectSize/30
        love.graphics.scale(s, s)
        love.graphics.setColor(State.objectColor)
        love.graphics.setLineWidth(2)
        for _, edge in ipairs(State.cubeEdges) do
            local p1 = State.cubeVertices[edge[1]]
            local p2 = State.cubeVertices[edge[2]]
            love.graphics.line(p1[1]*10, p1[2]*10, p2[1]*10, p2[2]*10)
        end
        love.graphics.pop()
    end
    if State.showSphere then
        love.graphics.setColor(State.objectColor)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", State.sphereX, State.sphereY, State.objectSize, 24)
    end
end

-- ======================== ОСНОВНЫЕ КОЛЛБЭКИ ========================
function love.load()
    State.font = love.graphics.getFont()
    local saved = loadProject("project.yml")
    State.project = saved or defaultProject()
    updateWorkspaceBlocks()
    initPaint()
end

function love.draw()
    local bg = getCurrentScene() and getCurrentScene().bgColor or {0.1,0.1,0.1}
    love.graphics.setBackgroundColor(bg)
    drawPalette()
    drawWorkspace()
    drawTabs()
    -- редактор параметра и клавиатура
    if State.editingBlockIdx then
        local block = State.workspaceBlocks[State.editingBlockIdx]
        local bx = State.workspaceStartX
        local by = State.workspaceStartY + (State.editingBlockIdx-1)*(State.blockHeight + State.blockSpacing) - State.workspaceScrollY
        love.graphics.setColor(1,1,1)
        love.graphics.print("Значение: " .. State.editingText, bx, by + State.blockHeight + 5)
        State.keyboardVisible = true
    else
        State.keyboardVisible = false
    end
    drawKeyboard()
    drawPaint()
    drawRunButton()
    drawSceneObjects()
    -- сообщения
    love.graphics.setFont(State.font)
    local msgY = State.workspaceStartY + #State.workspaceBlocks*(State.blockHeight+State.blockSpacing) + 20 - State.workspaceScrollY
    for _, msg in ipairs(State.messages) do
        if msgY > 0 and msgY < love.graphics.getHeight() then
            love.graphics.setColor(1,1,1)
            love.graphics.print(msg, State.workspaceStartX, msgY)
        end
        msgY = msgY + State.fontSize + 4
    end
end

function love.update(dt)
    local maxPal = math.max(0, State.paletteContentHeight - love.graphics.getHeight())
    State.paletteScrollY = math.max(0, math.min(State.paletteScrollY, maxPal))
    local maxWs = math.max(0, State.workspaceContentHeight - love.graphics.getHeight())
    State.workspaceScrollY = math.max(0, math.min(State.workspaceScrollY, maxWs))
    if State.waitTimer > 0 then
        State.waitTimer = State.waitTimer - dt
        if State.waitTimer <= 0 then State.waitTimer = 0 end
    end
    -- долгое нажатие на блок
    if State.longPressBlockIdx and not State.longPressMoved then
        if love.timer.getTime() - State.longPressStartTime > 0.5 then
            table.remove(State.workspaceBlocks, State.longPressBlockIdx)
            if State.editingBlockIdx == State.longPressBlockIdx then
                State.editingBlockIdx = nil
                State.editingText = ""
                State.keyboardVisible = false
            end
            State.longPressBlockIdx = nil
            calculateHeights()
        end
    end
end

function love.mousepressed(x, y, button)
    if State.paintMode then
        if handlePaintTouch(x, y, true) then return end
    end
    if State.keyboardVisible and handleKeyboardTouch(x, y) then return end
    local rx = love.graphics.getWidth() - 50
    if math.sqrt((x-rx)^2 + (y-15)^2) <= 22 then runProject(); return end
    if y <= 60 and handleTabsClick(x, y) then return end
    if x <= State.paletteWidth then
        local yPal = 10 - State.paletteScrollY
        local lastCat = nil
        for _, b in ipairs(State.paletteBlocks) do
            if b.category ~= lastCat then
                yPal = yPal + 20
                lastCat = b.category
            end
            if x >= 5 and x <= 5+State.blockWidth and y >= yPal and y <= yPal+State.blockHeight then
                local nb = {type=b.type, name=b.name, label=b.label, param=b.param, category=b.category}
                table.insert(State.workspaceBlocks, nb)
                calculateHeights()
                return
            end
            yPal = yPal + State.blockHeight + 6
        end
        State.touchActive = true
        return
    end
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
    State.isTapped = true
    State.touchActive = true
end

function love.mousereleased(x, y, button)
    if State.paintMode then return end
    if State.longPressBlockIdx and not State.longPressMoved then
        local elapsed = love.timer.getTime() - State.longPressStartTime
        if elapsed < 0.5 then
            State.editingBlockIdx = State.longPressBlockIdx
            State.editingText = tostring(State.workspaceBlocks[State.longPressBlockIdx].param or "")
            State.keyboardVisible = true
        end
        State.longPressBlockIdx = nil
    end
    State.isReleased = true
    State.touchActive = false
end

function love.touchmoved(id, x, y, dx, dy)
    if State.paintMode then
        handlePaintTouch(x, y, true)
        return
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

function love.touchpressed(id, x, y) love.mousepressed(x, y, 1) end
function love.touchreleased(id, x, y) love.mousereleased(x, y, 1) end
function love.wheelmoved(x, y)
    if x <= State.paletteWidth then
        State.paletteScrollY = State.paletteScrollY - y * 30
    else
        State.workspaceScrollY = State.workspaceScrollY - y * 30
    end
end

function love.textinput(t)
    -- не используется, оставил для совместимости с ПК-клавиатурой (опционально)
end

function love.keypressed(key)
    if key == "f5" then
        runProject()
    elseif key == "f2" then
        saveProject("project.yml")
    end
end
