-- src/project.lua
local State = require("src.state")
local blocks = require("src.blocks")
local utils = require("src.utils")

local M = {}

function M.defaultProject()
    return {
        scenes = {{
            name = "Scene 1",
            bgColor = {0.2,0.2,0.4},
            objects = {{
                name = "Object 1",
                x = 200,
                y = 200,
                image = nil,
                blocks = {}
            }}
        }},
        orientation = "portrait"
    }
end

function M.getCurrentScene()
    if not State.project then return nil end
    return State.project.scenes[State.currentSceneIdx]
end

function M.getCurrentObject()
    local s = M.getCurrentScene()
    if not s then return nil end
    return s.objects[State.currentObjectIdx]
end

function M.loadDefault()
    State.project = M.defaultProject()
    blocks.updateWorkspace()
end

function M.loadProject(filename)
    local info = love.filesystem.getInfo(filename)
    if not info then return nil end
    local contents = love.filesystem.read(filename)
    local data = utils.json.decode(contents)
    if data then
        State.project = data
        blocks.updateWorkspace()
        require("src.runtime").compileScript()
        return data
    end
    return nil
end

function M.saveProject(filename)
    local data = State.project
    local json = utils.json.encode(data)
    love.filesystem.write(filename, json)
end

function M.addScene()
    local newIdx = #State.project.scenes + 1
    table.insert(State.project.scenes, {
        name = "Scene " .. newIdx,
        bgColor = {0.2,0.2,0.4},
        objects = {{ name = "Object 1", image = nil, blocks = {} }}
    })
    State.currentSceneIdx = newIdx
    State.currentObjectIdx = 1
    blocks.updateWorkspace()
end

function M.addObject()
    local scene = M.getCurrentScene()
    if not scene then return end
    local newIdx = #scene.objects + 1
    table.insert(scene.objects, { name = "Object " .. newIdx, image = nil, blocks = {} })
    State.currentObjectIdx = newIdx
    blocks.updateWorkspace()
end

-- === ИСПРАВЛЕННАЯ ФУНКЦИЯ ДЛЯ ПЕРЕТАСКИВАНИЯ ФАЙЛОВ ===
function M.handleFileDrop(file)
    -- file может быть объектом File (в LÖVE 11+) или строкой (имя файла)
    local fname = type(file) == "table" and file:getFilename() or file
    if not fname then return end

    -- Определяем расширение
    local ext = fname:match("%.([^.]+)$")
    if not ext then return end
    ext = ext:lower()

    -- Определяем папку назначения
    local destFolder = "sprites/"
    if ext == "ogg" or ext == "mp3" or ext == "wav" then
        destFolder = "sounds/"
    end

    -- Создаём папку, если её нет
    love.filesystem.createDirectory(destFolder)

    -- Получаем имя файла без пути
    local baseName = fname:match("([^/\\]+)$") or fname
    local destName = destFolder .. baseName

    -- Копируем файл
    -- Если file - объект File, используем его методы
    if type(file) == "table" and file:getFilename then
        -- LÖVE 11+: можно прочитать содержимое через file:read()
        local data = file:read()
        if data then
            love.filesystem.write(destName, data)
        end
    else
        -- Если передана строка (имя файла) — читаем из обычной файловой системы
        -- Это не сработает в любом случае, т.к. love.filesystem не видит внешние файлы.
        -- Но мы можем использовать love.filesystem.read, если файл уже внутри .love.
        -- В случае перетаскивания обычно передаётся объект File.
        -- Добавим fallback.
        local fileHandle = io.open(fname, "rb")
        if fileHandle then
            local content = fileHandle:read("*all")
            fileHandle:close()
            love.filesystem.write(destName, content)
        else
            -- Пробуем через love.filesystem
            local data = love.filesystem.read(fname)
            if data then
                love.filesystem.write(destName, data)
            end
        end
    end

    -- Привязываем файл к текущему объекту
    local obj = M.getCurrentObject()
    if obj then
        if destFolder == "sprites/" then
            obj.image = destName
            -- Очищаем загруженное изображение, чтобы оно перезагрузилось
            obj.loadedImage = nil
            -- Также сбрасываем показ куба/сферы, показываем спрайт
            State.showImage = true
            State.showCube = false
            State.showSphere = false
        elseif destFolder == "sounds/" then
            obj.sound = destName
        end
    end
end

return M
