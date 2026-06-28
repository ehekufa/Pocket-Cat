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

-- Простой JSON (для совместимости)
M.json = {}
function M.json.encode(obj)
    if type(obj) == "table" then
        local t = {}
        for k, v in pairs(obj) do table.insert(t, '"' .. tostring(k) .. '":' .. M.json.encode(v)) end
        return "{" .. table.concat(t, ",") .. "}"
    elseif type(obj) == "string" then return '"' .. obj .. '"'
    elseif type(obj) == "number" then return tostring(obj)
    elseif type(obj) == "boolean" then return obj and "true" or "false"
    else return "null" end
end
function M.json.decode(str)
    str = str:gsub("%s", "")
    local pos = 1
    local function parse()
        local c = str:sub(pos, pos)
        if c == '{' then
            pos = pos + 1
            local obj = {}
            while str:sub(pos, pos) ~= '}' do
                local key = parse()
                pos = pos + 1
                local val = parse()
                obj[key] = val
                if str:sub(pos, pos) == ',' then pos = pos + 1 end
            end
            pos = pos + 1
            return obj
        elseif c == '"' then
            local start = pos + 1
            local finish = str:find('"', start)
            local val = str:sub(start, finish-1)
            pos = finish + 1
            return val
        elseif c:match("[%d]") then
            local val = str:match("([%d.]+)", pos)
            pos = pos + #val
            return tonumber(val)
        end
    end
    return parse()
end

return M
