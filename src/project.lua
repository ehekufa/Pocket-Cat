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

-- ============================================================
-- ОБРАБОТКА ПЕРЕТАСКИВАНИЯ ФАЙЛОВ (для LÖVE 11.x)
-- ============================================================
function M.handleFileDrop(file)
    -- file может быть строкой (путь) или таблицей (в LÖVE 11.x это таблица с полями)
    local filename
    if type(file) == "string" then
        filename = file
    elseif type(file) == "table" then
        -- В LÖVE 11.x в love.filedropped передаётся таблица с полями:
        -- .name (полное имя файла), .type (тип), .getBuffer() и т.д.
        -- Также может быть .getFilename() или .getName()
        if file.getName then
            filename = file:getName()
        elseif file.name then
            filename = file.name
        else
            -- Если ничего нет, пробуем получить через tostring (может вернуть путь)
            filename = tostring(file)
        end
    else
        print("Unknown file type:", type(file))
        return
    end

    if not filename or filename == "" then
        print("Empty filename")
        return
    end

    -- Определяем расширение
    local ext = filename:match("%.([^.]+)$")
    if not ext then
        print("No extension for:", filename)
        return
    end
    ext = ext:lower()

    -- Определяем папку назначения
    local destFolder = "sprites/"
    local isImage = false
    if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "gif" or ext == "bmp" then
        destFolder = "sprites/"
        isImage = true
    elseif ext == "ogg" or ext == "mp3" or ext == "wav" or ext == "flac" then
        destFolder = "sounds/"
    else
        print("Unsupported file type:", ext)
        return
    end

    -- Создаём папку, если её нет
    love.filesystem.createDirectory(destFolder)

    -- Формируем имя назначения (без пути, только имя файла)
    local baseName = filename:match("([^/\\]+)$") or filename
    local destName = destFolder .. baseName

    -- Проверяем, не существует ли уже такой файл (можно перезаписать)
    -- Для простоты перезаписываем

    -- Читаем исходный файл
    local data
    if type(file) == "table" and file.getBuffer then
        -- В LÖVE 11.x у file есть метод getBuffer() для чтения содержимого
        data = file:getBuffer()
    elseif type(file) == "table" and file.getData then
        data = file:getData()
    else
        -- Если file - строка (путь), читаем через love.filesystem.read
        local info = love.filesystem.getInfo(filename)
        if info then
            data = love.filesystem.read(filename)
        else
            -- Если файл не найден, возможно, это абсолютный путь, пытаемся прочитать через io
            local f = io.open(filename, "rb")
            if f then
                data = f:read("*all")
                f:close()
            else
                print("Cannot read file:", filename)
                return
            end
        end
    end

    if not data then
        print("Failed to read file data")
        return
    end

    -- Записываем в папку проекта
    local success = love.filesystem.write(destName, data)
    if not success then
        print("Failed to write file:", destName)
        return
    end

    -- Привязываем к текущему объекту
    local obj = M.getCurrentObject()
    if obj then
        if isImage then
            obj.image = destName
            -- Очищаем загруженное изображение, чтобы при следующей отрисовке оно перезагрузилось
            obj.loadedImage = nil
            table.insert(State.messages, "Sprite imported: " .. baseName)
        else
            obj.sound = destName
            table.insert(State.messages, "Sound imported: " .. baseName)
        end
    else
        print("No current object to attach file")
    end
end

return M
