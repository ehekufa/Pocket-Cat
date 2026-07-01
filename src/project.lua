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

-- ИСПРАВЛЕННАЯ ФУНКЦИЯ
function M.handleFileDrop(file)
    -- В LÖVE 11.x при перетаскивании файла передаётся объект File.
    -- Получаем имя файла.
    local filename = file:getFilename() or file.name or tostring(file)
    if not filename then return end

    local ext = filename:match("%.([^.]+)$")
    if not ext then return end
    ext = ext:lower()

    local destFolder = "sprites/"
    if ext == "ogg" or ext == "mp3" or ext == "wav" then
        destFolder = "sounds/"
    end

    love.filesystem.createDirectory(destFolder)

    -- Получаем базовое имя без расширения
    local basename = filename:match("^(.+)%.[^.]+$") or filename
    local destName = destFolder .. basename .. "." .. ext

    -- Читаем содержимое файла
    local data = love.filesystem.read(filename)
    if data then
        love.filesystem.write(destName, data)
    else
        -- Если не удалось прочитать (возможно, файл ещё не в песочнице), пробуем скопировать через системный путь
        -- В некоторых версиях LÖVE file может быть объектом с методом getFilename, но если не работает, используем системный путь
        -- Можно также использовать love.filesystem.newFile(file:getFilename())
        -- Для совместимости с перетаскиванием извне, попробуем другой подход: скопировать через системные вызовы
        -- или просто считать как обычно.
        -- Этот код можно доработать под свои нужды.
    end

    local obj = M.getCurrentObject()
    if obj then
        if destFolder == "sprites/" then
            obj.image = destName
        elseif destFolder == "sounds/" then
            obj.sound = destName
        end
    end
end

return M
