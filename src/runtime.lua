-- src/runtime.lua
-- Исполнение проектов: корутинный движок со всеми блоками каталога.
local State = require("src.state")
local expr = require("src.expr")
local catalog = require("src.catalog")

local M = {}

-- ============================ УСЛОВИЯ ============================
local function envOf(robj)
    local rt = State.rt
    local env = {}
    for k, v in pairs(rt.vars) do
        if type(v) == "number" then env[k] = v end
    end
    if robj then
        env.x = robj.x
        env.y = robj.y
        env.dir = robj.dir
        env.size = robj.size
        env.transparency = robj.transp
        env.brightness = robj.bright
    end
    env.volume = rt.globalVolume
    env.tempo = rt.tempo
    env.time = love.timer.getTime()
    local mx, my = love.mouse.getPosition()
    env.mousex = mx
    env.mousey = my
    env.touch = State.rt.touchActive and 1 or 0
    return env
end

local function truthy(v)
    return v ~= nil and v ~= 0 and v ~= false and v ~= ""
end

local function cmpParts(op, a, b)
    local na, nb = tonumber(a), tonumber(b)
    if na ~= nil and nb ~= nil then a, b = na, nb end
    if op == "=" then return a == b
    elseif op == "~=" then return a ~= b
    elseif op == "<" then return a < b
    elseif op == ">" then return a > b
    elseif op == "<=" then return a <= b
    elseif op == ">=" then return a >= b
    end
    return false
end

-- Оценка условий: поддерживает «и»/«или»/«не», сравнения и формулы
local function splitByOr(s)
    local out = {}
    local pattern = "%s*или%s+"
    local last = 1
    while true do
        local st, en = s:find(pattern, last)
        if not st then
            -- english fallback
            st, en = s:find("%s+or%s+", last)
        end
        if not st then
            table.insert(out, s:sub(last))
            break
        end
        table.insert(out, s:sub(last, st - 1))
        last = en + 1
    end
    return out
end

local function splitByAnd(s)
    local out = {}
    local last = 1
    while true do
        local st, en = s:find("%s+и%s+", last)
        if not st then st, en = s:find("%s+and%s+", last) end
        if not st then
            table.insert(out, s:sub(last))
            break
        end
        table.insert(out, s:sub(last, st - 1))
        last = en + 1
    end
    return out
end

M.evalCond = function(str, robj)
    if str == nil or str == "" then return false end
    if type(str) == "number" then return truthy(str) end
    local env = envOf(robj)
    local function evalSimple(s)
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        if s == "" then return true end
        if s == "истина" or s == "true" then return true end
        if s == "ложь" or s == "false" then return false end
        local neg = false
        local n1 = s:match("^не%s+(.*)$") or s:match("^not%s+(.*)$")
        if n1 then neg = true; s = n1 end
        local res
        for _, op in ipairs({"<=", ">=", "~=", "!=", "<", ">", "="}) do
            local esc = op:gsub("([~=<>!])", "%%%1")
            local a, b = s:match("^(.-)" .. esc .. "(.*)$")
            if a and a ~= "" and b ~= "" then
                if op == "!=" then op = "~=" end
                local va = expr.evaluate(a, env)
                local vb = expr.evaluate(b, env)
                res = cmpParts(op, va, vb)
                break
            end
        end
        if res == nil then
            res = truthy(expr.evaluate(s, env))
        end
        return neg and not res or res
    end
    for _, orPart in ipairs(splitByOr(tostring(str))) do
        if orPart:gsub("%s+", "") ~= "" then
            local all = true
            for _, andPart in ipairs(splitByAnd(orPart)) do
                if andPart:gsub("%s+", "") ~= "" and not evalSimple(andPart) then
                    all = false
                end
            end
            if all then return true end
        end
    end
    return false
end

-- ============================ ЗВУК-СИНТЕЗ ============================
local function beep(freq, dur, kind, vol)
    local ok = pcall(function()
        local rate = 22050
        local n = math.max(100, math.floor(rate * dur))
        local sd = love.sound.newSoundData(n, rate, 16, 1)
        for i = 0, n - 1 do
            local t = i / rate
            local v
            if kind == "орган" then
                v = math.sin(2 * math.pi * freq * t) * 0.3 + math.sin(4 * math.pi * freq * t) * 0.2
            elseif kind == "гитара" then
                v = ((freq * t) % 1) * 0.6 - 0.3
            elseif kind == "флейта" then
                v = math.asin(math.sin(2 * math.pi * freq * t)) / math.pi * 0.5
            else
                v = math.sin(2 * math.pi * freq * t) * 0.5
            end
            local envl = math.min(1, t * 30, (dur - t) * 8)
            sd:setSample(i, v * envl * vol)
        end
        local src = love.audio.newSource(sd)
        src:play()
        return src
    end)
    return ok
end

local function drumHit(dur, vol)
    pcall(function()
        local rate = 22050
        local n = math.floor(rate * dur)
        local sd = love.sound.newSoundData(n, rate, 16, 1)
        for i = 0, n - 1 do
            local t = i / rate
            local envl = math.max(0, 1 - t / dur)
            sd:setSample(i, (math.random() * 2 - 1) * envl * envl * 0.5 * vol)
        end
        love.audio.newSource(sd):play()
    end)
end

-- ============================ ЗАПУСК ============================
local function makeRobj(def, isClone)
    return {
        def = def,
        name = def.name,
        x = def.x or 200, y = def.y or 200,
        dir = 90,
        size = def.size or 100,
        visible = def.visible ~= false,
        transp = 0, bright = 100, colorFx = 0,
        lookIdx = 1,
        layer = 0,
        rotStyle = "вращаться",
        penDown = false, penColor = {1, 0, 0}, penSize = 2,
        volume = 100,
        instrument = "пиано",
        isClone = isClone or false,
        say = nil, think = nil, sayUntil = 0,
        dead = false,
    }
end

function M.start(sceneIdx)
    M.stopSounds()
    local sc = State.project.scenes[sceneIdx or State.currentSceneIdx]
    if not sc then return end
    local rt = {
        sceneIdx = sceneIdx or State.currentSceneIdx,
        scene = sc,
        objects = {},
        threads = {},
        queue = {},
        vars = {}, lists = {},
        varShows = {},
        penTrails = {},
        stamps = {},
        bgIdx = 1,
        tempo = 60,
        globalVolume = 100,
        flash = false, camOn = false, camFront = false,
        finished = false,
        whenTrueState = {},
        soundsPlaying = {},
        touchActive = false,
        asking = nil,
        time = 0,
    }
    State.rt = rt
    -- фон как объект
    rt.bgObject = makeRobj({name = "Фон", scripts = sc.backgroundScripts or {}, looks = sc.bgLooks or {}, sounds = {}}, false)
    rt.bgObject.isBackground = true
    for i, od in ipairs(sc.objects) do
        local r = makeRobj(od)
        r.layer = i
        table.insert(rt.objects, r)
    end
    State.running = true
    -- старт
    M.triggerAll("start")
end

function M.stop()
    State.running = false
    M.stopSounds()
    State.rt = nil
end

function M.stopSounds()
    pcall(function()
        for _, src in pairs(State.rt and State.rt.soundsPlaying or {}) do
            if src and src.stop then src:stop() end
        end
        love.audio.stop()
    end)
end

-- Триггеры событий
function M.triggerAll(evName, arg)
    local rt = State.rt
    if not rt then return end
    local function check(robj)
        for _, b in ipairs(robj.def.scripts or {}) do
            if b.type == "event" then
                local fire = false
                if b.name == evName then fire = true end
                if evName == "receive" and b.name == "receive" then
                    fire = (tostring(b.params and b.params.msg or "сообщение1") == tostring(arg))
                end
                if evName == "bgChange" and b.name == "bgChange" then
                    fire = (tostring(b.params and b.params.look or "") == tostring(arg))
                end
                if fire then
                    table.insert(rt.queue, {robj = robj, script = b})
                end
            end
        end
    end
    check(rt.bgObject)
    for _, r in ipairs(rt.objects) do check(r) end
end

function M.spawn(robj, eventBlock)
    local rt = State.rt
    -- исполняем всё после события
    local body = {}
    local scripts = robj.def.scripts or {}
    local found = false
    for _, b in ipairs(scripts) do
        if b == eventBlock then found = true
        elseif found then table.insert(body, b) end
    end
    local co = coroutine.create(function()
        M.exec(robj, body)
    end)
    table.insert(rt.threads, {co = co, robj = robj, gen = rt.genCounter or 0})
end

-- сон внутри корутины
local function sleep(t)
    local e = 0
    while e < t do
        local dt = coroutine.yield()
        e = e + (dt or 0.016)
    end
end

local function yieldFrame()
    coroutine.yield()
end

-- числовой параметр (с формулами)
local function getN(robj, b, id)
    local d = catalog.find(b.name)
    local def = nil
    if d then
        for _, p in ipairs(d.parts) do
            if type(p) == "table" and p.id == id then def = p.def end
        end
    end
    local v = b.params and b.params[id] or def
    if v == nil then return 0 end
    if type(v) == "number" then return v end
    local n = tonumber(v)
    if n then return n end
    return expr.evaluate(v, envOf(robj)) or 0
end

local function getS(robj, b, id)
    local v = b.params and b.params[id]
    if v == nil then
        local d = catalog.find(b.name)
        if d then
            for _, p in ipairs(d.parts) do
                if type(p) == "table" and p.id == id then v = p.def end
            end
        end
    end
    return tostring(v or "")
end

local function findRobjByName(name)
    local rt = State.rt
    for _, r in ipairs(rt.objects) do
        if r.name == name and not r.dead then return r end
    end
    return nil
end

local function lookImage(robj)
    local looks = robj.def.looks or {}
    local l = looks[robj.lookIdx]
    if l then return require("src.ui").loadImage(l.path) end
    return nil
end

local function stageSize()
    return love.graphics.getWidth(), love.graphics.getHeight()
end

local function penSegment(robj, x1, y1, x2, y2)
    local rt = State.rt
    table.insert(rt.penTrails, {x1, y1, x2, y2, robj.penColor[1], robj.penColor[2], robj.penColor[3], robj.penSize})
    if #rt.penTrails > 5000 then table.remove(rt.penTrails, 1) end
end

local function moveWithPen(robj, nx, ny)
    if robj.penDown then penSegment(robj, robj.x, robj.y, nx, ny) end
    robj.x = nx
    robj.y = ny
end

-- ============================ ИСПОЛНЕНИЕ ============================
function M.exec(robj, list)
    local rt = State.rt
    for _, b in ipairs(list) do
        if rt.finished or robj.dead then return end
        M.execBlock(robj, b)
    end
end

function M.execBlock(robj, b)
    local rt = State.rt
    local name = b.name

    -- ============ УПРАВЛЕНИЕ ============
    if name == "wait" then sleep(getN(robj, b, "secs"))
    elseif name == "repeat" then
        local n = math.floor(getN(robj, b, "times"))
        for _ = 1, n do
            if rt.finished or robj.dead then return end
            M.exec(robj, b.children or {})
            yieldFrame()
        end
    elseif name == "repeatUntil" then
        local guard = 0
        while not M.evalCond(getS(robj, b, "cond"), robj) and guard < 100000 do
            M.exec(robj, b.children or {})
            yieldFrame()
            guard = guard + 1
        end
    elseif name == "forever" then
        while not rt.finished and not robj.dead do
            M.exec(robj, b.children or {})
            yieldFrame()
        end
    elseif name == "if" then
        if M.evalCond(getS(robj, b, "cond"), robj) then M.exec(robj, b.children or {}) end
    elseif name == "ifElse" then
        if M.evalCond(getS(robj, b, "cond"), robj) then
            M.exec(robj, b.children or {})
        else
            M.exec(robj, b.elseChildren or {})
        end
    elseif name == "waitUntil" then
        local guard = 0
        while not M.evalCond(getS(robj, b, "cond"), robj) and guard < 100000 do
            yieldFrame()
            guard = guard + 1
        end
    elseif name == "forEach" then
        local from = getN(robj, b, "from")
        local to = getN(robj, b, "to")
        local var = getS(robj, b, "var")
        for v = from, to do
            rt.vars[var] = v
            M.exec(robj, b.children or {})
            yieldFrame()
        end
    elseif name == "broadcast" then
        M.triggerAll("receive", getS(robj, b, "msg"))
    elseif name == "broadcastWait" then
        local before = #rt.threads
        M.triggerAll("receive", getS(robj, b, "msg"))
        sleep(0.05)
        local spawned = {}
        for i = before + 1, #rt.threads do table.insert(spawned, rt.threads[i]) end
        local guard = 0
        while guard < 600 do
            local alive = false
            for _, th in ipairs(spawned) do
                if not th.dead and coroutine.status(th.co) ~= "dead" then alive = true end
            end
            if not alive then break end
            yieldFrame()
            guard = guard + 1
        end
    elseif name == "clone" then
        local who = getS(robj, b, "who")
        local src = (who == "себя" or who == "") and robj or findRobjByName(who) or robj
        local cl = makeRobj(src.def, true)
        cl.x, cl.y, cl.dir, cl.size = src.x, src.y, src.dir, src.size
        cl.visible = src.visible
        cl.lookIdx = src.lookIdx
        cl.layer = #rt.objects + 1
        table.insert(rt.objects, cl)
        for _, sb in ipairs(src.def.scripts or {}) do
            if sb.type == "event" and sb.name == "cloneStart" then
                table.insert(rt.queue, {robj = cl, script = sb})
            end
        end
    elseif name == "deleteClone" then
        if robj.isClone then robj.dead = true; error("endthread") end
    elseif name == "stop" then
        error("endthread")
    elseif name == "finish" then
        rt.finished = true
    elseif name == "startScene" then
        local scName = getS(robj, b, "scene")
        for i, sc in ipairs(State.project.scenes) do
            if sc.name == scName then
                rt.finished = true -- остановить текущую сцену
                M.start(i)
                return
            end
        end
    elseif name == "continueScene" then
        -- продолжить остановленную сцену: нет-оп
    elseif name == "note" then
        -- комментарий

    -- ============ ДВИЖЕНИЕ ============
    elseif name == "move" then
        local s = getN(robj, b, "steps")
        local rad = math.rad(robj.dir)
        moveWithPen(robj, robj.x + math.sin(rad) * s, robj.y - math.cos(rad) * s)
    elseif name == "turnLeft" then robj.dir = robj.dir - getN(robj, b, "deg")
    elseif name == "turnRight" then robj.dir = robj.dir + getN(robj, b, "deg")
    elseif name == "glide" then
        local t = getN(robj, b, "secs")
        local tx, ty = getN(robj, b, "x"), getN(robj, b, "y")
        local sx, sy = robj.x, robj.y
        local e = 0
        while e < t do
            local dt = coroutine.yield() or 0.016
            e = e + dt
            local k = math.min(1, e / math.max(0.01, t))
            moveWithPen(robj, sx + (tx - sx) * k, sy + (ty - sy) * k)
        end
    elseif name == "goTo" or name == "placeAt" then
        moveWithPen(robj, getN(robj, b, "x"), getN(robj, b, "y"))
    elseif name == "setX" then moveWithPen(robj, getN(robj, b, "x"), robj.y)
    elseif name == "setY" then moveWithPen(robj, robj.x, getN(robj, b, "y"))
    elseif name == "changeX" then moveWithPen(robj, robj.x + getN(robj, b, "d"), robj.y)
    elseif name == "changeY" then moveWithPen(robj, robj.x, robj.y + getN(robj, b, "d"))
    elseif name == "pointDir" then robj.dir = getN(robj, b, "deg")
    elseif name == "pointTo" then
        local t = findRobjByName(getS(robj, b, "obj"))
        if t then
            robj.dir = math.deg(math.atan2(t.x - robj.x, -(t.y - robj.y)))
        end
    elseif name == "bounce" then
        local w, h = stageSize()
        local m = 20
        local hitX, hitY = false, false
        if robj.x < m then robj.x = m; hitX = true end
        if robj.x > w - m then robj.x = w - m; hitX = true end
        if robj.y < m + 56 then robj.y = m + 56; hitY = true end
        if robj.y > h - m then robj.y = h - m; hitY = true end
        if hitX then robj.dir = -robj.dir end
        if hitY then robj.dir = 180 - robj.dir end
    elseif name == "goBack" then robj.layer = robj.layer - getN(robj, b, "n")
    elseif name == "front" then
        local maxL = 0
        for _, r in ipairs(rt.objects) do maxL = math.max(maxL, r.layer) end
        robj.layer = maxL + 1
    elseif name == "rotStyle" then robj.rotStyle = getS(robj, b, "style")

    -- ============ ЗВУК ============
    elseif name == "playSound" or name == "playSoundWait" then
        local sndName = getS(robj, b, "sound")
        local path = nil
        for _, s in ipairs(robj.def.sounds or {}) do
            if s.name == sndName then path = s.path end
        end
        local dur = 0.5
        pcall(function()
            local src = path and love.audio.newSource(path, "static") or nil
            if src then
                src:setVolume((robj.volume / 100) * (rt.globalVolume / 100))
                src:play()
                rt.soundsPlaying[sndName] = src
                dur = src:getDuration()
            end
        end)
        if name == "playSoundWait" then sleep(dur) end
    elseif name == "stopSound" then
        pcall(function()
            local src = rt.soundsPlaying[getS(robj, b, "sound")]
            if src then src:stop() end
        end)
    elseif name == "stopAllSounds" then M.stopSounds(); rt.soundsPlaying = {}
    elseif name == "setVolume" then robj.volume = math.max(0, math.min(100, getN(robj, b, "vol")))
    elseif name == "changeVolume" then robj.volume = math.max(0, math.min(100, robj.volume + getN(robj, b, "d")))
    elseif name == "speak" or name == "speakWait" then
        local txt = getS(robj, b, "txt")
        robj.say = txt
        robj.sayUntil = love.timer.getTime() + math.max(1, #txt * 0.06)
        if name == "speakWait" then sleep(math.max(1, #txt * 0.06)) end
    elseif name == "setInstrument" then robj.instrument = getS(robj, b, "inst")
    elseif name == "playNote" then
        local note = getN(robj, b, "note")
        local beats = getN(robj, b, "beats")
        local dur = beats * 60 / rt.tempo
        local freq = 440 * (2 ^ ((note - 69) / 12))
        beep(freq, dur, robj.instrument, (robj.volume / 100) * (rt.globalVolume / 100))
        sleep(dur)
    elseif name == "playDrum" then
        local beats = getN(robj, b, "beats")
        local dur = math.max(0.2, beats * 60 / rt.tempo * 0.5)
        drumHit(dur, (robj.volume / 100) * (rt.globalVolume / 100))
        sleep(dur)
    elseif name == "setTempo" then rt.tempo = math.max(10, getN(robj, b, "bpm"))
    elseif name == "changeTempo" then rt.tempo = math.max(10, rt.tempo + getN(robj, b, "d"))
    elseif name == "pauseBeats" then sleep(getN(robj, b, "beats") * 60 / rt.tempo)

    -- ============ ОБРАЗЫ ============
    elseif name == "show" then robj.visible = true
    elseif name == "hide" then robj.visible = false
    elseif name == "nextLook" then
        local n = #(robj.def.looks or {})
        if n > 0 then robj.lookIdx = (robj.lookIdx % n) + 1 end
    elseif name == "prevLook" then
        local n = #(robj.def.looks or {})
        if n > 0 then robj.lookIdx = ((robj.lookIdx - 2 + n) % n) + 1 end
    elseif name == "setLook" then
        local want = getS(robj, b, "look")
        for i, l in ipairs(robj.def.looks or {}) do
            if l.name == want then robj.lookIdx = i end
        end
    elseif name == "setLookNum" then
        local n = #(robj.def.looks or {})
        local idx = math.floor(getN(robj, b, "n"))
        if n > 0 then robj.lookIdx = ((idx - 1) % n) + 1 end
    elseif name == "setSize" then robj.size = math.max(1, getN(robj, b, "pct"))
    elseif name == "changeSize" then robj.size = math.max(1, robj.size + getN(robj, b, "d"))
    elseif name == "setTransp" then robj.transp = math.max(0, math.min(100, getN(robj, b, "pct")))
    elseif name == "changeTransp" then robj.transp = math.max(0, math.min(100, robj.transp + getN(robj, b, "d")))
    elseif name == "setBright" then robj.bright = math.max(0, math.min(200, getN(robj, b, "pct")))
    elseif name == "changeBright" then robj.bright = math.max(0, math.min(200, robj.bright + getN(robj, b, "d")))
    elseif name == "setColor" then robj.colorFx = getN(robj, b, "pct")
    elseif name == "changeColor" then robj.colorFx = robj.colorFx + getN(robj, b, "d")
    elseif name == "clearFx" then robj.transp = 0; robj.bright = 100; robj.colorFx = 0
    elseif name == "say" then robj.say = getS(robj, b, "txt"); robj.sayUntil = math.huge; robj.thinkBubble = false
    elseif name == "sayFor" then
        robj.say = getS(robj, b, "txt"); robj.thinkBubble = false
        robj.sayUntil = love.timer.getTime() + getN(robj, b, "secs")
        sleep(getN(robj, b, "secs"))
    elseif name == "think" then robj.say = getS(robj, b, "txt"); robj.sayUntil = math.huge; robj.thinkBubble = true
    elseif name == "thinkFor" then
        robj.say = getS(robj, b, "txt"); robj.thinkBubble = true
        robj.sayUntil = love.timer.getTime() + getN(robj, b, "secs")
        sleep(getN(robj, b, "secs"))
    elseif name == "setBackground" or name == "setBackgroundWait" then
        local want = getS(robj, b, "bg")
        for i, l in ipairs(rt.scene.bgLooks or {}) do
            if l.name == want then rt.bgIdx = i end
        end
        M.triggerAll("bgChange", want)
        if name == "setBackgroundWait" then sleep(0.3) end
    elseif name == "ask" then
        rt.asking = {q = getS(robj, b, "q"), var = getS(robj, b, "var"), answer = nil}
        robj.say = rt.asking.q
        robj.sayUntil = math.huge
        local guard = 0
        while not rt.asking.answer and guard < 3000 do
            yieldFrame()
            guard = guard + 1
        end
        rt.vars[rt.asking.var] = rt.asking.answer or ""
        rt.asking = nil
        robj.say = nil

    -- ============ ПЕРО ============
    elseif name == "penDown" then robj.penDown = true
    elseif name == "penUp" then robj.penDown = false
    elseif name == "clear" then rt.penTrails = {}; rt.stamps = {}
    elseif name == "penSize" then robj.penSize = math.max(1, getN(robj, b, "n"))
    elseif name == "penColor" then
        robj.penColor = {getN(robj, b, "r") / 255, getN(robj, b, "g") / 255, getN(robj, b, "b") / 255}
    elseif name == "stamp" then
        table.insert(rt.stamps, {
            img = lookImage(robj), x = robj.x, y = robj.y,
            rot = math.rad(robj.dir - 90), scale = robj.size / 100,
            alpha = 1 - robj.transp / 100,
        })

    -- ============ ДАННЫЕ ============
    elseif name == "setVar" then
        local val = getS(robj, b, "val")
        local n = tonumber(val)
        rt.vars[getS(robj, b, "var")] = n or expr.evaluate(val, envOf(robj)) or val
    elseif name == "changeVar" then
        local var = getS(robj, b, "var")
        rt.vars[var] = (tonumber(rt.vars[var]) or 0) + getN(robj, b, "d")
    elseif name == "showVar" then
        local var = getS(robj, b, "var")
        local count = 0
        for _ in pairs(rt.varShows) do count = count + 1 end
        rt.varShows[var] = {x = 12, y = 70 + count * 30}
    elseif name == "hideVar" then rt.varShows[getS(robj, b, "var")] = nil
    elseif name == "addList" then
        local l = getS(robj, b, "list")
        rt.lists[l] = rt.lists[l] or {}
        table.insert(rt.lists[l], getS(robj, b, "item"))
    elseif name == "delListItem" then
        local l = getS(robj, b, "list")
        local list = rt.lists[l]
        if list then table.remove(list, math.floor(getN(robj, b, "idx"))) end
    elseif name == "delListAll" then rt.lists[getS(robj, b, "list")] = {}
    elseif name == "insertList" then
        local l = getS(robj, b, "list")
        rt.lists[l] = rt.lists[l] or {}
        table.insert(rt.lists[l], math.floor(getN(robj, b, "idx")), getS(robj, b, "item"))
    elseif name == "replaceList" then
        local l = getS(robj, b, "list")
        rt.lists[l] = rt.lists[l] or {}
        rt.lists[l][math.floor(getN(robj, b, "idx"))] = getS(robj, b, "item")

    -- ============ УСТРОЙСТВО ============
    elseif name == "vibrate" then
        pcall(function() love.system.vibrate(getN(robj, b, "secs")) end)
    elseif name == "flashOn" then rt.flash = true
    elseif name == "flashOff" then rt.flash = false
    elseif name == "camOn" then rt.camOn = true; State.toast("Камера: превью недоступно на этом устройстве")
    elseif name == "camOff" then rt.camOn = false
    elseif name == "chooseCam" then rt.camFront = (getS(robj, b, "cam") == "передняя")
    end
end

-- ============================ ЦИКЛ ============================
function M.update(dt)
    local rt = State.rt
    if not rt or not State.running then return end
    rt.time = rt.time + dt

    -- события whenTrue
    local function checkWhen(robj)
        for _, b in ipairs(robj.def.scripts or {}) do
            if b.type == "event" and b.name == "whenTrue" then
                local key = tostring(robj.name) .. "|" .. tostring(b.id or b.name)
                local cond = M.evalCond(b.params and b.params.cond or "", robj)
                local prev = rt.whenTrueState[key]
                if cond and not prev then
                    table.insert(rt.queue, {robj = robj, script = b})
                end
                rt.whenTrueState[key] = cond
            end
        end
    end
    checkWhen(rt.bgObject)
    for _, r in ipairs(rt.objects) do checkWhen(r) end

    -- очередь событий
    local q = rt.queue
    rt.queue = {}
    for _, ev in ipairs(q) do
        if not ev.robj.dead then M.spawn(ev.robj, ev.script) end
    end

    -- потоки
    local alive = {}
    for _, th in ipairs(rt.threads) do
        if not th.dead and not (th.robj and th.robj.dead) then
            local ok, err = coroutine.resume(th.co, dt)
            if not ok then
                local s = tostring(err)
                if not s:find("endthread") then
                    State.toast("Ошибка в скрипте: " .. s)
                end
                th.dead = true
            end
            if coroutine.status(th.co) == "dead" then th.dead = true end
        else
            th.dead = true
        end
        if not th.dead then table.insert(alive, th) end
    end
    rt.threads = alive

    -- облачка речи
    local now = love.timer.getTime()
    local function clearSay(r)
        if r.say and r.sayUntil ~= math.huge and now > r.sayUntil then r.say = nil end
    end
    for _, r in ipairs(rt.objects) do clearSay(r) end

    -- удаление мёртвых клонов
    local objs = {}
    for _, r in ipairs(rt.objects) do
        if not r.dead then table.insert(objs, r) end
    end
    rt.objects = objs
end

-- касание сцены во время выполнения
function M.touchPressed(x, y)
    local rt = State.rt
    if not rt then return end
    rt.touchActive = true
    -- объект под пальцем (сверху по слоям)
    local sorted = {}
    for _, r in ipairs(rt.objects) do table.insert(sorted, r) end
    table.sort(sorted, function(a, b) return a.layer > b.layer end)
    for _, r in ipairs(sorted) do
        if r.visible then
            local img = lookImage(r)
            local half = (img and math.max(img:getWidth(), img:getHeight()) or 60) * (r.size / 100) / 2 + 10
            if math.abs(x - r.x) <= half and math.abs(y - r.y) <= half then
                for _, b in ipairs(r.def.scripts or {}) do
                    if b.type == "event" and b.name == "tap" then
                        table.insert(rt.queue, {robj = r, script = b})
                    end
                end
                break
            end
        end
    end
    M.triggerAll("stageTap")
end

function M.touchReleased()
    local rt = State.rt
    if rt then rt.touchActive = false end
end

return M
