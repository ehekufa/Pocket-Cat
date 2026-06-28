function love.conf(t)
    t.title = "Pocket Cat"
    t.version = "11.5"
    t.console = false

    t.window.width = 1024          -- фиксированный размер окна
    t.window.height = 768
    t.window.fullscreen = false    -- оконный режим по умолчанию
    t.window.resizable = true      -- разрешаем менять размер
    t.window.minwidth = 800
    t.window.minheight = 600

    -- на мобильных пусть будет fullscreen
    if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
        t.window.fullscreen = true
        t.window.resizable = false
    end
end
