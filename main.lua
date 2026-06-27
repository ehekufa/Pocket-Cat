-- Pocket Cat IDE для LÖVE (Android + Desktop)
-- Блоки drag-and-drop, авто-событие "start", YAML, куб
-- Без иконки

-- ========== БЛОКИ ==========
local paletteBlocks = {
    {type = "action", name = "cube",   label = "показать куб"},
    {type = "action", name = "sphere", label = "показать шар"}, -- заглушка
}

local workspaceBlocks = {}   -- блоки на рабочей области
local draggingBlock = nil   -- {block, offsetX, offsetY}
local dragFromPalette = false
local blockWidth, blockHeight = 160, 40
local snapGrid = 5

-- ========== КУБ (3D wireframe) ==========
local cubeVertices = {
    {-1,-1,-1}, { 1,-1,-1}, { 1, 1,-1}, {-1, 1,-1},
    {-1,-1, 1}, { 1,-1, 1}, { 1, 1, 1}, {-1, 1, 1}
}
local cubeEdges = {
    {1,2},{2,3},{3,4},{4,1}, -- задняя
    {5,6},{6,7},{7,8},{8,5}, -- передняя
    {1,5},{2,6},{3,7},{4,8}  -- соединения
}
local showCube = false
local angleX, angleY = 0, 0

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
            table.insert(blocks, {type=typ, name=name})
        end
    end
    return blocks
end

function saveYAML(path, blocks)
    local lines = {"blocks:"}
    for _, b in ipairs(blocks) do
        table.insert(lines, "  - type: " .. b.type)
        table.insert(lines, "    name: " .. b.name)
    end
    love.filesystem.write(path, table.concat(lines, "\n"))
end

-- ========== ПОМОЩНИКИ ==========
function hasEventBefore(index)
    if index > 1 and workspaceBlocks[index-1] and workspaceBlocks[index-1].type == "event" then
        return true
    end
    return false
end

function runProject()
    showCube = false
    angleX, angleY = 0, 0
    local activeEvent = nil
    for _, block in ipairs(workspaceBlocks) do
        if block.type == "event" then
            activeEvent = block.name
        elseif block.type == "action" and activeEvent == "start" then
            if block.name == "cube" then
                showCube = true
            elseif block.name == "sphere" then
                -- позже
            end
        end
    end
end

function insertBlockIntoWorkspace(newBlock)
    -- Если это действие и перед ним нет события "start", добавляем его
    if newBlock.type == "action" and #workspaceBlocks == 0 then
        table.insert(workspaceBlocks, {type="event", name="start"})
        table.insert(workspaceBlocks, newBlock)
    elseif newBlock.type == "action" then
        local lastEventIdx = nil
        for i = #workspaceBlocks, 1, -1 do
            if workspaceBlocks[i].type == "event" then
                lastEventIdx = i
                break
            end
        end
        if not lastEventIdx then
            table.insert(workspaceBlocks, 1, {type="event", name="start"})
        end
        table.insert(workspaceBlocks, newBlock)
    else
        -- События вставляем как есть
        table.insert(workspaceBlocks, newBlock)
    end
end

-- ========== ОТРИСОВКА ==========
function drawBlock(block, x, y, isDragging)
    local r, g, b
    if block.type == "event" then
        r, g, b = 0.9, 0.6, 0.2   -- оранжевый
    else
        r, g, b = 0.3, 0.7, 0.9   -- голубой
    end
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", x, y, blockWidth, blockHeight, 8)
    love.graphics.setColor(1,1,1)
    love.graphics.print(block.label or block.name, x+10, y+10)
    if isDragging then
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.rectangle("line", x, y, blockWidth, blockHeight, 8)
    end
    love.graphics.setColor(1,1,1)
end

function love.load()
    -- Попытка загрузить сохранённый проект
    local loaded = loadYAML("project.yml")
    if loaded then
        workspaceBlocks = loaded
    else
        -- начальный пример
        workspaceBlocks = {
            {type="event", name="start", label="при старте"},
            {type="action", name="cube", label="показать куб"}
        }
    end
end

function love.draw()
    -- Палитра (левая панель)
    love.graphics.setColor(0.2,0.2,0.2)
    love.graphics.rectangle("fill", 0, 0, 170, love.graphics.getHeight())
    love.graphics.setColor(1,1,1)
    love.graphics.print("Палитра", 10, 10)
    for i, b in ipairs(paletteBlocks) do
        drawBlock(b, 15, 50 + (i-1)*(blockHeight+10))
    end

    -- Рабочая область
    love.graphics.setColor(0.15,0.15,0.15)
    love.graphics.rectangle("fill", 170, 0, love.graphics.getWidth()-170, love.graphics.getHeight())
    love.graphics.setColor(1,1,1)
    love.graphics.print("Рабочая область (перетащи сюда)", 180, 10)

    -- Отрисовка блоков рабочей области
    for i, b in ipairs(workspaceBlocks) do
        local bx = 180 + (i-1)*(blockWidth + 10)
        local by = 80
        if b == draggingBlock and not dragFromPalette then
            -- не рисуем оригинал, т.к. тащим
        else
            drawBlock(b, bx, by)
        end
    end

    -- Перетаскиваемый блок
    if draggingBlock then
        local mx, my = love.mouse.getPosition()
        drawBlock(draggingBlock, mx - blockWidth/2, my - blockHeight/2, true)
    end

    -- Кнопки управления
    -- Зелёный флажок (запуск)
    love.graphics.setColor(0,1,0)
    love.graphics.circle("fill", 40, love.graphics.getHeight()-50, 24)
    love.graphics.setColor(1,1,1)
    love.graphics.print("▶", 28, love.graphics.getHeight()-60, 0, 1.8)

    -- Сохранить
    love.graphics.setColor(0.4,0.4,0.4)
    love.graphics.rectangle("fill", 5, love.graphics.getHeight()-90, 80, 30)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Сохранить", 10, love.graphics.getHeight()-85)

    -- Загрузить
    love.graphics.rectangle("fill", 90, love.graphics.getHeight()-90, 80, 30)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Загрузить", 95, love.graphics.getHeight()-85)

    -- Куб (если запущен)
    if showCube then
        -- проекция
        love.graphics.setColor(0.2, 0.8, 0.4)
        love.graphics.setLineWidth(2)
        for _, edge in ipairs(cubeEdges) do
            local p1 = cubeVertices[edge[1]]
            local p2 = cubeVertices[edge[2]]
            local x1, y1 = project(p1[1], p1[2], p1[3])
            local x2, y2 = project(p2[1], p2[2], p2[3])
            love.graphics.line(x1, y1, x2, y2)
        end
        love.graphics.setColor(1,1,1)
        love.graphics.print("Проект запущен!", 200, 300)
    end
end

function project(x, y, z)
    local scale = 200
    local distance = 5
    local radX = angleX
    local cosX, sinX = math.cos(radX), math.sin(radX)
    local y1 = y * cosX - z * sinX
    local z1 = y * sinX + z * cosX

    local radY = angleY
    local cosY, sinY = math.cos(radY), math.sin(radY)
    local x2 = x * cosY + z1 * sinY
    local z2 = -x * sinY + z1 * cosY

    local factor = scale / (distance + z2)
    local screenX = x2 * factor + love.graphics.getWidth() / 2 + 85  -- чуть правее центра
    local screenY = y1 * factor + love.graphics.getHeight() / 2
    return screenX, screenY
end

function love.update(dt)
    if showCube then
        angleX = angleX + 0.5 * dt
        angleY = angleY + 0.7 * dt
    end
end

-- ========== СОБЫТИЯ МЫШИ / КАСАНИЯ ==========
function love.mousepressed(x, y, button)
    if button == 1 then
        -- Проверка палитры
        for i, b in ipairs(paletteBlocks) do
            local bx, by = 15, 50 + (i-1)*(blockHeight+10)
            if x >= bx and x <= bx+blockWidth and y >= by and y <= by+blockHeight then
                draggingBlock = {
                    type = b.type,
                    name = b.name,
                    label = b.label
                }
                dragFromPalette = true
                return
            end
        end

        -- Проверка рабочей области (перемещение существующих)
        for i, b in ipairs(workspaceBlocks) do
            local bx = 180 + (i-1)*(blockWidth+10)
            local by = 80
            if x >= bx and x <= bx+blockWidth and y >= by and y <= by+blockHeight then
                draggingBlock = b
                dragFromPalette = false
                table.remove(workspaceBlocks, i)
                return
            end
        end

        -- Кнопка запуска
        local fx, fy = 40, love.graphics.getHeight()-50
        if math.sqrt((x-fx)^2 + (y-fy)^2) <= 24 then
            runProject()
            return
        end

        -- Кнопка Сохранить
        if x >= 5 and x <= 85 and y >= love.graphics.getHeight()-90 and y <= love.graphics.getHeight()-60 then
            saveYAML("project.yml", workspaceBlocks)
            return
        end

        -- Кнопка Загрузить
        if x >= 90 and x <= 170 and y >= love.graphics.getHeight()-90 and y <= love.graphics.getHeight()-60 then
            local loaded = loadYAML("project.yml")
            if loaded then workspaceBlocks = loaded end
            return
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and draggingBlock then
        if x >= 170 then  -- отпустили над рабочей областью
            insertBlockIntoWorkspace(draggingBlock)
        end
        draggingBlock = nil
        dragFromPalette = false
    end
end

function love.touchpressed(id, x, y)
    love.mousepressed(x, y, 1)
end

function love.touchreleased(id, x, y)
    love.mousereleased(x, y, 1)
end
