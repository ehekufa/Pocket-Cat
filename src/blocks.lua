-- src/blocks.lua
-- Отрисовка скриптов (блоки-паззлы как в Pocket Code) и списка блоков категории
local State = require("src.state")
local theme = require("src.theme")
local catalog = require("src.catalog")
local ui = require("src.ui")

local M = {}

local H = 52          -- высота обычного блока
local HAT = 16        -- надстройка шляпы
local INDENT = 30     -- отступ вложенных блоков
local ARM = 16        -- ширина левой стенки C-блока
local FOOT = 14       -- нижняя планка C-блока

function M.descOf(block)
    return catalog.find(block.name)
end

function M.paramValue(block, id)
    if block.params and block.params[id] ~= nil then return block.params[id] end
    local d = M.descOf(block)
    if d then
        for _, p in ipairs(d.parts) do
            if type(p) == "table" and p.id == id then return p.def end
        end
    end
    return ""
end

function M.blockLabel(block)
    local d = M.descOf(block)
    if not d then return block.name end
    local out = {}
    for _, p in ipairs(d.parts) do
        if type(p) == "string" then
            table.insert(out, p)
        else
            table.insert(out, "[" .. tostring(M.paramValue(block, p.id)) .. "]")
        end
    end
    return table.concat(out, " ")
end

-- Ширина пузыря параметра
local function bubbleWidth(text)
    return math.max(40, State.fontSmall:getWidth(tostring(text)) + 16)
end

-- Отрисовка строки частей блока; возвращает список хитов параметров
local function drawParts(block, x, y, hits, forPalette)
    local d = M.descOf(block)
    if not d then return end
    local cx = x
    local cy = y
    for _, part in ipairs(d.parts) do
        if type(part) == "string" then
            love.graphics.setFont(State.font)
            theme.setColor({1, 1, 1})
            love.graphics.print(part, cx, cy - 9)
            cx = cx + State.font:getWidth(part) + 6
        else
            local val = forPalette and part.def or M.paramValue(block, part.id)
            local txt = tostring(val)
            if txt == "" then txt = "…" end
            local bw = bubbleWidth(txt)
            if part.k == "d" then
                love.graphics.setColor(1, 1, 1, 0.25)
                love.graphics.rectangle("fill", cx, cy - 13, bw + 18, 26, 6, 6)
                love.graphics.setFont(State.fontSmall)
                theme.setColor({1, 1, 1})
                love.graphics.print(txt, cx + 8, cy - 7)
                ui.icon("caret", cx + bw + 8, cy, 12, {1, 1, 1})
            else
                love.graphics.setColor(1, 1, 1, 0.92)
                love.graphics.rectangle("fill", cx, cy - 13, bw, 26, 13, 13)
                love.graphics.setFont(State.fontSmall)
                love.graphics.setColor(0.15, 0.15, 0.2)
                love.graphics.print(txt, cx + 8, cy - 7)
            end
            if hits and not forPalette then
                table.insert(hits, {
                    kind = "param", block = block, paramId = part.id, part = part,
                    x = cx - 2, y = cy - 15, w = bw + (part.k == "d" and 22 or 4), h = 30,
                })
            end
            cx = cx + bw + (part.k == "d" and 18 or 0) + 6
        end
    end
end

-- Отрисовка левого значка-«линий» как в Pocket Code
local function drawLinesIcon(x, y, color)
    love.graphics.setColor(color[1] * 0.55, color[2] * 0.55, color[3] * 0.55)
    love.graphics.setLineWidth(1.4)
    for i = 0, 4 do
        love.graphics.line(x, y - 10 + i * 5, x + 22, y - 10 + i * 5)
    end
    love.graphics.setLineWidth(1)
end

-- Рекурсивная отрисовка списка блоков
function M.drawList(list, x, y, w, hits, depth)
    depth = depth or 0
    local first = true
    for _, b in ipairs(list) do
        local color = theme.catColor(b.category)
        local top = y
        if b.type == "event" then
            theme.setColor(color)
            love.graphics.rectangle("fill", x, top, w, H + HAT, 14, 14)
            love.graphics.rectangle("fill", x, top + 12, w, H + HAT - 12)
            drawLinesIcon(x + 14, top + (H + HAT) / 2 + 4, color)
            drawParts(b, x + 46, top + (H + HAT) / 2 + 4, hits)
            if hits then
                table.insert(hits, {kind = "block", block = b, list = list, x = x, y = top, w = w, h = H + HAT})
            end
            y = top + H + HAT + 4
        elseif b.type == "control" then
            -- шапка
            theme.setColor(color)
            if not first then love.graphics.rectangle("fill", x + 28, top - 4, 26, 5) end
            love.graphics.rectangle("fill", x, top, w, H)
            drawLinesIcon(x + 14, top + H / 2, color)
            drawParts(b, x + 46, top + H / 2, hits)
            if hits then
                table.insert(hits, {kind = "block", block = b, list = list, x = x, y = top, w = w, h = H})
            end
            y = top + H
            -- дети
            local bodyTop = y
            local childX = x + INDENT
            local childW = w - INDENT
            local yy = y + 3
            if b.children and #b.children > 0 then
                yy = M.drawList(b.children, childX, yy, childW, hits, depth + 1)
            else
                yy = yy + 8
            end
            local elseTop = nil
            if b.name == "ifElse" then
                elseTop = yy
                theme.setColor(color)
                love.graphics.rectangle("fill", x, yy, w, 30)
                love.graphics.setFont(State.font)
                theme.setColor({1, 1, 1})
                love.graphics.print("иначе", childX, yy + 6)
                if hits then
                    table.insert(hits, {kind = "else", block = b, x = x, y = yy, w = w, h = 30})
                end
                yy = yy + 33
                if b.elseChildren and #b.elseChildren > 0 then
                    yy = M.drawList(b.elseChildren, childX, yy, childW, hits, depth + 1)
                else
                    yy = yy + 8
                end
            end
            -- стенка слева
            local bodyH = yy - bodyTop
            theme.setColor(color)
            love.graphics.rectangle("fill", x, bodyTop, ARM, bodyH)
            -- низ
            love.graphics.rectangle("fill", x, yy, w, FOOT)
            love.graphics.rectangle("fill", x + 28, yy + FOOT - 1, 26, 5)
            y = yy + FOOT + 6
        else
            theme.setColor(color)
            if not first then love.graphics.rectangle("fill", x + 28, top - 4, 26, 5) end
            love.graphics.rectangle("fill", x, top, w, H)
            love.graphics.rectangle("fill", x + 28, top + H - 1, 26, 5)
            drawLinesIcon(x + 14, top + H / 2, color)
            drawParts(b, x + 46, top + H / 2, hits)
            if hits then
                table.insert(hits, {kind = "block", block = b, list = list, x = x, y = top, w = w, h = H})
            end
            y = top + H + 4
        end
        first = false
    end
    return y
end

-- Отрисовка области скриптов текущей цели
function M.drawScripts(areaX, areaY, areaW, areaH)
    theme.setColor(theme.stageDark)
    love.graphics.rectangle("fill", areaX, areaY, areaW, areaH)
    love.graphics.setScissor(areaX, areaY, areaW, areaH)
    local hits = {}
    local scripts = State.currentScripts()
    local y = areaY + 12 - (State.scriptScroll or 0)
    if #scripts == 0 then
        love.graphics.setFont(State.font)
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.print("Нет блоков. Нажмите «+», чтобы добавить.", areaX + 16, areaY + 20)
    end
    M.drawList(scripts, areaX, y, areaW, hits, 0)
    State.scriptHits = hits
    State.scriptContentH = (y - areaY + (State.scriptScroll or 0)) + 120
    love.graphics.setScissor()
    return hits
end

-- Список блоков выбранной категории (экран catblocks)
function M.drawCatalog(areaY)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    theme.setColor(theme.stageDark)
    love.graphics.rectangle("fill", 0, areaY, w, h - areaY)
    local cat = State.selectedCategory
    local list = catalog.BLOCKS[cat] or {}
    local color = theme.catColor(cat)

    love.graphics.setScissor(0, areaY, w, h - areaY)
    local y = areaY + 14 - (State.scroll.catblocks or 0)
    State.catHits = {}
    for _, desc in ipairs(list) do
        local bh = 52
        theme.setColor(color)
        love.graphics.rectangle("fill", 8, y, w - 16, bh, 8, 8)
        drawLinesIcon(8 + 12, y + bh / 2, color)
        -- превью частей со значениями по умолчанию
        local fake = {name = desc.name, params = nil}
        drawParts(fake, 8 + 42, y + bh / 2, nil, true)
        table.insert(State.catHits, {desc = desc, x = 8, y = y, w = w - 16, h = bh})
        y = y + bh + 8
    end
    State.catContentH = y - areaY + (State.scroll.catblocks or 0)
    love.graphics.setScissor()
end

return M
