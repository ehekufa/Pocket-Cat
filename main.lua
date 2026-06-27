-- Pocket Cat 2.3 – Полный рабочий код (без эмодзи)

function safeUTF8(str)
    if type(str) ~= "string" then return tostring(str) end
    local res = {}
    local i = 1
    while i <= #str do
        local c = str:byte(i)
        local len
        if c < 0x80 then len = 1
        elseif c >= 0xC2 and c < 0xE0 then len = 2
        elseif c >= 0xE0 and c < 0xF0 then len = 3
        elseif c >= 0xF0 and c < 0xF5 then len = 4
        else
            table.insert(res, "?")
            i = i + 1
            goto continue
        end
        if i + len - 1 > #str then
            table.insert(res, "?")
            break
        end
        local valid = true
        for j = 2, len do
            local cb = str:byte(i + j - 1)
            if not (cb >= 0x80 and cb < 0xC0) then valid = false; break end
        end
        if valid then
            table.insert(res, str:sub(i, i + len - 1))
            i = i + len
        else
            table.insert(res, "?")
            i = i + 1
        end
        ::continue::
    end
    return table.concat(res)
end

-- ======================== ГЛОБАЛЬНОЕ СОСТОЯНИЕ ========================
State = {
    project = nil,
    currentSceneIdx = 1,
    currentObjectIdx = 1,

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
        pen      = {0.2, 1.0, 0.4},
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
        {type="action", name="penDown",   label="включить перо",       category="pen"},
        {type="action", name="penUp",     label="выключить перо",      category="pen"},
        {type="action", name="penClear",  label="очистить перо",       category="pen"},
        {type="action", name="penColor",  label="цвет пера",           param="green", category="pen"},
        {type="action", name="penSize",   label="размер пера",         param=2, category="pen"},
        {type="action", name="playSound",  label="играть звук",        param="",     category="sound"},
        {type="action", name="wait",   label="ждать",                 param=1, category="control"},
        {type="action", name="repeat", label="повторить 3 раза",      param=3, category="control"},
        {type="action", name="forever",label="вечно",                 category="control"},
        {type="action", name="ifTap",  label="если нажато",           category="control"},
        {type="action", name="stopAll",label="остановить всё",        category="control"},
        {type="action", name="printText",label="вывести текст",       param="Привет!", category="text"},
        {type="action", name="mouseX",    label="мышь X",               category="sensing"},
        {type="action", name="mouseY",    label="мышь Y",               category="sensing"},
        {type="action", name="touchX",    label="касание X",             category="sensing"},
        {type="action", name="touchY",    label="касание Y",             category="sensing"},
    },
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

    draggingBlock = nil,
    dragFromPalette = false,

    longPressBlockIdx = nil,
    longPressStartTime = 0,
    longPressMoved = false,

    editingBlockIdx = nil,
    editingText = "",

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

    paintMode = false,
    paintCanvas = nil,
    paintSize = 32,
    paintScale = 10,
    paintBrushColor = {1,1,1},
    paintCurrentTool = "brush",

    showCube = false,
    showSphere = false,
    cubeX = 200, cubeY = 300,
    sphereX = 400, sphereY = 300,
    objectAngle = 0,
    objectColor = {0.2, 0.8, 0.4},
    objectSize = 50,
    cubeVertices = {{-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},{-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1}},
    cubeEdges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}},

    eventHandlers = {},
    stopAll = false,
    waitTimer = 0,
    isTapped = false,
    isReleased = false,
    touchActive = false,

    penDown = false,
    penColor = {1,0,0},
    penSize = 2,
    penPoints = {},

    drawCommands = {},
    messages = {},
    vars = {},
    font = nil,
    fontSize = 16,

    plugins = {},
    clipboard = nil,

    paletteTapBlock = nil,
    paletteTapTime = 0,
    paletteMoved = false,
}

-- ======================== JSON (встроенный) ========================
json = {}
function json.encode(obj)
    if type(obj) == "table" then
        local t = {}
        for k, v in pairs(obj) do
            table.insert(t, '"' .. tostring(k) .. '":' .. json.encode(v))
        end
        return "{" .. table.concat(t, ",") .. "}"
    elseif type(obj) == "string" then return '"' .. obj .. '"'
    elseif type(obj) == "number" then return tostring(obj)
    elseif type(obj) == "boolean" then return obj and "true" or "false"
    else return "null" end
end
function json.decode(str)
    str = str:gsub("%s", "")
    local pos = 1
    local function parse()
        local c = str:sub(pos, pos)
        if c == '{' then
            pos = pos + 1
            local obj = {}
            while str:sub(pos, pos) ~= '}' do
                local key = parse()
                pos = pos + 1
                local val = parse()
                obj[key] = val
                if str:sub(pos, pos) == ',' then pos = pos + 1 end
            end
            pos = pos + 1
            return obj
        elseif c == '"' then
            local start = pos + 1
            local finish = str:find('"', start)
            local val = str:sub(start, finish-1)
            pos = finish + 1
            return val
        elseif c:match("[%d]") then
            local val = str:match("([%d.]+)", pos)
            pos = pos + #val
            return tonumber(val)
        end
    end
    return parse()
end

-- ======================== ПРОЕКТ ========================
function defaultProject()
    return {
        scenes = {{
            name = "Сцена 1",
            bgColor = {0.2, 0.2, 0.4},
            objects = {{
                name = "Объект 1",
                image = nil,
                blocks = {
                    {type="event", name="start", label="при старте", category="event"},
                    {type="action", name="showCube", label="показать куб", category="looks"},
                }
            }}
        }}
    }
end
function getCurrentScene()
    if not State.project then return nil end
    return State.project.scenes[State.currentSceneIdx]
end
function getCurrentObject()
    local s = getCurrentScene()
    if not s then return nil end
    return s.objects[State.currentObjectIdx]
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

-- ======================== КНОПКИ ========================
function drawButtons()
    local rx = love.graphics.getWidth() - 50
    love.graphics.setColor(0,1,0)
    love.graphics.circle("fill", rx, 15, 22)
    love.graphics.setColor(1,1,1)
    love.graphics.print(">", rx-8, 5, 0, 1.6)  -- стрелка вместо эмодзи

    local btnY = 50
    love.graphics.setColor(0.2, 0.5, 1.0)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 150, btnY, 140, 30)
    love.graphics.print("Сохранить .cat", love.graphics.getWidth() - 145, btnY+8)

    btnY = btnY + 35
    love.graphics.setColor(0.2, 0.5, 1.0)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 150, btnY, 140, 30)
    love.graphics.print("Загрузить .cat", love.graphics.getWidth() - 145, btnY+8)

    btnY = btnY + 35
    love.graphics.setColor(0.7, 0.7, 0.2)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 150, btnY, 68, 25)
    love.graphics.print("Коп.", love.graphics.getWidth() - 145, btnY+5)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 78, btnY, 68, 25)
    love.graphics.print("Вст.", love.graphics.getWidth() - 73, btnY+5)
end

function checkButtonClick(x, y)
    local rx = love.graphics.getWidth() - 50
    if math.sqrt((x-rx)^2 + (y-15)^2) <= 22 then
        runProject()
        return true
    end
    local btnY = 50
    if x >= love.graphics.getWidth() - 150 and x <= love.graphics.getWidth() - 10 and y >= btnY and y <= btnY+30 then
        saveProject("project.cat")
        return true
    end
    btnY = btnY + 35
    if x >= love.graphics.getWidth() - 150 and x <= love.graphics.getWidth() - 10 and y >= btnY and y <= btnY+30 then
        local saved = loadProject("project.cat")
        if saved then
            State.project = saved
            updateWorkspaceBlocks()
        end
        return true
    end
    btnY = btnY + 35
    if x >= love.graphics.getWidth() - 150 and x <= love.graphics.getWidth() - 82 and y >= btnY and y <= btnY+25 then
        copyBlock()
        return true
    end
    if x >= love.graphics.getWidth() - 78 and x <= love.graphics.getWidth() - 10 and y >= btnY and y <= btnY+25 then
        pasteBlock()
        return true
    end
    return false
end

-- ======================== КОПИРОВАНИЕ / ВСТАВКА ========================
function copyBlock()
    if State.editingBlockIdx then
        local block = State.workspaceBlocks[State.editingBlockIdx]
        State.clipboard = {
            type = block.type,
            name = block.name,
            label = block.label,
            param = block.param,
            category = block.category,
        }
        table.insert(State.messages, "Блок скопирован")
    else
        table.insert(State.messages, "Выделите блок")
    end
end

function pasteBlock()
    if State.clipboard then
        table.insert(State.workspaceBlocks, State.clipboard)
        calculateHeights()
        table.insert(State.messages, "Блок вставлен")
    else
        table.insert(State.messages, "Буфер пуст")
    end
end

-- ======================== ВЫПОЛНЕНИЕ ========================
function compileScript()
    State.eventHandlers = {}
    local ce = nil
    for _, b in ipairs(State.workspaceBlocks) do
        if b.type == "event" then
            ce = b.name
            State.eventHandlers[ce] = State.eventHandlers[ce] or {}
        elseif b.type == "action" and ce then
            table.insert(State.eventHandlers[ce], b)
        end
    end
end

function executeActions(actions)
    if not actions then return false end
    local i = 1
    while i <= #actions and not State.stopAll do
        local a = actions[i]
        local p = a.param
        if a.name == "changeX" then State.cubeX = State.cubeX + (tonumber(p) or 10)
        elseif a.name == "changeY" then State.cubeY = State.cubeY + (tonumber(p) or 10)
        elseif a.name == "setX" then State.cubeX = tonumber(p) or 200
        elseif a.name == "setY" then State.cubeY = tonumber(p) or 200
        elseif a.name == "turn" then State.objectAngle = State.objectAngle + (tonumber(p) or 15)
        elseif a.name == "showCube" then State.showCube = true
        elseif a.name == "showSphere" then State.showSphere = true
        elseif a.name == "hide" then State.showCube, State.showSphere = false, false
        elseif a.name == "show" then State.showCube, State.showSphere = true, true
        elseif a.name == "setColor" then
            if p == "green" then State.objectColor = {0.2,0.8,0.4}
            elseif p == "red" then State.objectColor = {0.9,0.2,0.2}
            elseif p == "blue" then State.objectColor = {0.2,0.4,1.0}
            end
        elseif a.name == "setSize" then State.objectSize = tonumber(p) or 50
        elseif a.name == "penDown" then State.penDown = true
        elseif a.name == "penUp" then State.penDown = false
        elseif a.name == "penClear" then State.penPoints = {}
        elseif a.name == "penColor" then
            if p == "green" then State.penColor = {0.2,0.8,0.4}
            elseif p == "red" then State.penColor = {0.9,0.2,0.2}
            elseif p == "blue" then State.penColor = {0.2,0.4,1.0}
            end
        elseif a.name == "penSize" then State.penSize = tonumber(p) or 2
        elseif a.name == "playSound" then
            -- ищем файл в папке sounds/
            local filename = "sounds/" .. p
            if love.filesystem.getInfo(filename) then
                local source = love.audio.newSource(filename, "static")
                if source then source:play() end
            end
        elseif a.name == "wait" then State.waitTimer = tonumber(p) or 1; return true
        elseif a.name == "repeat" then
            -- упрощённая реализация
        elseif a.name == "forever" then
            if not State.stopAll then i = i - 1 end
        elseif a.name == "ifTap" then if not State.isTapped then return true end
        elseif a.name == "stopAll" then State.stopAll = true; return true
        elseif a.name == "printText" then table.insert(State.messages, tostring(p or "Привет!"))
        elseif a.name == "mouseX" then table.insert(State.messages, "mouse X: "..love.mouse.getX())
        elseif a.name == "mouseY" then table.insert(State.messages, "mouse Y: "..love.mouse.getY())
        elseif a.name == "touchX" then
            local touches = love.touch.getTouches()
            if touches[1] then
                local tx, _ = love.touch.getPosition(touches[1])
                table.insert(State.messages, "touch X: "..tx)
            else
                table.insert(State.messages, "no touch")
            end
        elseif a.name == "touchY" then
            local touches = love.touch.getTouches()
            if touches[1] then
                local _, ty = love.touch.getPosition(touches[1])
                table.insert(State.messages, "touch Y: "..ty)
            else
                table.insert(State.messages, "no touch")
            end
        end
        if State.penDown and (a.name == "changeX" or a.name == "changeY" or a.name == "setX" or a.name == "setY" or a.name == "turn") then
            table.insert(State.penPoints, {State.cubeX, State.cubeY, State.penColor[1], State.penColor[2], State.penColor[3], State.penSize})
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
    State.penDown = false
    State.penPoints = {}
    compileScript()
    if State.eventHandlers["start"] then
        executeActions(State.eventHandlers["start"])
    end
end

-- ======================== КЛАВИАТУРА ========================
function updateKeyboardPos()
    local keys = (State.keyboardMode == "digits" and State.digitsKeys or
                  St
