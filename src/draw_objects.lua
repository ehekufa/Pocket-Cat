-- src/draw_objects.lua
local State = require("src.state")
local project = require("src.project")

local M = {}

function M.drawSceneObjects()
    -- Draw pen trails
    if #State.penPoints > 1 then
        love.graphics.setLineWidth(State.penSize or 2)
        for i = 2, #State.penPoints do
            local p1 = State.penPoints[i-1]
            local p2 = State.penPoints[i]
            love.graphics.setColor(p1[3], p1[4], p1[5])
            love.graphics.line(p1[1], p1[2], p2[1], p2[2])
        end
    end

    -- Show image (sprite)
    if State.showImage then
        local obj = project.getCurrentObject()
        if obj and obj.image then
            if not obj.loadedImage then
                local file = love.filesystem.newFile(obj.image)
                if file then obj.loadedImage = love.graphics.newImage(file) end
            end
            if obj.loadedImage then
                love.graphics.setColor(1,1,1)
                love.graphics.draw(obj.loadedImage, State.cubeX, State.cubeY,
                    math.rad(State.objectAngle), State.objectSize/32, State.objectSize/32, 16, 16)
            end
        end
    end

    -- Show cube
    if State.showCube then
        love.graphics.push()
        love.graphics.translate(State.cubeX, State.cubeY)
        love.graphics.rotate(math.rad(State.objectAngle))
        local s = State.objectSize/30
        love.graphics.scale(s, s)
        love.graphics.setColor(State.objectColor)
        love.graphics.setLineWidth(2)
        for _, edge in ipairs(State.cubeEdges) do
            local p1 = State.cubeVertices[edge[1]]
            local p2 = State.cubeVertices[edge[2]]
            love.graphics.line(p1[1]*10, p1[2]*10, p2[1]*10, p2[2]*10)
        end
        love.graphics.pop()
    end

    -- Show sphere
    if State.showSphere then
        love.graphics.setColor(State.objectColor)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", State.sphereX, State.sphereY, State.objectSize, 24)
    end
end

return M
