-- src/screens.lua
-- Все экраны приложения в стиле Pocket Code + диалоги и оверлеи
local State = require("src.state")
local theme = require("src.theme")
local ui = require("src.ui")
local blocks = require("src.blocks")
local catalog = require("src.catalog")
local project = require("src.project")
local runtime = require("src.runtime")
local draw_objects = require("src.draw_objects")
local paint = require("src.paint")

local M = {}

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end

-- ========================= ВСПОМОГАТЕЛЬНЫЕ =========================
local function openInput(title, text, commit)
    State.input = {title = title, text = text or "", commit = commit}
    love.keyboard.setTextInput(true)
end

local function closeInput(apply)
    if not State.input then return end
    if apply and State.input.commit then State.input.commit(State.input.text) end
    State.input = nil
    love.keyboard.setTextInput(false)
end

local function dynOptions(dyn)
    local sc = State.currentScene()
    local obj = State.currentObject()
    local out = {}
    local function names(list)
        for _, it in ipairs(list or {}) do table.insert(out, it.name) end
    end
    if dyn == "objects" then names(sc and sc.objects)
    elseif dyn == "objectsSelf" then
        out = {"себя"}
        names(sc and sc.objects)
    elseif dyn == "looks" then names(obj and obj.looks)
    elseif dyn == "sounds" then names(obj and obj.sounds)
    elseif dyn == "scenes" then
        for _, s in ipairs(State.project and State.project.scenes or {}) do table.insert(out, s.name) end
    elseif dyn == "backgrounds" then names(sc and sc.bgLooks)
    end
    if #out == 0 then out = {"—"} end
    return out
end

local function openDropdown(x, y, options, fn)
    State.dropdown = {x = math.min(x, W() - 220), y = math.min(y, H() - #options * 40 - 20), options = options, fn = fn}
end

-- ========================= ДОМАШНИЙ ЭКРАН =========================
local function drawHome()
    local w, h = W(), H()
    theme.setColor(theme.bg)
    love.graphics.rectangle("fill", 0, 0, w, h)
    ui.appBar("Покет Код", {logo = true, help = true, menu = true})

    local prevH = math.floor(h * 0.45)
    local sc = State.currentScene()
    if sc then draw_objects.drawPreview(sc, 0, theme.appbarH, w, prevH) end

    -- кнопка редактирования по центру
    local cx, cy = w / 2, theme.appbarH + prevH / 2
    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.circle("line", cx, cy, 52)
    love.graphics.setLineWidth(8)
    love.graphics.circle("line", cx, cy, 48)
    love.graphics.setLineWidth(1)
    ui.icon("pencil", cx, cy, 44, {1, 1, 1})
    ui.addHit("home_edit", cx - 55, cy - 55, 110, 110)

    -- кнопка запуска
    local px, py = w - 52, theme.appbarH + prevH - 52
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", px, py, 30)
    ui.icon("play", px + 2, py, 30, {0.45, 0.45, 0.45})
    ui.addHit("home_play", px - 32, py - 32, 64, 64)

    -- пункты меню
    local rowY = theme.appbarH + prevH
    theme.setColor(theme.bg)
    love.graphics.rectangle("fill", 0, rowY, w, h - rowY)
    local rows = {
        {"Проекты на устройстве", "home_projects"},
        {"Сообщество Catrobat", "home_community"},
    }
    for i, r in ipairs(rows) do
        local y = rowY + 10 + (i - 1) * 78
        love.graphics.setFont(State.fontBig)
        theme.setColor(theme.textDim)
        love.graphics.print(r[1], 24, y + 24)
        ui.icon("arrow", w - 40, y + 34, 24, theme.textDim)
        ui.addHit(r[2], 0, y, w, 78)
    end

    ui.fab("home_add", w - 56, h - 64, "plus")
end

-- ========================= СПИСОК ПРОЕКТОВ =========================
local function drawProjects()
    local w, h = W(), H()
    theme.setColor(theme.bg)
    love.graphics.rectangle("fill", 0, 0, w, h)
    ui.appBar("Проекты на устройстве", {back = true})

    local y = theme.appbarH + 8 - (State.scroll.projects or 0)
    for i, p in ipairs(State.projects) do
        theme.setColor(theme.bgDark)
        love.graphics.rectangle("fill", 0, y, w, 64)
        theme.setColor(theme.bg)
        love.graphics.rectangle("fill", 0, y + 62, w, 2)
        -- миниатюра
        local sc = (p.data and p.data.scenes and p.data.scenes[1]) or nil
        if sc then
            love.graphics.setScissor(12, y + 8, 48, 48)
            draw_objects.drawPreview(sc, 12, y + 8, 48, 48)
            love.graphics.setScissor()
        end
        love.graphics.setFont(State.fontBig)
        theme.setColor(theme.textDim)
        love.graphics.print(p.name, 76, y + 20)
        ui.addHit("project_open_" .. i, 0, y, w - 56, 64)
        ui.icon("dots", w - 28, y + 32, 20, theme.textDim)
        ui.addHit("project_menu_" .. i, w - 52, y, 52, 64)
        y = y + 66
    end
    ui.fab("projects_add", w - 56, h - 64, "plus")
end

-- ========================= ЭКРАН ПРОЕКТА =========================
local function drawProject()
    local w, h = W(), H()
    theme.setColor(theme.bg)
    love.graphics.rectangle("fill", 0, 0, w, h)
    ui.appBar(State.project and State.project.name or "Мой проект", {back = true, menu = true})

    local sc = State.currentScene()
    if not sc then return end
    local y = theme.appbarH

    -- строка фона
    theme.setColor(theme.bg)
    love.graphics.rectangle("fill", 0, y, w, 84)
    local bgImg = sc.bgLooks[1] and ui.loadImage(sc.bgLooks[1].path) or nil
    if bgImg then
        ui.thumb(bgImg, 20, y + 10, 64)
    else
        theme.setColor({0.4, 0.75, 0.95})
        love.graphics.rectangle("fill", 20, y + 10, 64, 64, 10, 10)
    end
    love.graphics.setFont(State.fontBig)
    theme.setColor(theme.textDim)
    love.graphics.print("Фон", 104, y + 30)
    ui.addHit("project_bg", 0, y, w, 84)
    y = y + 84

    -- заголовок секции
    theme.setColor(theme.bgDark)
    love.graphics.rectangle("fill", 0, y, w, 52)
    love.graphics.setFont(State.fontBig)
    theme.setColor(theme.text)
    love.graphics.print("Актеры и объекты", 20, y + 15)
    y = y + 52

    -- список объектов
    y = y - (State.scroll.project or 0)
    for i, obj in ipairs(sc.objects) do
        theme.setColor(theme.bg)
        love.graphics.rectangle("fill", 0, y, w, 96)
        theme.setColor(theme.bgDark)
        love.graphics.rectangle("fill", 0, y + 94, w, 2)
        ui.icon("handle", 26, y + 48, 26, {0.1, 0.3, 0.4})
        local img = obj.looks and obj.looks[1] and ui.loadImage(obj.looks[1].path) or nil
        ui.thumb(img, 60, y + 14, 68)
        love.graphics.setFont(State.fontBig)
        theme.setColor(theme.textDim)
        love.graphics.print(obj.name, 150, y + 36)
        ui.addHit("object_open_" .. i, 0, y, w - 52, 96)
        ui.icon("dots", w - 26, y + 48, 20, theme.textDim)
        ui.addHit("object_menu_" .. i, w - 52, y, 52, 96)
        y = y + 96
    end

    ui.fab("project_play", w - 56, h - 148, "play")
    ui.fab("project_add", w - 56, h - 64, "plus")
end

-- ========================= ЭКРАН ОБЪЕКТА =========================
local function drawObject()
    local w, h = W(), H()
    theme.setColor(theme.stageDark)
    love.graphics.rectangle("fill", 0, 0, w, h)
    local isBg = State.currentObjectIdx == 0
    local obj = State.currentObject()
    local title = isBg and "Фон" or (obj and obj.name or "Объект")
    ui.appBar(title, {back = true, menu = true})

    -- вкладки
    local tabY = theme.appbarH
    local tabH = 48
    theme.setColor(theme.appbar)
    love.graphics.rectangle("fill", 0, tabY, w, tabH)
    local tabs = {{"scripts", "script"}, {"looks", "eye"}, {"sounds", "speaker"}}
    for i, t in ipairs(tabs) do
        local tx = (i - 0.5) * w / 3
        local active = State.tab == t[1]
        ui.icon(t[2], tx, tabY + tabH / 2, 24, active and {0.75, 0.9, 1} or theme.textDim)
        if active then
            theme.setColor({0.75, 0.9, 1})
            love.graphics.rectangle("fill", (i - 1) * w / 3, tabY + tabH - 3, w / 3, 3)
        end
        ui.addHit("tab_" .. t[1], (i - 1) * w / 3, tabY, w / 3, tabH)
    end

    local areaY = tabY + tabH
    if State.tab == "scripts" then
        blocks.drawScripts(0, areaY, w, h - areaY - 120)
    elseif State.tab == "looks" then
        drawLooksList(areaY)
    elseif State.tab == "sounds" then
        drawSoundsList(areaY)
    end

    ui.fab("object_play", w - 56, h - 148, "play")
    ui.fab("object_add", w - 56, h - 64, "plus")
end

function drawLooksList(areaY)
    local w, h = W(), H()
    local isBg = State.currentObjectIdx == 0
    local looks = isBg and (State.currentScene().bgLooks or {})
        or (State.currentObject() and State.currentObject().looks or {})
    local y = areaY + 8 - (State.scroll.looks or 0)
    for i, l in ipairs(looks) do
        local img = ui.loadImage(l.path)
        ui.thumb(img, 20, y + 8, 64)
        love.graphics.setFont(State.fontBig)
        theme.setColor(theme.textDim)
        love.graphics.print(l.name, 104, y + 28)
        ui.icon("dots", w - 26, y + 40, 20, theme.textDim)
        ui.addHit("look_menu_" .. i, w - 52, y, 52, 80)
        y = y + 88
    end
    if #looks == 0 then
        love.graphics.setFont(State.font)
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.print("Нет образов. Нажмите «+», чтобы добавить.", 20, areaY + 24)
    end
end

function drawSoundsList(areaY)
    local w = W()
    local obj = State.currentObject()
    local sounds = (obj and obj.sounds) or {}
    local y = areaY + 8
    for i, s in ipairs(sounds) do
        ui.icon("speaker", 36, y + 40, 24, theme.textDim)
        love.graphics.setFont(State.fontBig)
        theme.setColor(theme.textDim)
        love.graphics.print(s.name, 70, y + 28)
        ui.icon("dots", w - 26, y + 40, 20, theme.textDim)
        ui.addHit("sound_menu_" .. i, w - 52, y, 52, 80)
        y = y + 88
    end
    if #sounds == 0 then
        love.graphics.setFont(State.font)
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.print("Нет звуков. Перетащите .ogg/.mp3 в папку проекта.", 20, areaY + 24)
    end
end

-- ========================= КАТЕГОРИИ =========================
local function drawCategories()
    local w, h = W(), H()
    theme.setColor({0.02, 0.12, 0.16})
    love.graphics.rectangle("fill", 0, 0, w, h)
    ui.appBar("Категории", {back = true, search = true})

    local rowH = math.max(64, math.floor((h - theme.appbarH - 8) / #catalog.CATEGORIES) - 4)
    local y = theme.appbarH
    for _, cat in ipairs(catalog.CATEGORIES) do
        theme.setColor(theme.catColor(cat.id))
        love.graphics.rectangle("fill", 0, y, w, rowH)
        theme.setColor({0, 0, 0})
        love.graphics.rectangle("fill", 0, y + rowH, w, 3)
        love.graphics.setFont(State.fontBig)
        love.graphics.setColor(0.85, 0.9, 0.92)
        love.graphics.print(cat.name, 28, y + rowH / 2 - 11)
        ui.addHit("cat_" .. cat.id, 0, y, w, rowH)
        y = y + rowH + 3
    end
end

-- ========================= БЛОКИ КАТЕГОРИИ =========================
local function drawCatBlocks()
    local w = W()
    local cat = State.selectedCategory
    local catName = cat
    for _, c in ipairs(catalog.CATEGORIES) do
        if c.id == cat then catName = c.name end
    end
    theme.setColor(theme.stageDark)
    love.graphics.rectangle("fill", 0, 0, w, H())
    ui.appBar(catName, {back = true})
    blocks.drawCatalog(theme.appbarH)
end

-- ========================= ДИАЛОГИ =========================
local SOURCE_ITEMS = {
    {id = "paint", icon = "brush", label = "Нарисовать"},
    {id = "library", icon = "searchimage", label = "Загрузить из библиотеки"},
    {id = "gallery", icon = "image", label = "Загрузить из галереи"},
    {id = "camera", icon = "camera", label = "Сделать снимок"},
    {id = "portfolio", icon = "clipboard", label = "Портфель"},
    {id = "local", icon = "addbox", label = "Локальные актеры и объекты"},
    {id = "empty", icon = "plus", label = "Пустой объект"},
    {id = "localproj", icon = "addbox", label = "Загрузить из локальных проектов"},
}

local function drawSourceDialog()
    local d = State.dialog
    local mw = math.min(420, W() - 40)
    local mh = math.min(H() - 60, 560)
    local mx, my = ui.dialogFrame("Новый актер или объект", mw, mh)
    local cols = 2
    local cw = (mw - 40) / cols
    for i, it in ipairs(SOURCE_ITEMS) do
        if d.mode == "look" and (it.id == "empty" or it.id == "local" or it.id == "localproj") then
            -- для образов эти варианты не нужны
        else
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local x = mx + 20 + col * cw
            local y = my + 70 + row * 118
            ui.icon(it.icon, x + cw / 2, y + 24, 34, {1, 1, 1})
            love.graphics.setFont(State.font)
            theme.setColor(theme.dialogText)
            -- перенос длинных подписей
            local words = {}
            for wd in it.label:gmatch("%S+") do table.insert(words, wd) end
            local line1, line2 = "", ""
            for _, wd in ipairs(words) do
                if State.font:getWidth(line1 .. " " .. wd) < cw - 20 and line2 == "" then
                    line1 = line1 == "" and wd or line1 .. " " .. wd
                else
                    line2 = line2 == "" and wd or line2 .. " " .. wd
                end
            end
            love.graphics.print(line1, x + cw / 2 - State.font:getWidth(line1) / 2, y + 50)
            if line2 ~= "" then
                love.graphics.print(line2, x + cw / 2 - State.font:getWidth(line2) / 2, y + 70)
            end
            ui.addHit("source_" .. it.id, x, y - 8, cw, 108)
        end
    end
end

local function drawNameDialog()
    local d = State.dialog
    local mw = math.min(440, W() - 40)
    local mh = 240
    local mx, my = ui.dialogFrame(d.title, mw, mh)
    love.graphics.setFont(State.fontSmall)
    theme.setColor(theme.linkBlue)
    love.graphics.print(d.fieldLabel or "Название актера или объекта", mx + 24, my + 62)
    -- поле
    love.graphics.setFont(State.fontBig)
    local text = d.text or ""
    theme.setColor({0.45, 0.55, 0.6})
    love.graphics.rectangle("fill", mx + 24, my + 82, math.max(State.fontBig:getWidth(text) + 8, 200), 26)
    theme.setColor(theme.text)
    love.graphics.print(text, mx + 28, my + 86)
    theme.setColor(theme.linkBlue)
    love.graphics.rectangle("fill", mx + 24, my + 112, mw - 48, 2)
    ui.addHit("name_field", mx + 24, my + 70, mw - 48, 50)
    if d.note then
        love.graphics.setFont(State.font)
        theme.setColor(theme.dialogText)
        local note = d.note
        -- простой перенос
        local line, yy = "", my + 132
        for wd in note:gmatch("%S+") do
            if State.font:getWidth(line .. " " .. wd) > mw - 60 then
                love.graphics.print(line, mx + 24, yy)
                line = wd
                yy = yy + 22
            else
                line = line == "" and wd or line .. " " .. wd
            end
        end
        love.graphics.print(line, mx + 24, yy)
    end
    ui.dialogButtons(mx, my, mw, mh, d.okText or "ОК")
end

local function drawLibraryDialog()
    local d = State.dialog
    local mw = math.min(440, W() - 40)
    local items = project.libraryItems()
    local mh = math.min(H() - 80, 90 + #items * 72)
    local mx, my = ui.dialogFrame("Библиотека", mw, mh)
    for i, it in ipairs(items) do
        local y = my + 64 + (i - 1) * 72
        ui.thumb(ui.loadImage(it.path), mx + 20, y, 56)
        love.graphics.setFont(State.fontBig)
        theme.setColor(theme.dialogText)
        love.graphics.print(it.name, mx + 92, y + 18)
        ui.addHit("lib_" .. i, mx + 12, y - 4, mw - 24, 68)
    end
end

local function drawDialog()
    local d = State.dialog
    if not d then return end
    if d.kind == "source" then drawSourceDialog()
    elseif d.kind == "name" then drawNameDialog()
    elseif d.kind == "library" then drawLibraryDialog()
    end
end

-- ========================= МЕНЮ / DROPDOWN =========================
local function drawMenu()
    local m = State.menu
    if not m then return end
    love.graphics.setFont(State.font)
    local wMax = 0
    for _, it in ipairs(m.items) do
        wMax = math.max(wMax, State.font:getWidth(it.label))
    end
    local mw = wMax + 40
    local mh = #m.items * 44 + 8
    local x = math.min(m.x, W() - mw - 4)
    local y = math.min(m.y, H() - mh - 4)
    love.graphics.setColor(0.13, 0.13, 0.15, 0.97)
    love.graphics.rectangle("fill", x, y, mw, mh, 6, 6)
    for i, it in ipairs(m.items) do
        local iy = y + 4 + (i - 1) * 44
        theme.setColor(theme.text)
        love.graphics.print(it.label, x + 20, iy + 12)
        ui.addHit("menu_" .. i, x, iy, mw, 44)
    end
end

local function drawDropdown()
    local d = State.dropdown
    if not d then return end
    love.graphics.setFont(State.font)
    local wMax = 60
    for _, op in ipairs(d.options) do
        wMax = math.max(wMax, State.font:getWidth(tostring(op)))
    end
    local mw = wMax + 40
    local mh = #d.options * 40 + 8
    love.graphics.setColor(0.13, 0.13, 0.15, 0.97)
    love.graphics.rectangle("fill", d.x, d.y, mw, mh, 6, 6)
    for i, op in ipairs(d.options) do
        local iy = d.y + 4 + (i - 1) * 40
        theme.setColor(theme.text)
        love.graphics.print(tostring(op), d.x + 20, iy + 10)
        ui.addHit("dd_" .. i, d.x, iy, mw, 40)
    end
end

local function drawInputBar()
    local inp = State.input
    if not inp then return end
    local w, h = W(), H()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    local bh = 96
    theme.setColor(theme.dialogBg)
    love.graphics.rectangle("fill", 0, h - bh, w, bh)
    love.graphics.setFont(State.fontSmall)
    theme.setColor(theme.linkBlue)
    love.graphics.print(inp.title, 16, h - bh + 8)
    love.graphics.setFont(State.fontBig)
    theme.setColor(theme.text)
    love.graphics.print(inp.text .. "_", 16, h - bh + 34)
    theme.setColor(theme.linkBlue)
    love.graphics.rectangle("fill", 16, h - bh + 62, w - 32, 2)
    ui.icon("check", w - 96, h - bh / 2, 26, theme.linkBlue)
    ui.addHit("input_ok", w - 120, h - bh, 60, bh)
    ui.icon("close", w - 40, h - bh / 2, 24, theme.linkBlue)
    ui.addHit("input_cancel", w - 64, h - bh, 64, bh)
end

-- ========================= РАНТАЙМ-ОВЕРЛЕЙ =========================
local function drawRuntimeOverlay()
    local w = W()
    draw_objects.drawRuntime()
    ui.appBar(State.project and State.project.name or "", {back = true})
    -- кнопка стоп
    theme.setColor(theme.accent)
    love.graphics.circle("fill", w - 40, theme.appbarH + 40, 24)
    ui.icon("stop", w - 40, theme.appbarH + 40, 22, {1, 1, 1})
    ui.addHit("runtime_stop", w - 66, theme.appbarH + 14, 52, 52)
    -- запрос ответа
    local rt = State.rt
    if rt and rt.asking then
        local h2 = H()
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, h2 - 96, w, 96)
        love.graphics.setFont(State.font)
        theme.setColor(theme.text)
        love.graphics.print(rt.asking.q, 16, h2 - 88)
        love.graphics.setFont(State.fontBig)
        theme.setColor(theme.linkBlue)
        love.graphics.print((rt.asking.text or "") .. "_", 16, h2 - 60)
        ui.icon("check", w - 50, h2 - 48, 26, theme.linkBlue)
        ui.addHit("ask_ok", w - 80, h2 - 96, 80, 96)
    end
end

-- ========================= ГЛАВНАЯ ОТРИСОВКА =========================
function M.draw()
    ui.resetHits()
    if State.running then
        drawRuntimeOverlay()
    else
        if State.screen == "home" then drawHome()
        elseif State.screen == "projects" then drawProjects()
        elseif State.screen == "project" then drawProject()
        elseif State.screen == "object" then drawObject()
        elseif State.screen == "categories" then drawCategories()
        elseif State.screen == "catblocks" then drawCatBlocks()
        end
        paint.drawPaint()
        drawDialog()
        drawMenu()
        drawDropdown()
        drawInputBar()
    end
    ui.drawMessages()
end

-- ========================= ВВОД =========================
local function handleAppBarHit(id)
    if id == "appbar_back" then
        if State.screen == "categories" then
            State.screen = "object"
        elseif State.screen == "catblocks" then
            State.screen = State.insertTarget and "object" or "object"
            State.insertTarget = nil
        elseif State.screen == "object" then
            State.screen = "project"
        elseif State.screen == "project" then
            State.screen = "home"
        elseif State.screen == "projects" then
            State.screen = "home"
        end
        return true
    elseif id == "appbar_menu" then
        openScreenMenu()
        return true
    elseif id == "appbar_help" then
        State.toast("Покет Код: конструктор игр с блоками, как в Pocket Code")
        return true
    elseif id == "appbar_search" then
        State.toast("Поиск по блокам скоро будет!")
        return true
    end
    return false
end

function openScreenMenu()
    local items = {}
    if State.screen == "project" then
        items = {
            {label = "Сохранить", fn = function() project.saveProject() end},
            {label = "Переименовать проект", fn = function()
                openInput("Название проекта", State.project.name, function(v)
                    if v ~= "" then
                        State.project.name = v
                        State.currentProject.name = v
                        project.saveProject()
                    end
                end)
            end},
            {label = "Удалить проект", fn = function()
                local fname = State.currentProject.filename
                love.filesystem.remove(fname)
                project.loadProjectList()
                State.screen = "home"
                State.toast("Проект удалён")
            end},
        }
    elseif State.screen == "object" then
        items = {
            {label = "Сохранить", fn = function() project.saveProject() end},
        }
        if State.currentObjectIdx > 0 then
            table.insert(items, {label = "Переименовать объект", fn = function()
                openInput("Название актера или объекта", State.currentObject().name, function(v)
                    if v ~= "" then State.currentObject().name = v; project.saveProject() end
                end)
            end})
            table.insert(items, {label = "Удалить объект", fn = function()
                project.deleteObject(State.currentObjectIdx)
                State.screen = "project"
                State.toast("Объект удалён")
            end})
        end
    elseif State.screen == "home" then
        items = {
            {label = "О приложении", fn = function()
                State.toast("Pocket Cat — конструктор в духе Pocket Code (Catrobat)")
            end},
        }
    end
    if #items > 0 then
        State.menu = {x = W() - 220, y = theme.appbarH, items = items}
    end
end

local function onSourcePicked(srcId)
    local d = State.dialog
    State.dialog = nil
    if srcId == "paint" then
        if d.mode == "object" then
            State.dialog = {kind = "name", title = "Новый актер или объект",
                fieldLabel = "Название актера или объекта", text = "Мой актер или объект",
                note = "Примечание: образ будет создан в редакторе рисования.",
                onOk = function(name)
                    local obj = project.addObject(name, nil)
                    State.currentObjectIdx = #State.currentScene().objects
                    paint.openFor(function(path)
                        table.insert(obj.looks, {name = name, path = path})
                        project.saveProject()
                    end)
                end}
        else
            paint.openFor(function(path)
                local obj = State.currentObject()
                if obj then
                    table.insert(obj.looks, {name = "Образ " .. (#obj.looks + 1), path = path})
                    project.saveProject()
                end
            end)
        end
    elseif srcId == "library" then
        State.dialog = {kind = "library", mode = d.mode}
    elseif srcId == "empty" then
        State.dialog = {kind = "name", title = "Новый актер или объект",
            fieldLabel = "Название актера или объекта", text = "Мой актер или объект",
            note = "Примечание: Актер или объект будет создан без образа.",
            onOk = function(name)
                project.addObject(name, nil)
                State.toast("Объект создан: " .. name)
            end}
    elseif srcId == "local" then
        -- копия существующего объекта
        local sc = State.currentScene()
        local items = {}
        for i, o in ipairs(sc.objects) do
            table.insert(items, {label = o.name, fn = function()
                local copy = {name = o.name .. " (копия)", x = o.x + 30, y = o.y + 30,
                    size = o.size, visible = true,
                    looks = o.looks, sounds = o.sounds, scripts = {}}
                table.insert(sc.objects, copy)
                project.saveProject()
                State.toast("Копия создана")
            end})
        end
        if #items == 0 then State.toast("Нет локальных актеров") return end
        State.menu = {x = W() / 2 - 120, y = H() / 2 - #items * 22, items = items}
    else
        State.toast("Недоступно в этой сборке")
    end
end

local function onLibraryPicked(idx)
    local d = State.dialog
    State.dialog = nil
    local item = project.libraryItems()[idx]
    if not item then return end
    if d.mode == "object" then
        State.dialog = {kind = "name", title = "Новый актер или объект",
            fieldLabel = "Название актера или объекта", text = item.name,
            onOk = function(name)
                project.addObject(name, item.path)
                State.toast("Объект создан: " .. name)
            end}
    else
        local obj = State.currentObject()
        if obj then
            table.insert(obj.looks, {name = item.name, path = item.path})
            project.saveProject()
            State.toast("Образ добавлен: " .. item.name)
        end
    end
end

local function addCatalogBlock(desc)
    local inst = catalog.instantiate(desc)
    local target = State.insertTarget and State.insertTarget.list or State.currentScripts()
    table.insert(target, inst)
    project.saveProject()
    State.toast("Блок добавлен: " .. desc.name)
end

local function blockPopupFor(hit)
    local b = hit.block
    local items = {
        {label = "Удалить блок", fn = function()
            local list = hit.list
            for i, v in ipairs(list) do
                if v == b then table.remove(list, i) break end
            end
            project.saveProject()
        end},
    }
    if b.type == "control" then
        table.insert(items, {label = "Добавить внутрь", fn = function()
            State.insertTarget = {list = b.children}
            State.selectedCategory = nil
            State.screen = "categories"
        end})
    end
    if b.name == "ifElse" then
        table.insert(items, {label = "Добавить в «иначе»", fn = function()
            State.insertTarget = {list = b.elseChildren}
            State.screen = "categories"
        end})
    end
    table.insert(items, {label = "О блоке", fn = function()
        State.toast(blocks.blockLabel(b))
    end})
    State.menu = {x = 40, y = math.min(hit.y + 60, H() - 200), items = items}
end

local function paramTapped(hit)
    local part = hit.part
    if part.k == "d" then
        local options = part.opts or dynOptions(part.dyn)
        openDropdown(hit.x, hit.y + 30, options, function(val)
            hit.block.params = hit.block.params or {}
            hit.block.params[part.id] = val
            project.saveProject()
        end)
    else
        local cur = blocks.paramValue(hit.block, part.id)
        openInput("Значение параметра", tostring(cur), function(v)
            hit.block.params = hit.block.params or {}
            hit.block.params[part.id] = (part.k == "n" and tonumber(v)) and tonumber(v) or v
            project.saveProject()
        end)
    end
end

function M.mousepressed(x, y)
    if State.running then
        local id = ui.hitAt(x, y)
        if id == "runtime_stop" or id == "appbar_back" then
            runtime.stop()
            return
        end
        if id == "ask_ok" then
            State.rt.asking.answer = State.rt.asking.text or ""
            return
        end
        runtime.touchPressed(x, y)
        return
    end

    if paint.handleTouch(x, y, true) then return end

    local id = ui.hitAt(x, y)

    -- слой ввода
    if State.input then
        if id == "input_ok" then closeInput(true)
        elseif id == "input_cancel" then closeInput(false)
        end
        return
    end

    -- слой диалогов
    if State.dialog then
        local d = State.dialog
        if id == "dialog_ok" then
            if d.kind == "name" then
                local name = d.text
                State.dialog = nil
                if d.onOk then d.onOk(name) end
            end
        elseif id == "dialog_cancel" or id == "dialog_frame" or not id then
            State.dialog = nil
        elseif id == "name_field" then
            openInput(d.fieldLabel or "Название", d.text, function(v) d.text = v end)
        else
            local srcId = id and id:match("^source_(%a+)$")
            if srcId then onSourcePicked(srcId) end
            local libIdx = id and id:match("^lib_(%d+)$")
            if libIdx then onLibraryPicked(tonumber(libIdx)) end
        end
        return
    end

    -- слой меню
    if State.menu then
        local idx = id and id:match("^menu_(%d+)$")
        if idx and State.menu.items[tonumber(idx)] then
            local fn = State.menu.items[tonumber(idx)].fn
            State.menu = nil
            if fn then fn() end
        else
            State.menu = nil
        end
        return
    end

    -- слой dropdown
    if State.dropdown then
        local idx = id and id:match("^dd_(%d+)$")
        if idx then
            local fn = State.dropdown.fn
            local val = State.dropdown.options[tonumber(idx)]
            State.dropdown = nil
            if fn then fn(val) end
        else
            State.dropdown = nil
        end
        return
    end

    if id and handleAppBarHit(id) then return end
    id = id or ""

    -- экраны
    if State.screen == "home" then
        if id == "home_edit" then State.screen = "project"
        elseif id == "home_play" then runtime.start(State.currentSceneIdx)
        elseif id == "home_projects" then State.screen = "projects"
        elseif id == "home_community" then State.toast("Сообщество Catrobat: pocketcode.org (нужен интернет)")
        elseif id == "home_add" then
            State.dialog = {kind = "name", title = "Новый проект", fieldLabel = "Название проекта",
                text = "Мой проект",
                onOk = function(name)
                    project.newProject(name)
                    State.screen = "project"
                    State.toast("Проект создан: " .. name)
                end}
        end
    elseif State.screen == "projects" then
        if id == "projects_add" then
            State.dialog = {kind = "name", title = "Новый проект", fieldLabel = "Название проекта",
                text = "Мой проект",
                onOk = function(name)
                    project.newProject(name)
                    State.toast("Проект создан: " .. name)
                end}
            return
        end
        local openIdx = id:match("^project_open_(%d+)$")
        if openIdx then
            project.openProject(tonumber(openIdx))
            State.screen = "project"
            return
        end
        local menuIdx = id:match("^project_menu_(%d+)$")
        if menuIdx then
            local i = tonumber(menuIdx)
            State.menu = {x = W() - 220, y = y, items = {
                {label = "Открыть", fn = function() project.openProject(i); State.screen = "project" end},
                {label = "Удалить", fn = function()
                    love.filesystem.remove(State.projects[i].filename)
                    project.loadProjectList()
                    State.toast("Проект удалён")
                end},
            }}
        end
    elseif State.screen == "project" then
        if id == "project_bg" then
            State.currentObjectIdx = 0
            State.tab = "scripts"
            State.screen = "object"
            State.scriptScroll = 0
        elseif id == "project_play" then
            runtime.start(State.currentSceneIdx)
        elseif id == "project_add" then
            State.dialog = {kind = "source", mode = "object"}
        else
            local openIdx = id:match("^object_open_(%d+)$")
            if openIdx then
                State.currentObjectIdx = tonumber(openIdx)
                State.tab = "scripts"
                State.screen = "object"
                State.scriptScroll = 0
            end
            local menuIdx = id:match("^object_menu_(%d+)$")
            if menuIdx then
                local i = tonumber(menuIdx)
                State.menu = {x = W() - 240, y = y, items = {
                    {label = "Открыть", fn = function()
                        State.currentObjectIdx = i; State.tab = "scripts"; State.screen = "object"
                    end},
                    {label = "Переименовать", fn = function()
                        openInput("Название актера или объекта", State.currentScene().objects[i].name, function(v)
                            if v ~= "" then State.currentScene().objects[i].name = v; project.saveProject() end
                        end)
                    end},
                    {label = "Удалить", fn = function()
                        project.deleteObject(i)
                        State.toast("Объект удалён")
                    end},
                }}
            end
        end
    elseif State.screen == "object" then
        local tab = id:match("^tab_(%a+)$")
        if tab then
            State.tab = tab
            State.scroll.looks = 0
            return
        end
        if id == "object_play" then
            runtime.start(State.currentSceneIdx)
            return
        end
        if id == "object_add" then
            if State.tab == "scripts" then
                State.insertTarget = nil
                State.screen = "categories"
            elseif State.tab == "looks" then
                State.dialog = {kind = "source", mode = "look"}
            else
                State.toast("Звуки: перетащите .ogg/.mp3 в папку проекта")
            end
            return
        end
        local lookMenu = id:match("^look_menu_(%d+)$")
        if lookMenu then
            local i = tonumber(lookMenu)
            local isBg = State.currentObjectIdx == 0
            local looks = isBg and State.currentScene().bgLooks or State.currentObject().looks
            State.menu = {x = W() - 240, y = y, items = {
                {label = "Переименовать", fn = function()
                    openInput("Название образа", looks[i].name, function(v)
                        if v ~= "" then looks[i].name = v; project.saveProject() end
                    end)
                end},
                {label = "Удалить", fn = function()
                    table.remove(looks, i)
                    project.saveProject()
                end},
            }}
            return
        end
        local soundMenu = id:match("^sound_menu_(%d+)$")
        if soundMenu then
            local i = tonumber(soundMenu)
            local sounds = State.currentObject() and State.currentObject().sounds or {}
            State.menu = {x = W() - 240, y = y, items = {
                {label = "Удалить", fn = function() table.remove(sounds, i); project.saveProject() end},
            }}
            return
        end
        -- клики по скриптам: сначала параметры, потом «иначе», потом блоки
        if State.tab == "scripts" and State.scriptHits then
            local passes = {"param", "else", "block"}
            for _, kind in ipairs(passes) do
                for i = #State.scriptHits, 1, -1 do
                    local h2 = State.scriptHits[i]
                    if h2.kind == kind and ui.inRect(x, y, h2) then
                        if kind == "param" then
                            paramTapped(h2)
                        elseif kind == "else" then
                            State.insertTarget = {list = h2.block.elseChildren}
                            State.screen = "categories"
                        else
                            blockPopupFor(h2)
                        end
                        return
                    end
                end
            end
        end
    elseif State.screen == "categories" then
        local cat = id:match("^cat_(%a+)$")
        if cat then
            State.selectedCategory = cat
            State.scroll.catblocks = 0
            State.screen = "catblocks"
        end
    elseif State.screen == "catblocks" then
        if State.catHits then
            for _, h2 in ipairs(State.catHits) do
                if ui.inRect(x, y, h2) then
                    addCatalogBlock(h2.desc)
                    return
                end
            end
        end
    end
end

function M.mousereleased(x, y)
    if State.running then
        runtime.touchReleased()
    end
end

function M.wheelmoved(x, y)
    local d = y * 40
    local s = State.screen
    if s == "object" and State.tab == "scripts" then
        State.scriptScroll = math.max(0, (State.scriptScroll or 0) - d)
    else
        State.scroll[s] = math.max(0, (State.scroll[s] or 0) - d)
    end
end

function M.textinput(t)
    if State.running then
        if State.rt and State.rt.asking then
            State.rt.asking.text = (State.rt.asking.text or "") .. t
        end
        return
    end
    if State.input then
        State.input.text = State.input.text .. t
        return
    end
    if State.dialog and State.dialog.kind == "name" then
        State.dialog.text = (State.dialog.text or "") .. t
    end
end

function M.keypressed(key)
    if State.running then
        if State.rt and State.rt.asking then
            if key == "backspace" then
                State.rt.asking.text = (State.rt.asking.text or ""):sub(1, -2)
            elseif key == "return" or key == "kpenter" then
                State.rt.asking.answer = State.rt.asking.text or ""
            end
        elseif key == "escape" then
            runtime.stop()
        end
        return
    end
    if State.input then
        if key == "backspace" then
            State.input.text = State.input.text:sub(1, -2)
        elseif key == "return" or key == "kpenter" then
            closeInput(true)
        elseif key == "escape" then
            closeInput(false)
        end
        return
    end
    if State.dialog and State.dialog.kind == "name" then
        if key == "backspace" then
            State.dialog.text = (State.dialog.text or ""):sub(1, -2)
        elseif key == "return" or key == "kpenter" then
            local d = State.dialog
            State.dialog = nil
            if d.onOk then d.onOk(d.text) end
        elseif key == "escape" then
            State.dialog = nil
        end
        return
    end
    if key == "escape" then
        if State.menu then State.menu = nil
        elseif State.dropdown then State.dropdown = nil
        elseif State.screen == "catblocks" then State.screen = "object"
        elseif State.screen == "categories" then State.screen = "object"
        elseif State.screen == "object" then State.screen = "project"
        elseif State.screen == "project" then State.screen = "home"
        elseif State.screen == "projects" then State.screen = "home"
        end
    elseif key == "f5" then
        runtime.start(State.currentSceneIdx)
    elseif key == "f2" then
        project.saveProject()
    end
end

return M
