-- src/firebase.lua
local M = {}
local utils = require("src.utils")
local json = utils.json

-- Функции для работы с полным URL (пользователь вводит сам)
function M.getFull(url)
    if not url:match("%.json$") then
        url = url .. ".json"
    end
    local cmd = 'curl -s "' .. url .. '"'
    local f = io.popen(cmd, 'r')
    local data = f:read('*a')
    f:close()
    if data and data ~= "" then
        local decoded = json.decode(data)
        return decoded
    end
    return nil
end

function M.putFull(url, data)
    if not url:match("%.json$") then
        url = url .. ".json"
    end
    local jsonData = json.encode(data)
    local cmd = 'curl -s -X PUT -H "Content-Type: application/json" -d \'' .. jsonData .. '\' "' .. url .. '"'
    local f = io.popen(cmd, 'r')
    local result = f:read('*a')
    f:close()
    return result
end

-- (Оставляем старые функции для совместимости, но они не используются)
M.baseURL = "https://YOUR_PROJECT.firebaseio.com/"
M.authToken = nil

function M.setAuth(token)
    M.authToken = token
end

function M.get(path)
    local url = M.baseURL .. path .. ".json"
    if M.authToken then url = url .. "?auth=" .. M.authToken end
    local cmd = 'curl -s "' .. url .. '"'
    local f = io.popen(cmd, 'r')
    local data = f:read('*a')
    f:close()
    if data and data ~= "" then
        return json.decode(data)
    end
    return nil
end

function M.put(path, data)
    local url = M.baseURL .. path .. ".json"
    if M.authToken then url = url .. "?auth=" .. M.authToken end
    local jsonData = json.encode(data)
    local cmd = 'curl -s -X PUT -H "Content-Type: application/json" -d \'' .. jsonData .. '\' "' .. url .. '"'
    local f = io.popen(cmd, 'r')
    local result = f:read('*a')
    f:close()
    return result
end

return M
