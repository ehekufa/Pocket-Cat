-- src/state.lua
local State = {
    project = nil,
    currentSceneIdx = 1,
    currentObjectIdx = 1,

    paletteBlocks = {},  -- будет заполнено из constants
    workspaceBlocks = {},

    paletteWidth = 200,
    paletteScrollY = 0,
    paletteContentHeight = 0,

    workspaceStartX = 210,
    workspaceStartY = 80,
    blockWidth = 175,
    blockHeight = 34,
    blockSpacing = 8,
    workspaceScrollY = 0,
    workspaceContentHeight = 0,

    draggingBlock = nil,
    dragFromPalette = false,

    longPressBlockIdx = nil,
    longPressStartTime = 0,
    longPressMoved = false,

    editingBlockIdx = nil,
    editingText = "",

    -- Keyboard (for mobile)
    keyboardMode = "digits",
    keyboardVisible = false,
    keyboardHeight = 260,
    keyboardPosX = 0,
    keyboardPosY = 0,
    keyW = 44,
    keyH = 44,
    keySpacing = 4,
    digitsKeys = {{"1","2","3"},{"4","5","6"},{"7","8","9"},{".","0","⌫"}},
    ruKeys = {{"й","ц","у","к","е","н","г","ш","щ","з","х","ъ"},{"ф","ы","в","а","п","р","о","л","д","ж","э"},{"я","ч","с","м","и","т","ь","б","ю","ё"}},
    enKeys = {{"q","w","e","r","t","y","u","i","o","p"},{"a","s","d","f","g","h","j","k","l"},{"z","x","c","v","b","n","m"}},

    -- Paint
    paintMode = false,
    paintCanvas = nil,
    paintWidth = 64,
    paintHeight = 64,
    paintScale = 1,
    paintBrushColor = {1,1,1},
    paintCurrentTool = "brush",
    paintTools = {"brush", "eraser", "fill", "picker", "line", "rect", "ellipse"},
    paintColors = {
        {1,1,1}, {0,0,0}, {1,0,0}, {0,1,0}, {0,0,1}, {1,1,0}, {1,0,1}, {0,1,1},
        {0.5,0.5,0.5}, {1,0.5,0}, {0.5,0,0.5}, {0,0.5,0.5}
    },
    paintSizes = {1, 2, 4, 8},
    paintPresetSizes = {{64,64}, {32,32}, {16,16}, {128,128}, {200,146}},
    paintCustomStep = 0,
    paintCustomInputText = "",
    paintCustomX = nil,
    paintHue = 0,
    paintSaturation = 1,
    paintValue = 1,
    lineStart = nil,
    rectStart = nil,
    ellipseStart = nil,

    -- Runtime
    eventHandlers = {},
    stopAll = false,
    waitTimer = 0,
    isTapped = false,
    isReleased = false,
    touchActive = false,
    penDown = false,
    penColor = {1,0,0},
    penSize = 2,
    penPoints = {},
    drawCommands = {},
    messages = {},
    vars = {},

    -- Objects
    showCube = false,
    showSphere = false,
    showImage = false,
    cubeX = 200,
    cubeY = 300,
    sphereX = 400,
    sphereY = 300,
    objectAngle = 0,
    objectColor = {0.2, 0.8, 0.4},
    objectSize = 50,
    cubeVertices = {{-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},{-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1}},
    cubeEdges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}},

    -- Misc
    font = nil,
    fontSize = 16,
    clipboard = nil,
    bgColor = {0.1, 0.1, 0.1}
}

function State.init()
    local constants = require("src.constants")
    State.catColors = constants.catColors
    State.paletteBlocks = constants.paletteBlocks
end

return State
