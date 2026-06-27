-- Pocket Cat 2.3 – без эмодзи, с файловым менеджером, пером, вечным циклом

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
        -- Перо
        {type="action", name="penDown",   label="включить перо",       category="pen"},
        {type="action", name="penUp",     label="выключить перо",      category="pen"},
        {type="action", name="penClear",  label="очистить перо",       category="pen"},
        {type="action", name="penColor",  label="цвет пера",           param="green", category="pen"},
        {type="action", name="penSize",   label="размер пера",         param=2, category="pen"},
        -- Звук
        {type="action", name="playSound",  label="играть звук",        param="",     category="sound"},
        -- Управление
        {type="action", name="wait",   label="ждать",                 param=1, category="control"},
        {type="action", name="repeat", label="повторить 3 раза",      param=3, category="control"},
        {type="action", name="forever",label="вечно",                 category="control"},
        {type="action", name="ifTap",  label="если нажато",           category="control"},
        {type="action", name="stopAll",label="остановить всё",        category="control"},
        -- Текст
        {type="action", name="printText",label="вывести текст",       param="Привет!", category="text"},
        -- Датчики
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
    digitsKeys = {{"1","2","3"},{"4","5","6"},{"7","8","9"},{".","0","<"}},
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

    importList = {},
    showImport = false,

    paletteTapBlock = nil,
    paletteTapTime = 0,
    paletteMoved = false,

    currentSound = nil,
}

-- JSON и проект (без изменений)
-- Вставь сюда функции json.encode, json.decode, defaultProject, getCurrentScene, getCurrentObject, updateWorkspaceBlocks, calculateHeights, drawBlock, drawPalette, drawWorkspace
-- Они точно такие же, как в предыдущем полном коде, только без эмодзи-кнопок.

-- Кнопки и импорт файлов
function drawButtons()
    local rx = love.graphics.getWidth() - 50
    love.graphics.setColor(0,1,0)
    love.graphics.circle("fill", rx, 15, 22)
    love.graphics.setColor(1,1,1)
    love.graphics.print(">", rx-5, 5)

    local btnY = 50
    love.graphics.setColor(0.2, 0.5, 1.0)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 150, btnY, 140, 30)
    love.graphics.print("Сохранить (.cat)", love.graphics.getWidth() - 145, btnY+8)

    btnY = btnY + 35
    love.graphics.setColor(0.2, 0.5, 1.0)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 150, btnY, 140, 30)
    love.graphics.print("Загрузить (.cat)", love.graphics.getWidth() - 145, btnY+8)

    btnY = btnY + 35
    love.graphics.setColor(0.7, 0.7, 0.2)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 150, btnY, 68, 25)
    love.graphics.print("Коп.", love.graphics.getWidth() - 145, btnY+5)
    love.graphics.setColor(0.7, 0.7, 0.2)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 78, btnY, 68, 25)
    love.graphics.print("Вст.", love.graphics.getWidth() - 73, btnY+5)
end

function openFilePicker()
    -- Открываем системный файловый менеджер
    love.system.openURL("content://com.android.externalstorage.documents/tree/primary%3A")
end

function love.filedropped(file)
    if not file then return end
    local fname = file.name or file:getFilename()
    local ext = fname:match("%.([^.]+)$"):lower()
    local destFolder = "sprites/"
    if ext == "ogg" or ext == "mp3" or ext == "wav" then
        destFolder = "sounds/"
    end
    love.filesystem.createDirectory(destFolder)
    local dest = destFolder .. love.filesystem.getBasename(fname) .. "." .. ext
    local data = love.filesystem.read(file)
    if data then
        love.filesystem.write(dest, data)
    end
    local obj = getCurrentObject()
    if obj then
        if destFolder == "sprites/" then
            obj.image = dest
        elseif destFolder == "sounds/" then
            obj.sound = dest
        end
    end
end

-- Вкладки сцен и объектов (без эмодзи)
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
            -- Paint
            love.graphics.setColor(0.8, 0.6, 0.2)
            love.graphics.rectangle("fill", ox + w + 5, 35, 25, 25)
            love.graphics.print("P", ox + w + 7, 38)
            -- Файл
            love.graphics.setColor(0.4, 0.5, 1.0)
            love.graphics.rectangle("fill", ox + w + 35, 35, 25, 25)
            love.graphics.print("F", ox + w + 37, 38)
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
            if x >= sx and x <= sx+w then
                State.currentSceneIdx = i; State.currentObjectIdx = 1
                updateWorkspaceBlocks(); return true
            end
            sx = sx + w + 5
        end
        if x >= sx and x <= sx+25 then addScene(); return true end
    elseif y >= 35 and y <= 60 then
        local ox = 70
        local scene = getCurrentScene()
        if scene then
            for i, obj in ipairs(scene.objects) do
                local w = love.graphics.getFont():getWidth(obj.name) + 15
                if x >= ox and x <= ox+w then
                    State.currentObjectIdx = i
                    updateWorkspaceBlocks(); return true
                end
                if x >= ox + w + 5 and x <= ox + w + 30 then
                    State.paintMode = true; return true
                end
                if x >= ox + w + 35 and x <= ox + w + 60 then
                    openFilePicker()
                    return true
                end
                ox = ox + w + 65
            end
            if x >= ox and x <= ox+25 then addObject(); return true end
        end
    end
    return false
end

-- Остальные функции (executeActions, runProject, клавиатура, Paint, сохранение) бери из предыдущего полного кода,
-- но во всех print замени эмодзи на текстовые аналоги, как я показал выше.
-- Например, "Блок скопирован" вместо "📋 Блок скопирован".

-- В love.load добавь:
love.filesystem.createDirectory("sprites")
love.filesystem.createDirectory("sounds")
