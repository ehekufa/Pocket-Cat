function safeUTF8(str)
    if type(str) ~= "string" then return tostring(str) end
    local res = {}
    local i = 1
    while i <= #str do
        local c = str:byte(i)
        local len = 1
        if c < 0x80 then len = 1
        elseif c >= 0xC2 and c < 0xE0 then len = 2
        elseif c >= 0xE0 and c < 0xF0 then len = 3
        elseif c >= 0xF0 and c < 0xF5 then len = 4
        else
            table.insert(res, "?")
            i = i + 1
        end
        if len == 1 and c >= 0x80 then
        else
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
        end
    end
    return table.concat(res)
end

function hsvToRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    return r, g, b
end

State = {
    project = nil, currentSceneIdx = 1, currentObjectIdx = 1,
    catColors = {
        event = {0.9,0.6,0.2}, motion = {0.2,0.6,0.9}, looks = {0.7,0.3,0.9},
        sound = {0.3,0.9,0.4}, control = {1.0,0.8,0.2}, variables = {0.9,0.2,0.2},
        draw = {0.2,0.8,0.8}, text = {1.0,1.0,1.0}, sensing = {0.7,0.7,0.7}, pen = {0.2,1.0,0.4}
    },
    paletteBlocks = {
        {type="event", name="start", label="при старте", category="event"},
        {type="event", name="tap", label="при нажатии", category="event"},
        {type="event", name="release", label="при отпускании", category="event"},
        {type="event", name="touch", label="при касании", category="event"},
        {type="action", name="changeX", label="изменить X на", param=10, category="motion"},
        {type="action", name="changeY", label="изменить Y на", param=10, category="motion"},
        {type="action", name="setX", label="установить X в", param=200, category="motion"},
        {type="action", name="setY", label="установить Y в", param=200, category="motion"},
        {type="action", name="turn", label="повернуть на", param=15, category="motion"},
        {type="action", name="showCube", label="показать куб", category="looks"},
        {type="action", name="showSphere", label="показать сферу", category="looks"},
        {type="action", name="showImage", label="показать спрайт", category="looks"},
        {type="action", name="hide", label="скрыть объект", category="looks"},
        {type="action", name="show", label="показать объект", category="looks"},
        {type="action", name="setColor", label="установить цвет", param="green", category="looks"},
        {type="action", name="setSize", label="установить размер", param=50, category="looks"},
        {type="action", name="penDown", label="включить перо", category="pen"},
        {type="action", name="penUp", label="выключить перо", category="pen"},
        {type="action", name="penClear", label="очистить перо", category="pen"},
        {type="action", name="penColor", label="цвет пера", param="green", category="pen"},
        {type="action", name="penSize", label="размер пера", param=2, category="pen"},
        {type="action", name="playSound", label="играть звук", param="", category="sound"},
        {type="action", name="wait", label="ждать", param=1, category="control"},
        {type="action", name="repeat", label="повторить 3 раза", param=3, category="control"},
        {type="action", name="forever", label="вечно", category="control"},
        {type="action", name="ifTap", label="если нажато", category="control"},
        {type="action", name="stopAll", label="остановить всё", category="control"},
        {type="action", name="printText", label="вывести текст", param="Привет!", category="text"},
        {type="action", name="mouseX", label="мышь X", category="sensing"},
        {type="action", name="mouseY", label="мышь Y", category="sensing"},
        {type="action", name="touchX", label="касание X", category="sensing"},
        {type="action", name="touchY", label="касание Y", category="sensing"}
    },
    workspaceBlocks = {}, paletteWidth = 200, paletteScrollY = 0, paletteContentHeight = 0,
    workspaceStartX = 210, workspaceStartY = 80, blockWidth = 175, blockHeight = 34, blockSpacing = 8,
    workspaceScrollY = 0, workspaceContentHeight = 0,
    draggingBlock = nil, dragFromPalette = false,
    longPressBlockIdx = nil, longPressStartTime = 0, longPressMoved = false,
    editingBlockIdx = nil, editingText = "",
    keyboardMode = "digits", keyboardVisible = false, keyboardHeight = 260, keyboardPosX = 0, keyboardPosY = 0,
    keyW = 44, keyH = 44, keySpacing = 4,
    digitsKeys = {{"1","2","3"},{"4","5","6"},{"7","8","9"},{".","0","⌫"}},
    ruKeys = {{"й","ц","у","к","е","н","г","ш","щ","з","х","ъ"},{"ф","ы","в","а","п","р","о","л","д","ж","э"},{"я","ч","с","м","и","т","ь","б","ю","ё"}},
    enKeys = {{"q","w","e","r","t","y","u","i","o","p"},{"a","s","d","f","g","h","j","k","l"},{"z","x","c","v","b","n","m"}},
    paintMode = false, paintCanvas = nil, paintWidth = 64, paintHeight = 64, paintScale = 1,
    paintBrushColor = {1,1,1}, paintCurrentTool = "brush",
    paintTools = {"brush", "eraser", "fill", "picker", "line", "rect", "ellipse"},
    paintColors = {
        {1,1,1}, {0,0,0}, {1,0,0}, {0,1,0}, {0,0,1}, {1,1,0}, {1,0,1}, {0,1,1},
        {0.5,0.5,0.5}, {1,0.5,0}, {0.5,0,0.5}, {0,0.5,0.5}
    },
    paintSizes = {1, 2, 4, 8},
    paintPresetSizes = {{64,64}, {32,32}, {16,16}, {128,128}, {200,146}},
    paintCustomInput = false, paintCustomInputText = "",
    paintCustomStep = 0,
    paintCustomX = nil,
    paintHue = 0, paintSaturation = 1, paintValue = 1,
    showCube = false, showSphere = false, showImage = false,
    cubeX = 200, cubeY = 300, sphereX = 400, sphereY = 300,
    objectAngle = 0, objectColor = {0.2,0.8,0.4}, objectSize = 50,
    cubeVertices = {{-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},{-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1}},
    cubeEdges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}},
    eventHandlers = {}, stopAll = false, waitTimer = 0, isTapped = false, isReleased = false, touchActive = false,
    penDown = false, penColor = {1,0,0}, penSize = 2, penPoints = {},
    drawCommands = {}, messages = {}, vars = {}, font = nil, fontSize = 16,
    plugins = {}, clipboard = nil,
    paletteTapBlock = nil, paletteTapTime = 0, paletteMoved = false,
    bgColor = {0.1,0.1,0.1}
}

json = {}
function json.encode(obj)
    if type(obj) == "table" then
        local t = {}
        for k, v in pairs(obj) do table.insert(t, '"' .. tostring(k) .. '":' .. json.encode(v)) end
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

function defaultProject()
    return {
        scenes = {{ name = "Сцена 1", bgColor = {0.2,0.2,0.4}, objects = {{ name = "Объект 1", x=200, y=200, image = nil, blocks = {
            {type="event", name="start", label="при старте", category="event"},
            {type="action", name="showCube", label="показать куб", category="looks"}
        }}} }},
        orientation = "portrait"
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

function calculateHeights()
    local y = 10
    local lastCat = nil
    for _, b in ipairs(State.paletteBlocks) do
        if b.category ~= lastCat then y = y + 20; lastCat = b.category end
        y = y + State.blockHeight + 6
    end
    State.paletteContentHeight = y
    State.workspaceContentHeight = State.workspaceStartY + #State.workspaceBlocks * (State.blockHeight + State.blockSpacing) + 100
end
function drawBlock(block, x, y, isDragging, highlight)
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
function drawPalette()
    love.graphics.setScissor(0, 0, State.paletteWidth, love.graphics.getHeight())
    love.graphics.setColor(0.15,0.15,0.15)
    love.graphics.rectangle("fill", 0, 0, State.paletteWidth, love.graphics.getHeight())
    local y = 10 - State.paletteScrollY
    local lastCat = nil
    for _, b in ipairs(State.paletteBlocks) do
        if b.category ~= lastCat then love.graphics.setColor(1,1,1); love.graphics.print(b.category, 5, y); y = y + 20; lastCat = b.category end
        if y + State.blockHeight > 0 and y < love.graphics.getHeight() then drawBlock(b, 5, y) end
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
            if by + State.blockHeight > 0 and by < love.graphics.getHeight() then drawBlock(b, bx, by, false, highlight) end
        end
    end
    if State.draggingBlock then
        local mx, my = love.mouse.getPosition()
        drawBlock(State.draggingBlock, mx-State.blockWidth/2, my-State.blockHeight/2, true, false)
    end
    love.graphics.setScissor()
end
function drawButtons()
    local rx = love.graphics.getWidth() - 50
    love.graphics.setColor(0,1,0)
    love.graphics.circle("fill", rx, 15, 22)
    love.graphics.setColor(1,1,1)
    love.graphics.print(">", rx-8, 5, 0, 1.6)
    local btnY = 50
    love.graphics.setColor(0.2,0.5,1.0)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 140, 30)
    love.graphics.print("Сохранить .cat", love.graphics.getWidth()-145, btnY+8)
    btnY = btnY + 35
    love.graphics.setColor(0.2,0.5,1.0)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 140, 30)
    love.graphics.print("Загрузить .cat", love.graphics.getWidth()-145, btnY+8)
    btnY = btnY + 35
    love.graphics.setColor(0.7,0.7,0.2)
    love.graphics.rectangle("fill", love.graphics.getWidth()-150, btnY, 68, 25)
    love.graphics.print("Коп.", love.graphics.getWidth()-145, btnY+5)
    love.graphics.rectangle("fill", love.graphics.getWidth()-78, btnY, 68, 25)
    love.graphics.print("Вст.", love.graphics.getWidth()-73, btnY+5)
end
function checkButtonClick(x, y)
    local rx = love.graphics.getWidth() - 50
    if math.sqrt((x-rx)^2 + (y-15)^2) <= 22 then runProject(); return true end
    local btnY = 50
    if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+30 then saveProject("project.cat"); return true end
    btnY = btnY + 35
    if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+30 then
        local saved = loadProject("project.cat")
        if saved then State.project = saved; updateWorkspaceBlocks() end
        return true
    end
    btnY = btnY + 35
    if x >= love.graphics.getWidth()-150 and x <= love.graphics.getWidth()-82 and y >= btnY and y <= btnY+25 then copyBlock(); return true end
    if x >= love.graphics.getWidth()-78 and x <= love.graphics.getWidth()-10 and y >= btnY and y <= btnY+25 then pasteBlock(); return true end
    return false
end
function copyBlock()
    if State.editingBlockIdx then
        local block = State.workspaceBlocks[State.editingBlockIdx]
        State.clipboard = { type = block.type, name = block.name, label = block.label, param = block.param, category = block.category }
        table.insert(State.messages, "Блок скопирован")
    else table.insert(State.messages, "Выделите блок") end
end
function pasteBlock()
    if State.clipboard then table.insert(State.workspaceBlocks, State.clipboard); calculateHeights(); table.insert(State.messages, "Блок вставлен")
    else table.insert(State.messages, "Буфер пуст") end
end

function compileScript()
    State.eventHandlers = {}
    local ce = nil
    for _, b in ipairs(State.workspaceBlocks) do
        if b.type == "event" then ce = b.name; State.eventHandlers[ce] = State.eventHandlers[ce] or {}
        elseif b.type == "action" and ce then table.insert(State.eventHandlers[ce], b) end
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
        elseif a.name == "showCube" then State.showCube = true; State.showImage = false
        elseif a.name == "showSphere" then State.showSphere = true; State.showImage = false
        elseif a.name == "showImage" then State.showImage = true; State.showCube = false; State.showSphere = false
        elseif a.name == "hide" then State.showCube, State.showSphere, State.showImage = false, false, false
        elseif a.name == "show" then State.showImage = true
        elseif a.name == "setColor" then
            if p == "green" then State.objectColor = {0.2,0.8,0.4} elseif p == "red" then State.objectColor = {0.9,0.2,0.2} elseif p == "blue" then State.objectColor = {0.2,0.4,1.0} end
        elseif a.name == "setSize" then State.objectSize = tonumber(p) or 50
        elseif a.name == "penDown" then State.penDown = true
        elseif a.name == "penUp" then State.penDown = false
        elseif a.name == "penClear" then State.penPoints = {}
        elseif a.name == "penColor" then
            if p == "green" then State.penColor = {0.2,0.8,0.4} elseif p == "red" then State.penColor = {0.9,0.2,0.2} elseif p == "blue" then State.penColor = {0.2,0.4,1.0} end
        elseif a.name == "penSize" then State.penSize = tonumber(p) or 2
        elseif a.name == "playSound" then
            local filename = "sounds/" .. p
            if love.filesystem.getInfo(filename) then
                local source = love.audio.newSource(filename, "static")
                if source then source:play() end
            end
        elseif a.name == "wait" then State.waitTimer = tonumber(p) or 1; return true
        elseif a.name == "forever" then if not State.stopAll then i = i - 1 end
        elseif a.name == "ifTap" then if not State.isTapped then return true end
        elseif a.name == "stopAll" then State.stopAll = true; return true
        elseif a.name == "printText" then table.insert(State.messages, tostring(p or "Привет!"))
        elseif a.name == "mouseX" then table.insert(State.messages, "mouse X: "..love.mouse.getX())
        elseif a.name == "mouseY" then table.insert(State.messages, "mouse Y: "..love.mouse.getY())
        elseif a.name == "touchX" then
            local touches = love.touch.getTouches()
            if touches[1] then table.insert(State.messages, "touch X: "..love.touch.getPosition(touches[1])) else table.insert(State.messages, "no touch") end
        elseif a.name == "touchY" then
            local touches = love.touch.getTouches()
            if touches[1] then table.insert(State.messages, "touch Y: "..select(2, love.touch.getPosition(touches[1]))) else table.insert(State.messages, "no touch") end
        end
        if State.penDown and (a.name == "changeX" or a.name == "changeY" or a.name == "setX" or a.name == "setY" or a.name == "turn") then
            table.insert(State.penPoints, {State.cubeX, State.cubeY, State.penColor[1], State.penColor[2], State.penColor[3], State.penSize})
        end
        i = i + 1
    end
    return false
end
function runProject()
    State.stopAll = false; State.drawCommands = {}; State.messages = {}; State.vars = {}; State.waitTimer = 0
    State.penDown = false; State.penPoints = {}
    compileScript()
    if State.eventHandlers["start"] then executeActions(State.eventHandlers["start"]) end
end

function updateKeyboardPos()
    local keys = (State.keyboardMode == "digits" and State.digitsKeys or State.keyboardMode == "ru" and State.ruKeys or State.enKeys)
    local cols = 0
    for _, row in ipairs(keys) do if #row > cols then cols = #row end end
    State.keyboardPosX = love.graphics.getWidth()/2 - (cols * (State.keyW + State.keySpacing) + State.keySpacing)/2
    State.keyboardPosY = love.graphics.getHeight() - State.keyboardHeight
end
function drawKeyboard()
    if not State.keyboardVisible then return end
    updateKeyboardPos()
    local kx, ky = State.keyboardPosX, State.keyboardPosY
    local keys = (State.keyboardMode == "digits" and State.digitsKeys or State.keyboardMode == "ru" and State.ruKeys or State.enKeys)
    local rows, cols = #keys, 0
    for _, row in ipairs(keys) do if #row > cols then cols = #row end end
    local kw = cols * (State.keyW + State.keySpacing) + State.keySpacing
    local kh = rows * (State.keyH + State.keySpacing) + State.keySpacing + 80
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
    local swY = ky + rows*(State.keyH + State.keySpacing) + State.keySpacing + 10
    local modes = {{"123","digits"},{"АБВ","ru"},{"ABC","en"}}
    for i, m in ipairs(modes) do
        local bx = kx + State.keySpacing + (i-1)*(55 + State.keySpacing)
        love.graphics.setColor(0.3,0.3,0.3)
        love.graphics.rectangle("fill", bx, swY, 55, 30, 6)
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("line", bx, swY, 55, 30, 6)
        love.graphics.printf(m[1], bx, swY+8, 55, "center")
    end
    local doneX = kx + kw - 70
    local pasteX = doneX - 75
    love.graphics.setColor(0.4,0.5,1.0)
    love.graphics.rectangle("fill", pasteX, swY, 65, 30, 6)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", pasteX, swY, 65, 30, 6)
    love.graphics.printf("Paste", pasteX, swY+8, 65, "center")
    love.graphics.setColor(0.2,0.6,0.2)
    love.graphics.rectangle("fill", doneX, swY, 60, 30, 6)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", doneX, swY, 60, 30, 6)
    love.graphics.printf("Done", doneX, swY+8, 60, "center")
end
function handleKeyboardTouch(x, y)
    if not State.keyboardVisible then return false end
    local kx, ky = State.keyboardPosX, State.keyboardPosY
    local keys = (State.keyboardMode == "digits" and State.digitsKeys or State.keyboardMode == "ru" and State.ruKeys or State.enKeys)
    for i, row in ipairs(keys) do
        for j, char in ipairs(row) do
            local bx = kx + State.keySpacing + (j-1)*(State.keyW + State.keySpacing)
            local by = ky + State.keySpacing + (i-1)*(State.keyH + State.keySpacing)
            if x >= bx and x <= bx+State.keyW and y >= by and y <= by+State.keyH then
                if char == "⌫" then State.editingText = State.editingText:sub(1, -2)
                else State.editingText = State.editingText .. char end
                return true
            end
        end
    end
    local rows = #keys
    local swY = ky + rows*(State.keyH + State.keySpacing) + State.keySpacing + 10
    local modes = {{"123","digits"},{"АБВ","ru"},{"ABC","en"}}
    for i, m in ipairs(modes) do
        local bx = kx + State.keySpacing + (i-1)*(55 + State.keySpacing)
        if x >= bx and x <= bx+55 and y >= swY and y <= swY+30 then State.keyboardMode = m[2]; return true end
    end
    local cols = 0
    for _, row in ipairs(keys) do if #row > cols then cols = #row end end
    local totalW = cols * (State.keyW + State.keySpacing) + State.keySpacing
    local doneX = kx + totalW - 70
    local pasteX = doneX - 75
    if x >= pasteX and x <= pasteX+65 and y >= swY and y <= swY+30 then
        local clip = love.system.getClipboardText()
        if clip then State.editingText = State.editingText .. safeUTF8(clip) end
        return true
    end
    if x >= doneX and x <= doneX+60 and y >= swY and y <= swY+30 then
        if State.editingBlockIdx then
            local block = State.workspaceBlocks[State.editingBlockIdx]
            local val = safeUTF8(State.editingText)
            if tonumber(val) then block.param = tonumber(val) else block.param = val end
        end
        State.editingBlockIdx = nil; State.editingText = ""; State.keyboardVisible = false
        return true
    end
    if y < ky then State.editingBlockIdx = nil; State.editingText = ""; State.keyboardVisible = false; return true end
    return false
end

function drawTabs()
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
    local scene = getCurrentScene()
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
function handleTabsClick(x, y)
    if y >= 5 and y <= 30 then
        local sx = 70
        for i, sc in ipairs(State.project.scenes) do
            local w = love.graphics.getFont():getWidth(sc.name) + 15
            if x >= sx and x <= sx+w then State.currentSceneIdx = i; State.currentObjectIdx = 1; updateWorkspaceBlocks(); return true end
            sx = sx + w + 5
        end
        if x >= sx and x <= sx+25 then addScene(); return true end
    elseif y >= 35 and y <= 60 then
        local ox = 70
        local scene = getCurrentScene()
        if scene then
            for i, obj in ipairs(scene.objects) do
                local w = love.graphics.getFont():getWidth(obj.name) + 15
                if x >= ox and x <= ox+w then State.currentObjectIdx = i; updateWorkspaceBlocks(); return true end
                if x >= ox+w+5 and x <= ox+w+30 then State.paintMode = true; return true end
                if x >= ox+w+35 and x <= ox+w+60 then openFilePicker(); return true end
                ox = ox + w + 65
            end
            if x >= ox and x <= ox+25 then addObject(); return true end
        end
    end
    return false
end
function addScene()
    table.insert(State.project.scenes, { name = "Сцена " .. #State.project.scenes+1, bgColor = {0.2,0.2,0.4}, objects = {{ name = "Объект 1", image = nil, blocks = {} }} })
    State.currentSceneIdx = #State.project.scenes; State.currentObjectIdx = 1; updateWorkspaceBlocks()
end
function addObject()
    local scene = getCurrentScene()
    if not scene then return end
    table.insert(scene.objects, { name = "Объект " .. #scene.objects+1, image = nil, blocks = {} })
    State.currentObjectIdx = #scene.objects; updateWorkspaceBlocks()
end

function openFilePicker()
    if love.system.getOS() == "Android" then
        love.system.openURL("intent://#Intent;action=android.intent.action.GET_CONTENT;type=image/*,audio/*;end")
    end
end
function love.filedropped(file)
    local fname = file.name or file
    local ext = fname:match("%.([^.]+)$"):lower()
    local destFolder = "sprites/"
    if ext == "ogg" or ext == "mp3" or ext == "wav" then destFolder = "sounds/" end
    love.filesystem.createDirectory(destFolder)
    local destName = destFolder .. love.filesystem.getBasename(fname) .. "." .. ext
    local data = love.filesystem.read(fname)
    if data then love.filesystem.write(destName, data) end
    local obj = getCurrentObject()
    if obj then
        if destFolder == "sprites/" then obj.image = destName elseif destFolder == "sounds/" then obj.sound = destName end
    end
end

function initPaint()
    State.paintCanvas = love.graphics.newCanvas(State.paintWidth, State.paintHeight)
    love.graphics.setCanvas(State.paintCanvas)
    love.graphics.clear()
    love.graphics.setCanvas()
    State.paintCanvas:setFilter("linear", "linear")
end
function recalcPaintScale()
    local maxW = 340
    local maxH = 400
    State.paintScale = math.min(maxW / State.paintWidth, maxH / State.paintHeight)
end
function resizePaintCanvas(w, h)
    w = math.max(1, math.min(1024, w))
    h = math.max(1, math.min(1024, h))
    State.paintWidth, State.paintHeight = w, h
    State.paintCanvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(State.paintCanvas)
    love.graphics.clear()
    love.graphics.setCanvas()
    recalcPaintScale()
end
function drawPaint()
    if not State.paintMode then return end
    love.graphics.setCanvas()
    love.graphics.setColor(0.1,0.1,0.1,0.95)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    local cx, cy = 20, 50
    local pw = State.paintWidth * State.paintScale
    local ph = State.paintHeight * State.paintScale
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", cx, cy, pw, ph)
    love.graphics.draw(State.paintCanvas, cx, cy, 0, State.paintScale, State.paintScale)
    local px = cx + pw + 30
    love.graphics.setColor(0.2,0.2,0.2)
    love.graphics.rectangle("fill", px-10, 50, 140, 500, 8)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Tools:", px, 60)
    for i, tool in ipairs(State.paintTools) do
        local y = 90 + (i-1)*32
        if State.paintCurrentTool == tool then love.graphics.setColor(0.4,0.6,1) else love.graphics.setColor(0.3,0.3,0.3) end
        love.graphics.rectangle("fill", px, y, 120, 26, 5)
        love.graphics.setColor(1,1,1)
        love.graphics.print(tool, px+5, y+5)
    end
    love.graphics.print("Size:", px, 340)
    for i, sz in ipairs(State.paintSizes) do
        local sx = px + (i-1)*35
        if State.paintSize == sz then love.graphics.setColor(0.4,0.6,1) else love.graphics.setColor(0.3,0.3,0.3) end
        love.graphics.rectangle("fill", sx, 360, 30, 30, 5)
        love.graphics.setColor(1,1,1)
        love.graphics.print(sz, sx+10, 368)
    end
    love.graphics.print("Canvas:", px, 410)
    local py = 430
    for i, psz in ipairs(State.paintPresetSizes) do
        local sx = px + ((i-1)%3) * 55
        local sy = py + math.floor((i-1)/3) * 30
        love.graphics.setColor(0.3,0.3,0.3)
        love.graphics.rectangle("fill", sx, sy, 50, 24, 5)
        love.graphics.setColor(1,1,1)
        love.graphics.print(psz[1].."x"..psz[2], sx+4, sy+4)
    end
    local customY = py + 60
    love.graphics.setColor(0.5,0.5,0.5)
    love.graphics.rectangle("fill", px, customY, 120, 26, 5)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Custom...", px+10, customY+5)
    if State.paintCustomStep > 0 then
        love.graphics.setColor(0.2,0.2,0.2)
        love.graphics.rectangle("fill", px, customY+32, 120, 26)
        love.graphics.setColor(1,1,1)
        if State.paintCustomStep == 1 then
            love.graphics.print("X: " .. State.paintCustomInputText, px+5, customY+37)
        else
            love.graphics.print("Y: " .. State.paintCustomInputText, px+5, customY+37)
        end
    end
    love.graphics.setColor(1,1,1)
    love.graphics.print("Custom Color:", px, customY+70)
    local hsvX, hsvY = px, customY+90
    local hsvSize = 60
    for dx = 0, hsvSize-1 do
        for dy = 0, hsvSize-1 do
            local hue = dx / hsvSize
            local sat = 1 - dy / hsvSize
            local r,g,b = hsvToRGB(hue, sat, 1)
            love.graphics.setColor(r,g,b)
            love.graphics.rectangle("fill", hsvX+dx, hsvY+dy, 1, 1)
        end
    end
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", hsvX, hsvY, hsvSize, hsvSize)
    local mx = hsvX + State.paintHue * hsvSize
    local my = hsvY + (1 - State.paintSaturation) * hsvSize
    love.graphics.setColor(0,0,0)
    love.graphics.circle("line", mx, my, 3)
    love.graphics.setColor(1,1,1)
    love.graphics.circle("line", mx+1, my+1, 3)
    local vX, vY = px, hsvY + hsvSize + 10
    for i = 0, 119 do
        local val = i / 119
        local r,g,b = hsvToRGB(State.paintHue, State.paintSaturation, val)
        love.graphics.setColor(r,g,b)
        love.graphics.rectangle("fill", vX+i, vY, 1, 10)
    end
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", vX, vY, 120, 10)
    local vm = vX + State.paintValue * 119
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", vm-1, vY-1, 3, 12)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", vm-1, vY-1, 3, 12)
    love.graphics.setColor(0.3,0.8,0.3)
    love.graphics.rectangle("fill", px, vY+20, 120, 30, 5)
    love.graphics.print("Save", px+40, vY+28)
    love.graphics.setColor(0.8,0.3,0.3)
    love.graphics.rectangle("fill", px, vY+60, 120, 30, 5)
    love.graphics.print("Close", px+40, vY+68)
end
function handlePaintTouch(x, y, isDown)
    if not State.paintMode then return false end
    local cx, cy = 20, 50
    local pw = State.paintWidth * State.paintScale
    local ph = State.paintHeight * State.paintScale
    local px = cx + pw + 30
    if y > 550 and y < 590 and x > px and x < px+120 then
        love.graphics.setCanvas()
        local obj = getCurrentObject()
        if obj then
            local imgData = State.paintCanvas:newImageData()
            local filename = "obj_" .. State.currentSceneIdx .. "_" .. State.currentObjectIdx .. ".png"
            imgData:encode("png", filename)
            obj.image = filename
        end
        State.paintMode = false; State.paintCustomStep = 0; State.paintCustomInputText = ""; return true
    end
    if y > 590 and y < 630 and x > px and x < px+120 then
        love.graphics.setCanvas()
        State.paintMode = false; State.paintCustomStep = 0; State.paintCustomInputText = ""; return true
    end
    for i, tool in ipairs(State.paintTools) do
        local ty = 90 + (i-1)*32
        if x > px and x < px+120 and y > ty and y < ty+26 then
            State.paintCurrentTool = tool
            if tool == "fill" then
                love.graphics.setCanvas(State.paintCanvas)
                love.graphics.setColor(State.paintBrushColor)
                love.graphics.rectangle("fill", 0, 0, State.paintWidth, State.paintHeight)
                love.graphics.setCanvas()
            end
            return true
        end
    end
    for i, sz in ipairs(State.paintSizes) do
        local sx = px + (i-1)*35
        if x > sx and x < sx+30 and y > 360 and y < 390 then
            State.paintSize = sz; return true
        end
    end
    local py = 430
    for i, psz in ipairs(State.paintPresetSizes) do
        local sx = px + ((i-1)%3) * 55
        local sy = py + math.floor((i-1)/3) * 30
        if x > sx and x < sx+50 and y > sy and y < sy+24 then
            resizePaintCanvas(psz[1], psz[2])
            State.paintCustomStep = 0; State.paintCustomInputText = ""
            return true
        end
    end
    local customBtnY = py + 60
    if x > px and x < px+120 and y > customBtnY and y < customBtnY+26 then
        State.paintCustomStep = 1
        State.paintCustomInputText = ""
        State.editingBlockIdx = nil
        State.editingText = ""
        State.keyboardVisible = true
        return true
    end
    if State.paintCustomStep > 0 and x > px and x < px+120 and y > customBtnY+32 and y < customBtnY+58 then
        State.editingBlockIdx = nil
        State.editingText = State.paintCustomInputText
        State.keyboardVisible = true
        return true
    end
    local hsvX, hsvY2 = px, customBtnY+90
    local hsvSize = 60
    if x >= hsvX and x <= hsvX+hsvSize and y >= hsvY2 and y <= hsvY2+hsvSize then
        State.paintHue = (x - hsvX) / hsvSize
        State.paintSaturation = 1 - (y - hsvY2) / hsvSize
        local r,g,b = hsvToRGB(State.paintHue, State.paintSaturation, State.paintValue)
        State.paintBrushColor = {r,g,b}
        return true
    end
    local vX, vY = px, hsvY2 + hsvSize + 10
    if x >= vX and x <= vX+119 and y >= vY and y <= vY+10 then
        State.paintValue = (x - vX) / 119
        local r,g,b = hsvToRGB(State.paintHue, State.paintSaturation, State.paintValue)
        State.paintBrushColor = {r,g,b}
        return true
    end
    if x >= cx and x <= cx+pw and y >= cy and y <= cy+ph and isDown then
        local pxc = math.floor((x - cx) / State.paintScale) + 1
        local pyc = math.floor((y - cy) / State.paintScale) + 1
        if pxc >= 1 and pxc <= State.paintWidth and pyc >= 1 and pyc <= State.paintHeight then
            love.graphics.setCanvas(State.paintCanvas)
            local brushSize = State.paintSize or 1
            if State.paintCurrentTool == "brush" or State.paintCurrentTool == "eraser" then
                local alpha = (State.paintCurrentTool == "eraser") and 0 or 1
                for dx = -brushSize, brushSize do
                    for dy = -brushSize, brushSize do
                        local dist = math.sqrt(dx*dx + dy*dy)
                        if dist <= brushSize then
                            local a = (1 - dist/brushSize) * alpha
                            if a > 0 then
                                love.graphics.setColor(State.paintBrushColor[1], State.paintBrushColor[2], State.paintBrushColor[3], a)
                                love.graphics.rectangle("fill", pxc+dx-1, pyc+dy-1, 1, 1)
                            end
                        end
                    end
                end
                love.graphics.setCanvas()
            elseif State.paintCurrentTool == "line" then
                if not State.lineStart then
                    State.lineStart = {pxc, pyc}
                else
                    love.graphics.setColor(State.paintBrushColor)
                    love.graphics.setLineWidth(State.paintSize or 1)
                    love.graphics.line(State.lineStart[1], State.lineStart[2], pxc, pyc)
                    love.graphics.setCanvas()
                    State.lineStart = nil
                end
            elseif State.paintCurrentTool == "rect" then
                if not State.rectStart then
                    State.rectStart = {pxc, pyc}
                else
                    love.graphics.setColor(State.paintBrushColor)
                    local w = pxc - State.rectStart[1]
                    local h = pyc - State.rectStart[2]
                    love.graphics.rectangle("fill", State.rectStart[1], State.rectStart[2], w, h)
                    love.graphics.setCanvas()
                    State.rectStart = nil
                end
            elseif State.paintCurrentTool == "ellipse" then
                if not State.ellipseStart then
                    State.ellipseStart = {pxc, pyc}
                else
                    love.graphics.setColor(State.paintBrushColor)
                    local w = pxc - State.ellipseStart[1]
                    local h = pyc - State.ellipseStart[2]
                    love.graphics.ellipse("fill", State.ellipseStart[1], State.ellipseStart[2], w, h)
                    love.graphics.setCanvas()
                    State.ellipseStart = nil
                end
            elseif State.paintCurrentTool == "picker" then
                love.graphics.setCanvas()
                local imgData = State.paintCanvas:newImageData()
                local r,g,b,a = imgData:getPixel(pxc-1, pyc-1)
                State.paintBrushColor = {r,g,b}
                State.paintCurrentTool = "brush"
            else
                love.graphics.setCanvas()
            end
            return true
        end
    end
    return false
end

function saveProject(filename)
    local lines = {"scenes:"}
    for si, scene in ipairs(State.project.scenes) do
        table.insert(lines, "  - name: " .. scene.name)
        table.insert(lines, "    bgColor: [" .. table.concat(scene.bgColor, ",") .. "]")
        table.insert(lines, "    objects:")
        for oi, obj in ipairs(scene.objects) do
            table.insert(lines, "      - name: " .. obj.name)
            if obj.image then table.insert(lines, "        image: " .. obj.image) end
            table.insert(lines, "        x: " .. (obj.x or 200))
            table.insert(lines, "        y: " .. (obj.y or 200))
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
            local name = line:match("name: (.+)"):gsub("^%s+", ""):gsub("%s+$", "")
            currentScene = {name = name, bgColor = {0.2,0.2,0.4}, objects = {}}
            table.insert(project.scenes, currentScene)
        elseif line:match("^    bgColor: %[(.+)%]") then
            local vals = line:match("bgColor: %[(.+)%]")
            if currentScene then
                local r,g,b = vals:match("([%d.]+),([%d.]+),([%d.]+)")
                currentScene.bgColor = {tonumber(r), tonumber(g), tonumber(b)}
            end
        elseif line:match("^      %- name: (.+)") then
            local name = line:match("name: (.+)"):gsub("^%s+", ""):gsub("%s+$", "")
            currentObject = {name = name, image = nil, x=200, y=200, blocks = {}}
            table.insert(currentScene.objects, currentObject)
        elseif line:match("^        x: (.+)") then
            if currentObject then currentObject.x = tonumber(line:match("x: (.+)")) or 200 end
        elseif line:match("^        y: (.+)") then
            if currentObject then currentObject.y = tonumber(line:match("y: (.+)")) or 200 end
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
                local p = line:match("param: (.+)"):gsub("^%s*(.-)%s*$", "")
                if tonumber(p) then p = tonumber(p) end
                currentBlock.param = p
            end
        elseif line:match("^            category: (.+)") then
            if currentBlock then currentBlock.category = line:match("category: (.+)") end
        end
    end
    return project
end

function drawSceneObjects()
    if #State.penPoints > 1 then
        love.graphics.setLineWidth(State.penSize or 2)
        for i = 2, #State.penPoints do
            local p1 = State.penPoints[i-1]
            local p2 = State.penPoints[i]
            love.graphics.setColor(p1[3], p1[4], p1[5])
            love.graphics.line(p1[1], p1[2], p2[1], p2[2])
        end
    end
    if State.showImage then
        local obj = getCurrentObject()
        if obj and obj.image then
            if not obj.loadedImage then
                local file = love.filesystem.newFile(obj.image)
                if file then obj.loadedImage = love.graphics.newImage(file) end
            end
            if obj.loadedImage then
                love.graphics.setColor(1,1,1)
                love.graphics.draw(obj.loadedImage, State.cubeX, State.cubeY, math.rad(State.objectAngle), State.objectSize/32, State.objectSize/32, 16, 16)
            end
        end
    end
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

function love.load()
    State.font = love.graphics.getFont()
    love.filesystem.createDirectory("sprites")
    love.filesystem.createDirectory("sounds")
    local saved = loadProject("project.cat") or loadProject("project.yml")
    State.project = saved or defaultProject()
    updateWorkspaceBlocks()
    initPaint()
    recalcPaintScale()
    calculateHeights()
    State.bgColor = {0.1,0.1,0.1}
    if not State.paintSize then State.paintSize = 1 end
end

function love.draw()
    local bg = getCurrentScene() and getCurrentScene().bgColor or {0.1,0.1,0.1}
    love.graphics.setBackgroundColor(bg)
    drawPalette()
    drawWorkspace()
    drawTabs()
    if State.editingBlockIdx and not State.paintMode and not State.paintCustomStep then
        local block = State.workspaceBlocks[State.editingBlockIdx]
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", 10, 10, 200, 40, 5)
        love.graphics.setColor(1,1,1)
        love.graphics.print("Value: " .. safeUTF8(State.editingText), 20, 20)
        State.keyboardVisible = true
    elseif State.paintCustomStep > 0 then
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", 10, 10, 200, 40, 5)
        love.graphics.setColor(1,1,1)
        if State.paintCustomStep == 1 then
            love.graphics.print("Enter X size:", 20, 20)
        else
            love.graphics.print("Enter Y size:", 20, 20)
        end
        State.keyboardVisible = true
    else
        if not State.paintCustomInput then State.keyboardVisible = false end
    end
    drawKeyboard()
    drawPaint()
    drawButtons()
    drawSceneObjects()
    love.graphics.setFont(State.font)
    local msgY = State.workspaceStartY + #State.workspaceBlocks*(State.blockHeight+State.blockSpacing) + 20 - State.workspaceScrollY
    for _, msg in ipairs(State.messages) do
        if msgY > 0 and msgY < love.graphics.getHeight() then
            love.graphics.setColor(1,1,1)
            love.graphics.print(safeUTF8(msg), State.workspaceStartX, msgY)
        end
        msgY = msgY + State.fontSize + 4
    end
end

function love.update(dt)
    local maxPal = math.max(0, State.paletteContentHeight - love.graphics.getHeight())
    State.paletteScrollY = math.max(0, math.min(State.paletteScrollY, maxPal))
    local maxWs = math.max(0, State.workspaceContentHeight - love.graphics.getHeight())
    State.workspaceScrollY = math.max(0, math.min(State.workspaceScrollY, maxWs))
    if State.waitTimer > 0 then State.waitTimer = State.waitTimer - dt; if State.waitTimer <= 0 then State.waitTimer = 0 end end
    if State.longPressBlockIdx and not State.longPressMoved then
        if love.timer.getTime() - State.longPressStartTime > 0.5 then
            table.remove(State.workspaceBlocks, State.longPressBlockIdx)
            if State.editingBlockIdx == State.longPressBlockIdx then State.editingBlockIdx = nil; State.editingText = ""; State.keyboardVisible = false end
            State.longPressBlockIdx = nil
            calculateHeights()
        end
    end
end

function love.mousepressed(x, y, button)
    if State.paintMode then if handlePaintTouch(x, y, true) then return end end
    if State.keyboardVisible and handleKeyboardTouch(x, y) then return end
    if checkButtonClick(x, y) then return end
    if y <= 60 and handleTabsClick(x, y) then return end
    if x <= State.paletteWidth then
        local yPal = 10 - State.paletteScrollY
        local lastCat = nil
        for _, b in ipairs(State.paletteBlocks) do
            if b.category ~= lastCat then yPal = yPal + 20; lastCat = b.category end
            if x >= 5 and x <= 5+State.blockWidth and y >= yPal and y <= yPal+State.blockHeight then
                State.paletteTapBlock = b; State.paletteTapTime = love.timer.getTime(); State.paletteMoved = false; return
            end
            yPal = yPal + State.blockHeight + 6
        end
        State.touchActive = true; return
    end
    for i, b in ipairs(State.workspaceBlocks) do
        local bx = State.workspaceStartX
        local by = State.workspaceStartY + (i-1)*(State.blockHeight + State.blockSpacing) - State.workspaceScrollY
        if x >= bx and x <= bx+State.blockWidth and y >= by and y <= by+State.blockHeight then
            State.longPressBlockIdx = i; State.longPressStartTime = love.timer.getTime(); State.longPressMoved = false; return
        end
    end
    State.isTapped = true; State.touchActive = true
end

function love.mousereleased(x, y, button)
    if State.paintMode then return end
    if State.paletteTapBlock and not State.paletteMoved then
        local elapsed = love.timer.getTime() - State.paletteTapTime
        if elapsed < 0.4 then
            local nb = { type = State.paletteTapBlock.type, name = State.paletteTapBlock.name, label = State.paletteTapBlock.label, param = State.paletteTapBlock.param, category = State.paletteTapBlock.category }
            table.insert(State.workspaceBlocks, nb)
            calculateHeights()
        end
        State.paletteTapBlock = nil; return
    end
    State.paletteTapBlock = nil
    if State.longPressBlockIdx and not State.longPressMoved then
        local elapsed = love.timer.getTime() - State.longPressStartTime
        if elapsed < 0.5 then
            State.editingBlockIdx = State.longPressBlockIdx
            State.editingText = tostring(State.workspaceBlocks[State.longPressBlockIdx].param or "")
            State.keyboardVisible = true
        end
        State.longPressBlockIdx = nil
    end
    State.isReleased = true; State.touchActive = false
end

function love.touchmoved(id, x, y, dx, dy)
    if State.paintMode then handlePaintTouch(x, y, true); return end
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
    elseif x <= State.paletteWidth then State.paletteScrollY = State.paletteScrollY - dy
    else State.workspaceScrollY = State.workspaceScrollY - dy end
end
function love.touchpressed(id, x, y) love.mousepressed(x, y, 1) end
function love.touchreleased(id, x, y) love.mousereleased(x, y, 1) end
function love.wheelmoved(x, y)
    if x <= State.paletteWidth then State.paletteScrollY = State.paletteScrollY - y * 30
    else State.workspaceScrollY = State.workspaceScrollY - y * 30 end
end
function love.textinput(t)
    if State.paintCustomStep > 0 and State.keyboardVisible then
        State.paintCustomInputText = State.paintCustomInputText .. t
        State.editingText = State.paintCustomInputText
    elseif State.editingBlockIdx and not State.paintCustomStep then
        State.editingText = State.editingText .. t
    end
end
function love.keypressed(key)
    if State.paintCustomStep > 0 and State.keyboardVisible then
        if key == "return" or key == "kpenter" then
            if State.paintCustomStep == 1 then
                local val = tonumber(State.paintCustomInputText)
                if val then
                    State.paintCustomX = val
                    State.paintCustomStep = 2
                    State.paintCustomInputText = ""
                    State.editingText = ""
                end
            else
                local val = tonumber(State.paintCustomInputText)
                if val and State.paintCustomX then
                    resizePaintCanvas(State.paintCustomX, val)
                    State.paintCustomStep = 0
                    State.paintCustomInputText = ""
                    State.editingText = ""
                    State.keyboardVisible = false
                end
            end
        elseif key == "escape" then
            State.paintCustomStep = 0; State.paintCustomInputText = ""; State.editingText = ""; State.keyboardVisible = false
        elseif key == "backspace" then
            State.paintCustomInputText = State.paintCustomInputText:sub(1, -2)
            State.editingText = State.paintCustomInputText
        end
    elseif State.editingBlockIdx and not State.paintCustomStep then
        if key == "return" or key == "kpenter" then
            local block = State.workspaceBlocks[State.editingBlockIdx]
            local val = safeUTF8(State.editingText)
            if tonumber(val) then block.param = tonumber(val) else block.param = val end
            State.editingBlockIdx = nil; State.editingText = ""; State.keyboardVisible = false
        elseif key == "escape" then
            State.editingBlockIdx = nil; State.editingText = ""; State.keyboardVisible = false
        elseif key == "backspace" then
            State.editingText = State.editingText:sub(1, -2)
        end
    else
        if key == "f5" then runProject()
        elseif key == "f2" then saveProject("project.cat")
        elseif key == "delete" then
            if State.editingBlockIdx then
                table.remove(State.workspaceBlocks, State.editingBlockIdx)
                State.editingBlockIdx = nil; State.editingText = ""; State.keyboardVisible = false
                calculateHeights()
            end
        end
    end
end
