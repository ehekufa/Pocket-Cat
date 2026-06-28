-- src/project.lua
local State = require("src.state")
local blocks = require("src.blocks")

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
                blocks = {
                    {type="event", name="start", label="when start", category="event"},
                    {type="action", name="showCube", label="show cube", category="looks"}
                }
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
    local project = {scenes = {}}
    local currentScene, currentObject, currentBlock = nil, nil, nil
    for line in contents:gmatch("[^\r\n]+") do
        if line:match("^  %- name: (.+)") then
            local name = line:match("name: (.+)"):gsub("^%s+", ""):gsub("%s+$", "")
            currentScene = {name = name, bgColor = {0.2,0.2,0.4}, objects = {}}
            table.insert(project.scenes, currentScene)
        elseif line:match("^    bgColor: %[(.+)%]") then
            local vals = line:match("bgColor: %[(.+)%]")
            if currentScene then
                local r,g,b = vals:match("([%d.]+),([%d.]+),([%d.]+)")
                currentScene.bgColor = {tonumber(r), tonumber(g), tonumber(b)}
            end
        elseif line:match("^      %- name: (.+)") then
            local name = line:match("name: (.+)"):gsub("^%s+", ""):gsub("%s+$", "")
            currentObject = {name = name, image = nil, x=200, y=200, blocks = {}}
            table.insert(currentScene.objects, currentObject)
        elseif line:match("^        x: (.+)") then
            if currentObject then currentObject.x = tonumber(line:match("x: (.+)")) or 200 end
        elseif line:match("^        y: (.+)") then
            if currentObject then currentObject.y = tonumber(line:match("y: (.+)")) or 200 end
        elseif line:match("^        image: (.+)") then
            if currentObject then currentObject.image = line:match("image: (.+)") end
        elseif line:match("^          %- type: (.+)") then
            local typ = line:match("type: (%w+)")
            currentBlock = {type = typ}
            table.insert(currentObject.blocks, currentBlock)
        elseif line:match("^            name: (.+)") then
            if currentBlock then currentBlock.name = line:match("name: (.+)") end
        elseif line:match("^            param: (.+)") then
            if currentBlock then
                local p = line:match("param: (.+)"):gsub("^%s*(.-)%s*$", "")
                if tonumber(p) then p = tonumber(p) end
                currentBlock.param = p
            end
        elseif line:match("^            category: (.+)") then
            if currentBlock then currentBlock.category = line:match("category: (.+)") end
        end
    end
    return project
end

function M.saveProject(filename)
    local lines = {"scenes:"}
    for si, scene in ipairs(State.project.scenes) do
        table.insert(lines, "  - name: " .. scene.name)
        table.insert(lines, "    bgColor: [" .. table.concat(scene.bgColor, ",") .. "]")
        table.insert(lines, "    objects:")
        for oi, obj in ipairs(scene.objects) do
            table.insert(lines, "      - name: " .. obj.name)
            if obj.image then table.insert(lines, "        image: " .. obj.image) end
            table.insert(lines, "        x: " .. (obj.x or 200))
            table.insert(lines, "        y: " .. (obj.y or 200))
            table.insert(lines, "        blocks:")
            for _, block in ipairs(obj.blocks) do
                table.insert(lines, "          - type: " .. block.type)
                table.insert(lines, "            name: " .. block.name)
                if block.param then table.insert(lines, "            param: " .. tostring(block.param)) end
                if block.category then table.insert(lines, "            category: " .. block.category) end
            end
        end
    end
    love.filesystem.write(filename, table.concat(lines, "\n"))
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
    local fname = file.name or file
    local ext = fname:match("%.([^.]+)$"):lower()
    local destFolder = "sprites/"
    if ext == "ogg" or ext == "mp3" or ext == "wav" then destFolder = "sounds/" end
    love.filesystem.createDirectory(destFolder)
    local destName = destFolder .. love.filesystem.getBasename(fname) .. "." .. ext
    local data = love.filesystem.read(fname)
    if data then love.filesystem.write(destName, data) end
    local obj = M.getCurrentObject()
    if obj then
        if destFolder == "sprites/" then obj.image = destName
        elseif destFolder == "sounds/" then obj.sound = destName end
    end
end

return M
