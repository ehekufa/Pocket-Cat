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
    state.selectedCategory = nil
    state.showCategoryBlocks = false
    
    project.loadProjectList()
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0.12, 0.22)

    if state.currentScreen == "main" then
        drawMainScreen()
    elseif state.currentScreen == "project" then
        drawProjectScreen()
    elseif state.currentScreen == "categories" then
        drawCategoriesScreen()
    end
    
    if state.showCreateProject then
        drawCreateProjectModal()
    end
    
    paint.drawPaint()
    drawMessages()
end

-- ==================== MAIN SCREEN ====================
function drawMainScreen()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    -- AppBar
    drawAppBar("Pocket Cat", false)
    
    -- Banner with Panda
    local bannerY = 56
    local bannerH = 200
    love.graphics.setColor(0.45, 0.66, 0.26)
    love.graphics.rectangle("fill", 0, bannerY, w, bannerH)
    
    -- Panda
    drawPanda(w/2, bannerY + 90)
    
    -- Edit banner button
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", 40, bannerY + 40, 28)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("E", 32, bannerY + 30, 0, 1.4)
    
    -- Play banner button
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", w - 40, bannerY + bannerH - 40, 28)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print(">", w - 46, bannerY + bannerH - 50, 0, 1.4)
    
    -- Projects section
    local projY = bannerY + bannerH
    love.graphics.setColor(0, 0.21, 0.36)
    love.graphics.rectangle("fill", 0, projY, w, h - projY)
    
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Projects on device", 16, projY + 12)
    
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("F", w - 30, projY + 10)
    
    -- Project cards
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
    
    -- FAB Add button
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

-- ==================== PROJECT SCREEN ====================
function drawProjectScreen()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    -- AppBar
    drawAppBar(state.currentProject and state.currentProject.name or "Untitled", true)
    
    -- Scene background
    local scene = project.getCurrentScene()
    love.graphics.setBackgroundColor(scene and scene.bgColor or {0.1, 0.1, 0.1})
    
    -- Background selector
    local bgY = 56
    love.graphics.setColor(0, 0.30, 0.50)
    love.graphics.rectangle("fill", state.paletteWidth, bgY, w - state.paletteWidth, 50)
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", state.paletteWidth + 10, bgY + 8, 40, 34, 6)
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Background", state.paletteWidth + 60, bgY + 16)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print(">", w - 30, bgY + 16)
    
    -- Actors label
    love.graphics.setColor(0.69, 0.77, 0.87)
    love.graphics.print("Actors and objects", state.paletteWidth + 16, bgY + 58)
    
    -- Blocks palette and workspace
    if state.showCategoryBlocks and state.selectedCategory then
        blocks.drawCategoryBlocks(state.selectedCategory)
    else
        blocks.drawPalette()
    end
    blocks.drawWorkspace()
    draw_objects.drawSceneObjects()
    
    -- FAB buttons
    -- Play button
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
    
    -- Add button
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
    
    -- Back button for category blocks view
    if state.showCategoryBlocks then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", 10, h - 50, 100, 32, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Back to all", 22, h - 42)
    end
end

-- ==================== CATEGORIES SCREEN ====================
function drawCategoriesScreen()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    -- AppBar
    drawAppBar("Categories", true)
    
    -- Category list with colors as in NewCatroid
    local categories = {
        {"Lego NXT", {1, 0.82, 0.32}},
        {"Lego EV3", {0.97, 0.76, 0.19}},
        {"Phiro", {0.18, 0.66, 0.71}},
        {"Events", {0.82, 0.34, 0.15}},
        {"Control", {0.96, 0.58, 0.39}},
        {"Physics", {0.26, 0.56, 0.81}},
        {"Sound", {0.24, 0.72, 0.44}},
        {"Looks", {0.41, 0.21, 0.72}},
        {"Pen", {0.12, 0.80, 0.28}},
        {"Data", {0.80, 0.18, 0.18}},
    }
    
    local y = 60
    for _, cat in ipairs(categories) do
        love.graphics.setColor(cat[2][1], cat[2][2], cat[2][3])
        love.graphics.rectangle("fill", 0, y, w, 48)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(cat[1], 20, y + 14)
        
        -- Save category position for click
        state["category_" .. cat[1]] = {x = 0, y = y, w = w, h = 48}
        y = y + 50
    end
    
    -- Bottom toast
    love.graphics.setColor(0.16, 0.71, 0.96)
    love.graphics.rectangle("fill", 0, h - 48, w, 48)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("All blocks by category. Select one.", 16, h - 34)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("OK", w - 40, h - 34)
end

-- ==================== CREATE PROJECT MODAL ====================
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
    
    -- Buttons
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

-- ==================== HELPERS ====================
function drawAppBar(title, hasBack)
    local w = love.graphics.getWidth()
    local h = 56
    
    love.graphics.setColor(0, 0.18, 0.33)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", 0, h - 4, w, 4)
    
    -- Logo
    love.graphics.setColor(1, 0.65, 0)
    love.graphics.rectangle("fill", 12, 12, 32, 32, 6)
    love.graphics.setColor(0, 0.18, 0.33)
    love.graphics.print("C", 22, 18, 0, 1.2)
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, 52, 18)
    
    if hasBack then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("<", 12, 18, 0, 1.4)
    end
    
    -- Menu button
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", w - 30, 28, 16)
    love.graphics.setColor(0, 0.18, 0.33)
    love.graphics.print("=", w - 34, 20, 0, 1.2)
end

function drawPanda(cx, cy)
    love.graphics.setColor(1, 1, 1)
    love.graphics.ellipse("fill", cx, cy, 120, 100)
    love.graphics.setColor(0.13, 0.13, 0.13)
    love.graphics.circle("fill", cx - 80, cy - 40, 30)
    love.graphics.circle("fill", cx + 80, cy - 40, 30)
    love.graphics.ellipse("fill", cx - 38, cy - 8, 18, 24)
    love.graphics.ellipse("fill", cx + 38, cy - 8, 18, 24)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", cx - 32, cy - 14, 7)
    love.graphics.circle("fill", cx + 44, cy - 14, 7)
    love.graphics.setColor(0.13, 0.13, 0.13)
    love.graphics.polygon("fill", cx - 10, cy + 10, cx + 10, cy + 10, cx, cy + 24)
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

-- ==================== INPUT HANDLERS ====================
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
    
    -- AppBar clicks
    if y <= 56 then
        if x < 40 and state.currentScreen ~= "main" then
            if state.currentScreen == "categories" then
                state.currentScreen = "project"
            else
                state.currentScreen = "main"
            end
            return
        end
        if state.currentScreen == "project" and x > love.graphics.getWidth() - 50 then
            state.currentScreen = "categories"
            return
        end
        return
    end
    
    if state.currentScreen == "main" then
        handleMainClick(x, y)
    elseif state.currentScreen == "project" then
        handleProjectClick(x, y)
    elseif state.currentScreen == "categories" then
        handleCategoriesClick(x, y)
    end
end

function handleMainClick(x, y)
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
        local card = state["project_card_" .. i]
        if card then
            if x >= card.x and x <= card.x + card.w and y >= card.y and y <= card.y + card.h then
                state.currentProjectIndex = i
                state.currentProject = proj
                project.loadProject(proj.filename)
                state.currentScreen = "project"
                state.showCategoryBlocks = false
                state.selectedCategory = nil
                return
            end
        end
    end
end

function handleProjectClick(x, y)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    -- Back to all blocks button
    if state.showCategoryBlocks then
        if x >= 10 and x <= 110 and y >= h - 50 and y <= h - 18 then
            state.showCategoryBlocks = false
            state.selectedCategory = nil
            return
        end
    end
    
    -- Play button
    if state.playButton then
        local b = state.playButton
        if (x - b.x)^2 + (y - b.y)^2 <= (b.r + 5)^2 then
            runtime.runProject()
            table.insert(state.messages, "Project started!")
            return
        end
    end
    
    -- Add button
    if state.addButtonProject then
        local b = state.addButtonProject
        if (x - b.x)^2 + (y - b.y)^2 <= (b.r + 5)^2 then
            table.insert(state.messages, "Add actor or object")
            return
        end
    end
    
    -- Background selector
    local bgY = 56
    if y >= bgY and y <= bgY + 50 and x > state.paletteWidth then
        state.currentScreen = "categories"
        return
    end
    
    -- Blocks
    if x <= state.paletteWidth then
        if state.showCategoryBlocks then
            blocks.categoryBlockClick(x, y)
        else
            blocks.paletteClick(x, y)
        end
    else
        blocks.workspaceClick(x, y)
    end
end

function handleCategoriesClick(x, y)
    local categories = {"Lego NXT", "Lego EV3", "Phiro", "Events", "Control", "Physics", "Sound", "Looks", "Pen", "Data"}
    
    for _, catName in ipairs(categories) do
        local rect = state["category_" .. catName]
        if rect then
            if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
                -- Selected category
                state.selectedCategory = catName:lower()
                state.showCategoryBlocks = true
                state.currentScreen = "project"
                table.insert(state.messages, "Category: " .. catName)
                return
            end
        end
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
