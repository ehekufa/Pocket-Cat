-- main.lua
local state = require("src.state")
local project = require("src.project")
local blocks = require("src.blocks")
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
    
    state.font = love.graphics.newFont(16)
    love.graphics.setFont(state.font)
    state.currentScreen = "main"
    state.projects = {}
    state.currentProjectIndex = 1
    state.showCreateProject = false
    state.newProjectName = ""
    state.selectedOrientation = "portrait"
    state.showCategories = false
    
    project.loadProjectList()
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0.12, 0.22)

    if state.currentScreen == "main" then
        drawMainScreen()
    elseif state.currentScreen == "project" then
        drawProjectScreen()
    end
    
    if state.showCreateProject then
        drawCreateProjectModal()
    end
    
    paint.drawPaint()
    drawMessages()
end

function drawMainScreen()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    -- AppBar
    love.graphics.setColor(0, 0.18, 0.33)
    love.graphics.rectangle("fill", 0, 0, w, 56)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", 0, 52, w, 4)
    
    -- Иконка
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.circle("fill", 28, 28, 16)
    love.graphics.setColor(0, 0.18, 0.33)
    love.graphics.circle("fill", 28, 28, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("P", 22, 20, 0, 1.2)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Pocket Cat", 52, 18)
    
    -- Кнопка информации
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", w - 30, 28, 16)
    love.graphics.setColor(0, 0.18, 0.33)
    love.graphics.print("i", w - 34, 20, 0, 1.2)
    
    -- Баннер с пандой
    local bannerY = 56
    local bannerH = 200
    love.graphics.setColor(0.45, 0.66, 0.26)
    love.graphics.rectangle("fill", 0, bannerY, w, bannerH)
    
    -- Панда
    love.graphics.setColor(1, 1, 1)
    love.graphics.ellipse("fill", w/2, bannerY + 90, 120, 100)
    love.graphics.setColor(0.13, 0.13, 0.13)
    love.graphics.circle("fill", w/2 - 80, bannerY + 50, 30)
    love.graphics.circle("fill", w/2 + 80, bannerY + 50, 30)
    love.graphics.ellipse("fill", w/2 - 38, bannerY + 82, 18, 24)
    love.graphics.ellipse("fill", w/2 + 38, bannerY + 82, 18, 24)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", w/2 - 32, bannerY + 76, 7)
    love.graphics.circle("fill", w/2 + 44, bannerY + 76, 7)
    love.graphics.setColor(0.13, 0.13, 0.13)
    love.graphics.polygon("fill", w/2 - 10, bannerY + 100, w/2 + 10, bannerY + 100, w/2, bannerY + 114)
    
    -- Кнопка редактирования баннера
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", 40, bannerY + 40, 28)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("E", 32, bannerY + 30, 0, 1.4)
    
    -- Кнопка Play на баннере
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", w - 40, bannerY + bannerH - 40, 28)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print(">", w - 46, bannerY + bannerH - 50, 0, 1.4)
    
    -- Секция проектов
    local projY = bannerY + bannerH
    love.graphics.setColor(0, 0.21, 0.36)
    love.graphics.rectangle("fill", 0, projY, w, h - projY)
    
    -- Заголовок
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Projects on device", 16, projY + 12)
    
    -- Иконка папки
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("F", w - 30, projY + 10)
    
    -- Карточки проектов
    local cardY = projY + 44
    local cardSize = 80
    local spacing = 16
    local startX = 16
    
    for i, proj in ipairs(state.projects) do
        local x = startX + (i - 1) * (cardSize + spacing)
        if x + cardSize < w then
            local isActive = (i == state.currentProjectIndex)
            
            love.graphics.setColor(0.1, 0.1, 0.1)
            love.graphics.rectangle("fill", x, cardY, cardSize, cardSize, 10)
            
            if isActive then
                love.graphics.setColor(0.13, 0.53, 0.95)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", x, cardY, cardSize, cardSize, 10)
                love.graphics.setLineWidth(1)
            end
            
            love.graphics.setColor(0.8, 0.8, 0.8)
            local name = proj.name
            if #name > 8 then name = name:sub(1, 8) end
            love.graphics.print(name, x + 6, cardY + cardSize - 18, 0, 0.7)
            
            state["project_card_" .. i] = {x = x, y = cardY, w = cardSize, h = cardSize}
        end
    end
    
    -- Кнопка Add (FAB)
    local addX = w - 60
    local addY = h - 80
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.circle("fill", addX, addY, 30)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", addX + 2, addY + 2, 30)
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.circle("fill", addX, addY, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("+", addX - 10, addY - 16, 0, 2)
    state.addButton = {x = addX, y = addY, r = 30}
end

function drawProjectScreen()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    -- AppBar
    love.graphics.setColor(0, 0.18, 0.33)
    love.graphics.rectangle("fill", 0, 0, w, 56)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", 0, 52, w, 4)
    
    -- Кнопка назад
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("<", 12, 18, 0, 1.4)
    
    -- Название проекта
    local title = state.currentProject and state.currentProject.name or "Untitled"
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, 40, 18)
    
    -- Кнопка меню (категории)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", w - 30, 28, 16)
    love.graphics.setColor(0, 0.18, 0.33)
    love.graphics.print("=", w - 34, 20, 0, 1.2)
    
    -- Фон сцены
    local scene = project.getCurrentScene()
    love.graphics.setBackgroundColor(scene and scene.bgColor or {0.1, 0.1, 0.1})
    
    -- Палитра и рабочая область
    blocks.drawPalette()
    blocks.drawWorkspace()
    draw_objects.drawSceneObjects()
    
    -- FAB кнопки
    -- Play
    local playX = w - 60
    local playY = h - 160
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.circle("fill", playX, playY, 28)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", playX + 2, playY + 2, 28)
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.circle("fill", playX, playY, 28)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(">", playX - 8, playY - 12, 0, 1.5)
    state.playButton = {x = playX, y = playY, r = 28}
    
    -- Add
    local addX = w - 60
    local addY = h - 80
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.circle("fill", addX, addY, 28)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", addX + 2, addY + 2, 28)
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.circle("fill", addX, addY, 28)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("+", addX - 10, addY - 14, 0, 2)
    state.addButtonProject = {x = addX, y = addY, r = 28}
end

function drawCreateProjectModal()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    local mw = math.min(460, w - 40)
    local mh = 300
    local mx = (w - mw) / 2
    local my = (h - mh) / 2
    
    love.graphics.setColor(0, 0.18, 0.33)
    love.graphics.rectangle("fill", mx, my, mw, mh, 12)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("line", mx, my, mw, mh, 12)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Create Project", mx + 20, my + 18)
    
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Project name", mx + 20, my + 56)
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", mx + 20, my + 76, mw - 40, 34, 6)
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.rectangle("line", mx + 20, my + 76, mw - 40, 34, 6)
    love.graphics.setColor(1, 1, 1)
    if state.newProjectName ~= "" then
        love.graphics.print(state.newProjectName, mx + 28, my + 84)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Enter project name...", mx + 28, my + 84)
    end
    
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Orientation", mx + 20, my + 126)
    
    local orientY = my + 146
    -- Portrait
    local isPortrait = (state.selectedOrientation == "portrait")
    love.graphics.setColor(isPortrait and 1 or 0.3, isPortrait and 0.65 or 0.3, isPortrait and 0 or 0.3)
    love.graphics.rectangle("fill", mx + 20, orientY, 90, 46, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Portrait", mx + 34, orientY + 14)
    state.orientPortrait = {x = mx + 20, y = orientY, w = 90, h = 46}
    
    -- Landscape
    local isLandscape = (state.selectedOrientation == "landscape")
    love.graphics.setColor(isLandscape and 1 or 0.3, isLandscape and 0.65 or 0.3, isLandscape and 0 or 0.3)
    love.graphics.rectangle("fill", mx + 130, orientY, 90, 46, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Landscape", mx + 136, orientY + 14)
    state.orientLandscape = {x = mx + 130, y = orientY, w = 90, h = 46}
    
    -- Кнопки
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", mx + mw - 150, my + mh - 46, 55, 28, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Cancel", mx + mw - 140, my + mh - 40)
    state.modalCancel = {x = mx + mw - 150, y = my + mh - 46, w = 55, h = 28}
    
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.rectangle("fill", mx + mw - 85, my + mh - 46, 65, 28, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Create", mx + mw - 74, my + mh - 40)
    state.modalCreate = {x = mx + mw - 85, y = my + mh - 46, w = 65, h = 28}
end

function drawMessages()
    local msgY = 70
    local maxMessages = 5
    local startIdx = math.max(1, #state.messages - maxMessages + 1)
    
    for i = startIdx, #state.messages do
        local msg = state.messages[i]
        if msgY < love.graphics.getHeight() - 20 then
            love.graphics.setColor(0, 0, 0, 0.6)
            local tw = love.graphics.getFont():getWidth(msg) + 20
            love.graphics.rectangle("fill", 10, msgY - 2, math.min(tw, love.graphics.getWidth() - 40), 26, 8)
            love.graphics.setColor(0.8, 0.9, 1)
            love.graphics.print(msg, 18, msgY + 2)
            msgY = msgY + 32
        end
    end
end

function love.update(dt)
    blocks.updateScrolling(dt)
    runtime.update(dt)
end

function love.mousepressed(x, y, button)
    if state.keyboardVisible then
        keyboard.handleTouch(x, y)
        return
    end
    
    if paint.handleTouch(x, y, true) then return end
    
    if state.showCreateProject then
        handleCreateProjectClick(x, y)
        return
    end
    
    -- AppBar клики
    if y <= 56 then
        -- Назад
        if x < 40 and state.currentScreen ~= "main" then
            state.currentScreen = "main"
            return
        end
        -- Меню категорий (в проекте)
        if state.currentScreen == "project" and x > love.graphics.getWidth() - 50 then
            state.showCategories = not state.showCategories
            return
        end
        return
    end
    
    if state.currentScreen == "main" then
        handleMainScreenClick(x, y)
    elseif state.currentScreen == "project" then
        handleProjectScreenClick(x, y)
    end
end

function handleMainScreenClick(x, y)
    -- Кнопка Add
    if state.addButton then
        local b = state.addButton
        if (x - b.x)^2 + (y - b.y)^2 <= (b.r + 5)^2 then
            state.showCreateProject = true
            state.newProjectName = ""
            state.selectedOrientation = "portrait"
            love.keyboard.setTextInput(true)
            return
        end
    end
    
    -- Карточки проектов
    for i, proj in ipairs(state.projects) do
        local card = state["project_card_" .. i]
        if card then
            if x >= card.x and x <= card.x + card.w and y >= card.y and y <= card.y + card.h then
                state.currentProjectIndex = i
                state.currentProject = proj
                project.loadProject(proj.filename)
                state.currentScreen = "project"
                return
            end
        end
    end
end

function handleProjectScreenClick(x, y)
    -- FAB кнопки
    if state.playButton then
        local b = state.playButton
        if (x - b.x)^2 + (y - b.y)^2 <= (b.r + 5)^2 then
            runtime.runProject()
            table.insert(state.messages, "Project started!")
            return
        end
    end
    
    if state.addButtonProject then
        local b = state.addButtonProject
        if (x - b.x)^2 + (y - b.y)^2 <= (b.r + 5)^2 then
            table.insert(state.messages, "Add actor or object")
            return
        end
    end
    
    -- Блоки
    if x <= state.paletteWidth then
        blocks.paletteClick(x, y)
    else
        blocks.workspaceClick(x, y)
    end
end

function handleCreateProjectClick(x, y)
    if state.orientPortrait then
        local b = state.orientPortrait
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            state.selectedOrientation = "portrait"
            return
        end
    end
    
    if state.orientLandscape then
        local b = state.orientLandscape
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            state.selectedOrientation = "landscape"
            return
        end
    end
    
    if state.modalCancel then
        local b = state.modalCancel
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            state.showCreateProject = false
            state.newProjectName = ""
            love.keyboard.setTextInput(false)
            return
        end
    end
    
    if state.modalCreate then
        local b = state.modalCreate
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            if state.newProjectName ~= "" then
                local proj = project.createNewProject(state.newProjectName, state.selectedOrientation)
                table.insert(state.projects, proj)
                state.currentProjectIndex = #state.projects
                state.currentProject = proj
                state.showCreateProject = false
                state.newProjectName = ""
                love.keyboard.setTextInput(false)
                state.currentScreen = "project"
                table.insert(state.messages, "Project created: " .. proj.name)
            end
            return
        end
    end
end

function love.textinput(t)
    if state.showCreateProject then
        state.newProjectName = state.newProjectName .. t
    else
        keyboard.handleTextInput(t)
    end
end

function love.keypressed(key)
    if state.showCreateProject then
        if key == "return" or key == "kpenter" then
            if state.newProjectName ~= "" then
                local proj = project.createNewProject(state.newProjectName, state.selectedOrientation)
                table.insert(state.projects, proj)
                state.currentProjectIndex = #state.projects
                state.currentProject = proj
                state.showCreateProject = false
                state.newProjectName = ""
                love.keyboard.setTextInput(false)
                state.currentScreen = "project"
                table.insert(state.messages, "Project created: " .. proj.name)
            end
        elseif key == "escape" then
            state.showCreateProject = false
            state.newProjectName = ""
            love.keyboard.setTextInput(false)
        elseif key == "backspace" then
            state.newProjectName = state.newProjectName:sub(1, -2)
        end
        return
    end
    
    keyboard.handleKeyPressed(key)
    if not state.editingBlock then
        if key == "f5" then
            runtime.runProject()
        elseif key == "f2" then
            project.saveProject("project.cat")
        end
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

function love.filedropped(file)
    project.handleFileDrop(file)
end

function love.resize(w, h)
    state.windowWidth = w
    state.windowHeight = h
    state.paletteWidth = math.min(200, w * 0.25)
    blocks.calculateHeights()
end
