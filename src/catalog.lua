-- src/catalog.lua
-- Полный каталог блоков по категориям (на основе официальной документации
-- Catrobat: https://catrobat.org/docs/brickdocumentation/), с русскими
-- названиями как в Pocket Code.
--
-- Формат блока: {name=..., type=..., parts={...}}
-- part — строка, либо параметр: {k=kind, id=..., def=..., dyn=..., opts={...}}
--   k: "n" число, "t" текст, "c" условие, "v" переменная, "l" список,
--      "d" выпадающий список (dyn: objects/looks/sounds/scenes/backgrounds
--      или opts — фиксированный список)
-- type: "event" (шляпа), "action", "control" (C-блок с children)

local M = {}

M.CATEGORIES = {
    {id = "event",   name = "Событие"},
    {id = "control", name = "Управление"},
    {id = "motion",  name = "Движение"},
    {id = "sound",   name = "Звук"},
    {id = "looks",   name = "Образы"},
    {id = "pen",     name = "Перо"},
    {id = "data",    name = "Данные"},
    {id = "device",  name = "Устройство"},
}

local function P(k, id, def, extra)
    local p = {k = k, id = id, def = def}
    if extra then
        for key, val in pairs(extra) do p[key] = val end
    end
    return p
end

M.BLOCKS = {
    -- ============================= СОБЫТИЕ =============================
    event = {
        {name = "start",      type = "event", parts = {"При запуске сцены"}},
        {name = "tap",        type = "event", parts = {"Когда коснулись объекта"}},
        {name = "stageTap",   type = "event", parts = {"Когда коснулись сцены"}},
        {name = "receive",    type = "event", parts = {"Когда получено", P("t", "msg", "сообщение1")}},
        {name = "cloneStart", type = "event", parts = {"Когда клон создан"}},
        {name = "whenTrue",   type = "event", parts = {"Когда", P("c", "cond", ""), "истинно"}},
        {name = "bgChange",   type = "event", parts = {"Когда фон меняется на", P("d", "look", "", {dyn = "backgrounds"})}},
    },

    -- ============================ УПРАВЛЕНИЕ ===========================
    control = {
        {name = "wait",          type = "action",  parts = {"Ждать", P("n", "secs", 1), "секунд"}},
        {name = "repeat",        type = "control", parts = {"Повторить", P("n", "times", 10), "раз"}},
        {name = "repeatUntil",   type = "control", parts = {"Повторять, пока не", P("c", "cond", "")}},
        {name = "forever",       type = "control", parts = {"Всегда"}},
        {name = "if",            type = "control", parts = {"Если", P("c", "cond", ""), "истинно, то"}},
        {name = "ifElse",        type = "control", parts = {"Если", P("c", "cond", ""), "истинно, то … иначе"}},
        {name = "waitUntil",     type = "action",  parts = {"Ждать, пока не", P("c", "cond", "")}},
        {name = "broadcast",     type = "action",  parts = {"Отправить всем", P("t", "msg", "сообщение1")}},
        {name = "broadcastWait", type = "action",  parts = {"Отправить", P("t", "msg", "сообщение1"), "и ждать"}},
        {name = "clone",         type = "action",  parts = {"Клонировать", P("d", "who", "себя", {dyn = "objectsSelf"})}},
        {name = "deleteClone",   type = "action",  parts = {"Удалить этот клон"}},
        {name = "stop",          type = "action",  parts = {"Остановить этот скрипт"}},
        {name = "finish",        type = "action",  parts = {"Завершить сцену"}},
        {name = "startScene",    type = "action",  parts = {"Запустить сцену", P("d", "scene", "", {dyn = "scenes"})}},
        {name = "continueScene", type = "action",  parts = {"Продолжить сцену"}},
        {name = "note",          type = "action",  parts = {"Примечание:", P("t", "note", "")}},
        {name = "forEach",       type = "control", parts = {"Для каждого значения от", P("n", "from", 1), "до", P("n", "to", 10), "в", P("v", "var", "i")}},
    },

    -- ============================= ДВИЖЕНИЕ ============================
    motion = {
        {name = "move",      type = "action", parts = {"Идти", P("n", "steps", 10), "шагов"}},
        {name = "turnLeft",  type = "action", parts = {"Повернуть влево на", P("n", "deg", 15), "°"}},
        {name = "turnRight", type = "action", parts = {"Повернуть вправо на", P("n", "deg", 15), "°"}},
        {name = "glide",     type = "action", parts = {"Плыть", P("n", "secs", 1), "с к x:", P("n", "x", 0), "y:", P("n", "y", 0)}},
        {name = "goTo",      type = "action", parts = {"Перейти в x:", P("n", "x", 0), "y:", P("n", "y", 0)}},
        {name = "placeAt",   type = "action", parts = {"Поместить в x:", P("n", "x", 0), "y:", P("n", "y", 0)}},
        {name = "setX",      type = "action", parts = {"Установить x в", P("n", "x", 0)}},
        {name = "setY",      type = "action", parts = {"Установить y в", P("n", "y", 0)}},
        {name = "changeX",   type = "action", parts = {"Изменить x на", P("n", "d", 10)}},
        {name = "changeY",   type = "action", parts = {"Изменить y на", P("n", "d", 10)}},
        {name = "pointDir",  type = "action", parts = {"Указать направление", P("n", "deg", 90), "°"}},
        {name = "pointTo",   type = "action", parts = {"Указать на", P("d", "obj", "", {dyn = "objects"})}},
        {name = "bounce",    type = "action", parts = {"Отскочить от края"}},
        {name = "goBack",    type = "action", parts = {"Перейти на", P("n", "n", 1), "слоя назад"}},
        {name = "front",     type = "action", parts = {"Перейти на передний план"}},
        {name = "rotStyle",  type = "action", parts = {"Стиль вращения:", P("d", "style", "вращаться", {opts = {"вращаться", "лево-право", "не вращаться"}})}},
    },

    -- ============================== ЗВУК ===============================
    sound = {
        {name = "playSound",     type = "action", parts = {"Играть звук", P("d", "sound", "", {dyn = "sounds"})}},
        {name = "playSoundWait", type = "action", parts = {"Играть звук и ждать", P("d", "sound", "", {dyn = "sounds"})}},
        {name = "stopSound",     type = "action", parts = {"Остановить звук", P("d", "sound", "", {dyn = "sounds"})}},
        {name = "stopAllSounds", type = "action", parts = {"Остановить все звуки"}},
        {name = "setVolume",     type = "action", parts = {"Громкость", P("n", "vol", 100), "%"}},
        {name = "changeVolume",  type = "action", parts = {"Изменить громкость на", P("n", "d", -10)}},
        {name = "speak",         type = "action", parts = {"Произнеси", P("t", "txt", "Привет!")}},
        {name = "speakWait",     type = "action", parts = {"Произнеси и жди", P("t", "txt", "Привет!")}},
        {name = "setInstrument", type = "action", parts = {"Инструмент:", P("d", "inst", "пиано", {opts = {"пиано", "орган", "гитара", "флейта"}})}},
        {name = "playNote",      type = "action", parts = {"Играть ноту", P("n", "note", 60), "на", P("n", "beats", 1), "долей"}},
        {name = "playDrum",      type = "action", parts = {"Барабан", P("n", "drum", 1), "на", P("n", "beats", 1), "долей"}},
        {name = "setTempo",      type = "action", parts = {"Темп", P("n", "bpm", 60), "уд/мин"}},
        {name = "changeTempo",   type = "action", parts = {"Изменить темп на", P("n", "d", 10)}},
        {name = "pauseBeats",    type = "action", parts = {"Пауза", P("n", "beats", 1), "долей"}},
    },

    -- ============================== ОБРАЗЫ =============================
    looks = {
        {name = "show",            type = "action", parts = {"Показать"}},
        {name = "hide",            type = "action", parts = {"Скрыть"}},
        {name = "nextLook",        type = "action", parts = {"Следующий образ"}},
        {name = "prevLook",        type = "action", parts = {"Предыдущий образ"}},
        {name = "setLook",         type = "action", parts = {"Сменить образ на", P("d", "look", "", {dyn = "looks"})}},
        {name = "setLookNum",      type = "action", parts = {"Сменить образ на номер", P("n", "n", 1)}},
        {name = "setSize",         type = "action", parts = {"Размер", P("n", "pct", 100), "%"}},
        {name = "changeSize",      type = "action", parts = {"Изменить размер на", P("n", "d", 10)}},
        {name = "setTransp",       type = "action", parts = {"Прозрачность", P("n", "pct", 0), "%"}},
        {name = "changeTransp",    type = "action", parts = {"Изменить прозрачность на", P("n", "d", 10)}},
        {name = "setBright",       type = "action", parts = {"Яркость", P("n", "pct", 100), "%"}},
        {name = "changeBright",    type = "action", parts = {"Изменить яркость на", P("n", "d", 10)}},
        {name = "setColor",        type = "action", parts = {"Цвет", P("n", "pct", 0), "%"}},
        {name = "changeColor",     type = "action", parts = {"Изменить цвет на", P("n", "d", 10)}},
        {name = "clearFx",         type = "action", parts = {"Убрать графические эффекты"}},
        {name = "say",             type = "action", parts = {"Сказать", P("t", "txt", "Привет!")}},
        {name = "sayFor",          type = "action", parts = {"Сказать", P("t", "txt", "Привет!"), "в течение", P("n", "secs", 2), "с"}},
        {name = "think",           type = "action", parts = {"Подумать", P("t", "txt", "Хм…")}},
        {name = "thinkFor",        type = "action", parts = {"Подумать", P("t", "txt", "Хм…"), "в течение", P("n", "secs", 2), "с"}},
        {name = "setBackground",       type = "action", parts = {"Установить фон", P("d", "bg", "", {dyn = "backgrounds"})}},
        {name = "setBackgroundWait",   type = "action", parts = {"Установить фон и ждать", P("d", "bg", "", {dyn = "backgrounds"})}},
        {name = "ask",             type = "action", parts = {"Спросить", P("t", "q", "Как тебя зовут?"), "и записать ответ в", P("v", "var", "ответ")}},
    },

    -- =============================== ПЕРО ==============================
    pen = {
        {name = "penDown",    type = "action", parts = {"Опустить перо"}},
        {name = "penUp",      type = "action", parts = {"Поднять перо"}},
        {name = "clear",      type = "action", parts = {"Очистить"}},
        {name = "penSize",    type = "action", parts = {"Размер пера", P("n", "n", 2)}},
        {name = "penColor",   type = "action", parts = {"Цвет пера R:", P("n", "r", 255), "G:", P("n", "g", 0), "B:", P("n", "b", 0)}},
        {name = "stamp",      type = "action", parts = {"Штамп"}},
    },

    -- ============================== ДАННЫЕ =============================
    data = {
        {name = "setVar",     type = "action", parts = {"Задать", P("v", "var", "моя переменная"), "значение", P("t", "val", "0")}},
        {name = "changeVar",  type = "action", parts = {"Изменить", P("v", "var", "моя переменная"), "на", P("n", "d", 1)}},
        {name = "showVar",    type = "action", parts = {"Показать переменную", P("v", "var", "моя переменная")}},
        {name = "hideVar",    type = "action", parts = {"Скрыть переменную", P("v", "var", "моя переменная")}},
        {name = "addList",    type = "action", parts = {"Добавить", P("t", "item", "элемент"), "в список", P("l", "list", "список1")}},
        {name = "delListItem",type = "action", parts = {"Удалить из списка", P("l", "list", "список1"), "элемент", P("n", "idx", 1)}},
        {name = "delListAll", type = "action", parts = {"Очистить список", P("l", "list", "список1")}},
        {name = "insertList", type = "action", parts = {"Вставить", P("t", "item", "элемент"), "в список", P("l", "list", "список1"), "на позицию", P("n", "idx", 1)}},
        {name = "replaceList",type = "action", parts = {"Заменить элемент", P("n", "idx", 1), "списка", P("l", "list", "список1"), "на", P("t", "item", "элемент")}},
    },

    -- ============================ УСТРОЙСТВО ===========================
    device = {
        {name = "vibrate",   type = "action", parts = {"Вибрировать", P("n", "secs", 1), "с"}},
        {name = "flashOn",   type = "action", parts = {"Включить вспышку"}},
        {name = "flashOff",  type = "action", parts = {"Выключить вспышку"}},
        {name = "camOn",     type = "action", parts = {"Включить камеру"}},
        {name = "camOff",    type = "action", parts = {"Выключить камеру"}},
        {name = "chooseCam", type = "action", parts = {"Камера:", P("d", "cam", "задняя", {opts = {"задняя", "передняя"}})}},
    },
}

-- Обратный поиск описания блока по имени
local byName = nil
function M.find(name)
    if not byName then
        byName = {}
        for _, list in pairs(M.BLOCKS) do
            for _, b in ipairs(list) do
                byName[b.name] = b
            end
        end
    end
    return byName[name]
end

function M.categoryOf(name)
    for cat, list in pairs(M.BLOCKS) do
        for _, b in ipairs(list) do
            if b.name == name then return cat end
        end
    end
    return nil
end

-- Создание экземпляра блока из описания
local nextId = 1
function M.instantiate(desc, category)
    local params = {}
    for _, part in ipairs(desc.parts) do
        if type(part) == "table" then
            params[part.id] = part.def
        end
    end
    local inst = {
        id = nextId,
        name = desc.name,
        type = desc.type,
        category = category or M.categoryOf(desc.name),
        params = params,
    }
    nextId = nextId + 1
    if desc.type == "control" then
        inst.children = {}
        if desc.name == "ifElse" then inst.elseChildren = {} end
    end
    return inst
end

function M.nextBlockId()
    local v = nextId
    nextId = nextId + 1
    return v
end

function M.setBlockIdCounter(v)
    nextId = v
end

return M
