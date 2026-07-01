-- main.lua
local state = require("src.state")
local project = require("src.project")
local blocks = require("src.blocks")
local ui = require("src.ui")
local runtime = require("src.runtime")
local paint = require("src.paint")
local keyboard = require("src.keyboard")
local draw_objects = require("src.draw_objects")

function love.load()
    state.init()
    project.loadDefault()
    blocks.updateWorkspace()
    paint.init()
    runtime.compileScript()
end

function love.draw()
    local scene = project.getCurrentScene()
    love.graphics.setBackgroundColor(scene and scene.bgColor or {0.1, 0.1, 0.1})

    blocks.drawPalette()
    blocks.drawWorkspace()
    ui.drawTabs()
    ui.drawButtons()
    draw_objects.drawSceneObjects()
    keyboard.drawKeyboard()
    paint.drawPaint()
    ui.drawMessages()
end

function love.update(dt)
    blocks.updateScrolling(dt)
    runtime.update(dt)
    ui.updateLongPress(dt)
end

-- Обработка мыши / тач с блокировкой Paint при открытой клавиатуре
function love.mousepressed(x, y, button)
    if state.keyboardVisible then
        keyboard.handleTouch(x, y)
        return
    end
    if paint.handleTouch(x, y, true) then return end
    if keyboard.handleTouch(x, y) then return end
    if ui.handleClick(x, y) then return end
    if x <= state.paletteWidth then
        blocks.paletteClick(x, y)
    else
        blocks.workspaceClick(x, y)
    end
end

function love.mousereleased(x, y, button)
    if state.keyboardVisible then return end
    blocks.paletteRelease()
    blocks.workspaceRelease()
    runtime.isReleased = true
end

function love.touchmoved(id, x, y, dx, dy)
    if state.keyboardVisible then return end
    paint.handleTouch(x, y, true)
    blocks.handleTouchMove(x, y, dx, dy)
end

function love.touchpressed(id, x, y)
    if state.keyboardVisible then
        keyboard.handleTouch(x, y)
        return
    end
    love.mousepressed(x, y, 1)
end

function love.touchreleased(id, x, y)
    if state.keyboardVisible then return end
    love.mousereleased(x, y, 1)
end

function love.wheelmoved(x, y)
    blocks.handleWheel(x, y)
end

function love.textinput(t)
    keyboard.textInput(t)
end

function love.keypressed(key)
    keyboard.keyPressed(key)
end

function love.filedropped(file)
    project.handleFileDrop(file)
end
