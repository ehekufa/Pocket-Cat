function love.conf(t)
    t.title = "Pocket Cat"            -- заголовок окна
    t.version = "12.0"                -- версия LÖVE (можно не указывать)
    t.console = false                 -- отключаем консоль в десктоп-режиме

    -- Настройки окна
    t.window.width = 0                -- 0 = автоматически (полноэкранно на Android)
    t.window.height = 0
    t.window.fullscreen = true        -- на ПК будет оконный режим, если не задать иначе
    t.window.resizable = false        -- запрещаем изменение размера, чтобы не ломать вёрстку
    t.window.minwidth = 800
    t.window.minheight = 600

    -- Для мобильных: автоматически ставит fullscreen и правильное разрешение
    if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
        t.window.fullscreen = true
        t.window.resizable = false
    end
end
