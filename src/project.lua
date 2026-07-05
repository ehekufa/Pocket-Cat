-- src/project.lua
local State = require("src.state")
local blocks = require("src.blocks")
local utils = require("src.utils")
local runtime = require("src.runtime")

local M = {}

function M.defaultProject()
    return {
        scenes = {{
            name = "Scene 1",
            bgColor = {0.2,0.2,0.4},
            blocks = {},  -- блоки теперь хранятся в сцене
            objects = {{
                name = "Object 1",
                x = 200,
                y = 200,
                image = nil,
                -- blocks убраны
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
    runtime.compileScript()
end

-- Сохранение .cat с указанным именем (по умолчанию pocketcatproject.cat)
function M.saveProject(filename)
    -- Сохраняем текущие блоки в сцену перед сохранением
    blocks.saveSceneBlocks()
    
    if not filename or filename == "" then
        filename = "pocketcatproject.cat"
    end
    if not filename:match("%.cat$") then
        filename = filename .. ".cat"
    end
    local json = utils.json.encode(State.project)
    love.filesystem.write(filename, json)
    table.insert(State.messages, "Project saved as " .. filename)
    return true
end

-- Загрузка .cat по имени
function M.loadProject(filename)
    local info = love.filesystem.getInfo(filename)
    if not info then
        table.insert(State.messages, "File not found: " .. filename)
        return nil
    end
    local contents = love.filesystem.read(filename)
    if not contents then
        table.insert(State.messages, "Failed to read " .. filename)
        return nil
    end
    local data = utils.json.decode(contents)
    if data then
        State.project = data
        -- Если в сцене нет поля blocks, создаём пустой массив
        for _, sc in ipairs(State.project.scenes) do
            if not sc.blocks then sc.blocks = {} end
        end
        blocks.updateWorkspace()
        runtime.compileScript()
        table.insert(State.messages, "Project loaded from " .. filename)
        return data
    else
        table.insert(State.messages, "Invalid project file")
        return nil
    end
end

-- Получить список всех .cat файлов в папке проекта
function M.getProjectFiles()
    local files = {}
    local items = love.filesystem.getDirectoryItems(".")
    for _, item in ipairs(items) do
        if item:match("%.cat$") then
            table.insert(files, item)
        end
    end
    return files
end

-- Удалить .cat файл
function M.deleteProjectFile(filename)
    if love.filesystem.getInfo(filename) then
        love.filesystem.remove(filename)
        table.insert(State.messages, "Deleted " .. filename)
        return true
    end
    return false
end

-- Обработка перетаскивания файлов (изображения, звуки, проекты)
function M.handleFileDrop(file)
    local fname = type(file) == "string" and file or (file.name or "")
    if fname == "" then return end
    local ext = fname:match("%.([^.]+)$")
    if not ext then return end
    ext = ext:lower()
    
    -- Если перетащили .cat проект – загружаем его
    if ext == "cat" then
        M.loadProject(fname)
        return
    end
    
    -- Иначе изображения и звуки
    local destFolder = "sprites/"
    if ext == "ogg" or ext == "mp3" or ext == "wav" then
        destFolder = "sounds/"
    elseif ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "gif" then
        destFolder = "sprites/"
    else
        table.insert(State.messages, "Unsupported file type: " .. ext)
        return
    end
    
    love.filesystem.createDirectory(destFolder)
    local baseName = fname:match("([^/\\]+)$") or fname
    local destName = destFolder .. baseName
    local data
    if love.filesystem.getInfo(fname) then
        data = love.filesystem.read(fname)
    end
    if data then
        love.filesystem.write(destName, data)
        if destFolder == "sprites/" then
            local obj = M.getCurrentObject()
            if obj then
                obj.image = destName
                obj.loadedImage = nil
                table.insert(State.messages, "Sprite imported: " .. baseName)
            end
        elseif destFolder == "sounds/" then
            local obj = M.getCurrentObject()
            if obj then
                obj.sound = destName
                table.insert(State.messages, "Sound imported: " .. baseName)
            end
        end
    else
        table.insert(State.messages, "Failed to read file: " .. fname)
    end
end

return M
