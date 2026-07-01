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
    -- file может быть объектом FileData или строкой с путём
    local fname
    local isString = type(file) == "string"
    if isString then
        fname = file
    else
        -- Если это объект, у него может быть метод getFilename или getExtension
        fname = file:getFilename() or file:getName() or tostring(file)
    end
    
    -- Если всё ещё nil, пробуем извлечь из пути
    if not fname or fname == "" then
        fname = tostring(file)
    end
    
    -- Получаем расширение (без точки)
    local ext = ""
    local dotPos = fname:find("%.[^.]+$")
    if dotPos then
        ext = fname:sub(dotPos + 1):lower()
    end
    
    local destFolder = "sprites/"
    if ext == "ogg" or ext == "mp3" or ext == "wav" then
        destFolder = "sounds/"
    end
    
    -- Получаем базовое имя без расширения
    local baseName = fname:match("^(.+)%.[^.]+$") or fname
    -- Убираем путь, оставляем только имя файла
    baseName = baseName:match("([^/\\]+)$") or baseName
    
    local destName = destFolder .. baseName .. "." .. ext
    
    -- Копируем файл
    love.filesystem.createDirectory(destFolder)
    local data
    if isString then
        data = love.filesystem.read(fname)
    else
        -- если это FileData, читаем из него
        data = file:getString()
    end
    
    if data then
        love.filesystem.write(destName, data)
    end
    
    -- Привязываем к текущему объекту
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
