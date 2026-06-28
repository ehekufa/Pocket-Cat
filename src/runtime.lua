-- src/runtime.lua
local State = require("src.state")
local project = require("src.project")

local M = {}

function M.compileScript()
    State.eventHandlers = {}
    local ce = nil
    for _, b in ipairs(State.workspaceBlocks) do
        if b.type == "event" then
            ce = b.name
            State.eventHandlers[ce] = State.eventHandlers[ce] or {}
        elseif b.type == "action" and ce then
            table.insert(State.eventHandlers[ce], b)
        end
    end
end

function M.executeActions(actions)
    if not actions then return false end
    local i = 1
    while i <= #actions and not State.stopAll do
        local a = actions[i]
        local p = a.param
        if a.name == "changeX" then State.cubeX = State.cubeX + (tonumber(p) or 10)
        elseif a.name == "changeY" then State.cubeY = State.cubeY + (tonumber(p) or 10)
        elseif a.name == "setX" then State.cubeX = tonumber(p) or 200
        elseif a.name == "setY" then State.cubeY = tonumber(p) or 200
        elseif a.name == "turn" then State.objectAngle = State.objectAngle + (tonumber(p) or 15)
        elseif a.name == "showCube" then State.showCube = true; State.showImage = false
        elseif a.name == "showSphere" then State.showSphere = true; State.showImage = false
        elseif a.name == "showImage" then State.showImage = true; State.showCube = false; State.showSphere = false
        elseif a.name == "hide" then State.showCube, State.showSphere, State.showImage = false, false, false
        elseif a.name == "show" then State.showImage = true
        elseif a.name == "setColor" then
            if p == "green" then State.objectColor = {0.2,0.8,0.4}
            elseif p == "red" then State.objectColor = {0.9,0.2,0.2}
            elseif p == "blue" then State.objectColor = {0.2,0.4,1.0}
            end
        elseif a.name == "setSize" then State.objectSize = tonumber(p) or 50
        elseif a.name == "penDown" then State.penDown = true
        elseif a.name == "penUp" then State.penDown = false
        elseif a.name == "penClear" then State.penPoints = {}
        elseif a.name == "penColor" then
            if p == "green" then State.penColor = {0.2,0.8,0.4}
            elseif p == "red" then State.penColor = {0.9,0.2,0.2}
            elseif p == "blue" then State.penColor = {0.2,0.4,1.0}
            end
        elseif a.name == "penSize" then State.penSize = tonumber(p) or 2
        elseif a.name == "playSound" then
            local filename = "sounds/" .. p
            if love.filesystem.getInfo(filename) then
                local source = love.audio.newSource(filename, "static")
                if source then source:play() end
            end
        elseif a.name == "wait" then State.waitTimer = tonumber(p) or 1; return true
        elseif a.name == "forever" then if not State.stopAll then i = i - 1 end
        elseif a.name == "ifTap" then if not State.isTapped then return true end
        elseif a.name == "stopAll" then State.stopAll = true; return true
        elseif a.name == "printText" then table.insert(State.messages, tostring(p or "Hello!"))
        elseif a.name == "mouseX" then table.insert(State.messages, "mouse X: "..love.mouse.getX())
        elseif a.name == "mouseY" then table.insert(State.messages, "mouse Y: "..love.mouse.getY())
        elseif a.name == "touchX" then
            local touches = love.touch.getTouches()
            if touches[1] then table.insert(State.messages, "touch X: "..love.touch.getPosition(touches[1])) else table.insert(State.messages, "no touch") end
        elseif a.name == "touchY" then
            local touches = love.touch.getTouches()
            if touches[1] then table.insert(State.messages, "touch Y: "..select(2, love.touch.getPosition(touches[1]))) else table.insert(State.messages, "no touch") end
        end
        if State.penDown and (a.name == "changeX" or a.name == "changeY" or a.name == "setX" or a.name == "setY" or a.name == "turn") then
            table.insert(State.penPoints, {State.cubeX, State.cubeY, State.penColor[1], State.penColor[2], State.penColor[3], State.penSize})
        end
        i = i + 1
    end
    return false
end

function M.runProject()
    State.stopAll = false
    State.drawCommands = {}
    State.messages = {}
    State.vars = {}
    State.waitTimer = 0
    State.penDown = false
    State.penPoints = {}
    M.compileScript()
    if State.eventHandlers["start"] then
        M.executeActions(State.eventHandlers["start"])
    end
end

function M.update(dt)
    if State.waitTimer > 0 then
        State.waitTimer = State.waitTimer - dt
        if State.waitTimer <= 0 then State.waitTimer = 0 end
    end
end

return M
