-- main.lua
-- Pocket Cat — конструктор игр в стиле Pocket Code (Catrobat)
local State = require("src.state")
local project = require("src.project")
local runtime = require("src.runtime")
local screens = require("src.screens")
local paint = require("src.paint")

function love.load()
    State.init()
    State.fontSmall = love.graphics.newFont(13)
    State.font = love.graphics.newFont(16)
    State.fontBig = love.graphics.newFont(20)
    love.graphics.setFont(State.font)

    project.ensureLibrary()
    project.loadProjectList()
    State.screen = "home"
end

function love.draw()
    love.graphics.setBackgroundColor(0.02, 0.12, 0.16)
    screens.draw()
end

function love.update(dt)
    runtime.update(dt)
end

function love.mousepressed(x, y, button)
    screens.mousepressed(x, y)
end

function love.mousereleased(x, y, button)
    screens.mousereleased(x, y)
end

function love.touchpressed(id, x, y)
    screens.mousepressed(x, y)
end

function love.touchreleased(id, x, y)
    screens.mousereleased(x, y)
end

function love.wheelmoved(x, y)
    screens.wheelmoved(x, y)
end

function love.textinput(t)
    screens.textinput(t)
end

function love.keypressed(key)
    screens.keypressed(key)
end

function love.resize(w, h)
    paint.recalcScale()
end

-- Перетаскивание файлов: образы и звуки для текущего объекта
function love.filedropped(file)
    local fname = type(file) == "string" and file or (file and file:getFilename()) or ""
    local ext = (fname:match("%.([^.]+)$") or ""):lower()
    local obj = State.currentObject()
    if ext == "png" or ext == "jpg" or ext == "jpeg" then
        love.filesystem.createDirectory("sprites")
        local dest = "sprites/" .. (fname:match("([^/\\]+)$") or "drop.png")
        local data = file and file:read() or nil
        if data then
            love.filesystem.write(dest, data)
            if obj then
                table.insert(obj.looks, {name = dest:match("([^/]+)$"), path = dest})
                State.toast("Образ добавлен: " .. dest)
            end
        end
    elseif ext == "ogg" or ext == "mp3" or ext == "wav" then
        love.filesystem.createDirectory("sounds")
        local dest = "sounds/" .. (fname:match("([^/\\]+)$") or "drop.ogg")
        local data = file and file:read() or nil
        if data then
            love.filesystem.write(dest, data)
            if obj then
                table.insert(obj.sounds, {name = dest:match("([^/]+)$"), path = dest})
                State.toast("Звук добавлен: " .. dest)
            end
        end
    else
        State.toast("Неподдерживаемый файл: " .. ext)
    end
end
