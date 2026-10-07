-- test/run.lua
-- Headless-прогон интерфейса и рантайма под моком LÖVE
dofile("test/mock_love.lua")
dofile("main.lua")
love.load()
love.resize(1280, 800) -- ранний resize (как на Android) не должен падать

local State = require("src.state")
local ui = require("src.ui")
local screens = require("src.screens")
local runtime = require("src.runtime")
local project = require("src.project")
local paint = require("src.paint")
local blocks = require("src.blocks")

local function drawAll()
    love.draw()
end

local function findHit(pattern)
    for i = #ui.hits, 1, -1 do
        local h = ui.hits[i]
        if h.id == pattern or (type(pattern) == "string" and pattern:find("^%^") and h.id:match(pattern)) then
            return h
        end
    end
    return nil
end

local function tap(id)
    local h = findHit(id)
    if not h then error("MISS " .. tostring(id)) end
    local x, y = h.x + h.w / 2, h.y + h.h / 2
    screens.mousepressed(x, y)
    screens.mousereleased(x, y)
end

local function step(n)
    for _ = 1, (n or 1) do
        love.update(0.016)
        drawAll()
    end
end

print("== home ==")
drawAll()
tap("home_add")
drawAll()
tap("dialog_ok") -- создаёт проект "Мой проект" (имя по умолчанию)
step()
print("screen:", State.screen, "projects:", #State.projects)

print("== projects list ==")
screens.keypressed("escape") -- из project в home
step()
tap("home_projects")
step()
-- открываем демо-проект (тот, где 3 объекта)
local target = 1
for i, p in ipairs(State.projects) do
    if p.data and p.data.scenes and p.data.scenes[1].objects and #p.data.scenes[1].objects >= 3 then
        target = i
    end
end
tap("project_open_" .. target)
step()
print("screen:", State.screen, "project:", State.project.name, "objects:", #State.currentScene().objects)

print("== add empty object ==")
tap("project_add")
step()
tap("source_empty")
step()
tap("dialog_ok")
step()
print("objects:", #State.currentScene().objects)

print("== add object from library ==")
tap("project_add")
step()
tap("source_library")
step()
tap("lib_4") -- мяч
step()
tap("dialog_ok")
step()
print("objects:", #State.currentScene().objects)

print("== open object, add blocks ==")
local oh = findHit("^object_open_")
tap(oh.id)
step()
print("object screen:", State.screen, State.currentObjectIdx)
tap("object_add")
step()
print("categories:", State.screen)
tap("cat_control")
step()
print("catblocks:", State.screen, State.selectedCategory)
-- добавить несколько блоков управления
for i = 1, 3 do
    local h = State.catHits[i]
    screens.mousepressed(h.x + h.w / 2, h.y + h.h / 2)
    screens.mousereleased(h.x + h.w / 2, h.y + h.h / 2)
    drawAll()
end
screens.keypressed("escape") -- назад в объект
step()
tap("object_add")
step()
tap("cat_motion")
step()
for i = 1, 4 do
    local h = State.catHits[i]
    screens.mousepressed(h.x + h.w / 2, h.y + h.h / 2)
    screens.mousereleased(h.x + h.w / 2, h.y + h.h / 2)
    drawAll()
end
screens.keypressed("escape")
step()
print("scripts:", #State.currentScripts())

print("== edit param via input bar ==")
drawAll()
local paramHit = nil
for _, h in ipairs(State.scriptHits or {}) do
    if h.kind == "param" and h.part.k == "n" then paramHit = h break end
end
if paramHit then
    screens.mousepressed(paramHit.x + 5, paramHit.y + 5)
    print("after param tap: input=", State.input ~= nil, "menu=", State.menu ~= nil, "dd=", State.dropdown ~= nil)
    drawAll()
    screens.textinput("42")
    screens.keypressed("return")
    step()
    print("param edited:", blocks.paramValue(paramHit.block, paramHit.part.id))
else
    print("no numeric param found")
end

print("== block popup menu (delete) ==")
drawAll()
local blockHit = nil
for _, h in ipairs(State.scriptHits or {}) do
    if h.kind == "block" then blockHit = h break end
end
if blockHit then
    print("before block tap: menu=", State.menu ~= nil, "input=", State.input ~= nil)
    screens.mousepressed(blockHit.x + 100, blockHit.y + 10)
    print("after block tap: menu=", State.menu ~= nil)
    drawAll()
    tap("menu_1") -- удалить блок
    step()
    print("after delete:", #State.currentScripts())
end

print("== dropdown (clone on bird) ==")
screens.keypressed("escape") -- в проект
step()
local oh3 = nil
for i = #ui.hits, 1, -1 do
    if ui.hits[i].id == "object_open_3" then oh3 = ui.hits[i] end
end
if oh3 then
    tap("object_open_3")
    step()
    drawAll()
    local dd = nil
    for _, h in ipairs(State.scriptHits or {}) do
        if h.kind == "param" and h.part.k == "d" then dd = h break end
    end
    if dd then
        screens.mousepressed(dd.x + 5, dd.y + 5)
        drawAll()
        tap("dd_1")
        step()
        print("dropdown ok")
    end
end

print("== looks tab + paint ==")
tap("tab_looks")
step()
tap("object_add")
step()
tap("source_paint")
step()
print("paint mode:", State.paintMode)
paint.handleTouch(100, 100, true)
paint.handleTouch(110, 110, true)
local hh = love.graphics.getHeight()
paint.handleTouch(50, hh - 50, true) -- сохранить
step()
print("looks after paint:", #(State.currentObject().looks or {}))

print("== runtime ==")
screens.keypressed("escape") -- на проект? (мы в object)
step()
runtime.start(State.currentSceneIdx)
step(120)
print("running threads:", State.rt and #State.rt.threads or 0, "objects:", State.rt and #State.rt.objects or 0)
runtime.touchPressed(240, 400)
step(30)
runtime.stop()
step()
print("running:", State.running)

print("== categories screen draw ==")
State.screen = "categories"
step()
State.screen = "catblocks"
State.selectedCategory = "device"
step()
State.selectedCategory = "data"
step()

print("== save/load ==")
project.saveProject()
project.loadProjectList()
step()

print("ALL OK")
