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
-- ИСПРАВЛЕННАЯ ФУНКЦИЯ handleFileDrop
-- Теперь работает с любыми файлами (PNG, JPG, OGG, MP3, WAV)
-- ============================================================
function M.handleFileDrop(file)
    -- file может быть строкой (путь) или объектом File (в LÖVE 11)
    local fname
    if type(file) == "string" then
        fname = file
    elseif type(file) == "table" and file.name then
        fname = file.name
    else
        print("Unknown file type")
        return
    end

    -- Извлекаем расширение и имя без пути
    local ext = fname:match("%.([^.]+)$")
    if not ext then
        print("No extension")
        return
    end
    ext = ext:lower()

    -- Определяем папку назначения
    local destFolder = "sprites/"
    if ext == "ogg" or ext == "mp3" or ext == "wav" then
        destFolder = "sounds/"
    elseif ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "gif" then
        destFolder = "sprites/"
    else
        print("Unsupported file type: " .. ext)
        return
    end

    -- Создаём папку, если её нет
    love.filesystem.createDirectory(destFolder)

    -- Получаем имя файла без пути (базовое имя)
    local baseName = fname:match("([^/\\]+)$") or fname
    local destName = destFolder .. baseName

    -- Читаем исходный файл (если он ещё не в love.filesystem)
    -- В LÖVE файлы, перетащенные в окно, доступны через love.filesystem
    local data
    if love.filesystem.getInfo(fname) then
        data = love.filesystem.read(fname)
    else
        -- Если файл не найден в sandbox, пытаемся прочитать как обычный файл (только если разрешено)
        -- В LÖVE 11.4+ есть love.filesystem.newFile, но для простоты используем стандартный путь
        -- В GitHub Actions или настольных версиях можно использовать io.open, но это небезопасно
        -- Лучше использовать love.filesystem, если файл уже в проекте
        print("File not found in love.filesystem: " .. fname)
        return
    end

    if data then
        love.filesystem.write(destName, data)
        print("Copied to: " .. destName)
    else
        print("Failed to read file")
        return
    end

    -- Если это спрайт, прикрепляем его к текущему объекту
    if destFolder == "sprites/" then
        local obj = M.getCurrentObject()
        if obj then
            obj.image = destName
            -- Сбрасываем загруженное изображение, чтобы оно перезагрузилось
            obj.loadedImage = nil
            print("Sprite set: " .. destName)
        else
            print("No current object")
        end
    elseif destFolder == "sounds/" then
        local obj = M.getCurrentObject()
        if obj then
            obj.sound = destName
            print("Sound set: " .. destName)
        end
    end
end

return M
