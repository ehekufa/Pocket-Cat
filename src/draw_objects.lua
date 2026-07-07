-- src/draw_objects.lua
local State = require("src.state")
local project = require("src.project")

local M = {}

function M.drawSceneObjects()
    -- Следы пера
    if #State.penPoints > 1 then
        love.graphics.setLineWidth(State.penSize or 2)
        for i = 2, #State.penPoints do
            local p1 = State.penPoints[i-1]
            local p2 = State.penPoints[i]
            love.graphics.setColor(p1[3], p1[4], p1[5])
            love.graphics.line(p1[1], p1[2], p2[1], p2[2])
        end
    end

    -- Спрайт (изображение)
    if State.showImage then
        local obj = project.getCurrentObject()
        if obj and obj.image then
            if not obj.loadedImage then
                if love.filesystem.getInfo(obj.image) then
                    local success, img = pcall(love.graphics.newImage, obj.image)
                    if success and img then
                        obj.loadedImage = img
                    else
                        obj.loadedImage = false
                    end
                else
                    obj.loadedImage = false
                end
            end
            if obj.loadedImage and obj.loadedImage ~= false then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(obj.loadedImage, State.cubeX, State.cubeY,
                    math.rad(State.objectAngle),
                    State.objectSize / 32, State.objectSize / 32,
                    16, 16)
            end
        end
    end

    -- Залитый куб
    if State.showCube then
        love.graphics.push()
        love.graphics.translate(State.cubeX, State.cubeY)
        love.graphics.rotate(math.rad(State.objectAngle))
        local s = State.objectSize / 30
        love.graphics.scale(s, s)
        local v = State.cubeVertices
        local size = 10
        -- Передняя грань
        love.graphics.setColor(State.objectColor)
        love.graphics.polygon("fill",
            v[1][1]*size, v[1][2]*size,
            v[2][1]*size, v[2][2]*size,
            v[3][1]*size, v[3][2]*size,
            v[4][1]*size, v[4][2]*size)
        love.graphics.polygon("fill",
            v[4][1]*size, v[4][2]*size,
            v[3][1]*size, v[3][2]*size,
            v[7][1]*size, v[7][2]*size,
            v[8][1]*size, v[8][2]*size)
        love.graphics.polygon("fill",
            v[2][1]*size, v[2][2]*size,
            v[6][1]*size, v[6][2]*size,
            v[7][1]*size, v[7][2]*size,
            v[3][1]*size, v[3][2]*size)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(1)
        for _, edge in ipairs(State.cubeEdges) do
            local p1 = State.cubeVertices[edge[1]]
            local p2 = State.cubeVertices[edge[2]]
            love.graphics.line(p1[1]*size, p1[2]*size, p2[1]*size, p2[2]*size)
        end
        love.graphics.pop()
    end

    -- Залитая сфера
    if State.showSphere then
        love.graphics.setColor(State.objectColor)
        love.graphics.circle("fill", State.sphereX, State.sphereY, State.objectSize, 24)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", State.sphereX, State.sphereY, State.objectSize, 24)
    end
end

return M
