-- src/project.lua
-- Модель проекта: сцены, фон, объекты, образы, звуки, скрипты.
-- Сохранение в .cat (JSON). Миграция старых проектов.
local State = require("src.state")
local utils = require("src.utils")
local catalog = require("src.catalog")

local M = {}

-- ======================= БИБЛИОТЕКА СПРАЙТОВ =======================
local function encodeCanvas(canvas, path)
    local ok, data = pcall(function() return canvas:newImageData() end)
    if not ok then return false end
    local ok2 = pcall(function() data:encode("png", path) end)
    return ok2
end

local function newCanvas(w, h)
    local c = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(c)
    love.graphics.clear()
    return c
end

function M.ensureLibrary()
    love.filesystem.createDirectory("library")
    if love.filesystem.getInfo("library/clouds.png") then return end

    -- Небо (градиент)
    local sky = newCanvas(128, 128)
    for yy = 0, 127 do
        local t = yy / 127
        love.graphics.setColor(0.25 + 0.35 * t, 0.62 + 0.22 * t, 0.88 + 0.1 * t)
        love.graphics.rectangle("fill", 0, yy, 128, 1)
    end
    encodeCanvas(sky, "library/sky.png")

    -- Облака
    local clouds = newCanvas(160, 100)
    local function cloud(cx, cy, s, col)
        love.graphics.setColor(col)
        love.graphics.circle("fill", cx, cy, 14 * s)
        love.graphics.circle("fill", cx - 16 * s, cy + 5 * s, 10 * s)
        love.graphics.circle("fill", cx + 16 * s, cy + 5 * s, 11 * s)
        love.graphics.circle("fill", cx + 4 * s, cy - 8 * s, 10 * s)
    end
    cloud(45, 30, 1.1, {1, 1, 1})
    cloud(115, 25, 0.9, {0.65, 0.65, 0.65})
    cloud(40, 70, 0.8, {0.75, 0.75, 0.75})
    cloud(110, 70, 1.0, {1, 1, 1})
    encodeCanvas(clouds, "library/clouds.png")

    -- Птица (как "Животное" на скриншотах)
    local bird = newCanvas(120, 110)
    love.graphics.setColor(0.2, 0.45, 0.1)
    love.graphics.setLineWidth(3)
    love.graphics.line(18, 55, 2, 40)
    love.graphics.line(18, 60, 0, 55)
    love.graphics.line(18, 65, 4, 75)
    love.graphics.setColor(0.95, 0.78, 0.15)
    love.graphics.ellipse("fill", 55, 62, 30, 24)
    love.graphics.polygon("fill", 40, 45, 60, 30, 68, 50)
    love.graphics.setColor(0.55, 0.7, 0.2)
    love.graphics.polygon("fill", 62, 38, 70, 18, 76, 36)
    love.graphics.polygon("fill", 70, 36, 82, 20, 84, 38)
    love.graphics.circle("fill", 78, 42, 14)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", 82, 38, 7)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", 84, 38, 3)
    love.graphics.setColor(0.95, 0.6, 0.1)
    love.graphics.polygon("fill", 90, 44, 110, 52, 90, 58)
    love.graphics.setColor(0.6, 0.45, 0.1)
    love.graphics.line(30, 84, 26, 96)
    love.graphics.line(45, 86, 44, 98)
    encodeCanvas(bird, "library/bird.png")

    -- Мяч
    local ball = newCanvas(64, 64)
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.circle("fill", 32, 32, 28)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.circle("fill", 24, 22, 9)
    encodeCanvas(ball, "library/ball.png")

    -- Звезда
    local star = newCanvas(64, 64)
    love.graphics.setColor(1, 0.85, 0.1)
    local pts = {}
    for i = 0, 9 do
        local r = i % 2 == 0 and 28 or 12
        local a = -math.pi / 2 + i * math.pi / 5
        table.insert(pts, 32 + r * math.cos(a))
        table.insert(pts, 32 + r * math.sin(a))
    end
    love.graphics.polygon("fill", pts)
    encodeCanvas(star, "library/star.png")

    -- Дерево
    local tree = newCanvas(80, 96)
    love.graphics.setColor(0.45, 0.3, 0.15)
    love.graphics.rectangle("fill", 35, 55, 10, 38)
    love.graphics.setColor(0.2, 0.55, 0.2)
    love.graphics.circle("fill", 40, 38, 26)
    love.graphics.circle("fill", 24, 50, 16)
    love.graphics.circle("fill", 56, 50, 16)
    encodeCanvas(tree, "library/tree.png")

    love.graphics.setCanvas()
end

function M.libraryItems()
    return {
        {name = "Небо", path = "library/sky.png"},
        {name = "Облака", path = "library/clouds.png"},
        {name = "Птица", path = "library/bird.png"},
        {name = "Мяч", path = "library/ball.png"},
        {name = "Звезда", path = "library/star.png"},
        {name = "Дерево", path = "library/tree.png"},
    }
end

-- ======================= МОДЕЛЬ =======================
function M.defaultProject(name)
    return {
        name = name or "Мой проект",
        orientation = "portrait",
        scenes = {{
            name = "Сцена 1",
            bgColor = {0.36, 0.68, 0.92},
            bgLooks = {},
            backgroundScripts = {},
            objects = {},
        }},
    }
end

function M.makeDemoProject()
    local p = M.defaultProject("Мой проект")
    local sc = p.scenes[1]
    sc.bgLooks = {{name = "Фон 1", path = "library/sky.png"}}
    local function mkObj(name, path, x, y, scripts)
        return {name = name, x = x, y = y, size = 100, visible = true,
                looks = {{name = name, path = path}}, sounds = {}, scripts = scripts or {}}
    end
    local function blk(name, params, children)
        local d = catalog.find(name)
        local inst = catalog.instantiate(d)
        if params then
            for k, v in pairs(params) do inst.params[k] = v end
        end
        if children then inst.children = children end
        return inst
    end
    sc.objects[1] = mkObj("Облака1", "library/clouds.png", 120, 140, {
        blk("start"),
        blk("forever", nil, {blk("move", {steps = 2}), blk("bounce")}),
    })
    sc.objects[2] = mkObj("Облака2", "library/clouds.png", 260, 420, {
        blk("start"),
        blk("forever", nil, {blk("move", {steps = 1}), blk("bounce")}),
    })
    sc.objects[3] = mkObj("Животное", "library/bird.png", 200, 300, {
        blk("start"),
        blk("clone", {who = "себя"}),
    })
    return p
end

-- ======================= СОХРАНЕНИЕ =======================
function M.saveProject(filename)
    if not State.project then return false end
    filename = filename or State.currentProject and State.currentProject.filename
    if not filename then
        filename = (State.project.name or "project"):gsub("%s+", "_"):lower() .. ".cat"
    end
    if not filename:match("%.cat$") then filename = filename .. ".cat" end
    local json = utils.json.encode(State.project)
    if json then
        love.filesystem.write(filename, json)
        if State.currentProject then State.currentProject.filename = filename end
        State.toast("Проект сохранён: " .. filename)
        return true
    end
    return false
end

function M.loadProjectList()
    State.projects = {}
    local items = love.filesystem.getDirectoryItems(".") or {}
    for _, item in ipairs(items) do
        if item:match("%.cat$") then
            local contents = love.filesystem.read(item)
            if contents then
                local data = utils.json.decode(contents)
                if data and data.name then
                    table.insert(State.projects, {name = data.name, filename = item, data = data})
                end
            end
        end
    end
    table.sort(State.projects, function(a, b) return a.name < b.name end)
    if #State.projects == 0 then
        local demo = M.makeDemoProject()
        State.project = demo
        local json = utils.json.encode(demo)
        love.filesystem.write("moi_proekt.cat", json)
        table.insert(State.projects, {name = demo.name, filename = "moi_proekt.cat", data = demo})
    end
    State.currentProjectIndex = 1
    State.currentProject = State.projects[1]
    M.openProject(1)
end

-- ======================= МИГРАЦИЯ СТАРЫХ БЛОКОВ =======================
local LEGACY = {
    start = {"start"}, tap = {"tap"}, release = {"stageTap"}, touch = {"stageTap"},
    changeX = {"changeX", {d = "param"}}, changeY = {"changeY", {d = "param"}},
    setX = {"setX", {x = "param"}}, setY = {"setY", {y = "param"}},
    turn = {"turnRight", {deg = "param"}},
    showCube = {"show"}, showSphere = {"show"}, showImage = {"show"},
    hide = {"hide"}, show = {"show"},
    setSize = {"setSize", {pct = "param"}},
    penDown = {"penDown"}, penUp = {"penUp"}, penClear = {"clear"},
    penSize = {"penSize", {n = "param"}},
    playSound = {"playSound", {sound = "param"}},
    ["repeat"] = {"repeat", {times = "param"}, true}, forever = {"forever", nil, true},
    setVar = {"setVar", {val = "param"}}, changeVar = {"changeVar", {d = "param"}},
    showVar = {"showVar"}, printText = {"say", {txt = "param"}},
}

local function convertLegacy(old)
    local m = LEGACY[old.name]
    if not m then return nil end
    local desc = catalog.find(m[1])
    if not desc then return nil end
    local inst = catalog.instantiate(desc)
    if m[2] then
        for pid, src in pairs(m[2]) do
            if src == "param" and old.param ~= nil then
                inst.params[pid] = old.param
            end
        end
    end
    if m[3] and old.children then
        inst.children = {}
        for _, c in ipairs(old.children) do
            local cc = convertLegacy(c)
            if cc then table.insert(inst.children, cc) end
        end
    end
    return inst
end

function M.normalizeProject(data)
    data.scenes = data.scenes or {}
    if #data.scenes == 0 then data.scenes = {M.defaultProject().scenes[1]} end
    for _, sc in ipairs(data.scenes) do
        sc.bgLooks = sc.bgLooks or {}
        sc.backgroundScripts = sc.backgroundScripts or {}
        sc.objects = sc.objects or {}
        -- миграция: блоки сцены -> скрипты первого объекта
        if sc.blocks and #sc.blocks > 0 then
            if #sc.objects == 0 then
                table.insert(sc.objects, {name = "Объект 1", x = 200, y = 200, size = 100,
                                          visible = true, looks = {}, sounds = {}, scripts = {}})
            end
            sc.objects[1].scripts = sc.objects[1].scripts or {}
            for _, old in ipairs(sc.blocks) do
                local conv = convertLegacy(old)
                if conv then table.insert(sc.objects[1].scripts, conv) end
            end
            sc.blocks = nil
        end
        for _, obj in ipairs(sc.objects) do
            obj.x = obj.x or 200
            obj.y = obj.y or 200
            obj.size = obj.size or 100
            if obj.visible == nil then obj.visible = true end
            obj.scripts = obj.scripts or {}
            obj.sounds = obj.sounds or {}
            -- миграция старого одиночного образа
            if obj.image and (not obj.looks or #obj.looks == 0) then
                obj.looks = {{name = obj.name, path = obj.image}}
            end
            obj.looks = obj.looks or {}
        end
    end
    -- восстановить счётчик id блоков
    local maxId = 1
    local function walk(list)
        for _, b in ipairs(list or {}) do
            if b.id and b.id >= maxId then maxId = b.id + 1 end
            walk(b.children)
            walk(b.elseChildren)
        end
    end
    for _, sc in ipairs(data.scenes) do
        walk(sc.backgroundScripts)
        for _, obj in ipairs(sc.objects) do walk(obj.scripts) end
    end
    catalog.setBlockIdCounter(maxId)
    return data
end

function M.openProject(idx)
    local pr = State.projects[idx]
    if not pr then return end
    State.currentProjectIndex = idx
    State.currentProject = pr
    State.project = M.normalizeProject(utils.json.decode(love.filesystem.read(pr.filename)) or pr.data)
    State.currentSceneIdx = 1
    State.currentObjectIdx = 1
    State.scriptScroll = 0
end

function M.newProject(name)
    local p = M.defaultProject(name)
    State.project = p
    local filename = name:gsub("%s+", "_"):lower() .. ".cat"
    love.filesystem.write(filename, utils.json.encode(p))
    table.insert(State.projects, {name = name, filename = filename, data = p})
    State.currentProjectIndex = #State.projects
    State.currentProject = State.projects[#State.projects]
    State.currentSceneIdx = 1
    State.currentObjectIdx = 1
    return p
end

-- Создание объекта; lookPath может быть nil (без образа)
function M.addObject(name, lookPath)
    local sc = State.currentScene()
    if not sc then return nil end
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local obj = {
        name = name,
        x = w / 2, y = h / 2,
        size = 100, visible = true,
        looks = lookPath and {{name = name, path = lookPath}} or {},
        sounds = {},
        scripts = {},
    }
    table.insert(sc.objects, obj)
    M.saveProject()
    return obj
end

function M.deleteObject(idx)
    local sc = State.currentScene()
    if sc and sc.objects[idx] then
        table.remove(sc.objects, idx)
        M.saveProject()
    end
end

return M
