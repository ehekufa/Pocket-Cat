-- src/draw_objects.lua
local State = require("src.state")
local project = require("src.project")

local M = {}

function M.drawSceneObjects()
    -- Рисуем следы пера
    if #State.penPoints > 1 then
        love.graphics.setLineWidth(State.penSize or 2)
        for i = 2, #State.penPoints do
            local p1 = State.penPoints[i-1]
            local p2 = State.penPoints[i]
            love.graphics.setColor(p1[3], p1[4], p1[5])
            love.graphics.line(p1[1], p1[2], p2[1], p2[2])
        end
    end

    -- Показываем спрайт (изображение)
    if State.showImage then
        local obj = project.getCurrentObject()
        if obj and obj.image then
            -- Пытаемся загрузить изображение, если ещё не загружено
            if not obj.loadedImage then
                -- Проверяем, существует ли файл
                if love.filesystem.getInfo(obj.image) then
                    -- Загружаем изображение напрямую по пути (строке)
                    local success, img = pcall(love.graphics.newImage, obj.image)
                    if success and img then
                        obj.loadedImage = img
                        print("Image loaded: " .. obj.image)
                    else
                        print("Failed to load image: " .. obj.image)
                        obj.loadedImage = false -- чтобы не пытаться снова
                    end
                else
                    print("Image file not found: " .. obj.image)
                    obj.loadedImage = false
                end
            end

            -- Если изображение загружено успешно, рисуем его
            if obj.loadedImage and obj.loadedImage ~= false then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(obj.loadedImage, State.cubeX, State.cubeY,
                    math.rad(State.objectAngle),
                    State.objectSize / 32, State.objectSize / 32,
                    16, 16) -- центрируем (предполагаем размер 32x32)
            end
        end
    end

    -- Показываем куб
    if State.showCube then
        love.graphics.push()
        love.graphics.translate(State.cubeX, State.cubeY)
        love.graphics.rotate(math.rad(State.objectAngle))
        local s = State.objectSize / 30
        love.graphics.scale(s, s)
        love.graphics.setColor(State.objectColor)
        love.graphics.setLineWidth(2)
        for _, edge in ipairs(State.cubeEdges) do
            local p1 = State.cubeVertices[edge[1]]
            local p2 = State.cubeVertices[edge[2]]
            love.graphics.line(p1[1] * 10, p1[2] * 10, p2[1] * 10, p2[2] * 10)
        end
        love.graphics.pop()
    end

    -- Показываем сферу
    if State.showSphere then
        love.graphics.setColor(State.objectColor)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", State.sphereX, State.sphereY, State.objectSize, 24)
    end
end

return M
