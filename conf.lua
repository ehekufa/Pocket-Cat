function love.conf(t)
    t.title = "Pocket Cat"
    t.version = "12.0"
    t.console = false

    -- Базовые настройки окна
    t.window.width = 1024
    t.window.height = 768
    t.window.fullscreen = false
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    
    -- Для мобильных устройств
    if love._os == "Android" or love._os == "iOS" then
        t.window.fullscreen = true
        t.window.resizable = false
        -- Убираем минимальные размеры для мобильных
        t.window.minwidth = nil
        t.window.minheight = nil
    end
    
    -- Дополнительные настройки для стабильности
    t.window.highdpi = false  -- Отключаем для совместимости
    t.window.vsync = 1        -- Вертикальная синхронизация
    t.window.fsaa = 0         -- Без сглаживания
    t.window.display = 1      -- Основной монитор
    
    -- Настройки модулей
    t.modules.audio = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = true
    t.modules.video = false
    t.modules.window = true
end
