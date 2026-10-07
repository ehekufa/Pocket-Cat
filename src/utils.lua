-- src/utils.lua
local M = {}

function M.safeUTF8(str)
    if type(str) ~= "string" then return tostring(str) end
    local res = {}
    local i = 1
    while i <= #str do
        local c = str:byte(i)
        local len = 1
        if c < 0x80 then len = 1
        elseif c >= 0xC2 and c < 0xE0 then len = 2
        elseif c >= 0xE0 and c < 0xF0 then len = 3
        elseif c >= 0xF0 and c < 0xF5 then len = 4
        else
            table.insert(res, "?")
            i = i + 1
        end
        if len == 1 and c >= 0x80 then
            -- skip invalid
        else
            if i + len - 1 > #str then
                table.insert(res, "?")
                break
            end
            local valid = true
            for j = 2, len do
                local cb = str:byte(i + j - 1)
                if not (cb >= 0x80 and cb < 0xC0) then valid = false; break end
            end
            if valid then
                table.insert(res, str:sub(i, i + len - 1))
                i = i + len
            else
                table.insert(res, "?")
                i = i + 1
            end
        end
    end
    return table.concat(res)
end

function M.hsvToRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    return r, g, b
end

-- ============================ JSON ============================
M.json = {}

local function escapeStr(s)
    s = s:gsub("\\", "\\\\")
    s = s:gsub("\"", "\\\"")
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\t", "\\t")
    s = s:gsub("[%c]", function(ch)
        return string.format("\\u%04x", ch:byte())
    end)
    return s
end

local function isArray(t)
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" then return false end
        n = n + 1
    end
    return n == #t
end

function M.json.encode(obj)
    local t = type(obj)
    if t == "table" then
        if isArray(obj) then
            local parts = {}
            for _, v in ipairs(obj) do
                table.insert(parts, M.json.encode(v))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local parts = {}
        for k, v in pairs(obj) do
            if v ~= nil and type(v) ~= "function" then
                table.insert(parts, '"' .. escapeStr(tostring(k)) .. '":' .. M.json.encode(v))
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif t == "string" then
        return '"' .. escapeStr(obj) .. '"'
    elseif t == "number" then
        if obj ~= obj or obj == math.huge or obj == -math.huge then return "null" end
        if obj == math.floor(obj) and math.abs(obj) < 1e15 then
            return string.format("%d", obj)
        end
        return string.format("%.14g", obj)
    elseif t == "boolean" then
        return obj and "true" or "false"
    end
    return "null"
end

function M.json.decode(str)
    if type(str) ~= "string" or str == "" then return nil end
    local pos = 1
    local len = #str

    local function skipWs()
        while pos <= len do
            local c = str:sub(pos, pos)
            if c == " " or c == "\t" or c == "\n" or c == "\r" then
                pos = pos + 1
            else
                break
            end
        end
    end

    local parseValue

    local function parseString()
        -- pos на открывающей кавычке
        pos = pos + 1
        local out = {}
        while pos <= len do
            local c = str:sub(pos, pos)
            if c == '"' then
                pos = pos + 1
                return table.concat(out)
            elseif c == "\\" then
                local e = str:sub(pos + 1, pos + 1)
                if e == "n" then table.insert(out, "\n")
                elseif e == "r" then table.insert(out, "\r")
                elseif e == "t" then table.insert(out, "\t")
                elseif e == "b" then table.insert(out, "\b")
                elseif e == "f" then table.insert(out, "\f")
                elseif e == "/" then table.insert(out, "/")
                elseif e == "\\" then table.insert(out, "\\")
                elseif e == '"' then table.insert(out, '"')
                elseif e == "u" then
                    local hex = str:sub(pos + 2, pos + 5)
                    local code = tonumber(hex, 16)
                    if code then
                        -- UTF-8
                        if code < 0x80 then
                            table.insert(out, string.char(code))
                        elseif code < 0x800 then
                            table.insert(out, string.char(0xC0 + math.floor(code / 0x40), 0x80 + code % 0x40))
                        else
                            table.insert(out, string.char(0xE0 + math.floor(code / 0x1000),
                                0x80 + math.floor(code / 0x40) % 0x40, 0x80 + code % 0x40))
                        end
                    end
                    pos = pos + 4
                end
                pos = pos + 2
            else
                table.insert(out, c)
                pos = pos + 1
            end
        end
        return table.concat(out)
    end

    local function parseNumber()
        local s = str:match("^-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
        pos = pos + #s
        return tonumber(s)
    end

    -- объект с числовыми ключами ("1":..) превращаем в массив (старые файлы)
    local function maybeArray(obj)
        local n = 0
        for k in pairs(obj) do
            if type(k) ~= "string" or not k:match("^%d+$") then return obj end
            n = n + 1
        end
        if n == 0 then return obj end
        local arr = {}
        for k, v in pairs(obj) do
            arr[tonumber(k)] = v
        end
        return arr
    end

    parseValue = function()
        skipWs()
        local c = str:sub(pos, pos)
        if c == "{" then
            pos = pos + 1
            local obj = {}
            skipWs()
            if str:sub(pos, pos) == "}" then pos = pos + 1 return obj end
            while pos <= len do
                skipWs()
                local key = parseString()
                skipWs()
                if str:sub(pos, pos) == ":" then pos = pos + 1 end
                obj[key] = parseValue()
                skipWs()
                local sep = str:sub(pos, pos)
                if sep == "," then pos = pos + 1
                elseif sep == "}" then pos = pos + 1 break end
            end
            return maybeArray(obj)
        elseif c == "[" then
            pos = pos + 1
            local arr = {}
            skipWs()
            if str:sub(pos, pos) == "]" then pos = pos + 1 return arr end
            while pos <= len do
                table.insert(arr, parseValue())
                skipWs()
                local sep = str:sub(pos, pos)
                if sep == "," then pos = pos + 1
                elseif sep == "]" then pos = pos + 1 break end
            end
            return arr
        elseif c == '"' then
            return parseString()
        elseif c == "t" then pos = pos + 4; return true
        elseif c == "f" then pos = pos + 5; return false
        elseif c == "n" then pos = pos + 4; return nil
        else
            return parseNumber()
        end
    end

    local ok, res = pcall(parseValue)
    if ok then return res end
    return nil
end

return M
