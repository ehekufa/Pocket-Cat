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

function M.handleFileDrop(file)
    -- Получаем имя файла (в LÖVE 11.4+ используется file:getFilename(), в 11.3 - file.name)
    local fname
    if type(file) == "string" then
        fname = file
    elseif file.getFilename then
        fname = file:getFilename()
    else
        fname = file.name or tostring(file)
    end
    if not fname then return end

    local ext = fname:match("%.([^.]+)$")
    if not ext then return end
    ext = ext:lower()
    local destFolder = "sprites/"
    if ext == "ogg" or ext == "mp3" or ext == "wav" then destFolder = "sounds/" end
    love.filesystem.createDirectory(destFolder)
    local destName = destFolder .. love.filesystem.getBasename(fname) .. "." .. ext
    -- Копируем файл
    local data = love.filesystem.read(fname)
    if data then
        love.filesystem.write(destName, data)
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
