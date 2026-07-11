-- src/state.lua
local State = {
    project = nil,
    currentSceneIdx = 1,
    currentObjectIdx = 1,
    currentScreen = "main",
    currentProject = nil,
    currentProjectIndex = 1,
    projects = {},
    showCreateProject = false,
    newProjectName = "",
    selectedOrientation = "portrait",
    showCategories = false,

    paletteBlocks = {},
    workspaceBlocks = {},

    paletteWidth = 200,
    paletteScrollY = 0,
    paletteContentHeight = 0,

    workspaceStartX = 210,
    workspaceStartY = 80,
    blockWidth = 160,
    blockHeight = 34,
    blockSpacing = 6,
    workspaceScrollY = 0,
    workspaceContentHeight = 0,

    draggingBlock = nil,
    dragFromPalette = false,
    dragSourceParent = nil,
    dragSourceIndex = nil,

    longPressBlockIdx = nil,
    longPressStartTime = 0,
    longPressMoved = false,

    editingBlock = nil,
    editingText = "",
    inputMode = nil,

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
    varList = {},

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

    font = nil,
    fontSize = 16,
    clipboard = nil,
    bgColor = {0.1, 0.1, 0.1},
    topBarHeight = 56,
    windowWidth = 1024,
    windowHeight = 768,
    keyboardVisible = false,
    
    catColors = {
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
}

function State.init()
    local constants = require("src.constants")
    State.paletteBlocks = constants.paletteBlocks
end

return State
