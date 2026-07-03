-- src/constants.lua
local M = {}

M.catColors = {
    event = {0.9,0.6,0.2},
    motion = {0.2,0.6,0.9},
    looks = {0.7,0.3,0.9},
    sound = {0.3,0.9,0.4},
    control = {1.0,0.8,0.2},
    variables = {0.9,0.2,0.2},
    draw = {0.2,0.8,0.8},
    text = {1.0,1.0,1.0},
    sensing = {0.7,0.7,0.7},
    pen = {0.2,1.0,0.4},
    cloud = {0.2,0.6,1.0}
}

M.paletteBlocks = {
    {type="event", name="start", label="when start", category="event"},
    {type="event", name="tap", label="on tap", category="event"},
    {type="event", name="release", label="on release", category="event"},
    {type="event", name="touch", label="on touch", category="event"},
    {type="action", name="changeX", label="change X by", param=10, category="motion"},
    {type="action", name="changeY", label="change Y by", param=10, category="motion"},
    {type="action", name="setX", label="set X to", param=200, category="motion"},
    {type="action", name="setY", label="set Y to", param=200, category="motion"},
    {type="action", name="turn", label="turn by", param=15, category="motion"},
    {type="action", name="showCube", label="show cube", category="looks"},
    {type="action", name="showSphere", label="show sphere", category="looks"},
    {type="action", name="showImage", label="show sprite", category="looks"},
    {type="action", name="hide", label="hide object", category="looks"},
    {type="action", name="show", label="show object", category="looks"},
    {type="action", name="setColor", label="set color", param="green", category="looks"},
    {type="action", name="setSize", label="set size", param=50, category="looks"},
    {type="action", name="penDown", label="pen down", category="pen"},
    {type="action", name="penUp", label="pen up", category="pen"},
    {type="action", name="penClear", label="clear pen", category="pen"},
    {type="action", name="penColor", label="pen color", param="green", category="pen"},
    {type="action", name="penSize", label="pen size", param=2, category="pen"},
    {type="action", name="playSound", label="play sound", param="", category="sound"},
    {type="control", name="repeat", label="repeat", param=3, category="control"},
    {type="control", name="forever", label="forever", category="control"},
    {type="control", name="if", label="if", param="", category="control"},
    {type="control", name="ifElse", label="if else", param="", category="control"},
    {type="action", name="setVar", label="set variable", param="", category="variables"},
    {type="action", name="changeVar", label="change variable by", param="", category="variables"},
    {type="action", name="showVar", label="show variable", param="", category="variables"},
    {type="action", name="printText", label="print text", param="Hello!", category="text"},
    {type="action", name="mouseX", label="mouse X", category="sensing"},
    {type="action", name="mouseY", label="mouse Y", category="sensing"},
    {type="action", name="touchX", label="touch X", category="sensing"},
    {type="action", name="touchY", label="touch Y", category="sensing"},
    {type="action", name="firebaseGet", label="firebase get", param="URL", category="cloud"},
    {type="action", name="firebasePut", label="firebase put", param="URL|varName", category="cloud"},
}

return M
