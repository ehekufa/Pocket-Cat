-- Pocket Cat IDE v0.5 – Вертикальные блоки + редактор параметров + скролл
-- События, движение, внешность, звук, управление, переменные, рисование, датчики

-- ========== КАТЕГОРИИ И ЦВЕТА ==========
local catColors = {
    event    = {0.9, 0.6, 0.2},
    motion   = {0.2, 0.6, 0.9},
    looks    = {0.7, 0.3, 0.9},
    sound    = {0.3, 0.9, 0.4},
    control  = {1.0, 0.8, 0.2},
    variables= {0.9, 0.2, 0.2},
    draw     = {0.2, 0.8, 0.8},
    text     = {1.0, 1.0, 1.0},
    sensing  = {0.7, 0.7, 0.7},
}

-- ========== ПАЛИТРА БЛОКОВ ==========
local paletteBlocks = {
    -- События
    {type="event", name="start",      label="при старте",           category="event"},
    {type="event", name="tap",        label="при нажатии",          category="event"},
    {type="event", name="release",    label="при отпускании",       category="event"},
    {type="event", name="touch",      label="при касании",          category="event"},
    {type="event", name="mousemove",  label="при движении мыши",    category="event"},
    {type="event", name="key_a",      label="при нажатии A",        category="event"},
    {type="event", name="key_b",      label="при нажатии B",        category="event"},
    -- Движение
    {type="action", name="changeX",   label="изменить X на",        param=10, category="motion"},
    {type="action", name="changeY",   label="изменить Y на",        param=10, category="motion"},
    {type="action", name="setX",      label="установить X в",       param=200, category="motion"},
    {type="action", name="setY",      label="установить Y в",       param=200, category="motion"},
    {type="action", name="turn",      label="повернуть на",          param=15, category="motion"},
    {type="action", name="setAngle",  label="установить угол",      param=0,  category="motion"},
    {type="action", name="glide",     label="скользить 1 сек в X:", param=300, category="motion"},
    {type="action", name="bounceEdge",label="если край – оттолкнуться", category="motion"},
    -- Внешность
    {type="action", name="showCube",  label="показать куб",          category="looks"},
    {type="action", name="showSphere",label="показать сферу",        category="looks"},
    {type="action", name="hide",      label="скрыть объект",         category="looks"},
    {type="action", name="show",      label="показать объект",       category="looks"},
    {type="action", name="setColor",  label="установить цвет",      param="green", category="looks"},
    {type="action", name="setAlpha",  label="прозрачность",          param=0.5, category="looks"},
    {type="action", name="changeSize",label="изменить размер на",    param=10, category="looks"},
    {type="action", name="setSize",   label="установить размер",     param=50, category="looks"},
    {type="action", name="nextBg",    label="следующий фон",         category="looks"},
    -- Звук
    {type="action", name="playSound", label="играть звук",           param="meow", category="sound"},
    {type="action", name="stopSounds",label="остановить звуки",      category="sound"},
    {type="action", name="changeVol", label="изменить громкость на", param=0.1, category="sound"},
    {type="action", name="setVol",    label="установить громкость",  param=0.5, category="sound"},
    -- Управление
    {type="action", name="wait",      label="ждать",                 param=1, category="control"},
    {type="action", name="repeat",    label="повторить 3 раза",      param=3, category="control"},
    {type="action", name="ifTap",     label="если нажато",           category="control"},
    {type="action", name="stopAll",   label="остановить всё",        category="control"},
    -- Переменные
    {type="action", name="setVar",    label="установить [v] в",      param="x=10", category="variables"},
    {type="action", name="changeVar", label="изменить [v] на",       param="x=5", category="variables"},
    {type="action", name="showVar",   label="показать переменную",   param="x", category="variables"},
    {type="action", name="hideVar",   label="скрыть переменную",     param="x", category="variables"},
    -- Рисование
    {type="action", name="line",      label="линия (0,0)→(100,100)", category="draw"},
    {type="action", name="rect",      label="прямоугольник",         category="draw"},
    {type="action", name="ellipse",   label="эллипс",               category="draw"},
    {type="action", name="clear",     label="очистить экран",        category="draw"},
    {type="action", name="setPenColor",label="цвет пера",            param="red", category="draw"},
    -- Текст
    {type="action", name="printText", label="вывести текст",         param="Привет!", category="text"},
    {type="action", name="setFont",   label="установить шрифт",      param="default", category="text"},
    {type="action", name="setFontSize",label="размер шрифта",        param=16, category="text"},
    -- Датчики
    {type="action", name="mouseX",    label="мышь X",               category="sensing"},
    {type="action", name="mouseY",    label="мышь Y",               category="sensing"},
    {type="action", name="mouseDown", label="нажата мышь?",          category="sensing"},
    {type="action", name="touchX",    label="касание X",             category="sensing"},
    {type="action", name="touchY",    label="касание Y",             category="sensing"},
    {type="action", name="accelX",    label="акселерометр X",        category="sensing"},
}

-- ========== РАБОЧЕЕ ПРОСТРАНСТВО ==========
local workspaceBlocks = {}
local draggingBlock = nil
local dragFromPalette = false
local blockWidth, blockHeight = 175, 34
local paletteWidth = 200
local paletteScrollY = 0
local paletteContentHeight = 0
local workspaceStartX = paletteWidth + 10   -- стартовый X для блоков
local workspaceStartY = 60                  -- стартовый Y для первого блока
local blockSpacing = 8                      -- отступ между блоками по вертикали

-- ========== РЕДАКТИРОВАНИЕ ПАРАМЕТРА ==========
local editingBlockIdx = nil     -- индекс блока в workspaceBlocks
local editingText = ""          -- текст в поле ввода
local editFieldW = 120
local editFieldH = 30

-- ========== КУБ И СФЕРА ==========
local cubeVertices = {
    {-1,-1,-1}, { 1,-1,-1}, { 1, 1,-1}, {-1, 1,-1},
    {-1,-1, 1}, { 1,-1, 1}, { 1, 1, 1}, {-1, 1, 1}
}
local cubeEdges = {
    {1,2},{2,3},{3,4},{4,1},
    {5,6},{6,7},{7,8},{8,5},
    {1,5},{2,6},{3,7},{4,8}
}
function drawSphere(x, y, r)
    love.graphics.circle("line", x, y, r, 24)
end

-- ========== СОСТОЯНИЕ СЦЕНЫ ==========
local showCube, showSphere = false, false
local cubeX, cubeY = 200, 300
local sphereX, sphereY = 400, 300
local objectAngle = 0
local objectColor = {0.2, 0.8, 0.4}
local objectAlpha = 1
local objectSize = 50
local isTapped = false
local isReleased = false
local touchActive = false
local mouseMoved = false
local keyAPressed = false
local keyBPressed = false
local penColor = {1,0,0}
local drawCommands = {}
local messages = {}
local vars = {}
local font = love.graphics.getFont()
local fontSize = 16
local waitTimer = 0
local stopAll = false

-- ========== YAML ==========
function loadYAML(path)
    local info = love.filesystem.getInfo(path)
    if not info then return nil end
    local contents = love.filesystem.read(path)
    local blocks = {}
    for line in contents:gmatch("[^\r\n]+") do
        local typ = line:match("type:%s*(%w+)")
        local name = line:match("name:%s*(%w+)")
        if typ and name then
            local param = line:match("param:%s*(.+)")
            if param then
                param = param:gsub("^%s*(.-)%s*$", "")
                if tonumber(param) then param = tonumber(param) end
            end
            local cat = line:match("category:%s*(%w+)")
            table.insert(blocks, {type=typ, name=name, param=param, category=cat})
        end
    end
    return blocks
end

function saveYAML(path, blocks)
    local lines = {"blocks:"}
    for _, b in ipairs(blocks) do
        table.insert(lines, "  - type: " .. b.type)
        table.insert(lines, "    name: " .. b.name)
        if b.param then table.insert(lines, "    param: " .. tostring(b.param)) end
        if b.category then table.insert(lines, "    category: " .. b.category) end
    end
    love.filesystem.write(path, table.concat(lines, "\n"))
end

-- ========== ВЫПОЛНЕНИЕ ==========
local eventHandlers = {}

function compileScript()
    eventHandlers = {}
    local currentEvent = nil
    for _, block in ipairs(workspaceBlocks) do
        if block.type == "event" then
            currentEvent = block.name
            eventHandlers[currentEvent] = eventHandlers[currentEvent] or {}
        elseif block.type == "action" and currentEvent then
            table.insert(eventHandlers[currentEvent], block)
        end
    end
end

function executeActions(actions)
    if not actions then return false end
    local i = 1
    while i <= #actions and not stopAll do
        local act = actions[i]
        local p = act.param
        if act.name == "changeX" then cubeX = cubeX + (tonumber(p) or 10)
        elseif act.name == "changeY" then cubeY = cubeY + (tonumber(p) or 10)
        elseif act.name == "setX" then cubeX = tonumber(p) or 200
        elseif act.name == "setY" then cubeY = tonumber(p) or 200
        elseif act.name == "turn" then objectAngle = objectAngle + (tonumber(p) or 15)
        elseif act.name == "setAngle" then objectAngle = tonumber(p) or 0
        elseif act.name == "glide" then cubeX = tonumber(p) or 300
        elseif act.name == "bounceEdge" then
            if cubeX < 0 or cubeX > love.graphics.getWidth() then cubeX = math.max(0, math.min(cubeX, love.graphics.getWidth())) end
            if cubeY < 0 or cubeY > love.graphics.getHeight() then cubeY = math.max(0, math.min(cubeY, love.graphics.getHeight())) end
        elseif act.name == "showCube" then showCube = true
        elseif act.name == "showSphere" then showSphere = true
        elseif act.name == "hide" then showCube, showSphere = false, false
        elseif act.name == "show" then showCube, showSphere = true, true
        elseif act.name == "setColor" then
            if p == "green" then objectColor = {0.2,0.8,0.4}
            elseif p == "red" then objectColor = {0.9,0.2,0.2}
            elseif p == "blue" then objectColor = {0.2,0.4,1.0}
            end
        elseif act.name == "setAlpha" then objectAlpha = math.max(0, math.min(1, tonumber(p) or 1))
        elseif act.name == "changeSize" then objectSize = objectSize + (tonumber(p) or 10)
        elseif act.name == "setSize" then objectSize = tonumber(p) or 50
        elseif act.name == "playSound" then -- love.audio.newSource(p..".ogg") (заглушка)
        elseif act.name == "stopSounds" then love.audio.stop()
        elseif act.name == "changeVol" then
        elseif act.name == "setVol" then
        elseif act.name == "wait" then waitTimer = tonumber(p) or 1; return true
        elseif act.name == "repeat" then
            local times = tonumber(p) or 3
            for _=1, times do
            end
        elseif act.name == "ifTap" then
            if not isTapped then return true end
        elseif act.name == "stopAll" then stopAll = true; return true
        elseif act.name == "setVar" then
            local name, val = p:match("([%w]+)%s*=%s*(.+)")
            if name then vars[name] = tonumber(val) or val end
        elseif act.name == "changeVar" then
            local name, val = p:match("([%w]+)%s*=%s*(.+)")
            if name then vars[name] = (vars[name] or 0) + (tonumber(val) or 0) end
        elseif act.name == "showVar" then
            local name = p or "x"
            table.insert(messages, name .. " = " .. tostring(vars[name] or 0))
        elseif act.name == "line" then table.insert(drawCommands, {"line", 0,0,100,100})
        elseif act.name == "rect" then table.insert(drawCommands, {"rect", 50,50,60,40})
        elseif act.name == "ellipse" then table.insert(drawCommands, {"ellipse", 100,100,30,20})
        elseif act.name == "clear" then drawCommands = {}
        elseif act.name == "setPenColor" then
            if p == "red" then penColor = {1,0,0}
            elseif p == "green" then penColor = {0,1,0}
            elseif p == "blue" then penColor = {0,0,1}
            end
        elseif act.name == "printText" then table.insert(messages, tostring(p or "Привет!"))
        elseif act.name == "setFont" then font = love.graphics.newFont(p or 16)
        elseif act.name == "setFontSize" then fontSize = tonumber(p) or 16; font = love.graphics.newFont(fontSize)
        elseif act.name == "mouseX" then table.insert(messages, "mouse X: "..love.mouse.getX())
        elseif act.name == "mouseY" then table.insert(messages, "mouse Y: "..love.mouse.getY())
        elseif act.name == "mouseDown" then table.insert(messages, "mouse down: "..tostring(love.mouse.isDown(1)))
        elseif act.name == "touchX" then table.insert(messages, "touch X: "..(love.touch.getTouches()[1] and love.touch.getPosition(1)))
        elseif act.name == "touchY" then
        elseif act.name == "accelX" then
            table.insert(messages, "accel X (orientation: "..(love.system.getOrientation() or "unknown")..")")
        end
        i = i + 1
    end
    return false
end

function runProject()
    stopAll = false
    drawCommands = {}
    messages = {}
    vars = {}
    waitTimer = 0
    compileScript()
    if eventHandlers["start"] then
        executeActions(eventHandlers["start"])
    end
end

-- ========== РАСЧЁТ ВЫСОТЫ ПАЛИТРЫ ==========
function calculatePaletteContentHeight()
    local y = 10
    local lastCat = nil
    for _, b in ipairs(paletteBlocks) do
        if b.category ~= lastCat then
            y = y + 20
            lastCat = b.category
        end
        y = y + blockHeight + 6
    end
    return y
end

-- ========== ОТРИСОВКА БЛОКОВ ==========
function drawBlock(block, x, y, isDragging, highlight)
    local color = catColors[block.category] or {0.4,0.4,0.8}
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, blockWidth, blockHeight, 6)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", x, y, blockWidth, blockHeight, 6)
    if highlight then
        love.graphics.setColor(1,1,0)
        love.graphics.rectangle("line", x, y, blockWidth, blockHeight, 6)
    end
    love.graphics.setColor(1,1,1)
    love.graphics.print(block.label or block.name, x+8, y+8)
    if isDragging then
        love.graphics.setColor(1,1,1,0.6)
        love.graphics.rectangle("line", x, y, blockWidth, blockHeight, 6)
    end
    love.graphics.setColor(1,1,1)
end

function love.load()
    local loaded = loadYAML("project.yml")
    if loaded then workspaceBlocks = loaded
    else
        workspaceBlocks = {
            {type="event", name="start", label="при старте", category="event"},
            {type="action", name="showCube", label="показать куб", category="looks"},
            {type="action", name="printText", label="вывести текст", param="Привет, Pocket Cat!", category="text"}
        }
    end
    paletteContentHeight = calculatePaletteContentHeight()
end

function love.draw()
    -- Палитра со скроллом
    love.graphics.setScissor(0, 0, paletteWidth, love.graphics.getHeight())
    love.graphics.setColor(0.15,0.15,0.15)
    love.graphics.rectangle("fill", 0, 0, paletteWidth, love.graphics.getHeight())

    local y = 10 - paletteScrollY
    local lastCat = nil
    for _, b in ipairs(paletteBlocks) do
        if b.category ~= lastCat then
            love.graphics.setColor(1,1,1)
            love.graphics.print(b.category, 5, y)
            y = y + 20
            lastCat = b.category
        end
        if y + blockHeight > 0 and y < love.graphics.getHeight() then
            drawBlock(b, 5, y, false, false)
        end
        y = y + blockHeight + 6
    end
    love.graphics.setScissor()

    -- Рабочая область
    love.graphics.setColor(0.1,0.1,0.1)
    love.graphics.rectangle("fill", paletteWidth, 0, love.graphics.getWidth()-paletteWidth, love.graphics.getHeight())
    love.graphics.setColor(1,1,1)
    love.graphics.print("Рабочая область (перетащи сюда)", workspaceStartX, 10)

    -- Отрисовка блоков вертикально
    for i, b in ipairs(workspaceBlocks) do
        local bx = workspaceStartX
        local by = workspaceStartY + (i-1)*(blockHeight + blockSpacing)
        local highlight = (editingBlockIdx == i)
        if not (draggingBlock == b and not dragFromPalette) then
            drawBlock(b, bx, by, false, highlight)
        end
    end

    if draggingBlock then
        local mx, my = love.mouse.getPosition()
        drawBlock(draggingBlock, mx-blockWidth/2, my-blockHeight/2, true, false)
    end

    -- Кнопка запуска
    love.graphics.setColor(0,1,0)
    love.graphics.circle("fill", 30, love.graphics.getHeight()-40, 22)
    love.graphics.setColor(1,1,1)
    love.graphics.print("▶", 18, love.graphics.getHeight()-50, 0, 1.6)
    love.graphics.setColor(0.5,0.5,0.5)
    love.graphics.rectangle("fill", 5, love.graphics.getHeight()-80, 70, 25)
    love.graphics.print("Сохранить", 8, love.graphics.getHeight()-78)
    love.graphics.rectangle("fill", 80, love.graphics.getHeight()-80, 70, 25)
    love.graphics.print("Загрузить", 83, love.graphics.getHeight()-78)

    -- Сцена (куб, сфера)
    love.graphics.push()
    love.graphics.translate(cubeX, cubeY)
    love.graphics.rotate(math.rad(objectAngle))
    local s = objectSize/30
    love.graphics.scale(s, s)
    if showCube then
        love.graphics.setColor(objectColor)
        love.graphics.setLineWidth(2)
        for _, edge in ipairs(cubeEdges) do
            local p1 = cubeVertices[edge[1]]
            local p2 = cubeVertices[edge[2]]
            love.graphics.line(p1[1]*10, p1[2]*10, p2[1]*10, p2[2]*10)
        end
    end
    love.graphics.pop()

    if showSphere then
        love.graphics.setColor(objectColor)
        love.graphics.setLineWidth(2)
        drawSphere(sphereX, sphereY, objectSize)
    end

    -- Примитивы из буфера
    for _, cmd in ipairs(drawCommands) do
        love.graphics.setLineWidth(2)
        if cmd[1] == "line" then
            love.graphics.setColor(penColor)
            love.graphics.line(cmd[2], cmd[3], cmd[4], cmd[5])
        elseif cmd[1] == "rect" then
            love.graphics.setColor(penColor)
            love.graphics.rectangle("line", cmd[2], cmd[3], cmd[4], cmd[5])
        elseif cmd[1] == "ellipse" then
            love.graphics.setColor(penColor)
            love.graphics.ellipse("line", cmd[2], cmd[3], cmd[4], cmd[5])
        end
    end

    -- Текстовые сообщения
    love.graphics.setFont(font)
    local msgY = workspaceStartY + #workspaceBlocks*(blockHeight+blockSpacing) + 20
    for _, msg in ipairs(messages) do
        love.graphics.setColor(1,1,1)
        love.graphics.print(msg, workspaceStartX, msgY)
        msgY = msgY + fontSize + 4
    end
    love.graphics.setFont(love.graphics.getFont())

    -- Редактор параметра (если открыт)
    if editingBlockIdx then
        local block = workspaceBlocks[editingBlockIdx]
        local bx = workspaceStartX
        local by = workspaceStartY + (editingBlockIdx-1)*(blockHeight + blockSpacing)
        -- Поле ввода под блоком
        love.graphics.setColor(0.2,0.2,0.2)
        love.graphics.rectangle("fill", bx, by + blockHeight + 5, editFieldW, editFieldH)
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("line", bx, by + blockHeight + 5, editFieldW, editFieldH)
        love.graphics.print(editingText, bx+5, by + blockHeight + 10)
        love.graphics.print("Enter - сохранить", bx, by + blockHeight + editFieldH + 10)
    end
end

function love.update(dt)
    local maxScroll = math.max(0, paletteContentHeight - love.graphics.getHeight())
    paletteScrollY = math.max(0, math.min(paletteScrollY, maxScroll))

    if not stopAll then
        if eventHandlers["tap"] and isTapped then
            executeActions(eventHandlers["tap"])
            isTapped = false
        end
        if eventHandlers["release"] and isReleased then
            executeActions(eventHandlers["release"])
            isReleased = false
        end
        if eventHandlers["touch"] and touchActive then
            executeActions(eventHandlers["touch"])
        end
        if eventHandlers["mousemove"] and mouseMoved then
            executeActions(eventHandlers["mousemove"])
            mouseMoved = false
        end
        if eventHandlers["key_a"] and keyAPressed then
            executeActions(eventHandlers["key_a"])
            keyAPressed = false
        end
        if eventHandlers["key_b"] and keyBPressed then
            executeActions(eventHandlers["key_b"])
            keyBPressed = false
        end
    end

    if waitTimer > 0 then
        waitTimer = waitTimer - dt
        if waitTimer <= 0 then waitTimer = 0 end
    end
end

function love.wheelmoved(x, y)
    local mx, my = love.mouse.getPosition()
    if mx <= paletteWidth then
        paletteScrollY = paletteScrollY - y * 30
    end
end

-- Обработка ввода текста для редактирования параметра
function love.textinput(t)
    if editingBlockIdx then
        editingText = editingText .. t
    end
end

function love.keypressed(key)
    if editingBlockIdx then
        if key == "return" or key == "kpenter" then
            local block = workspaceBlocks[editingBlockIdx]
            local val = editingText
            if tonumber(val) then
                block.param = tonumber(val)
            else
                block.param = val
            end
            editingBlockIdx = nil
            editingText = ""
        elseif key == "escape" then
            editingBlockIdx = nil
            editingText = ""
        elseif key == "backspace" then
            editingText = editingText:sub(1, -2)
        end
    else
        if key == "a" then keyAPressed = true
        elseif key == "b" then keyBPressed = true
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Если редактор открыт, клик вне поля закрывает его (кроме самого поля)
        if editingBlockIdx then
            local bx = workspaceStartX
            local by = workspaceStartY + (editingBlockIdx-1)*(blockHeight + blockSpacing)
            local inEditor = (x >= bx and x <= bx + editFieldW and
                              y >= by + blockHeight + 5 and y <= by + blockHeight + 5 + editFieldH)
            if not inEditor then
                editingBlockIdx = nil
                editingText = ""
            end
            return
        end

        -- Кнопка запуска
        if math.sqrt((x-30)^2 + (y-(love.graphics.getHeight()-40))^2) <= 22 then
            runProject()
            return
        end
        -- Сохранить / Загрузить
        if x>=5 and x<=75 and y>=love.graphics.getHeight()-80 and y<=love.graphics.getHeight()-55 then
            saveYAML("project.yml", workspaceBlocks)
            return
        end
        if x>=80 and x<=150 and y>=love.graphics.getHeight()-80 and y<=love.graphics.getHeight()-55 then
            local loaded = loadYAML("project.yml")
            if loaded then workspaceBlocks = loaded end
            return
        end

        -- Палитра (с учётом скролла)
        local py = 10 - paletteScrollY
        local lastCat = nil
        for _, b in ipairs(paletteBlocks) do
            if b.category ~= lastCat then
                py = py + 20
                lastCat = b.category
            end
            local bx, by = 5, py
            if x>=bx and x<=bx+blockWidth and y>=by and y<=by+blockHeight then
                draggingBlock = {type=b.type, name=b.name, label=b.label, param=b.param, category=b.category}
                dragFromPalette = true
                return
            end
            py = py + blockHeight + 6
        end

        -- Рабочая область: ищем блок под курсором (вертикально)
        for i, b in ipairs(workspaceBlocks) do
            local bx = workspaceStartX
            local by = workspaceStartY + (i-1)*(blockHeight + blockSpacing)
            if x>=bx and x<=bx+blockWidth and y>=by and y<=by+blockHeight then
                draggingBlock = b
                dragFromPalette = false
                table.remove(workspaceBlocks, i)
                return
            end
        end

        -- Клик по пустому месту рабочей области
        if x >= paletteWidth then
            isTapped = true
            touchActive = true
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        if draggingBlock then
            if x >= paletteWidth then
                -- Вставляем блок в конец списка
                table.insert(workspaceBlocks, draggingBlock)
                local idx = #workspaceBlocks
                -- Проверяем, был ли это клик (почти без перемещения)
                if not dragFromPalette then
                    local startX = workspaceStartX
                    local startY = workspaceStartY + (idx-1)*(blockHeight + blockSpacing)
                    local dx = x - (startX + blockWidth/2)
                    local dy = y - (startY + blockHeight/2)
                    if math.abs(dx) < 15 and math.abs(dy) < 15 then
                        -- Открываем редактор параметра для этого блока
                        editingBlockIdx = idx
                        editingText = tostring(draggingBlock.param or "")
                    end
                end
            end
            draggingBlock = nil
            dragFromPalette = false
        end
        isReleased = true
        touchActive = false
    end
end

function love.touchpressed(id, x, y) love.mousepressed(x, y, 1) end
function love.touchreleased(id, x, y) love.mousereleased(x, y, 1) end
function love.mousemoved(x, y) mouseMoved = true end
