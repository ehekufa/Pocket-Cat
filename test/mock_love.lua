-- test/mock_love.lua
-- Минимальный мок LÖVE для headless-проверки логики и отрисовки
local BASE = os.getenv("POCKETCAT_TESTDIR") or "/tmp/pocketcat_test"
os.execute("mkdir -p '" .. BASE .. "'")

local function full(p)
    return BASE .. "/" .. p
end

local function ensureDir(path)
    os.execute("mkdir -p '" .. path .. "'")
end

local FS = {}
function FS.write(path, data)
    local f = full(path)
    ensureDir(f:match("(.*/)[^/]*$") or BASE)
    local fh = io.open(f, "wb")
    if not fh then return false end
    fh:write(data)
    fh:close()
    return true
end

function FS.read(path)
    local fh = io.open(full(path), "rb")
    if not fh then return nil end
    local data = fh:read("*a")
    fh:close()
    return data
end

function FS.getInfo(path)
    local fh = io.open(full(path), "rb")
    if fh then
        fh:close()
        return {type = "file", size = 0}
    end
    return nil
end

function FS.remove(path)
    return os.remove(full(path))
end

function FS.createDirectory(path)
    ensureDir(full(path))
    return true
end

function FS.getDirectoryItems(path)
    local dir = full(path == "." and "" or path)
    if dir:sub(-1) == "/" then dir = dir:sub(1, -2) end
    if dir == "" then dir = BASE end
    local out = {}
    local tmp = "/tmp/pocketcat_ls.txt"
    os.execute("ls -1 '" .. dir .. "' > '" .. tmp .. "' 2>/dev/null")
    local fh = io.open(tmp, "r")
    if fh then
        for line in fh:lines() do
            if line ~= "" then table.insert(out, line) end
        end
        fh:close()
    end
    return out
end

local G = {}
local curFont = nil
local function makeFont(size)
    return {
        size = size,
        getWidth = function(self, s) return #(tostring(s)) * (size * 0.55) end,
        getHeight = function(self) return size end,
    }
end
curFont = makeFont(12)

function G.getWidth() return 480 end
function G.getHeight() return 800 end
function G.setBackgroundColor() end
function G.setColor() end
function G.setLineWidth() end
function G.setScissor() end
function G.setCanvas() end
function G.setBlendMode() end
function G.clear() end
function G.rectangle() end
function G.circle() end
function G.line() end
function G.ellipse() end
function G.arc() end
function G.polygon() end
function G.print() end
function G.draw() end
function G.setFont(f) curFont = f end
function G.getFont() return curFont end
function G.newFont(size) return makeFont(size) end
function G.isCreated() return true end

local function makeImageData(w, h)
    return {
        w = w, h = h,
        encode = function(self, fmt, path)
            if type(fmt) == "string" and not path then path = fmt end
            FS.write(path, "PNGMOCK")
            return true
        end,
        getPixel = function(self, x, y) return 1, 1, 1, 1 end,
        setPixel = function() end,
    }
end

function G.newCanvas(w, h)
    return {
        w = w, h = h,
        newImageData = function(self) return makeImageData(self.w, self.h) end,
        setFilter = function() end,
        getWidth = function(self) return self.w end,
        getHeight = function(self) return self.h end,
    }
end

function G.newImage(path)
    return {
        getWidth = function() return 64 end,
        getHeight = function() return 64 end,
        setFilter = function() end,
    }
end

local function makeSource()
    return {
        play = function() end,
        stop = function() end,
        setVolume = function() end,
        getDuration = function() return 1 end,
    }
end

love = {
    graphics = G,
    filesystem = FS,
    timer = {
        getTime = function() return os.clock() end,
    },
    keyboard = {
        setTextInput = function() end,
        isDown = function() return false end,
    },
    system = {
        getClipboardText = function() return "" end,
        vibrate = function() end,
    },
    mouse = {
        getPosition = function() return 0, 0 end,
        getX = function() return 0 end,
        getY = function() return 0 end,
    },
    touch = {
        getTouches = function() return {} end,
        getPosition = function() return 0, 0 end,
    },
    audio = {
        newSource = function() return makeSource() end,
        stop = function() end,
    },
    sound = {
        newSoundData = function(n) return {setSample = function() end} end,
    },
    _os = "Linux",
}
