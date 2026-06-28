function love.conf(t)
    t.title = "Pocket Cat"
    t.version = "12.0"
    t.console = false

    t.window.width = 1024
    t.window.height = 768
    t.window.fullscreen = false
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600

    if love._os == "Android" or love._os == "iOS" then
        t.window.fullscreen = true
        t.window.resizable = false
    end
end
