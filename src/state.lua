-- src/state.lua
-- Глобальное состояние приложения
local State = {
    -- навигация
    screen = "home",        -- home | projects | project | object | categories | catblocks
    tab = "scripts",        -- scripts | looks | sounds (экран объекта)
    scroll = {},            -- скролл по экранам

    -- проекты
    projects = {},
    currentProjectIndex = 1,
    currentProject = nil,
    project = nil,          -- данные текущего проекта (таблица)
    currentSceneIdx = 1,
    currentObjectIdx = 1,   -- индекс объекта в сцене (0 = фон)
    selectedCategory = nil, -- для экрана catblocks

    -- диалоги / оверлеи
    dialog = nil,           -- {kind=..., ...}
    menu = nil,             -- {x,y,items=[{label,fn}]}
    dropdown = nil,         -- {x,y,options=[..],fn}
    input = nil,            -- {title,text,commit}
    blockPopup = nil,       -- {block,list,index,x,y} меню блока (удалить/инфо)

    -- редактор блоков
    editTarget = nil,       -- {kind="object"|"background"}
    scriptScroll = 0,

    -- runtime
    running = false,
    rt = nil,

    -- paint
    paintMode = false,
    paintOnSave = nil,
    paintWidth = 96,
    paintHeight = 96,
    paintScale = 1,

    -- прочее
    font = nil,
    fontSmall = nil,
    fontBig = nil,
    messages = {},
    messageTimers = {},
    imageCache = {},

    keyboardVisible = false,
    editingBlock = nil,
    editingText = "",
    inputMode = nil,
}

function State.init()
    State.messages = {}
end

function State.toast(msg)
    table.insert(State.messages, {text = msg, t = love.timer.getTime()})
    if #State.messages > 6 then table.remove(State.messages, 1) end
end

function State.currentScene()
    if not State.project then return nil end
    return State.project.scenes[State.currentSceneIdx]
end

function State.currentObject()
    local s = State.currentScene()
    if not s then return nil end
    return s.objects[State.currentObjectIdx]
end

-- Скрипты текущей цели редактирования (объект или фон)
function State.currentScripts()
    local s = State.currentScene()
    if not s then return {} end
    if State.currentObjectIdx == 0 then
        return s.backgroundScripts or {}
    end
    local obj = s.objects[State.currentObjectIdx]
    if not obj then return {} end
    return obj.scripts or {}
end

return State
