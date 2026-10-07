-- src/draw_objects.lua
-- Отрисовка сцены: статичное превью и выполнение проекта
local State = require("src.state")
local ui = require("src.ui")

local M = {}

local function drawLook(img, x, y, rot, scale, alpha, bright)
    if not img then return false end
    local b = math.max(0, math.min(1, (bright or 100) / 100))
    love.graphics.setColor(b, b, b, alpha or 1)
    love.graphics.draw(img, x, y, rot or 0, scale or 1, scale or 1, img:getWidth() / 2, img:getHeight() / 2)
    return true
end

local function drawBubble(x, y, text, think)
    love.graphics.setFont(State.fontSmall)
    local w = State.fontSmall:getWidth(text) + 20
    local h = 26
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.rectangle("fill", x - w / 2, y - h - 14, w, h, 8, 8)
    if think then
        love.graphics.circle("fill", x - 4, y - 10, 4)
        love.graphics.circle("fill", x - 8, y - 4, 2.5)
    else
        love.graphics.polygon("fill", x - 5, y - 15, x + 5, y - 15, x, y - 6)
    end
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.print(text, x - w / 2 + 10, y - h - 9)
end

-- Статичное превью сцены (домашний экран, миниатюры)
function M.drawPreview(scene, x, y, w, h)
    love.graphics.setScissor(x, y, w, h)
    local bg = scene.bgColor or {0.2, 0.2, 0.4}
    love.graphics.setColor(bg[1], bg[2], bg[3])
    love.graphics.rectangle("fill", x, y, w, h)
    local bgLook = (scene.bgLooks or {})[1]
    if bgLook then
        local img = ui.loadImage(bgLook.path)
        if img then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(img, x, y, 0, w / img:getWidth(), h / img:getHeight())
        end
    end
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()
    for _, obj in ipairs(scene.objects or {}) do
        if obj.visible ~= false then
            local img = obj.looks and obj.looks[1] and ui.loadImage(obj.looks[1].path) or nil
            local sx = x + (obj.x / W) * w
            local sy = y + (obj.y / H) * h
            local s = (math.min(w / W, h / H)) * ((obj.size or 100) / 100)
            drawLook(img, sx, sy, 0, s, 1, 100)
        end
    end
    love.graphics.setScissor()
end

-- Выполняемая сцена на весь экран
function M.drawRuntime()
    local rt = State.rt
    if not rt then return end
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local top = 0

    -- фон
    local bg = rt.scene.bgColor or {0.2, 0.2, 0.4}
    love.graphics.setColor(bg[1], bg[2], bg[3])
    love.graphics.rectangle("fill", 0, top, w, h - top)
    local bgLook = (rt.scene.bgLooks or {})[rt.bgIdx]
    if bgLook then
        local img = ui.loadImage(bgLook.path)
        if img then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(img, 0, top, 0, w / img:getWidth(), (h - top) / img:getHeight())
        end
    end

    -- штампы
    for _, st in ipairs(rt.stamps) do
        drawLook(st.img, st.x, st.y, st.rot, st.scale, st.alpha, 100)
    end

    -- перо
    for _, p in ipairs(rt.penTrails) do
        love.graphics.setColor(p[5], p[6], p[7])
        love.graphics.setLineWidth(p[8])
        love.graphics.line(p[1], p[2], p[3], p[4])
    end
    love.graphics.setLineWidth(1)

    -- объекты по слоям
    local sorted = {}
    for _, r in ipairs(rt.objects) do table.insert(sorted, r) end
    table.sort(sorted, function(a, b) return a.layer < b.layer end)
    for _, r in ipairs(sorted) do
        if r.visible then
            local looks = r.def.looks or {}
            local img = looks[r.lookIdx] and ui.loadImage(looks[r.lookIdx].path) or nil
            local rot = 0
            if img then
                local baseScale = r.size / 100
                if r.rotStyle == "вращаться" then
                    rot = math.rad(r.dir - 90)
                elseif r.rotStyle == "лево-право" then
                    if math.cos(math.rad(r.dir)) < 0 then baseScale = -baseScale end
                end
                drawLook(img, r.x, r.y, rot, baseScale, 1 - r.transp / 100, r.bright)
            end
            if r.say then
                drawBubble(r.x, r.y - ((img and img:getHeight() or 60) * (r.size / 100)) / 2, r.say, r.thinkBubble)
            end
        end
    end

    -- показатели переменных
    love.graphics.setFont(State.font)
    for var, pos in pairs(rt.varShows) do
        local val = rt.vars[var]
        if type(val) == "table" then val = "(таблица)" end
        love.graphics.setColor(0, 0, 0, 0.5)
        local text = var .. ": " .. tostring(val ~= nil and val or 0)
        local tw = State.font:getWidth(text)
        love.graphics.rectangle("fill", pos.x, pos.y, tw + 14, 24, 6, 6)
        love.graphics.setColor(1, 0.85, 0.3)
        love.graphics.print(text, pos.x + 7, pos.y + 4)
    end

    -- вспышка
    if rt.flash then
        love.graphics.setColor(1, 1, 0.9, 0.25)
        love.graphics.rectangle("fill", 0, top, w, h - top)
    end
end

return M
