-- src/expr.lua
local M = {}

local function tokenize(expr)
    local tokens = {}
    local i = 1
    while i <= #expr do
        local c = expr:sub(i, i)
        if c:match("%s") then
            i = i + 1
        elseif c:match("[%d.]") then
            local num = ""
            while i <= #expr and expr:sub(i, i):match("[%d.]") do
                num = num .. expr:sub(i, i)
                i = i + 1
            end
            table.insert(tokens, {type = "number", value = tonumber(num)})
        elseif c:match("[%a_]") then
            local id = ""
            while i <= #expr and expr:sub(i, i):match("[%a_%d]") do
                id = id .. expr:sub(i, i)
                i = i + 1
            end
            if id == "sin" or id == "cos" or id == "tan" or id == "sqrt" or id == "abs" or id == "log" or id == "exp" then
                table.insert(tokens, {type = "function", value = id})
            elseif id == "pi" then
                table.insert(tokens, {type = "number", value = math.pi})
            elseif id == "e" then
                table.insert(tokens, {type = "number", value = math.exp(1)})
            else
                table.insert(tokens, {type = "variable", value = id})
            end
        else
            if c == "+" or c == "-" or c == "*" or c == "/" or c == "^" or c == "(" or c == ")" then
                table.insert(tokens, {type = "operator", value = c})
            else
                -- игнорируем неизвестные символы
                i = i + 1
            end
        end
    end
    return tokens
end

local function toRPN(tokens)
    local output = {}
    local stack = {}
    local precedence = {["+"] = 1, ["-"] = 1, ["*"] = 2, ["/"] = 2, ["^"] = 3}
    local rightAssoc = {["^"] = true}

    for _, tok in ipairs(tokens) do
        if tok.type == "number" or tok.type == "variable" then
            table.insert(output, tok)
        elseif tok.type == "function" then
            table.insert(stack, tok)
        elseif tok.type == "operator" then
            if tok.value == "(" then
                table.insert(stack, tok)
            elseif tok.value == ")" then
                while #stack > 0 and stack[#stack].value ~= "(" do
                    table.insert(output, table.remove(stack))
                end
                table.remove(stack)
                if #stack > 0 and stack[#stack].type == "function" then
                    table.insert(output, table.remove(stack))
                end
            else
                while #stack > 0 and stack[#stack].type == "operator" and stack[#stack].value ~= "(" and
                      (precedence[stack[#stack].value] > precedence[tok.value] or
                       (precedence[stack[#stack].value] == precedence[tok.value] and not rightAssoc[tok.value])) do
                    table.insert(output, table.remove(stack))
                end
                table.insert(stack, tok)
            end
        end
    end
    while #stack > 0 do
        table.insert(output, table.remove(stack))
    end
    return output
end

function M.evaluate(expr, env)
    env = env or {}
    if type(expr) == "number" then return expr end
    if type(expr) == "string" then
        local num = tonumber(expr)
        if num then return num end
    end
    local tokens = tokenize(expr)
    if #tokens == 0 then return nil end
    local rpn = toRPN(tokens)
    local stack = {}

    for _, tok in ipairs(rpn) do
        if tok.type == "number" then
            table.insert(stack, tok.value)
        elseif tok.type == "variable" then
            local val = env[tok.value]
            if val == nil then
                -- если переменная не определена, считаем её за 0
                val = 0
            end
            table.insert(stack, val)
        elseif tok.type == "function" then
            local arg = table.remove(stack)
            if arg == nil then arg = 0 end
            if tok.value == "sin" then table.insert(stack, math.sin(arg))
            elseif tok.value == "cos" then table.insert(stack, math.cos(arg))
            elseif tok.value == "tan" then table.insert(stack, math.tan(arg))
            elseif tok.value == "sqrt" then table.insert(stack, math.sqrt(arg))
            elseif tok.value == "abs" then table.insert(stack, math.abs(arg))
            elseif tok.value == "log" then table.insert(stack, math.log(arg))
            elseif tok.value == "exp" then table.insert(stack, math.exp(arg))
            end
        elseif tok.type == "operator" then
            local b = table.remove(stack)
            local a = table.remove(stack)
            if a == nil then a = 0 end
            if b == nil then b = 0 end
            if tok.value == "+" then table.insert(stack, a + b)
            elseif tok.value == "-" then table.insert(stack, a - b)
            elseif tok.value == "*" then table.insert(stack, a * b)
            elseif tok.value == "/" then table.insert(stack, (b ~= 0 and a / b) or 0)
            elseif tok.value == "^" then table.insert(stack, a ^ b)
            end
        end
    end

    return stack[1]
end

return M
