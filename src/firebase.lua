-- src/firebase.lua
local M = {}
local json = require("src.utils").json

-- Попытка загрузить LuaSocket (есть на Windows, на Android обычно нет)
local hasSocket, http, ltn12, url = pcall(function()
    return require("socket.http"), require("ltn12"), require("socket.url")
end)

-- Если LuaSocket не загружен, будем использовать love.net (Android / fallback)
local function useLoveNet()
    if not love.net then
        error("Neither LuaSocket nor love.net available")
    end
end

-- Вспомогательная функция: отправляет запрос и возвращает (data, code)
local function request(method, fullUrl, data)
    if hasSocket then
        -- === Ветка LuaSocket (синхронно) ===
        local parsed = url.parse(fullUrl)
        if not parsed.host then
            return nil, "Invalid URL"
        end
        local body = data and json.encode(data) or ""
        local req = {
            url = fullUrl,
            method = method,
            headers = {
                ["Content-Type"] = "application/json",
                ["Content-Length"] = tostring(#body),
            },
            source = ltn12.source.string(body),
            sink = ltn12.sink.table({}),
        }
        local response_table = {}
        local res, code, headers = http.request(req)
        if code and code >= 200 and code < 300 then
            local result = table.concat(response_table)
            if result and result ~= "" then
                local decoded = json.decode(result)
                return decoded, code
            end
            return true, code  -- успех, но тело пустое
        else
            return nil, code or "Network error"
        end
    else
        -- === Ветка love.net (асинхронно, но делаем синхронную обёртку через канал) ===
        useLoveNet()
        local channel = love.thread.getChannel("firebase_response")
        local req = love.net.newHTTPRequest(method, fullUrl, {
            ["Content-Type"] = "application/json"
        }, data and json.encode(data) or nil)

        req:setCallback(function(response)
            local status = response:getStatus()
            local body = response:getBody()
            if status >= 200 and status < 300 then
                if body and body ~= "" then
                    local decoded = json.decode(body)
                    channel:push({ok = true, data = decoded, code = status})
                else
                    channel:push({ok = true, data = true, code = status})
                end
            else
                channel:push({ok = false, code = status})
            end
        end)

        req:send()

        -- Ждём ответа (блокируем поток до получения)
        while true do
            local resp = channel:pop()
            if resp then
                if resp.ok then
                    return resp.data, resp.code
                else
                    return nil, resp.code
                end
            end
            love.timer.sleep(0.01) -- не нагружаем процессор
        end
    end
end

-- ===== Публичные функции (интерфейс не меняется) =====
function M.getFull(url)
    local data, err = request("GET", url)
    if err then
        print("Firebase GET error:", err)
        return nil
    end
    return data
end

function M.putFull(url, data)
    local result, err = request("PUT", url, data)
    if err then
        print("Firebase PUT error:", err)
        return nil
    end
    return result
end

-- Для обратной совместимости со старым кодом (базовый URL + токен)
M.baseURL = ""
M.authToken = nil
function M.setAuth(token) M.authToken = token end
function M.get(path)
    local full = M.baseURL .. path .. ".json"
    if M.authToken then full = full .. "?auth=" .. M.authToken end
    return M.getFull(full)
end
function M.put(path, data)
    local full = M.baseURL .. path .. ".json"
    if M.authToken then full = full .. "?auth=" .. M.authToken end
    return M.putFull(full, data)
end

return M
