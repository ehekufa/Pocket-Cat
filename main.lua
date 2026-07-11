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
    
    state.font = love.graphics.newFont(16)
    love.graphics.setFont(state.font)
    state.currentScreen = "main"
    state.projects = {}
    state.currentProjectIndex = 1
    state.showCreateProject = false
    state.newProjectName = ""
    state.selectedOrientation = "portrait"
    
    project.loadProjectList()
end

function love.draw()
    love.graphics.setBackgroundColor(0.03, 0.03, 0.06)

    if state.currentScreen == "main" then
        drawMainScreen()
    elseif state.currentScreen == "project" then
        drawProjectScreen()
    end
    
    if state.showCreateProject then
        drawCreateProjectModal()
    end
    
    paint.drawPaint()
    ui.drawMessages()
end

function drawMainScreen()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local topBar = 56
    
    ui.drawTopBar("Pocket Cat")
    
    local bannerY = topBar
    local bannerH = 180
    love.graphics.setColor(0.45, 0.66, 0.26)
    love.graphics.rectangle("fill", 0, bannerY, w, bannerH)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.ellipse("fill", w/2, bannerY + 80, 120, 100)
    love.graphics.setColor(0.13, 0.13, 0.13)
    love.graphics.circle("fill", w/2 - 80, bannerY + 40, 30)
    love.graphics.circle("fill", w/2 + 80, bannerY + 40, 30)
    love.graphics.ellipse("fill", w/2 - 40, bannerY + 75, 18, 22)
    love.graphics.ellipse("fill", w/2 + 40, bannerY + 75, 18, 22)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", w/2 - 35, bannerY + 70, 6)
    love.graphics.circle("fill", w/2 + 45, bannerY + 70, 6)
    love.graphics.setColor(0.13, 0.13, 0.13)
    love.graphics.polygon("fill", w/2 - 10, bannerY + 95, w/2 + 10, bannerY + 95, w/2, bannerY + 108)
    
    local editX = 20
    local editY = bannerY + 20
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", editX + 20, editY + 20, 25)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("E", editX + 14, editY + 10, 0, 1.2)
    
    local playX = w - 50
    local playY = bannerY + bannerH - 50
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", playX, playY, 25)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print(">", playX - 6, playY - 10, 0, 1.4)
    
    local projY = bannerY + bannerH + 10
    love.graphics.setColor(0, 0.21, 0.36)
    love.graphics.rectangle("fill", 0, projY, w, h - projY)
    
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Projects on device", 16, projY + 10)
    
    -- Список проектов (текстовый, без картинок)
    local listY = projY + 40
    local itemHeight = 40
    
    for i, proj in ipairs(state.projects) do
        local y = listY + (i - 1) * itemHeight
        if y < h then
            local isActive = (i == state.currentProjectIndex)
            
            -- Фон элемента
            if isActive then
                love.graphics.setColor(0.13, 0.53, 0.95, 0.3)
            else
                love.graphics.setColor(0.1, 0.1, 0.1)
            end
            love.graphics.rectangle("fill", 16, y, w - 32, itemHeight - 4, 6)
            
            -- Рамка для активного
            if isActive then
                love.graphics.setColor(0.13, 0.53, 0.95)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", 16, y, w - 32, itemHeight - 4, 6)
                love.graphics.setLineWidth(1)
            end
            
            -- Имя проекта
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print(proj.name, 28, y + 10)
            
            -- Маленький индикатор ориентации
            love.graphics.setColor(0.5, 0.5, 0.5)
            if proj.orientation == "portrait" then
                love.graphics.print("[P]", w - 60, y + 10)
            else
                love.graphics.print("[L]", w - 60, y + 10)
            end
            
            state["project_item_" .. i] = {x = 16, y = y, w = w - 32, h = itemHeight - 4}
        end
    end
    
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
    ui.drawTopBar("Project: " .. (state.currentProject and state.currentProject.name or "Untitled"))
    
    local scene = project.getCurrentScene()
    love.graphics.setBackgroundColor(scene and scene.bgColor or {0.1, 0.1, 0.1})
    
    blocks.drawPalette()
    blocks.drawWorkspace()
    draw_objects.drawSceneObjects()
    ui.drawFAB()
end

function drawCreateProjectModal()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    local mw = math.min(500, w - 40)
    local mh = 320
    local mx = (w - mw) / 2
    local my = (h - mh) / 2
    
    love.graphics.setColor(0, 0.18, 0.33)
    love.graphics.rectangle("fill", mx, my, mw, mh, 12)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("line", mx, my, mw, mh, 12)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Create Project", mx + 20, my + 20)
    
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Project name", mx + 20, my + 60)
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", mx + 20, my + 80, mw - 40, 36, 6)
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.rectangle("line", mx + 20, my + 80, mw - 40, 36, 6)
    love.graphics.setColor(1, 1, 1)
    if state.newProjectName ~= "" then
        love.graphics.print(state.newProjectName, mx + 28, my + 88)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Enter project name...", mx + 28, my + 88)
    end
    
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Orientation", mx + 20, my + 134)
    
    local orientY = my + 154
    local isPortrait = (state.selectedOrientation == "portrait")
    love.graphics.setColor(isPortrait and 1 or 0.3, isPortrait and 0.65 or 0.3, isPortrait and 0 or 0.3)
    love.graphics.rectangle("fill", mx + 20, orientY, 100, 50, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Portrait", mx + 30, orientY + 16)
    state.orientPortrait = {x = mx + 20, y = orientY, w = 100, h = 50}
    
    local isLandscape = (state.selectedOrientation == "landscape")
    love.graphics.setColor(isLandscape and 1 or 0.3, isLandscape and 0.65 or 0.3, isLandscape and 0 or 0.3)
    love.graphics.rectangle("fill", mx + 140, orientY, 100, 50, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Landscape", mx + 145, orientY + 16)
    state.orientLandscape = {x = mx + 140, y = orientY, w = 100, h = 50}
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", mx + mw - 160, my + mh - 50, 60, 30, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Cancel", mx + mw - 150, my + mh - 42)
    state.modalCancel = {x = mx + mw - 160, y = my + mh - 50, w = 60, h = 30}
    
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.rectangle("fill", mx + mw - 90, my + mh - 50, 70, 30, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Create", mx + mw - 78, my + mh - 42)
    state.modalCreate = {x = mx + mw - 90, y = my + mh - 50, w = 70, h = 30}
end

function love.update(dt)
    blocks.updateScrolling(dt)
    runtime.update(dt)
    ui.updateLongPress(dt)
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
    
    if ui.handleTopBarClick(x, y) then return end
    
    if state.currentScreen == "main" then
        handleMainScreenClick(x, y)
    elseif state.currentScreen == "project" then
        handleProjectScreenClick(x, y)
    end
end

function handleMainScreenClick(x, y)
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
    
    for i, proj in ipairs(state.projects) do
        local item = state["project_item_" .. i]
        if item then
            if x >= item.x and x <= item.x + item.w and y >= item.y and y <= item.y + item.h then
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
