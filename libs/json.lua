-- libs/json.lua
-- Простой JSON-кодер/декодер для LÖVE

local json = {}

function json.encode(obj)
    if type(obj) == "table" then
        local isArray = true
        for k, v in pairs(obj) do
            if type(k) ~= "number" then
                isArray = false
                break
            end
        end
        if isArray then
            local t = {}
            for i, v in ipairs(obj) do
                table.insert(t, json.encode(v))
            end
            return "[" .. table.concat(t, ",") .. "]"
        else
            local t = {}
            for k, v in pairs(obj) do
                table.insert(t, '"' .. tostring(k) .. '":' .. json.encode(v))
            end
            return "{" .. table.concat(t, ",") .. "}"
        end
    elseif type(obj) == "string" then
        return '"' .. obj:gsub('"', '\\"') .. '"'
    elseif type(obj) == "number" then
        return tostring(obj)
    elseif type(obj) == "boolean" then
        return obj and "true" or "false"
    else
        return "null"
    end
end

function json.decode(str)
    if type(str) ~= "string" then return nil end
    str = str:gsub("%s", "")  -- удаляем пробелы
    local pos = 1

    local function parseValue()
        local c = str:sub(pos, pos)
        if c == '{' then
            pos = pos + 1
            local obj = {}
            while pos <= #str and str:sub(pos, pos) ~= '}' do
                -- читаем ключ
                local key = parseValue()
                pos = pos + 1  -- пропускаем ':'
                -- читаем значение
                local val = parseValue()
                obj[key] = val
                -- пропускаем запятую, если есть
                if str:sub(pos, pos) == ',' then pos = pos + 1 end
            end
            pos = pos + 1  -- пропускаем '}'
            return obj
        elseif c == '[' then
            pos = pos + 1
            local arr = {}
            while pos <= #str and str:sub(pos, pos) ~= ']' do
                local val = parseValue()
                table.insert(arr, val)
                if str:sub(pos, pos) == ',' then pos = pos + 1 end
            end
            pos = pos + 1  -- пропускаем ']'
            return arr
        elseif c == '"' then
            local start = pos + 1
            local finish = start
            while finish <= #str do
                if str:sub(finish, finish) == '\\' then
                    finish = finish + 2  -- пропускаем экранированный символ
                elseif str:sub(finish, finish) == '"' then
                    break
                else
                    finish = finish + 1
                end
            end
            local val = str:sub(start, finish-1):gsub('\\.', function(esc)
                if esc == '\\"' then return '"'
                elseif esc == '\\\\' then return '\\'
                elseif esc == '\\/' then return '/'
                elseif esc == '\\n' then return '\n'
                elseif esc == '\\r' then return '\r'
                elseif esc == '\\t' then return '\t'
                else return esc
                end
            end)
            pos = finish + 1
            return val
        elseif c:match("[%d%-]") then
            local val = str:match("([%d%.%-]+)", pos)
            pos = pos + #val
            return tonumber(val)
        elseif c == 't' then
            pos = pos + 4
            return true
        elseif c == 'f' then
            pos = pos + 5
            return false
        elseif c == 'n' then
            pos = pos + 4
            return nil
        else
            error("Unexpected character at position " .. pos .. ": " .. c)
        end
    end

    return parseValue()
end

return json
