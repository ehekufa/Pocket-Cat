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
    -- Виртуальная клавиатура больше не рисуется
    paint.drawPaint()
    ui.drawMessages()
end

function love.update(dt)
    blocks.updateScrolling(dt)
    runtime.update(dt)
    ui.updateLongPress(dt)
end

-- Обработка мыши / тач
function love.mousepressed(x, y, button)
    if state.keyboardVisible then  -- больше не используется, но оставим для совместимости
        keyboard.handleTouch(x, y)
        return
    end
    if paint.handleTouch(x, y, true) then return end
    if ui.handleClick(x, y) then return end
    if x <= state.paletteWidth then
        blocks.paletteClick(x, y)
    else
        blocks.workspaceClick(x, y)
    end
end

function love.mousereleased(x, y, button)
    blocks.paletteRelease()
    blocks.workspaceRelease()
    runtime.isReleased = true
end

function love.touchmoved(id, x, y, dx, dy)
    paint.handleTouch(x, y, true)
    blocks.handleTouchMove(x, y, dx, dy)
end

function love.touchpressed(id, x, y)
    love.mousepressed(x, y, 1)
end

function love.touchreleased(id, x, y)
    love.mousereleased(x, y, 1)
end

function love.wheelmoved(x, y)
    blocks.handleWheel(x, y)
end

-- Системный ввод текста
function love.textinput(t)
    keyboard.handleTextInput(t)
end

-- Обработка нажатий клавиш (включая Enter, Escape, Backspace)
function love.keypressed(key)
    -- Сначала обработка редактирования параметра
    keyboard.handleKeyPressed(key)
    -- Если не в режиме редактирования, обрабатываем глобальные горячие клавиши
    if not state.editingBlock then
        if key == "f5" then
            runtime.runProject()
        elseif key == "f2" then
            project.saveProject("project.cat")
        end
    end
end

function love.filedropped(file)
    project.handleFileDrop(file)
end
