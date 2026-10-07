-- src/ui.lua
-- Базовые виджеты интерфейса: app bar, FAB, иконки, тосты, диалоги
local State = require("src.state")
local theme = require("src.theme")

local M = {}

M.hits = {} -- хит-области текущего кадра

function M.resetHits()
    M.hits = {}
end

function M.addHit(id, x, y, w, h)
    table.insert(M.hits, {id = id, x = x, y = y, w = w, h = h})
end

function M.hitAt(x, y)
    -- верхние по списку = нарисованные позже = приоритетнее
    for i = #M.hits, 1, -1 do
        local h = M.hits[i]
        if x >= h.x and x <= h.x + h.w and y >= h.y and y <= h.y + h.h then
            return h.id
        end
    end
    return nil
end

function M.inRect(px, py, r)
    return r and px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

-- ============================ ИКОНКИ ============================
local function line(x1, y1, x2, y2)
    love.graphics.line(x1, y1, x2, y2)
end

function M.icon(name, x, y, s, color)
    -- x,y — центр; s — размер
    theme.setColor(color or theme.text)
    love.graphics.setLineWidth(math.max(1.5, s * 0.09))
    local h = s / 2
    if name == "back" then
        line(x - h * 0.7, y, x + h * 0.8, y)
        line(x - h * 0.7, y, x - h * 0.05, y - h * 0.65)
        line(x - h * 0.7, y, x - h * 0.05, y + h * 0.65)
    elseif name == "search" then
        love.graphics.circle("line", x - h * 0.15, y - h * 0.15, h * 0.55)
        line(x + h * 0.25, y + h * 0.25, x + h * 0.75, y + h * 0.75)
    elseif name == "dots" then
        love.graphics.circle("fill", x, y - h * 0.6, s * 0.09)
        love.graphics.circle("fill", x, y, s * 0.09)
        love.graphics.circle("fill", x, y + h * 0.6, s * 0.09)
    elseif name == "help" then
        love.graphics.circle("line", x, y, h * 0.85)
        love.graphics.print("?", x - s * 0.11, y - s * 0.26)
    elseif name == "plus" then
        line(x - h * 0.6, y, x + h * 0.6, y)
        line(x, y - h * 0.6, x, y + h * 0.6)
    elseif name == "play" then
        love.graphics.polygon("fill", x - h * 0.4, y - h * 0.6, x - h * 0.4, y + h * 0.6, x + h * 0.65, y)
    elseif name == "stop" then
        love.graphics.rectangle("fill", x - h * 0.5, y - h * 0.5, s * 0.5, s * 0.5, 2, 2)
    elseif name == "pencil" then
        love.graphics.setLineWidth(math.max(2, s * 0.16))
        line(x - h * 0.55, y + h * 0.55, x + h * 0.35, y - h * 0.35)
        line(x + h * 0.35, y - h * 0.35, x + h * 0.6, y - h * 0.1)
        love.graphics.setLineWidth(math.max(1.5, s * 0.09))
    elseif name == "eye" then
        love.graphics.arc("line", "open", x, y + h * 0.35, h * 0.9, math.pi * 1.15, math.pi * 1.85)
        love.graphics.arc("line", "open", x, y - h * 0.35, h * 0.9, math.pi * 0.15, math.pi * 0.85)
        love.graphics.circle("fill", x, y, h * 0.28)
    elseif name == "speaker" then
        love.graphics.polygon("fill", x - h * 0.6, y - h * 0.25, x - h * 0.15, y - h * 0.25, x + h * 0.25, y - h * 0.6, x + h * 0.25, y + h * 0.6, x - h * 0.15, y + h * 0.25, x - h * 0.6, y + h * 0.25)
        love.graphics.arc("line", "open", x + h * 0.3, y, h * 0.55, -math.pi * 0.35, math.pi * 0.35)
    elseif name == "script" then
        love.graphics.rectangle("line", x - h * 0.55, y - h * 0.65, s * 0.55, s * 0.65, 2, 2)
        line(x - h * 0.3, y - h * 0.3, x + h * 0.3, y - h * 0.3)
        line(x - h * 0.3, y, x + h * 0.3, y)
        line(x - h * 0.3, y + h * 0.3, x + h * 0.1, y + h * 0.3)
    elseif name == "handle" then
        for i = -2, 2 do
            line(x - h * 0.6, y + i * h * 0.32, x + h * 0.6, y + i * h * 0.32)
        end
    elseif name == "camera" then
        love.graphics.rectangle("line", x - h * 0.7, y - h * 0.4, s * 0.7, s * 0.5, 3, 3)
        love.graphics.circle("line", x, y, h * 0.28)
        line(x - h * 0.25, y - h * 0.4, x - h * 0.12, y - h * 0.62)
        line(x - h * 0.12, y - h * 0.62, x + h * 0.12, y - h * 0.62)
        line(x + h * 0.12, y - h * 0.62, x + h * 0.25, y - h * 0.4)
    elseif name == "image" then
        love.graphics.rectangle("line", x - h * 0.65, y - h * 0.5, s * 0.65, s * 0.5, 2, 2)
        love.graphics.circle("fill", x - h * 0.3, y - h * 0.2, h * 0.12)
        love.graphics.polygon("fill", x - h * 0.5, y + h * 0.35, x - h * 0.05, y - h * 0.05, x + h * 0.25, y + h * 0.35)
        love.graphics.polygon("fill", x + h * 0.05, y + h * 0.35, x + h * 0.3, y + h * 0.1, x + h * 0.55, y + h * 0.35)
    elseif name == "clipboard" then
        love.graphics.rectangle("line", x - h * 0.5, y - h * 0.55, s * 0.5, s * 0.62, 2, 2)
        love.graphics.rectangle("fill", x - h * 0.22, y - h * 0.72, s * 0.22, s * 0.14, 2, 2)
        love.graphics.circle("line", x, y - h * 0.62, h * 0.12)
    elseif name == "addbox" then
        love.graphics.rectangle("line", x - h * 0.55, y - h * 0.55, s * 0.5, s * 0.5, 3, 3)
        line(x - h * 0.3, y - h * 0.3, x + h * 0.0, y - h * 0.3)
        line(x - h * 0.3, y + h * 0.2, x + h * 0.6, y + h * 0.2)
        line(x + h * 0.2, y - h * 0.3, x + h * 0.2, y + h * 0.7)
        love.graphics.rectangle("fill", x - h * 0.05, y - h * 0.6, s * 0.34, s * 0.34, 3, 3)
        theme.setColor(theme.bgDark)
        line(x + h * 0.12, y - h * 0.43, x + h * 0.12, y - h * 0.09)
        line(x - h * 0.05 + s * 0.03, y - h * 0.26, x + h * 0.29 - s * 0.03, y - h * 0.26)
        theme.setColor(color or theme.text)
    elseif name == "brush" then
        love.graphics.setLineWidth(math.max(2, s * 0.14))
        line(x + h * 0.6, y - h * 0.6, x - h * 0.1, y + h * 0.1)
        love.graphics.circle("fill", x - h * 0.35, y + h * 0.4, h * 0.28)
        love.graphics.setLineWidth(math.max(1.5, s * 0.09))
    elseif name == "searchimage" then
        love.graphics.rectangle("line", x - h * 0.65, y - h * 0.5, s * 0.6, s * 0.5, 2, 2)
        love.graphics.circle("line", x + h * 0.25, y + h * 0.15, h * 0.32)
        line(x + h * 0.48, y + h * 0.38, x + h * 0.75, y + h * 0.65)
    elseif name == "arrow" then
        line(x - h * 0.6, y, x + h * 0.5, y)
        line(x + h * 0.5, y, x + h * 0.05, y - h * 0.45)
        line(x + h * 0.5, y, x + h * 0.05, y + h * 0.45)
    elseif name == "caret" then
        love.graphics.polygon("fill", x - h * 0.4, y - h * 0.25, x + h * 0.4, y - h * 0.25, x, y + h * 0.35)
    elseif name == "close" then
        line(x - h * 0.5, y - h * 0.5, x + h * 0.5, y + h * 0.5)
        line(x - h * 0.5, y + h * 0.5, x + h * 0.5, y - h * 0.5)
    elseif name == "check" then
        line(x - h * 0.5, y, x - h * 0.1, y + h * 0.4)
        line(x - h * 0.1, y + h * 0.4, x + h * 0.55, y - h * 0.4)
    end
    love.graphics.setLineWidth(1)
end

-- ============================ APP BAR ============================
function M.appBar(title, opts)
    opts = opts or {}
    local w = love.graphics.getWidth()
    local h = theme.appbarH
    theme.setColor(theme.appbar)
    love.graphics.rectangle("fill", 0, 0, w, h)
    theme.setColor({0, 0, 0}, 0.25)
    love.graphics.rectangle("fill", 0, h - 2, w, 2)

    if opts.back then
        M.icon("back", 28, h / 2, 22)
        M.addHit("appbar_back", 0, 0, 56, h)
    end
    if opts.logo then
        M.drawLogo(12, 10)
    end

    love.graphics.setFont(State.fontBig)
    theme.setColor(theme.text)
    local tx = (opts.back or opts.logo) and 56 or 16
    love.graphics.print(title, tx, (h - 22) / 2)

    local rx = w - 28
    if opts.menu then
        M.icon("dots", rx, h / 2, 22)
        M.addHit("appbar_menu", rx - 24, 0, 48, h)
        rx = rx - 48
    end
    if opts.help then
        M.icon("help", rx, h / 2, 22)
        M.addHit("appbar_help", rx - 24, 0, 48, h)
        rx = rx - 48
    end
    if opts.search then
        M.icon("search", rx, h / 2, 22)
        M.addHit("appbar_search", rx - 24, 0, 48, h)
    end
    return h
end

function M.drawLogo(x, y)
    -- карман с значком, как в "Покет Код"
    theme.setColor({0.13, 0.6, 0.65})
    love.graphics.rectangle("fill", x, y + 8, 26, 22, 4, 4)
    theme.setColor({0.9, 0.55, 0.1})
    love.graphics.rectangle("fill", x + 5, y, 16, 12, 2, 2)
    theme.setColor(theme.text)
    love.graphics.circle("line", x + 13, y + 19, 7)
    love.graphics.polygon("fill", x + 11, y + 15.5, x + 11, y + 22.5, x + 17, y + 19)
end

-- ============================ FAB ============================
function M.fab(id, x, y, iconName)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", x + 2, y + 3, 28)
    theme.setColor(theme.accent)
    love.graphics.circle("fill", x, y, 28)
    M.icon(iconName, x, y, 26, {1, 1, 1})
    M.addHit(id, x - 30, y - 30, 60, 60)
end

-- ============================ ТОСТЫ ============================
function M.drawMessages()
    local now = love.timer.getTime()
    local w = love.graphics.getWidth()
    local y = theme.appbarH + 8
    local alive = {}
    for _, m in ipairs(State.messages) do
        local age = now - m.t
        if age < 3 then
            table.insert(alive, m)
            local alpha = age > 2.4 and (3 - age) / 0.6 or 1
            love.graphics.setFont(State.fontSmall)
            local tw = State.fontSmall:getWidth(m.text)
            local bw = math.min(tw + 24, w - 40)
            love.graphics.setColor(0, 0, 0, 0.65 * alpha)
            love.graphics.rectangle("fill", (w - bw) / 2, y, bw, 26, 13, 13)
            love.graphics.setColor(0.85, 0.93, 1, alpha)
            love.graphics.print(m.text, (w - tw) / 2, y + 5)
            y = y + 32
        end
    end
    State.messages = alive
end

-- ============================ ДИАЛОГИ ============================
function M.dialogFrame(title, mw, mh)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)
    local mx = (w - mw) / 2
    local my = (h - mh) / 2
    theme.setColor(theme.dialogBg)
    love.graphics.rectangle("fill", mx, my, mw, mh, 4, 4)
    if title then
        love.graphics.setFont(State.fontBig)
        theme.setColor(theme.dialogText)
        love.graphics.print(title, mx + 24, my + 22)
    end
    M.addHit("dialog_frame", mx, my, mw, mh)
    return mx, my
end

function M.dialogButtons(mx, my, mw, mh, okText, onOk)
    love.graphics.setFont(State.fontBig)
    local cancelW = State.fontBig:getWidth("ОТМЕНИТЬ")
    local okW = State.fontBig:getWidth(okText or "ОК")
    local bx = mx + mw - 24 - okW
    theme.setColor(theme.linkBlue)
    love.graphics.print(okText or "ОК", bx, my + mh - 44)
    M.addHit("dialog_ok", bx - 10, my + mh - 52, okW + 20, 40)
    local cx = bx - 30 - cancelW
    love.graphics.print("ОТМЕНИТЬ", cx, my + mh - 44)
    M.addHit("dialog_cancel", cx - 10, my + mh - 52, cancelW + 20, 40)
end

-- ============================ ПРОЧЕЕ ============================
function M.thumb(img, x, y, size, bgColor)
    theme.setColor(bgColor or {0.13, 0.13, 0.13})
    love.graphics.rectangle("fill", x, y, size, size, 10, 10)
    if img then
        local s = math.min(size / img:getWidth(), size / img:getHeight()) * 0.9
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(img, x + size / 2, y + size / 2, 0, s, s, img:getWidth() / 2, img:getHeight() / 2)
    end
end

function M.loadImage(path)
    if not path then return nil end
    if State.imageCache[path] then
        local v = State.imageCache[path]
        return v ~= false and v or nil
    end
    local ok, img = pcall(love.graphics.newImage, path)
    if ok and img then
        img:setFilter("linear", "linear")
        State.imageCache[path] = img
        return img
    end
    State.imageCache[path] = false
    return nil
end

return M
