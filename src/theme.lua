-- src/theme.lua
-- Цвета и размеры интерфейса в стиле Pocket Code (см. скриншоты)
local M = {}

M.appbarH = 56

M.appbar     = {0.024, 0.19, 0.24}   -- тёмно-бирюзовый app bar
M.bg         = {0.02, 0.27, 0.37}    -- бирюзовый фон экранов
M.bgDark     = {0.015, 0.13, 0.17}   -- тёмные секции-заголовки
M.stageDark  = {0.02, 0.10, 0.13}    -- фон области скриптов
M.text       = {1, 1, 1}
M.textDim    = {0.66, 0.83, 0.90}    -- голубоватый текст списков
M.accent     = {0.984, 0.663, 0.098} -- оранжевые FAB
M.dialogBg   = {0.26, 0.26, 0.26}
M.dialogText = {0.95, 0.95, 0.95}
M.linkBlue   = {0.61, 0.83, 0.93}    -- акцент в диалогах
M.separator  = {0, 0, 0}

-- Цвета категорий блоков (как на скриншоте "Категории")
M.catColors = {
    event   = {0.755, 0.337, 0.110}, -- Событие
    control = {0.925, 0.580, 0.388}, -- Управление
    motion  = {0.255, 0.529, 0.737}, -- Движение
    sound   = {0.541, 0.275, 0.718}, -- Звук
    looks   = {0.369, 0.580, 0.282}, -- Образы
    pen     = {0.173, 0.314, 0.086}, -- Перо
    data    = {0.910, 0.329, 0.333}, -- Данные
    device  = {0.561, 0.478, 0.031}, -- Устройство
}

function M.catColor(cat)
    return M.catColors[cat] or {0.4, 0.4, 0.4}
end

function M.setColor(c, a)
    if a then
        love.graphics.setColor(c[1], c[2], c[3], a)
    else
        love.graphics.setColor(c[1], c[2], c[3])
    end
end

function M.rect(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r or 0, r or 0)
end

return M
