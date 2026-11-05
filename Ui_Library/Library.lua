local function NatAovHubCleanupGuis()
    local coreGui = game:GetService("CoreGui")
    local doomed = {}
    for _, child in ipairs(coreGui:GetChildren()) do
        if string.find(child.Name, "NatAovHub_", 1, true) then
            table.insert(doomed, child)
        end
    end
    for _, child in ipairs(doomed) do
        pcall(function()
            child:Destroy()
        end)
    end
    return #doomed
end

if getgenv().Nousigi then
    NatAovHubCleanupGuis()
end
getgenv().Nousigi = true

local DisableAnimation = false
pcall(function()
    local lp = game:GetService("Players").LocalPlayer
    if lp and lp:FindFirstChild("PlayerGui") then
        DisableAnimation = lp.PlayerGui:FindFirstChild("TouchGui") ~= nil
    end
end)

local T1UIColor = {
    ["Border Color"] = Color3.fromRGB(0, 170, 255),
    ["Click Effect Color"] = Color3.fromRGB(0, 170, 255),
    ["Setting Icon Color"] = Color3.fromRGB(200, 200, 200),
    ["Logo Image"] = "rbxassetid://120488231660846",
    ["Search Icon Color"] = Color3.fromRGB(0, 170, 255),
    ["Search Icon Highlight Color"] = Color3.fromRGB(50, 200, 255),
    ["GUI Text Color"] = Color3.fromRGB(240, 240, 240),
    ["Text Color"] = Color3.fromRGB(240, 240, 240),
    ["Placeholder Text Color"] = Color3.fromRGB(100, 100, 100),
    ["Title Text Color"] = Color3.fromRGB(0, 170, 255),
    ["Background Main Color"] = Color3.fromRGB(18, 18, 20),
    ["Background 1 Color"] = Color3.fromRGB(26, 26, 29),
    ["Background 1 Transparency"] = 0.05,
    ["Background 2 Color"] = Color3.fromRGB(34, 34, 38),
    ["Background 3 Color"] = Color3.fromRGB(26, 26, 29),
    ["Page Selected Color"] = Color3.fromRGB(0, 170, 255),
    ["Section Text Color"] = Color3.fromRGB(255, 255, 255),
    ["Section Underline Color"] = Color3.fromRGB(0, 170, 255),
    ["Toggle Border Color"] = Color3.fromRGB(96, 96, 104),
    ["Toggle Checked Color"] = Color3.fromRGB(0, 170, 255),
    ["Toggle Desc Color"] = Color3.fromRGB(180, 180, 180),
    ["Button Color"] = Color3.fromRGB(0, 132, 235),
    ["Label Color"] = Color3.fromRGB(34, 34, 38),
    ["Dropdown Icon Color"] = Color3.fromRGB(0, 170, 255),
    ["Dropdown Selected Color"] = Color3.fromRGB(0, 170, 255),
    ["Dropdown Selected Check Color"] = Color3.fromRGB(0, 170, 255),
    ["Textbox Highlight Color"] = Color3.fromRGB(0, 170, 255),
    ["Box Highlight Color"] = Color3.fromRGB(0, 170, 255),
    ["Slider Line Color"] = Color3.fromRGB(44, 44, 49),
    ["Slider Highlight Color"] = Color3.fromRGB(0, 170, 255),
    ["Tween Animation 1 Speed"] = DisableAnimation and 0 or 0.18,
    ["Tween Animation 2 Speed"] = DisableAnimation and 0 or 0.3,
    ["Tween Animation 3 Speed"] = DisableAnimation and 0 or 0.08,
    ["Stroke Color"] = Color3.fromRGB(58, 58, 64),
    ["Text Stroke Transparency"] = 0.8,
}

getgenv().UIColor = T1UIColor
getgenv().AllControls = {}
getgenv().UIToggled = false

local currcolor = {}
local Library = {}
local Library_Function = {}

local function flexibleApi(apiTable, colonNames)
    local raw = {}
    for name, fn in pairs(apiTable) do
        if type(fn) == "function" then
            raw[name] = fn
        end
    end
    local colonSet = {}
    if type(colonNames) == "table" then
        for _, n in ipairs(colonNames) do
            colonSet[n] = true
        end
    end
    for name, fn in pairs(raw) do
        if colonSet[name] then
            apiTable[name] = function(first, ...)
                if first == apiTable then
                    return fn(apiTable, ...)
                end
                return fn(apiTable, first, ...)
            end
        else
            apiTable[name] = function(first, ...)
                if first == apiTable then
                    return fn(...)
                end
                return fn(first, ...)
            end
        end
    end
    return apiTable
end

local TweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local StyleQuad = Enum.EasingStyle.Quad
local StyleQuart = Enum.EasingStyle.Quart
local StyleBack = Enum.EasingStyle.Back
local StyleSine = Enum.EasingStyle.Sine
local DirOut = Enum.EasingDirection.Out
local DirIn = Enum.EasingDirection.In

local function animDuration(key, fallback)
    if DisableAnimation then
        return 0
    end
    local v = getgenv().UIColor and getgenv().UIColor[key]
    if type(v) == "number" then
        return v
    end
    return fallback or 0.18
end

local function tween(object, props, duration, style, dir)
    if not object then
        return nil
    end
    duration = duration or 0.18
    if DisableAnimation then
        duration = 0
    end
    local tw = TweenService:Create(object, TweenInfo.new(duration, style or StyleQuad, dir or DirOut), props)
    tw:Play()
    return tw
end

local function tweenUI(object, props, speedKey, style, dir)
    return tween(object, props, animDuration(speedKey, 0.18), style, dir)
end

local function isPressInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMoveInput(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local SLIDER_DRAG_THRESHOLD = 6

local function bindSliderDrag(button, apply, onStart, onStop)
    local moveConn
    local activated = false

    local function stop()
        if moveConn then
            moveConn:Disconnect()
            moveConn = nil
        end
        if activated then
            activated = false
            if onStop then
                pcall(onStop)
            end
        end
    end

    button.InputBegan:Connect(function(input)
        if not isPressInput(input) then
            return
        end

        local startPos = input.Position
        activated = false

        if moveConn then
            moveConn:Disconnect()
        end

        moveConn = uis.InputChanged:Connect(function(move)
            if not isMoveInput(move) then
                return
            end

            if not activated then
                local dx = math.abs(move.Position.X - startPos.X)
                local dy = math.abs(move.Position.Y - startPos.Y)

                if dy > dx and dy > SLIDER_DRAG_THRESHOLD then
                    stop()
                    return
                end
                if dx < SLIDER_DRAG_THRESHOLD then
                    return
                end
                activated = true
                if onStart then
                    pcall(onStart)
                end
            end

            apply(move)
        end)

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                stop()
            end
        end)
    end)

    button.AncestryChanged:Connect(function(_, parent)
        if not parent then
            stop()
        end
    end)
end

local function clampCenterOffset(offsetX, offsetY)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local margin = 24
    local halfW, halfH = viewport.X * 0.5, viewport.Y * 0.5
    return math.clamp(offsetX, -halfW + margin, halfW - margin), math.clamp(offsetY, -halfH + margin, halfH - margin)
end

local function makeDraggable(topBarObject, object)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPosition = nil

    topBarObject.InputBegan:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = true
            dragStart = input.Position
            startPosition = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topBarObject.InputChanged:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragInput = input
        end
    end)
    uis.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local offsetX, offsetY =
                clampCenterOffset(startPosition.X.Offset + delta.X, startPosition.Y.Offset + delta.Y)
            object.Position = UDim2.new(startPosition.X.Scale, offsetX, startPosition.Y.Scale, offsetY)
        end
    end)
end

Library_Function.Gui = Instance.new("ScreenGui")
Library_Function.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Library_Function.Gui.Name = "NatAovHub_Main"
Library_Function.Gui.Enabled = false

getgenv().ReadyForGuiLoaded = false
spawn(function()
    repeat
        task.wait()
    until getgenv().ReadyForGuiLoaded
    if getgenv().UIToggled then
        Library_Function.Gui.Enabled = true
    end
end)

Library_Function.NotiGui = Instance.new("ScreenGui")
Library_Function.NotiGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Library_Function.NotiGui.Name = "NatAovHub_Notification"

Library_Function.HideGui = Instance.new("ScreenGui")
Library_Function.HideGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Library_Function.HideGui.Name = "NatAovHub_Hide"

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ToggleScreenGui = Instance.new("ScreenGui")
ToggleScreenGui.Parent = game:GetService("CoreGui")
ToggleScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleScreenGui.Name = "NatAovHub_ToggleButton"

local mainButton = Instance.new("ImageButton")
mainButton.Name = "ToggleButton"
mainButton.Parent = ToggleScreenGui
mainButton.Size = UDim2.new(0, 60, 0, 60)
mainButton.Position = UDim2.new(0, 15, 1, -75)
mainButton.Draggable = false
mainButton.AnchorPoint = Vector2.new(0, 1)
mainButton.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
mainButton.BackgroundTransparency = 0.2
mainButton.BorderSizePixel = 0
mainButton.AutoButtonColor = false
mainButton.Image = ""

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = mainButton

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = mainButton
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.7

local ImageLabel = Instance.new("ImageLabel")
ImageLabel.Parent = mainButton
ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
ImageLabel.Size = UDim2.new(0, 54, 0, 54)
ImageLabel.BackgroundTransparency = 1
ImageLabel.BorderSizePixel = 0
ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel.Image = getgenv().UIColor["Logo Image"]

local ImageLabelCorner = Instance.new("UICorner")
ImageLabelCorner.CornerRadius = UDim.new(1, 0)
ImageLabelCorner.Parent = ImageLabel

Library_Function.ToggleButtonIcon = ImageLabel

local ICON_SIZE = 54
local BUTTON_SIZE = 60
local DRAG_THRESHOLD = 10

local isToggled = getgenv().UIToggled or false
local isHovering = false

if isToggled then
    mainButton.BackgroundColor3 = getgenv().UIColor["Background Main Color"]
end
ImageLabel.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)

local dragging, dragMoved, dragInput, dragStart, startPos

local function clampButtonOffset(rawOffsetX, rawOffsetY)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local size = mainButton.AbsoluteSize
    local anchor = mainButton.AnchorPoint
    local margin = 24

    local absAnchorX = rawOffsetX
    local absAnchorY = viewport.Y + rawOffsetY
    local topLeftX = absAnchorX - anchor.X * size.X
    local topLeftY = absAnchorY - anchor.Y * size.Y

    local clampedLeft = math.clamp(topLeftX, -(size.X - margin), viewport.X - margin)
    local clampedTop = math.clamp(topLeftY, -(size.Y - margin), viewport.Y - margin)

    local clampedAnchorX = clampedLeft + anchor.X * size.X
    local clampedAnchorY = clampedTop + anchor.Y * size.Y

    return clampedAnchorX, clampedAnchorY - viewport.Y
end

local function update(input)
    local delta = input.Position - dragStart
    local offsetX, offsetY = clampButtonOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
    mainButton.Position = UDim2.new(startPos.X.Scale, offsetX, startPos.Y.Scale, offsetY)
end

mainButton.InputBegan:Connect(function(input)
    if not isPressInput(input) then
        return
    end
    dragging = true
    dragMoved = false
    dragStart = input.Position
    startPos = mainButton.Position
    dragInput = input

    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
        end
    end)
end)

mainButton.InputChanged:Connect(function(input)
    if isMoveInput(input) then
        dragInput = input
    end
end)

mainButton.InputEnded:Connect(function(input)
    if isPressInput(input) then
        dragging = false
    end
end)

uis.InputChanged:Connect(function(input)
    if not dragging or not dragStart then
        return
    end
    if not (input == dragInput or isMoveInput(input)) then
        return
    end
    local delta = input.Position - dragStart
    if not dragMoved then
        if (math.abs(delta.X) < DRAG_THRESHOLD) and (math.abs(delta.Y) < DRAG_THRESHOLD) then
            return
        end
        dragMoved = true
        dragStart = input.Position
        startPos = mainButton.Position
        return
    end
    update(input)
end)

mainButton.MouseEnter:Connect(function()
    isHovering = true
    tween(UIStroke, { Transparency = 0.4 }, 0.14, StyleQuad, DirOut)
    tween(mainButton, {
        BackgroundTransparency = 0.1,
        BackgroundColor3 = getgenv().UIColor["Background 1 Color"],
    }, 0.14, StyleQuad, DirOut)
end)

mainButton.MouseLeave:Connect(function()
    isHovering = false
    local targetColor = isToggled and getgenv().UIColor["Background Main Color"]
        or getgenv().UIColor["Background 2 Color"]
    tween(UIStroke, { Transparency = 0.7 }, 0.16, StyleQuad, DirOut)
    tween(mainButton, {
        BackgroundTransparency = 0.2,
        BackgroundColor3 = targetColor,
    }, 0.16, StyleQuad, DirOut)
end)

mainButton.MouseButton1Click:Connect(function()
    if dragMoved then
        return
    end
    Library.ToggleUI()
end)

Library_Function._toggleGen = 0

Library.ToggleUI = function()
    getgenv().UIToggled = not getgenv().UIToggled
    Library_Function._toggleGen = (Library_Function._toggleGen or 0) + 1
    local myGen = Library_Function._toggleGen
    local opening = getgenv().UIToggled

    local gui = nil
    if game.CoreGui:FindFirstChild("NatAovHub_Main") then
        for a, b in ipairs(game.CoreGui:GetChildren()) do
            if b.Name == "NatAovHub_Main" then
                gui = b
            end
        end
    end

    if gui then
        local mainFrame = gui:FindFirstChild("Main")
        if mainFrame and Library_Function.LastWindowSize then
            mainFrame.Size = Library_Function.LastWindowSize
        end
        local fadeLayer = mainFrame and mainFrame:FindFirstChild("WindowFade")
        local shadow = mainFrame and mainFrame:FindFirstChild("Shadow")
        local fadeTime = animDuration("Tween Animation 2 Speed", 0.2)

        if opening then
            gui.Enabled = true
            if fadeLayer then
                fadeLayer.Visible = true
                fadeLayer.BackgroundTransparency = 0.45
                local tw = tween(fadeLayer, { BackgroundTransparency = 1 }, fadeTime, StyleQuad, DirOut)
                if tw then
                    tw.Completed:Connect(function()
                        if fadeLayer and getgenv().UIToggled then
                            fadeLayer.Visible = false
                        end
                    end)
                end
            end
            if shadow then
                shadow.ImageTransparency = 0.75
                tween(shadow, { ImageTransparency = 0.35 }, fadeTime, StyleQuad, DirOut)
            end
        else
            if fadeLayer then
                fadeLayer.Visible = true
                tween(fadeLayer, { BackgroundTransparency = 0.35 }, fadeTime * 0.75, StyleQuad, DirIn)
            end
            if shadow then
                tween(shadow, { ImageTransparency = 0.85 }, fadeTime * 0.75, StyleQuad, DirIn)
            end
            task.delay(math.max(fadeTime * 0.75, 0.01), function()
                if Library_Function._toggleGen == myGen and not getgenv().UIToggled then
                    gui.Enabled = false
                    if fadeLayer then
                        fadeLayer.BackgroundTransparency = 1
                        fadeLayer.Visible = false
                    end
                    if shadow then
                        shadow.ImageTransparency = 0.35
                    end
                end
            end)
        end
    end

    isToggled = opening
    local targetColor = isToggled and getgenv().UIColor["Background Main Color"]
        or getgenv().UIColor["Background 2 Color"]
    tween(mainButton, {
        Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE),
        BackgroundColor3 = targetColor,
    }, 0.16, StyleQuad, DirOut)
    tween(UIStroke, { Transparency = isToggled and 0.35 or 0.7 }, 0.16, StyleQuad, DirOut)
    ImageLabel.ImageTransparency = 0.35
    tween(ImageLabel, { ImageTransparency = 0 }, 0.18, StyleSine, DirOut)
    ImageLabel.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
end

Library.DestroyUI = function()
    if Library_Function.ResetDynamicIsland then
        Library_Function.ResetDynamicIsland()
    end
    NatAovHubCleanupGuis()

    getgenv().Nousigi = false
    getgenv().UIToggled = false
    getgenv().AllControls = {}
    getgenv().ReadyForGuiLoaded = false
end

local NotiContainer = Instance.new("Frame")
local NotiList = Instance.new("UIListLayout")

NotiContainer.Name = "NotiContainer"
NotiContainer.Parent = Library_Function.NotiGui
NotiContainer.AnchorPoint = Vector2.new(1, 1)
NotiContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
NotiContainer.BackgroundTransparency = 1.000
NotiContainer.Position = UDim2.new(1, -5, 1, -5)
NotiContainer.Size = UDim2.new(0, 350, 1, -10)

NotiList.Name = "NotiList"
NotiList.Parent = NotiContainer
NotiList.SortOrder = Enum.SortOrder.LayoutOrder
NotiList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotiList.Padding = UDim.new(0, 5)

Library_Function.Gui.Parent = game:GetService("CoreGui")
Library_Function.NotiGui.Parent = game:GetService("CoreGui")
Library_Function.HideGui.Parent = game:GetService("CoreGui")

function Library_Function.Getcolor(color)
    return {
        math.floor(color.r * 255),
        math.floor(color.g * 255),
        math.floor(color.b * 255),
    }
end

local libCreateNotiInternal = function(Setting, onClosed)
    getgenv().TitleNameNoti = Setting.Title or ""
    local Description = Setting.Description or Setting.Desc or Setting.Content or ""
    local Duration = Setting.Duration or Setting.Timeshow or Setting.Delay or 10

    local NotiFrame = Instance.new("Frame")
    local Noticontainer = Instance.new("Frame")
    local UICorner = Instance.new("UICorner")
    local Topnoti = Instance.new("Frame")
    local Ruafimg = Instance.new("ImageLabel")
    local RuafimgCorner = Instance.new("UICorner")
    local TextLabelNoti = Instance.new("TextLabel")
    local CloseContainer = Instance.new("Frame")
    local CloseImage = Instance.new("ImageLabel")
    local TextButton = Instance.new("TextButton")
    local TextLabelNoti2 = Instance.new("TextLabel")

    NotiFrame.Name = "NotiFrame"
    NotiFrame.Parent = NotiContainer
    NotiFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    NotiFrame.BackgroundTransparency = 1.000
    NotiFrame.ClipsDescendants = true
    NotiFrame.Position = UDim2.new(0, 0, 0, 0)
    NotiFrame.Size = UDim2.new(1, 0, 0, 0)
    NotiFrame.AutomaticSize = Enum.AutomaticSize.Y

    Noticontainer.Name = "Noticontainer"
    Noticontainer.Parent = NotiFrame
    Noticontainer.Position = UDim2.new(1, 60, 0, 0)
    Noticontainer.Size = UDim2.new(1, 0, 1, 6)
    Noticontainer.AutomaticSize = Enum.AutomaticSize.Y
    Noticontainer.BackgroundColor3 = getgenv().UIColor["Background 3 Color"]
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Noticontainer
    Noticontainer.BackgroundTransparency = 1

    local NotiStroke = Instance.new("UIStroke")
    NotiStroke.Parent = Noticontainer
    NotiStroke.Color = getgenv().UIColor["Border Color"]
    NotiStroke.Transparency = 1
    NotiStroke.Thickness = 1

    local NotiScale = Instance.new("UIScale")
    NotiScale.Parent = Noticontainer
    NotiScale.Scale = 0.85

    Topnoti.Name = "Topnoti"
    Topnoti.Parent = Noticontainer
    Topnoti.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    Topnoti.BackgroundTransparency = 1.000
    Topnoti.Position = UDim2.new(0, 0, 0, 5)
    Topnoti.Size = UDim2.new(1, 0, 0, 25)

    Ruafimg.Name = "Ruafimg"
    Ruafimg.Parent = Topnoti
    Ruafimg.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    Ruafimg.BackgroundTransparency = 1.000
    Ruafimg.Position = UDim2.new(0, 5, 0, getgenv().T1 and 5 or 0)
    Ruafimg.Size = UDim2.new(0, getgenv().T1 and 30 or 25, 0, getgenv().T1 and 15 or 25)
    Ruafimg.Image = getgenv().UIColor["Logo Image"]

    RuafimgCorner.CornerRadius = UDim.new(1, 0)
    RuafimgCorner.Name = "RuafimgCorner"
    RuafimgCorner.Parent = Ruafimg

    local colorR = tostring(Library_Function.Getcolor(getgenv().UIColor["Title Text Color"])[1])
    local colorG = tostring(Library_Function.Getcolor(getgenv().UIColor["Title Text Color"])[2])
    local colorB = tostring(Library_Function.Getcolor(getgenv().UIColor["Title Text Color"])[3])
    local color = colorR .. "," .. colorG .. "," .. colorB
    TextLabelNoti.Text = '<font color="rgb('
        .. tostring(color or "255,80,80")
        .. ')">'
        .. tostring(getgenv().TitleNameMain or "NatAov Hub")
        .. "</font> "
        .. tostring(getgenv().TitleNameNoti or "")

    TextLabelNoti.Name = "TextLabelNoti"
    TextLabelNoti.Parent = Topnoti
    TextLabelNoti.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    TextLabelNoti.BackgroundTransparency = 1.000
    TextLabelNoti.Position = UDim2.new(0, getgenv().T1 and 40 or 35, 0, 0)
    TextLabelNoti.Size = UDim2.new(1, getgenv().T1 and -70 or -65, 1, 0)
    TextLabelNoti.Font = Enum.Font.GothamBold
    TextLabelNoti.TextSize = 14.000
    TextLabelNoti.TextWrapped = true
    TextLabelNoti.TextXAlignment = Enum.TextXAlignment.Left
    TextLabelNoti.RichText = true
    TextLabelNoti.TextColor3 = getgenv().UIColor["GUI Text Color"]

    CloseContainer.Name = "CloseContainer"
    CloseContainer.Parent = Topnoti
    CloseContainer.AnchorPoint = Vector2.new(1, 0.5)
    CloseContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    CloseContainer.BackgroundTransparency = 1.000
    CloseContainer.Position = UDim2.new(1, -4, 0.5, 0)
    CloseContainer.Size = UDim2.new(0, 22, 0, 22)

    local CountdownLabel = Instance.new("TextLabel")
    CountdownLabel.Name = "CountdownLabel"
    CountdownLabel.Parent = Topnoti
    CountdownLabel.AnchorPoint = Vector2.new(1, 0.5)
    CountdownLabel.BackgroundTransparency = 1
    CountdownLabel.Position = UDim2.new(1, -30, 0.5, 0)
    CountdownLabel.Size = UDim2.new(0, 26, 0, 16)
    CountdownLabel.Font = Enum.Font.GothamBold
    CountdownLabel.TextSize = 11
    CountdownLabel.TextXAlignment = Enum.TextXAlignment.Right
    CountdownLabel.TextColor3 = getgenv().UIColor["Search Icon Color"]
    CountdownLabel.Text = tostring(math.ceil(Duration)) .. "s"

    CloseImage.Name = "CloseImage"
    CloseImage.Parent = CloseContainer
    CloseImage.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    CloseImage.BackgroundTransparency = 1.000
    CloseImage.Size = UDim2.new(1, 0, 1, 0)
    CloseImage.Image = "rbxassetid://3926305904"
    CloseImage.ImageRectOffset = Vector2.new(284, 4)
    CloseImage.ImageRectSize = Vector2.new(24, 24)
    CloseImage.ImageColor3 = getgenv().UIColor["Search Icon Color"]

    TextButton.Parent = CloseContainer
    TextButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    TextButton.BackgroundTransparency = 1.000
    TextButton.Size = UDim2.new(1, 0, 1, 0)
    TextButton.Font = Enum.Font.SourceSans
    TextButton.Text = ""
    TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    TextButton.TextSize = 14.000

    if Description then
        TextLabelNoti2.Name = "TextColor"
        TextLabelNoti2.Parent = Noticontainer
        TextLabelNoti2.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        TextLabelNoti2.BackgroundTransparency = 1.000
        TextLabelNoti2.Position = UDim2.new(0, 10, 0, 35)
        TextLabelNoti2.Size = UDim2.new(1, -15, 0, 0)
        TextLabelNoti2.Font = Enum.Font.GothamBold
        TextLabelNoti2.Text = Description
        TextLabelNoti2.TextSize = 14.000
        TextLabelNoti2.TextXAlignment = Enum.TextXAlignment.Left
        TextLabelNoti2.RichText = true
        TextLabelNoti2.TextColor3 = getgenv().UIColor["Text Color"]
        TextLabelNoti2.AutomaticSize = Enum.AutomaticSize.Y
        TextLabelNoti2.TextWrapped = true
    end

    local DurationBar = Instance.new("Frame")
    DurationBar.Name = "DurationBar"
    DurationBar.Parent = Noticontainer
    DurationBar.AnchorPoint = Vector2.new(0, 1)
    DurationBar.Position = UDim2.new(0, 0, 1, 0)
    DurationBar.Size = UDim2.new(1, 0, 0, 2)
    DurationBar.BorderSizePixel = 0
    DurationBar.BackgroundColor3 = getgenv().UIColor["Slider Highlight Color"]
    DurationBar.BackgroundTransparency = 0.1
    DurationBar.ZIndex = 5

    local fadeTargets = {}
    local function addFadeTarget(object, property, defaultValue)
        object[property] = 1
        table.insert(fadeTargets, {
            Object = object,
            Property = property,
            Value = defaultValue,
        })
    end
    addFadeTarget(Ruafimg, "ImageTransparency", 0)
    addFadeTarget(TextLabelNoti, "TextTransparency", 0)
    addFadeTarget(TextLabelNoti2, "TextTransparency", 0)
    addFadeTarget(CloseImage, "ImageTransparency", 0)
    addFadeTarget(CountdownLabel, "TextTransparency", 0)
    addFadeTarget(DurationBar, "BackgroundTransparency", 0.1)

    local removing = false
    local function remove()
        if removing then
            return
        end

        removing = true

        for _, target in ipairs(fadeTargets) do
            TweenService:Create(target.Object, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                [target.Property] = 1,
            }):Play()
        end
        TweenService:Create(Noticontainer, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 60, 0, 0),
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(NotiScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Scale = 0.88,
        }):Play()
        TweenService:Create(NotiStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Transparency = 1,
        }):Play()
        task.wait(0.3)
        NotiFrame:Destroy()
        if onClosed then
            task.spawn(onClosed)
        end
    end

    TweenService:Create(Noticontainer, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.08,
    }):Play()
    TweenService:Create(NotiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = 1,
    }):Play()
    TweenService:Create(NotiStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 0.35,
    }):Play()
    for i, target in ipairs(fadeTargets) do
        task.delay(0.05 + 0.04 * i, function()
            if target.Object and target.Object.Parent then
                TweenService
                    :Create(target.Object, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        [target.Property] = target.Value,
                    })
                    :Play()
            end
        end)
    end

    TextButton.MouseEnter:Connect(function()
        TweenService:Create(CloseImage, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
            ImageColor3 = getgenv().UIColor["Search Icon Highlight Color"],
            Rotation = 90,
        }):Play()
    end)

    TextButton.MouseLeave:Connect(function()
        TweenService:Create(CloseImage, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
            ImageColor3 = getgenv().UIColor["Search Icon Color"],
            Rotation = 0,
        }):Play()
    end)

    TextButton.MouseButton1Click:Connect(function()
        TweenService:Create(NotiScale, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Scale = 0.96,
        }):Play()
        task.wait(0.08)
        remove()
    end)

    Noticontainer.Active = true
    local remainingSeconds = Duration
    local barTween

    local function playBar(forTime)
        barTween = TweenService:Create(DurationBar, TweenInfo.new(forTime, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 0, 2),
        })
        barTween.Completed:Connect(function(playbackState)
            if playbackState == Enum.PlaybackState.Completed then
                remove()
            end
        end)
        barTween:Play()
    end
    playBar(Duration)

    Noticontainer.MouseEnter:Connect(function()
        if barTween then
            barTween:Pause()
        end
    end)
    Noticontainer.MouseLeave:Connect(function()
        if barTween then
            barTween:Play()
        end
    end)

    task.spawn(function()
        while NotiFrame.Parent do
            task.wait(1)
            if not NotiFrame.Parent then
                break
            end
            if barTween and barTween.PlaybackState == Enum.PlaybackState.Playing then
                remainingSeconds = math.max(0, remainingSeconds - 1)
                CountdownLabel.Text = tostring(math.ceil(remainingSeconds)) .. "s"
            end
        end
    end)
end

local NotiQueue = {}
local NotiShowing = false

local function libProcessNotiQueue()
    if NotiShowing then
        return
    end

    local nextSetting = table.remove(NotiQueue, 1)
    if not nextSetting then
        return
    end

    NotiShowing = true

    local finished = false
    local function onClosed()
        if finished then
            return
        end
        finished = true
        NotiShowing = false
        libProcessNotiQueue()
    end

    local ok = pcall(function()
        libCreateNotiInternal(nextSetting, onClosed)
    end)

    if not ok then
        onClosed()
    else
        local guardDuration = tonumber(nextSetting.Duration)
            or tonumber(nextSetting.Timeshow)
            or tonumber(nextSetting.Delay)
            or 10
        task.delay(guardDuration + 5, onClosed)
    end
end

local function libCreateNoti(Setting)
    table.insert(NotiQueue, Setting or {})
    libProcessNotiQueue()
end

function Library:Notify(Setting, bypass)
    if not getgenv().Config or bypass then
        pcall(function()
            libCreateNoti(Setting)
        end)
    end
end

local DynamicIsland = {
    Enabled = false,
    Token = 0,
    TypingToken = 0,
    PulseToken = 0,
    IdleToken = 0,
    SpinToken = 0,
    Pending = nil,
    Current = nil,
    Gui = nil,
    Root = nil,
    Scaler = nil,
    Stroke = nil,
    Content = nil,
    ContentScale = nil,
    IconHolder = nil,
    IconScale = nil,
    PingFrame = nil,
    PingScale = nil,
    PingStroke = nil,
    IconImage = nil,
    IconDot = nil,
    IconDotStroke = nil,
    IconGlyph = nil,
    Spinner = nil,
    SpinnerDots = {},
    IdleDot = nil,
    IdleScale = nil,
    Text = nil,
    Subtitle = nil,
    Corner = nil,
    ArtworkCorner = nil,
    ControlsRow = nil,
    ControlButtons = {},
    ControlCallbacks = {},
    Wave = nil,
    WaveBars = {},
    ProgressTrack = nil,
    ProgressFill = nil,
    Overlay = nil,
    IconIsImage = true,
    Tweens = {},
    ViewportConnection = nil,
    CameraConnection = nil,
    Config = {
        DefaultTime = 5,
        OffsetY = 11,
        RespectTopBarInset = true,
        Scale = 1,
        CollapsedWidth = 88,
        CollapsedHeight = 26,
        ExpandedHeight = 34,
        CardHeight = 48,
        MaxWidthScale = 0.82,
        MaxWidth = 460,
        PaddingLeft = 8,
        PaddingRight = 11,
        IconSize = 18,
        IconSizeCard = 26,
        Gap = 7,
        TextSize = 12,
        SubtitleSize = 11,
        TypeSpeed = 45,
        TypeTime = 0.9,
        Pulse = false,
        PulseInterval = 1.6,
        PulseStrength = 0.1,
        PingRing = false,
        TapToDismiss = true,
        Hover = false,
        Gloss = true,
        Glow = true,
        TextPop = 1.16,
        Shadow = false,
        Burst = false,
        TextShine = false,
        TapDip = true,
        PulseByKind = true,
        StaggerTime = 0.06,
        Crossfade = true,
        MorphOverlap = 0.07,
        IconMorph = true,
        TextWipe = false,
        ProgressBar = false,
        ProgressShimmer = true,
        Draggable = true,
        DragThreshold = 22,
        Nudge = false,
        Glass = false,
        Stroke = false,
        Gloss = false,
        Glow = false,
        IconBackdrop = false,
        Waveform = true,
        Glyphs = nil,
        IconShape = "circle",
        IconStyle = "vector",
        IconAnim = true,
        CornerRadius = 15,
        ConcentricCorners = true,
        ControlsHeight = 72,
        SubtitleColor = Color3.fromRGB(152, 152, 157),
        ProgressGlow = true,
        ProgressThickness = 3,
        Font = Enum.Font.GothamMedium,
        TextColor = Color3.fromRGB(242, 242, 247),
        StrokeBase = 0.72,
        SpringTime = 0.46,
        Accent = nil,
        ColorIdle = Color3.fromRGB(142, 142, 147),
        ColorSuccess = Color3.fromRGB(48, 209, 88),
        ColorWarning = Color3.fromRGB(255, 179, 64),
        ColorError = Color3.fromRGB(255, 69, 58),
        ColorLoading = Color3.fromRGB(150, 152, 168),
        ColorMusic = Color3.fromRGB(255, 45, 85),
    },
}

local StyleQuint = Enum.EasingStyle.Quint
local StyleLinear = Enum.EasingStyle.Linear
local DYNAMIC_EASE = {
    Enter = { 0.55, StyleQuint, DirOut },
    Exit = { 0.26, StyleQuart, DirIn },
    Snap = { 0.25, StyleQuart, DirOut },
    Micro = { 0.13, StyleSine, DirOut },
    Spring = { 0.45, StyleBack, DirOut },
    Pop = { 0.42, StyleQuint, DirOut },
    Resize = { 0.42, StyleQuint, DirOut },
    Glow = { 1.4, StyleSine, DirInOut },
}

local function dynamicEase(profile, extra)
    local data = DYNAMIC_EASE[profile] or DYNAMIC_EASE.Snap
    local duration = data[1]
    if type(extra) == "number" then
        duration = extra
    end
    return duration, data[2], data[3]
end

local DYNAMIC_KIND_PULSE = {
    info = 1.6,
    success = 1.8,
    warning = 1.25,
    error = 0.95,
    loading = 1.1,
    idle = 2.0,
    running = 1.6,
}

local DYNAMIC_CLEAR_SEQ = NumberSequence.new(0)
local DYNAMIC_SHINE_SEQ = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.42, 1),
    NumberSequenceKeypoint.new(0.5, 0.15),
    NumberSequenceKeypoint.new(0.58, 1),
    NumberSequenceKeypoint.new(1, 1),
})
local DYNAMIC_WIPE_SEQ = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.34, 0),
    NumberSequenceKeypoint.new(0.5, 1),
    NumberSequenceKeypoint.new(1, 1),
})

local DYNAMIC_FRAME = 0.033
local DYNAMIC_DEBUG = false
pcall(function()
    DYNAMIC_DEBUG = (getgenv().DynamicIslandDebug == true)
end)

local function dynamicIsColor(value)
    if typeof(value) == "Color3" then
        return true
    end
    return type(value) == "table" and value.R ~= nil and value.G ~= nil and value.B ~= nil
end

local function dynamicAccent()
    local config = DynamicIsland.Config
    if dynamicIsColor(config.Accent) then
        return config.Accent
    end
    local colors = getgenv().UIColor
    if colors and dynamicIsColor(colors["Title Text Color"]) then
        return colors["Title Text Color"]
    end
    return Color3.fromRGB(0, 170, 255)
end

local DYNAMIC_KINDS = {
    info = { ColorKey = nil, Spinner = false },
    success = { ColorKey = "ColorSuccess", Spinner = false },
    warning = { ColorKey = "ColorWarning", Spinner = false },
    error = { ColorKey = "ColorError", Spinner = false },
    loading = { ColorKey = "ColorLoading", Spinner = true },
    music = { ColorKey = "ColorMusic", Spinner = false, Wave = true },
    running = { ColorKey = "ColorSuccess", Spinner = false },
    idle = { ColorKey = "ColorIdle", Spinner = false },
}

local DYNAMIC_GLYPHS = {
    music = "♪",
    success = "v",
    warning = "!",
    error = "x",
    running = ">",
}

local DYNAMIC_VECTOR_ICONS = {
    music = {
        Anim = { Scale = 0.55, Rotation = -14 },
        Parts = {
            { 0.300, 0.745, 0.300, 0.235, -20 },
            { 0.660, 0.685, 0.300, 0.235, -20 },
            { 0.415, 0.455, 0.078, 0.575, 0 },
            { 0.775, 0.395, 0.078, 0.575, 0 },
            { 0.593, 0.130, 0.430, 0.104, -9.5 },
        },
    },
    success = {
        Anim = { Scale = 0.6, Rotation = -10 },
        Parts = {
            { 0.360, 0.600, 0.230, 0.112, 45 },
            { 0.585, 0.505, 0.455, 0.112, -50 },
        },
    },
    warning = {
        Anim = { Scale = 0.7, OffsetY = -0.18 },
        Parts = {
            { 0.500, 0.392, 0.112, 0.400, 0 },
            { 0.500, 0.730, 0.125, 0.125, 0 },
        },
    },
    error = {
        Anim = { Scale = 0.5, Rotation = -70 },
        Parts = {
            { 0.500, 0.500, 0.640, 0.112, 45 },
            { 0.500, 0.500, 0.640, 0.112, -45 },
        },
    },
    running = {
        Anim = { Scale = 1, OffsetX = -0.18 },
        Parts = {
            { 0.510, 0.360, 0.400, 0.112, 40 },
            { 0.510, 0.640, 0.400, 0.112, -40 },
        },
    },
    info = {
        Anim = { Scale = 0.6 },
        Parts = {
            { 0.500, 0.268, 0.125, 0.125, 0 },
            { 0.500, 0.600, 0.112, 0.420, 0 },
        },
    },
}

local function dynamicKindColor(kind)
    local data = DYNAMIC_KINDS[kind or "info"] or DYNAMIC_KINDS.info
    local config = DynamicIsland.Config
    local color = data.ColorKey and config[data.ColorKey]
    if dynamicIsColor(color) then
        return color
    end
    return dynamicAccent()
end

local function dynamicTextColor()
    local colors = getgenv().UIColor
    if colors and dynamicIsColor(colors["GUI Text Color"]) then
        return colors["GUI Text Color"]
    end
    return Color3.fromRGB(240, 240, 240)
end

local function dynamicViewport()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize
    if not viewport or (viewport.X or 0) <= 0 or (viewport.Y or 0) <= 0 then
        viewport = Vector2.new(1280, 720)
    end
    return viewport
end

local function dynamicTopInset()
    local config = DynamicIsland.Config
    if not config.RespectTopBarInset then
        return 0
    end

    local island = DynamicIsland
    if island.TopInset ~= nil then
        return island.TopInset
    end

    local ok, inset = pcall(function()
        return game:GetService("GuiService"):GetGuiInset()
    end)
    if ok and inset and tonumber(inset.Y) then
        island.TopInset = math.max(0, inset.Y)
    else
        island.TopInset = 0
    end
    return island.TopInset
end

local function dynamicOffsetY()
    local config = DynamicIsland.Config
    return config.OffsetY + dynamicTopInset()
end

local function dynamicSanitizeConfig()
    local config = DynamicIsland.Config
    local function num(value, default, min, max)
        local number = tonumber(value)
        if number == nil then
            return default
        end
        return math.clamp(number, min, max)
    end

    local DYNAMIC_SIZE_KEYS = {
        "CollapsedWidth", "CollapsedHeight", "ExpandedHeight", "CardHeight",
        "ControlsHeight", "PaddingLeft", "PaddingRight", "IconSize", "IconSizeCard",
        "Gap", "TextSize", "SubtitleSize", "CornerRadius",
    }
    local scale = num(config.Scale, 1, 0.6, 1.6)
    local applied = DynamicIsland.AppliedScale or 1
    if scale ~= applied then
        local factor = scale / applied
        for _, key in ipairs(DYNAMIC_SIZE_KEYS) do
            local value = tonumber(config[key])
            if value then
                config[key] = value * factor
            end
        end
        DynamicIsland.AppliedScale = scale
    end

    config.TextSize = num(config.TextSize, 12, 8, 24)
    config.SubtitleSize = num(config.SubtitleSize, 11, 8, 22)
    config.IconSize = num(config.IconSize, 18, 8, 48)
    config.IconSizeCard = num(config.IconSizeCard, 26, 8, 64)
    config.Gap = num(config.Gap, 9, 0, 40)
    config.PaddingLeft = num(config.PaddingLeft, 12, 0, 60)
    config.PaddingRight = num(config.PaddingRight, 16, 0, 60)
    config.CollapsedWidth = num(config.CollapsedWidth, 88, 40, 320)
    config.CollapsedHeight = num(config.CollapsedHeight, 26, 16, 80)
    config.ExpandedHeight = math.max(num(config.ExpandedHeight, 34, 20, 120), config.CollapsedHeight + 4)
    local cardFloor = math.max(config.ExpandedHeight + 8, config.CollapsedHeight + 4)
    config.CardHeight = math.max(num(config.CardHeight, 48, 30, 160), cardFloor)
    config.MaxWidth = num(config.MaxWidth, 460, 120, 900)
    config.MaxWidthScale = num(config.MaxWidthScale, 0.82, 0.3, 1)
    config.OffsetY = num(config.OffsetY, 11, -60, 400)
    config.DefaultTime = num(config.DefaultTime, 5, 0, 60)
    config.TypeSpeed = num(config.TypeSpeed, 45, 0, 400)
    config.TypeTime = num(config.TypeTime, 0.9, 0.1, 5)
    config.PulseInterval = num(config.PulseInterval, 1.6, 0.4, 10)
    config.PulseStrength = num(config.PulseStrength, 0.1, 0, 0.35)
    config.TextPop = num(config.TextPop, 1.16, 1, 1.6)
    config.StaggerTime = num(config.StaggerTime, 0.06, 0, 0.3)
    config.MorphOverlap = num(config.MorphOverlap, 0.07, 0, 0.2)
    config.DragThreshold = num(config.DragThreshold, 22, 8, 120)
    config.ProgressThickness = num(config.ProgressThickness, 3, 2, 6)
    config.ProgressBar = (config.ProgressBar == true)
    config.StrokeBase = num(config.StrokeBase, 0.72, 0, 0.98)
    config.SpringTime = num(config.SpringTime, 0.46, 0.1, 2)
    config.CornerRadius = num(config.CornerRadius, 15, 5, 80)
    config.ControlsHeight = math.max(num(config.ControlsHeight, 72, 40, 160), config.ExpandedHeight + 12)

    local shape = string.lower(tostring(config.IconShape or "circle"))
    if shape == "squircle" or shape == "rounded" or shape == "square" then
        config.IconShape = "squircle"
    else
        config.IconShape = "circle"
    end
    local style = string.lower(tostring(config.IconStyle or "vector"))
    if style == "glyph" or style == "text" then
        config.IconStyle = "glyph"
    else
        config.IconStyle = "vector"
    end
    config.IconAnim = (config.IconAnim ~= false)
end

local function dynamicMaxWidth()
    local config = DynamicIsland.Config
    local viewport = dynamicViewport()
    local maxWidth = math.floor(viewport.X * config.MaxWidthScale)

    local screenLimit = math.max(96, math.floor(viewport.X) - 16)
    maxWidth = math.min(maxWidth, screenLimit)

    return math.clamp(maxWidth, math.min(96, screenLimit), config.MaxWidth)
end

local function dynamicIsCard()
    local current = DynamicIsland.Current
    return current ~= nil and current.Title ~= nil
end

local function dynamicWaveActive()
    local island = DynamicIsland
    local current = island.Current
    if current == nil or not island.Config.Waveform then
        return false
    end
    return current.Wave == true
end

local function dynamicIconSize()
    local config = DynamicIsland.Config
    if dynamicIsCard() then
        return config.IconSizeCard or 34
    end
    return config.IconSize
end

local function dynamicTextLeft()
    local config = DynamicIsland.Config
    return config.PaddingLeft + dynamicIconSize() + config.Gap
end

local function dynamicRightPad()
    local config = DynamicIsland.Config
    return config.PaddingRight + (dynamicWaveActive() and 26 or 0)
end

local function dynamicPillRadius(height)
    local config = DynamicIsland.Config
    local half = math.max(1, (height or 0) / 2)
    if (height or 0) <= (config.ExpandedHeight or 34) + 1 then
        return math.floor(half)
    end
    return math.min(math.floor(half), math.max(5, tonumber(config.CornerRadius) or 15))
end

local function dynamicCornerUDim(height)
    local config = DynamicIsland.Config
    if (height or 0) <= (config.ExpandedHeight or 34) + 1 then
        return UDim.new(1, 0)
    end
    return UDim.new(0, dynamicPillRadius(height))
end

local function dynamicControlsActive()
    local current = DynamicIsland.Current
    if current == nil then
        return false
    end
    local list = current.Controls
    return type(list) == "table" and #list > 0
end

local function dynamicControlsCount()
    local current = DynamicIsland.Current
    if current == nil or type(current.Controls) ~= "table" then
        return 0
    end
    return math.min(#current.Controls, 3)
end

local function dynamicArtworkRadius(height, iconSize)
    local config = DynamicIsland.Config
    if not config.ConcentricCorners then
        return math.floor((iconSize or config.IconSize) * 0.28)
    end
    local outer = dynamicPillRadius(height)
    local inset = math.max(0, (tonumber(config.PaddingLeft) or 10) - 2)
    local radius = math.max(4, math.floor(outer - inset))
    return math.min(radius, math.floor((iconSize or config.IconSize) / 2))
end

local function dynamicArtworkUDim(height, iconSize)
    local config = DynamicIsland.Config
    if (config.IconShape or "circle") == "squircle" then
        return UDim.new(0, dynamicArtworkRadius(height, iconSize))
    end
    return UDim.new(0.5, 0)
end

local function dynamicCardHeight()
    local config = DynamicIsland.Config
    if dynamicControlsActive() then
        return config.ControlsHeight or 96
    end
    if dynamicIsCard() then
        return config.CardHeight or 64
    end
    return config.ExpandedHeight
end

local function dynamicPrimaryY()
    local height = dynamicCardHeight()
    if dynamicControlsActive() then
        return -math.floor(height * 0.21)
    end
    return dynamicIsCard() and -math.floor(height * 0.19) or 0
end

local function dynamicSubtitleY()
    if dynamicControlsActive() then
        return 0
    end
    return math.floor(dynamicCardHeight() * 0.17)
end

local function dynamicControlsY()
    return math.floor(dynamicCardHeight() * 0.30)
end

local function dynamicControlSize()
    local height = dynamicCardHeight()
    return math.clamp(math.floor(height * 0.32), 16, 30)
end

local function dynamicMeasureLine(text, textSize, available)
    local value = tostring(text or "")
    if value == "" then
        return 0
    end

    local length = #value
    if utf8 and utf8.len then
        length = utf8.len(value) or length
    end
    local width = length * (textSize * 0.55)

    local ok, result = pcall(function()
        return game:GetService("TextService"):GetTextSize(
            value,
            textSize,
            DynamicIsland.Config.Font or Enum.Font.GothamBold,
            Vector2.new(available, 60)
        )
    end)
    if ok and result and tonumber(result.X) then
        width = result.X
    end
    return width
end

local function dynamicMeasureWidth(text, subtitle)
    local config = DynamicIsland.Config
    local fixedWidth = config.PaddingLeft + dynamicIconSize() + config.Gap + dynamicRightPad()
    local maxWidth = dynamicMaxWidth()
    local available = math.max(48, maxWidth - fixedWidth)

    local width = dynamicMeasureLine(text, config.TextSize, available)
    if subtitle and subtitle ~= "" then
        width = math.max(width, dynamicMeasureLine(subtitle, config.SubtitleSize or 13, available))
    end

    return math.clamp(math.ceil(width) + fixedWidth, config.CollapsedWidth, maxWidth)
end

local function dynamicApplyControls(notification)
    local island = DynamicIsland
    if not island.ControlsRow or not island.ControlButtons then
        return
    end

    local list = (notification and notification.Controls) or {}
    local count = math.min(#list, 3)

    for index, button in ipairs(island.ControlButtons) do
        local data = list[index]
        if index <= count and data ~= nil then
            local label, callback
            if type(data) == "table" then
                label = data.Icon or data.Text or data.Label or ""
                callback = data.Callback or data.OnTap
            else
                label = tostring(data)
            end
            button.Text = tostring(label)
            button.Visible = true
            island.ControlCallbacks[index] = callback
        else
            button.Text = ""
            button.Visible = false
            island.ControlCallbacks[index] = nil
        end
    end

    island.ControlsRow.Visible = count > 0
end

local function dynamicApplyTextLayout(noSubtitle)
    local island = DynamicIsland
    local config = island.Config
    if not island.Text then
        return
    end

    local left = dynamicTextLeft()
    local rightPad = dynamicRightPad()
    local card = dynamicIsCard()

    local iconSize = dynamicIconSize()
    if island.IconHolder then
        local iconY = 0
        if card then
            iconY = math.floor((dynamicPrimaryY() + dynamicSubtitleY()) / 2)
        end
        island.IconHolder.Size = UDim2.new(0, iconSize, 0, iconSize)
        island.IconHolder.Position = UDim2.new(0, config.PaddingLeft + iconSize / 2, 0.5, iconY)
    end
    if island.IconBackdrop then
        island.IconBackdrop.Size = UDim2.new(0, iconSize + 12, 0, iconSize + 12)
    end
    if island.IconGlyph then
        island.IconGlyph.TextSize = math.floor(iconSize * 0.6)
    end
    local target = island.Current and dynamicCardHeight() or config.CollapsedHeight
    local shapeUDim = dynamicArtworkUDim(target, iconSize)
    if island.ArtworkCorner then
        island.ArtworkCorner.CornerRadius = shapeUDim
    end
    if island.IconDotCorner then
        island.IconDotCorner.CornerRadius = shapeUDim
    end
    if island.IconImageCorner then
        island.IconImageCorner.CornerRadius = shapeUDim
    end

    if island.ControlsRow then
        local size = dynamicControlSize()
        island.ControlsRow.Position = UDim2.new(0.5, 0, 0.5, dynamicControlsY())
        island.ControlsRow.Size = UDim2.new(1, -18, 0, size)
        if island.ControlButtons then
            for _, button in ipairs(island.ControlButtons) do
                button.Size = UDim2.new(0, size, 0, size)
                button.TextSize = math.clamp(math.floor(size * 0.5), 8, 14)
            end
        end
    end

    if island.Wave then
        local wh = math.clamp(math.floor(dynamicCardHeight() * 0.25), 9, 16)
        island.Wave.Size = UDim2.new(0, math.floor(wh * 1.25), 0, wh)
    end

    if island.Spinner and island.SpinnerDots then
        local radius = math.max(3, iconSize / 2 - 2)
        for index, dot in ipairs(island.SpinnerDots) do
            local angle = (index - 1) * math.pi / 4
            dot.Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius)
        end
    end

    island.Text.Position = UDim2.new(0, left, 0.5, card and dynamicPrimaryY() or 0)
    if card then
        island.Text.Size = UDim2.new(1, -(left + rightPad), 0, 20)
    else
        island.Text.Size = UDim2.new(1, -(left + rightPad), 1, 0)
    end

    if island.TextGhost then
        island.TextGhost.Position = UDim2.new(0, left, 0.5, card and dynamicPrimaryY() or 0)
        if card then
            island.TextGhost.Size = UDim2.new(1, -(left + rightPad), 0, 20)
        else
            island.TextGhost.Size = UDim2.new(1, -(left + rightPad), 1, 0)
        end
    end

    if island.Subtitle then
        island.Subtitle.Position = UDim2.new(0, left, 0.5, dynamicSubtitleY())
        island.Subtitle.Size = UDim2.new(1, -(left + rightPad), 0, 16)
        island.Subtitle.Font = config.Font or Enum.Font.GothamBold
        island.Subtitle.TextSize = tonumber(config.SubtitleSize) or 13
        island.Subtitle.TextColor3 = dynamicIsColor(config.SubtitleColor) and config.SubtitleColor
            or Color3.fromRGB(152, 152, 157)
        if noSubtitle or not card then
            island.Subtitle.Visible = false
            island.Subtitle.TextTransparency = 1
        end
    end
end

local function dynamicCancel(key)
    local tweenObject = DynamicIsland.Tweens[key]
    if tweenObject then
        DynamicIsland.Tweens[key] = nil
        pcall(function()
            tweenObject:Cancel()
        end)
    end
end

local function dynamicCancelAll()
    local keys = {}
    for key in pairs(DynamicIsland.Tweens) do
        keys[#keys + 1] = key
    end
    for _, key in ipairs(keys) do
        dynamicCancel(key)
    end
end

local function dynamicOwnerTable()
    local island = DynamicIsland
    if island.PropOwner == nil then
        island.PropOwner = setmetatable({}, { __mode = "k" })
    end
    return island.PropOwner
end

local function dynamicClaimProperties(object, properties, key)
    local owners = dynamicOwnerTable()
    local map = owners[object]
    if map == nil then
        map = {}
        owners[object] = map
    end
    for property in pairs(properties) do
        map[property] = key
    end
end

local function dynamicStillOwner(object, properties, key)
    local owners = dynamicOwnerTable()
    local map = owners[object]
    if map == nil then
        return true
    end
    for property in pairs(properties) do
        if map[property] ~= nil and map[property] ~= key then
            return false
        end
    end
    return true
end

local function dynamicTween(key, object, properties, duration, style, direction)
    if not object then
        return nil
    end

    dynamicCancel(key)

    duration = DisableAnimation and 0 or (tonumber(duration) or 0.25)
    if duration <= 0 then
        dynamicClaimProperties(object, properties, key)
        for property, value in pairs(properties) do
            pcall(function()
                object[property] = value
            end)
        end
        return nil
    end

    dynamicClaimProperties(object, properties, key)

    local created, tweenObject = pcall(function()
        return TweenService:Create(object, TweenInfo.new(duration, style or StyleQuart, direction or DirOut), properties)
    end)
    if not created or not tweenObject then
        for property, value in pairs(properties) do
            pcall(function()
                object[property] = value
            end)
        end
        return nil
    end
    DynamicIsland.Tweens[key] = tweenObject
    tweenObject:Play()
    return tweenObject
end

local function dynamicSpring(key, object, peak, target, duration, style)
    duration = duration or 0.4
    dynamicTween(key, object, peak, duration * 0.45, style or StyleBack, DirOut)
    task.delay(duration * 0.45, function()
        if object == nil or object.Parent == nil then
            return
        end
        if not dynamicStillOwner(object, peak, key) then
            return
        end
        dynamicTween(key, object, target, duration * 0.55, StyleQuart, DirOut)
    end)
end

local function dynamicSyncDecor(width, height, duration, style, direction)
    local island = DynamicIsland
    if island.Shadow then
        island.Shadow.Position = UDim2.new(0.5, 0, 0, dynamicOffsetY() + height / 2 + 14)
        if island.Config.Shadow then
            island.Shadow.Visible = true
        else
            island.Shadow.Visible = false
            dynamicTween("shadowSize", island.Shadow, {
                Size = UDim2.new(0, width + 132, 0, height + 66),
            }, duration or 0.3, style or StyleQuart, direction or DirOut)
        end
    end
    if island.Burst then
        island.Burst.Position = UDim2.new(0.5, 0, 0, dynamicOffsetY() + height / 2)
    end
end

local function dynamicPillSize(width, height, duration, style, direction)
    local island = DynamicIsland
    if not island.Root then
        return nil
    end
    local tweenObject = dynamicTween(
        "rootSize",
        island.Root,
        { Size = UDim2.new(0, width, 0, height) },
        duration,
        style,
        direction
    )
    if island.ArtworkCorner then
        dynamicTween(
            "artworkCorner",
            island.ArtworkCorner,
            { CornerRadius = dynamicArtworkUDim(height, dynamicIconSize()) },
            duration,
            style,
            direction
        )
    end
    if island.Corner then
        dynamicTween(
            "corner",
            island.Corner,
            { CornerRadius = dynamicCornerUDim(height) },
            duration,
            style,
            direction
        )
    end
    dynamicSyncDecor(width, height, duration, style, direction)
    return tweenObject
end

local function dynamicCancelSiblings(...)
    for index = 1, select("#", ...) do
        dynamicCancel((select(index, ...)))
    end
end

local function dynamicTextShine(token)
    local island = DynamicIsland
    if not island.TextShine or not island.Config.TextShine or DisableAnimation then
        return
    end
    island.ShineToken = (island.ShineToken or 0) + 1
    local shineToken = island.ShineToken

    dynamicCancel("shine")
    dynamicCancel("textWipe")
    island.TextShine.Transparency = DYNAMIC_SHINE_SEQ
    island.TextShine.Offset = Vector2.new(-1, 0)
    dynamicTween("shine", island.TextShine, { Offset = Vector2.new(1, 0) }, 0.66, StyleQuad, DirOut)

    task.delay(0.72, function()
        if island.ShineToken ~= shineToken or not island.TextShine then
            return
        end
        island.TextShine.Transparency = DYNAMIC_CLEAR_SEQ
    end)
end

local function dynamicTextWipe(token)
    local island = DynamicIsland
    local gradient = island.TextShine
    if not gradient or DisableAnimation then
        return false
    end

    island.ShineToken = (island.ShineToken or 0) + 1
    local shineToken = island.ShineToken

    dynamicCancel("shine")
    dynamicCancel("textWipe")
    gradient.Transparency = DYNAMIC_WIPE_SEQ
    gradient.Offset = Vector2.new(1, 0)
    dynamicTween("textWipe", gradient, { Offset = Vector2.new(-1, 0) }, 0.42, StyleQuart, DirOut)

    task.delay(0.46, function()
        if island.ShineToken ~= shineToken or not gradient then
            return
        end
        gradient.Transparency = DYNAMIC_CLEAR_SEQ
        if island.Enabled and island.Token == token then
            dynamicTextShine(token)
        end
    end)
    return true
end

local function dynamicGhostOut(duration)
    local island = DynamicIsland
    local ghost = island.TextGhost
    if not ghost then
        return
    end
    duration = duration or 0.2
    dynamicTween("ghostFade", ghost, { TextTransparency = 1 }, duration, StyleQuad, DirOut)
    dynamicTween("ghostSlide", ghost, {
        Position = UDim2.new(0, dynamicTextLeft() - 8, 0.5, -4),
    }, duration, StyleQuart, DirOut)
end

local function dynamicGhostClear()
    local island = DynamicIsland
    if not island.TextGhost then
        return
    end
    dynamicCancel("ghostFade")
    dynamicCancel("ghostSlide")
    island.TextGhost.TextTransparency = 1
end

local function dynamicBurst(token, accent)
    local island = DynamicIsland
    if DisableAnimation or not island.Config.Burst or not island.Burst then
        return
    end
    island.BurstStroke.Color = accent or dynamicAccent()
    island.BurstStroke.Transparency = 0.3
    island.BurstScale.Scale = 0.8
    dynamicTween("burstScale", island.BurstScale, { Scale = 3.4 }, 0.7, StyleQuad, DirOut)
    dynamicTween("burstFade", island.BurstStroke, { Transparency = 1 }, 0.7, StyleQuad, DirOut)
end

local function dynamicResolveIcon(icon)
    if dynamicIsColor(icon) then
        return "color", icon
    end

    if type(icon) == "number" then
        return "image", "rbxassetid://" .. tostring(math.floor(icon))
    end

    if type(icon) == "string" and icon ~= "" then
        if string.match(icon, "^%d+$") then
            return "image", "rbxassetid://" .. icon
        end
        if
            string.match(icon, "^rbxassetid://")
            or string.match(icon, "^rbxasset://")
            or string.match(icon, "^rbxthumb://")
            or string.match(icon, "^https?://")
        then
            return "image", icon
        end
    end

    local colors = getgenv().UIColor
    local logo = colors and colors["Logo Image"]
    if type(logo) == "string" and logo ~= "" then
        return "image", logo
    end

    return "color", dynamicAccent()
end

local function dynamicStopSpinner()
    local island = DynamicIsland
    island.SpinToken = island.SpinToken + 1
    dynamicCancel("spin")
    if island.Spinner then
        island.Spinner.Visible = false
        island.Spinner.Rotation = 0
    end
end

local function dynamicStartSpinner(token)
    local island = DynamicIsland
    if not island.Spinner then
        return
    end

    island.SpinToken = island.SpinToken + 1
    local spinToken = island.SpinToken
    island.Spinner.Visible = true
    island.Spinner.Rotation = 0

    local function tick()
        if
            not island.Enabled
            or island.SpinToken ~= spinToken
            or island.Current == nil
            or not island.Spinner.Visible
        then
            return
        end
        island.Spinner.Rotation = 0
        local spin = dynamicTween("spin", island.Spinner, { Rotation = 360 }, 0.9, Enum.EasingStyle.Linear, DirOut)
        if spin then
            spin.Completed:Connect(function(playbackState)
                if playbackState ~= Enum.PlaybackState.Completed then
                    return
                end
                tick()
            end)
        else
            island.Spinner.Rotation = 360
        end
    end

    tick()
end

local function dynamicStopPulse()
    local island = DynamicIsland
    island.PulseToken = island.PulseToken + 1

    dynamicCancel("iconPulse")
    dynamicCancel("pingScale")
    dynamicCancel("pingFade")
    dynamicCancel("strokeBreathe")

    if island.IconScale then
        island.IconScale.Scale = 1
    end
    if island.PingScale then
        island.PingScale.Scale = 0.85
    end
    if island.PingStroke then
        island.PingStroke.Transparency = 1
    end
    if island.Stroke then
        local base = island.StrokeBase or 0.72
        island.Stroke.Transparency = island.Hovering and (base - 0.17) or base
    end
    dynamicCancel("glowPulse")
    if island.Glow then
        island.Glow.ImageTransparency = 0.92
    end
end

local function dynamicPulseTick(pulseToken)
    local island = DynamicIsland
    if
        not island.Enabled
        or island.PulseToken ~= pulseToken
        or island.Current == nil
        or not island.Config.Pulse
        or not island.IconScale
    then
        return
    end

    local config = island.Config
    local interval = math.max(0.6, tonumber(config.PulseInterval) or 1.6)
    if config.PulseByKind and island.Current then
        interval = DYNAMIC_KIND_PULSE[island.Current.Kind or "info"] or interval
    end
    local strength = math.clamp(tonumber(config.PulseStrength) or 0.1, 0, 0.35)

    dynamicCancelSiblings("iconOut", "iconPop")
    dynamicTween("iconPulse", island.IconScale, { Scale = 1 + strength }, interval * 0.18, StyleSine, DirOut)
    task.delay(interval * 0.2, function()
        if island.Enabled and island.PulseToken == pulseToken and island.Current ~= nil then
            dynamicTween("iconPulse", island.IconScale, { Scale = 1 }, interval * 0.32, StyleSine, DirIn)
        end
    end)

    if config.PingRing and island.PingScale and island.PingStroke then
        island.PingScale.Scale = 0.55
        island.PingStroke.Transparency = 0.4
        dynamicTween("pingScale", island.PingScale, { Scale = 1.9 }, 1.15, StyleQuad, DirOut)
        dynamicTween("pingFade", island.PingStroke, { Transparency = 1 }, 1.15, StyleQuad, DirOut)
    end

    if config.Glow and island.Glow then
        dynamicTween("glowPulse", island.Glow, { ImageTransparency = 0.86 }, DYNAMIC_EASE.Glow[1] * 0.5, StyleSine, DirInOut)
    end

    if island.Stroke and not island.Hovering then
        dynamicCancel("strokeFlash")
        local base = island.StrokeBase or 0.72
        local bright = math.max(0.02, base - 0.28)
        dynamicTween("strokeBreathe", island.Stroke, { Transparency = bright }, interval * 0.3, StyleSine, DirOut)
        task.delay(interval * 0.34, function()
            if island.Enabled and island.PulseToken == pulseToken and island.Current ~= nil then
                dynamicTween("strokeBreathe", island.Stroke, { Transparency = base }, interval * 0.4, StyleSine, DirIn)
            end
        end)
    end

    task.delay(interval, function()
        if island.Enabled and island.PulseToken == pulseToken and island.Current ~= nil then
            dynamicPulseTick(pulseToken)
        end
    end)
end

local function dynamicStartPulse(delay)
    local island = DynamicIsland
    dynamicStopPulse()
    if DisableAnimation or not island.Config.Pulse or island.Current == nil then
        return
    end
    island.PulseToken = island.PulseToken + 1
    local pulseToken = island.PulseToken

    task.delay(delay or 0.42, function()
        if island.Enabled and island.PulseToken == pulseToken and island.Current ~= nil then
            dynamicPulseTick(pulseToken)
        end
    end)
end

local function dynamicShowIcon(duration)
    local island = DynamicIsland
    duration = duration or 0.16
    if island.IconBackdrop then
        dynamicTween("backdropFade", island.IconBackdrop, { BackgroundTransparency = 0.86 }, duration, StyleQuad, DirOut)
    end
    if island.IconBackdropStroke then
        dynamicTween("backdropStroke", island.IconBackdropStroke, { Transparency = 0.7 }, duration, StyleQuad, DirOut)
    end
    if island.IconVectorGroup and island.IconVectorGroup.Group then
        island.IconVectorGroup.Group.Visible = true
    end
    if island.IconIsImage then
        dynamicTween("iconFade", island.IconImage, { ImageTransparency = 0 }, duration, StyleQuad, DirOut)
    else
        dynamicTween("dotFade", island.IconDot, { BackgroundTransparency = 0.05 }, duration, StyleQuad, DirOut)
        if island.IconGlyph and island.IconGlyph.Visible then
            dynamicTween("glyphFade", island.IconGlyph, { TextTransparency = 0 }, duration, StyleQuad, DirOut)
        end
        if island.IconDotStroke then
            dynamicTween("iconStrokeFade", island.IconDotStroke, { Transparency = 0.45 }, duration, StyleQuad, DirOut)
        end
    end
end

local function dynamicHideIcon(duration)
    local island = DynamicIsland
    duration = duration or 0.12
    if island.IconBackdrop then
        dynamicTween("backdropFade", island.IconBackdrop, { BackgroundTransparency = 1 }, duration, StyleQuad, DirIn)
    end
    if island.IconBackdropStroke then
        dynamicTween("backdropStroke", island.IconBackdropStroke, { Transparency = 1 }, duration, StyleQuad, DirIn)
    end
    if island.IconImage then
        dynamicTween("iconFade", island.IconImage, { ImageTransparency = 1 }, duration, StyleQuad, DirIn)
    end
    if island.IconDot then
        dynamicTween("dotFade", island.IconDot, { BackgroundTransparency = 1 }, duration, StyleQuad, DirIn)
    end
    if island.IconDotStroke then
        dynamicTween("iconStrokeFade", island.IconDotStroke, { Transparency = 1 }, duration, StyleQuad, DirIn)
    end
    if island.IconGlyph then
        dynamicTween("glyphFade", island.IconGlyph, { TextTransparency = 1 }, duration, StyleQuad, DirIn)
    end
    local entry = island.IconVectorGroup
    if entry and entry.Group then
        if DisableAnimation or not island.Config.IconAnim then
            entry.Group.Visible = false
            entry.Scale.Scale = 1
        else
            dynamicTween("vecOut", entry.Scale, { Scale = 0.7 }, duration + 0.02, StyleQuart, DirIn)
            island.VectorToken = (island.VectorToken or 0) + 1
            local token = island.VectorToken
            task.delay(duration + 0.04, function()
                if island.VectorToken ~= token or island.IconVectorGroup ~= entry then
                    return
                end
                entry.Group.Visible = false
                entry.Scale.Scale = 1
            end)
        end
    end
end

local function dynamicHideVectors()
    local island = DynamicIsland
    island.VectorToken = (island.VectorToken or 0) + 1
    if not island.IconVectors then
        return
    end
    for _, entry in pairs(island.IconVectors) do
        if entry.Group then
            entry.Group.Visible = false
            entry.Group.Rotation = 0
            entry.Group.Position = UDim2.new(0.5, 0, 0.5, 0)
        end
        if entry.Scale then
            entry.Scale.Scale = 1
        end
    end
    island.IconVectorGroup = nil
    island.IconVectorKind = nil
end

local function dynamicShowVector(kind)
    local island = DynamicIsland
    local entry = island.IconVectors and island.IconVectors[kind]
    dynamicHideVectors()
    if not entry or not entry.Group then
        return false
    end
    entry.Group.Position = UDim2.new(0.5, 0, 0.5, 0)
    entry.Group.Rotation = 0
    entry.Scale.Scale = 1
    entry.Group.Visible = true
    island.VectorToken = (island.VectorToken or 0) + 1
    island.IconVectorGroup = entry
    island.IconVectorKind = kind
    return true
end

local function dynamicPlayVectorIn()
    local island = DynamicIsland
    local entry = island.IconVectorGroup
    if not entry or not entry.Group or not entry.Group.Visible then
        return
    end
    if DisableAnimation or not island.Config.IconAnim then
        entry.Group.Position = UDim2.new(0.5, 0, 0.5, 0)
        entry.Group.Rotation = 0
        entry.Scale.Scale = 1
        return
    end
    local anim = entry.Anim or {}
    entry.Group.Position = UDim2.new(0.5 + (anim.OffsetX or 0), 0, 0.5 + (anim.OffsetY or 0), 0)
    entry.Group.Rotation = anim.Rotation or 0
    entry.Scale.Scale = anim.Scale or 0.6
    dynamicSpring("vecScale", entry.Scale, { Scale = 1.14 }, { Scale = 1 }, 0.42, StyleBack)
    dynamicTween("vecRot", entry.Group, { Rotation = 0 }, 0.5, StyleBack, DirOut)
    dynamicTween("vecPos", entry.Group, { Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.46, StyleQuart, DirOut)
end

local function dynamicApplyIcon(notification)
    local island = DynamicIsland
    local kindData = DYNAMIC_KINDS[notification.Kind or "info"] or DYNAMIC_KINDS.info
    local accent = notification.Accent or dynamicKindColor(notification.Kind)
    local explicit = notification.Icon

    notification.AccentResolved = accent

    if explicit == nil and kindData.ColorKey ~= nil then
        explicit = accent
    end

    if kindData.Spinner and notification.Icon == nil then
        island.IconIsImage = false
        island.IconImage.Visible = false
        island.IconDot.Visible = false
        if island.IconDotStroke then
            island.IconDotStroke.Transparency = 1
        end
        if island.IconGlyph then
            island.IconGlyph.Text = ""
            island.IconGlyph.Visible = false
            island.IconGlyph.TextTransparency = 1
        end
        dynamicHideVectors()
        dynamicStartSpinner(notification.Token)
        if island.PingStroke then
            island.PingStroke.Transparency = 1
        end
        return accent
    end

    dynamicStopSpinner()

    local kindOf, value = dynamicResolveIcon(explicit)
    if kindOf == "image" then
        local ok = pcall(function()
            island.IconImage.Image = value
        end)
        if not ok then
            kindOf, value = "color", accent
        end
    end

    if kindOf == "image" then
        island.IconIsImage = true
        island.IconImage.Visible = true
        island.IconDot.Visible = false
        if island.IconGlyph then
            island.IconGlyph.Text = ""
            island.IconGlyph.Visible = false
        end
        dynamicHideVectors()
        island.IconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
        if island.IconDotStroke then
            island.IconDotStroke.Transparency = 1
        end
    else
        island.IconIsImage = false
        island.IconImage.Visible = false
        island.IconDot.Visible = true
        island.IconDot.BackgroundColor3 = value

        local iconConfig = DynamicIsland.Config
        local glyphSet = (type(iconConfig.Glyphs) == "table") and iconConfig.Glyphs or DYNAMIC_GLYPHS
        local glyph = (notification.Icon == nil) and glyphSet[notification.Kind or "info"] or nil
        local glyphMode = (iconConfig.IconStyle == "glyph") or (type(iconConfig.Glyphs) == "table")
        local shownVector = false
        if notification.Icon == nil and not glyphMode then
            shownVector = dynamicShowVector(notification.Kind or "info")
        end
        if not shownVector then
            dynamicHideVectors()
        end
        if island.IconGlyph then
            if shownVector then
                island.IconGlyph.Text = ""
                island.IconGlyph.Visible = false
            else
                island.IconGlyph.Text = glyph or ""
                island.IconGlyph.Visible = glyph ~= nil
            end
        end
        if island.IconDotStroke then
            island.IconDotStroke.Color = value
        end
    end

    if island.PingStroke then
        island.PingStroke.Color = accent
        island.PingStroke.Transparency = 1
    end
    if island.Glow then
        island.Glow.ImageColor3 = accent
    end
    if island.IconBackdrop then
        island.IconBackdrop.BackgroundColor3 = accent
    end
    if island.IconBackdropStroke then
        island.IconBackdropStroke.Color = accent
    end
    if island.ProgressGlow then
        island.ProgressGlow.ImageColor3 = accent
    end

    return accent
end

local function dynamicApplyLayout()
    local island = DynamicIsland
    local config = island.Config
    if not island.Root then
        return
    end

    dynamicCancel("rootSize")
    dynamicCancel("rootPos")

    dynamicCancel("artworkCorner")

    dynamicApplyTextLayout(island.Current == nil)
    island.Root.Position = UDim2.new(0.5, 0, 0, dynamicOffsetY())
    if island.Current then
        local width = dynamicMeasureWidth(island.Current.Text, island.Current.Subtitle)
        local height = dynamicCardHeight()
        island.Root.Size = UDim2.new(0, width, 0, height)
        dynamicSyncDecor(width, height, 0)
        if island.Corner then
            island.Corner.CornerRadius = dynamicCornerUDim(height)
        end
    else
        island.Root.Size = UDim2.new(0, config.CollapsedWidth, 0, config.CollapsedHeight)
        dynamicSyncDecor(config.CollapsedWidth, config.CollapsedHeight, 0)
        if island.Corner then
            island.Corner.CornerRadius = dynamicCornerUDim(config.CollapsedHeight)
        end
    end
end

local function dynamicBindViewport()
    local island = DynamicIsland
    if island.ViewportConnection then
        pcall(function()
            island.ViewportConnection:Disconnect()
        end)
        island.ViewportConnection = nil
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local ok, connection = pcall(function()
        return camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            dynamicApplyLayout()
        end)
    end)
    if ok then
        island.ViewportConnection = connection
    end
end

local function dynamicIdleVisual(dotTransparency, ringTransparency, duration, style, direction)
    local island = DynamicIsland
    if island.IdleDot then
        dynamicTween("idleFade", island.IdleDot, { BackgroundTransparency = dotTransparency }, duration, style, direction)
    end
    if island.IdleRing then
        dynamicTween("idleRingFade", island.IdleRing, { Transparency = ringTransparency }, duration, style, direction)
    end
end

local function dynamicIdleBreath(token)
    local island = DynamicIsland
    if not island.Enabled or island.IdleToken ~= token or island.Current ~= nil or not island.IdleDot then
        return
    end

    local appear = 1.1
    if island.IdleDot and (tonumber(island.IdleDot.BackgroundTransparency) or 1) > 0.9 then
        appear = 0.3
    end
    dynamicIdleVisual(0.25, 0.55, appear, StyleSine, DirInOut)
    if island.IdleScale then
        dynamicCancelSiblings("idlePop")
        dynamicTween("idleScale", island.IdleScale, { Scale = 1.25 }, 1.1, StyleSine, DirInOut)
    end

    task.delay(1.1, function()
        if not island.Enabled or island.IdleToken ~= token or island.Current ~= nil or not island.IdleDot then
            return
        end
        dynamicIdleVisual(0.6, 0.85, 1.1, StyleSine, DirInOut)
        if island.IdleScale then
            dynamicCancelSiblings("idlePop")
            dynamicTween("idleScale", island.IdleScale, { Scale = 0.9 }, 1.1, StyleSine, DirInOut)
        end
        task.delay(1.1, function()
            dynamicIdleBreath(token)
        end)
    end)
end

local function dynamicStartIdleBreath()
    local island = DynamicIsland
    island.IdleToken = island.IdleToken + 1
    if DisableAnimation then
        if island.IdleDot then
            island.IdleDot.BackgroundTransparency = 0.35
        end
        if island.IdleRing then
            island.IdleRing.Transparency = 0.6
        end
        if island.IdleScale then
            island.IdleScale.Scale = 1
        end
        return
    end
    dynamicIdleBreath(island.IdleToken)
end

local function dynamicStopIdleBreath()
    local island = DynamicIsland
    island.IdleToken = island.IdleToken + 1
    dynamicCancel("idleFade")
    dynamicCancel("idleRingFade")
    dynamicCancel("idleScale")
    if island.IdleDot then
        island.IdleDot.BackgroundTransparency = 1
    end
    if island.IdleRing then
        island.IdleRing.Transparency = 1
    end
    if island.IdleScale then
        island.IdleScale.Scale = 1
    end
end

local function dynamicBuild()
    local island = DynamicIsland
    if island.Gui and island.Gui.Parent then
        return island.Gui
    end

    dynamicSanitizeConfig()

    if island.UISConns then
        for _, conn in ipairs(island.UISConns) do
            pcall(function()
                conn:Disconnect()
            end)
        end
    end
    island.UISConns = {}

    local config = island.Config
    local coreGui = game:GetService("CoreGui")
    local iconSize = config.IconSize

    local parentGui = coreGui
    pcall(function()
        if type(gethui) == "function" then
            local hui = gethui()
            if hui then
                parentGui = hui
            end
        end
    end)

    pcall(function()
        for _, container in ipairs({ parentGui, coreGui, player and player:FindFirstChild("PlayerGui") }) do
            if container then
                for _, child in ipairs(container:GetChildren()) do
                    if child ~= island.Gui and child.Name == "NatAovHub_DynamicIsland" then
                        child:Destroy()
                    end
                end
            end
        end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "NatAovHub_DynamicIsland"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.Enabled = false
    gui.Parent = parentGui

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "AmbientShadow"
    shadow.Parent = gui
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0, dynamicOffsetY() + config.CollapsedHeight / 2 + 16)
    shadow.Size = UDim2.new(0, config.CollapsedWidth + 132, 0, config.CollapsedHeight + 66)
    shadow.BackgroundTransparency = 1
    shadow.BorderSizePixel = 0
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 1
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = 0
    shadow.Visible = config.Shadow

    local burst = Instance.new("Frame")
    burst.Name = "Burst"
    burst.Parent = gui
    burst.AnchorPoint = Vector2.new(0.5, 0.5)
    burst.Position = UDim2.new(0.5, 0, 0, dynamicOffsetY() + config.CollapsedHeight / 2)
    burst.Size = UDim2.new(0, 22, 0, 22)
    burst.BackgroundTransparency = 1
    burst.BorderSizePixel = 0
    burst.ZIndex = 0

    local burstCorner = Instance.new("UICorner")
    burstCorner.CornerRadius = UDim.new(1, 0)
    burstCorner.Parent = burst

    local burstStroke = Instance.new("UIStroke")
    burstStroke.Color = dynamicAccent()
    burstStroke.Thickness = 1.5
    burstStroke.Transparency = 1
    burstStroke.Parent = burst

    local burstScale = Instance.new("UIScale")
    burstScale.Scale = 1
    burstScale.Parent = burst

    local root = Instance.new("Frame")
    root.Name = "DynamicIsland"
    root.Parent = gui
    root.AnchorPoint = Vector2.new(0.5, 0)
    root.Position = UDim2.new(0.5, 0, 0, -(config.CollapsedHeight + 40))
    root.Size = UDim2.new(0, config.CollapsedWidth, 0, config.CollapsedHeight)
    root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Active = false
    root.ZIndex = 1

    local rootCorner = Instance.new("UICorner")
    rootCorner.CornerRadius = UDim.new(1, 0)
    rootCorner.Parent = root

    local rootStroke = Instance.new("UIStroke")
    rootStroke.Color = Color3.fromRGB(255, 255, 255)
    rootStroke.Thickness = 1
    rootStroke.Transparency = config.StrokeBase or 0.72
    rootStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rootStroke.Enabled = (config.Stroke == true)
    rootStroke.Parent = root

    local rootGradient = Instance.new("UIGradient")
    if config.Glass then
        rootGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(44, 44, 52)),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(20, 20, 25)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 13)),
        })
        rootGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.45, 0.04),
            NumberSequenceKeypoint.new(1, 0.1),
        })
    else
        rootGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
        rootGradient.Transparency = NumberSequence.new(0)
    end
    rootGradient.Rotation = 90
    rootGradient.Parent = root

    local topHighlight = Instance.new("Frame")
    topHighlight.Name = "TopHighlight"
    topHighlight.Parent = root
    topHighlight.AnchorPoint = Vector2.new(0.5, 0)
    topHighlight.Position = UDim2.new(0.5, 0, 0, 0.5)
    topHighlight.Size = UDim2.new(1, -18, 0, 1)
    topHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topHighlight.BackgroundTransparency = 0
    topHighlight.BorderSizePixel = 0
    topHighlight.ZIndex = 6
    topHighlight.Visible = config.Glass

    local topGradient = Instance.new("UIGradient")
    topGradient.Rotation = 0
    topGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.18, 0.8),
        NumberSequenceKeypoint.new(0.82, 0.8),
        NumberSequenceKeypoint.new(1, 1),
    })
    topGradient.Parent = topHighlight

    local glow = Instance.new("ImageLabel")
    glow.Name = "AccentGlow"
    glow.Parent = root
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.Size = UDim2.new(1, 40, 1, 40)
    glow.BackgroundTransparency = 1
    glow.BorderSizePixel = 0
    glow.Image = "rbxassetid://6014261993"
    glow.ImageColor3 = dynamicAccent()
    glow.ImageTransparency = 0.92
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(49, 49, 450, 450)
    glow.ZIndex = 1
    glow.Visible = config.Glow

    local gloss = Instance.new("Frame")
    gloss.Name = "Gloss"
    gloss.Parent = root
    gloss.Size = UDim2.new(1, 0, 0.62, 0)
    gloss.Position = UDim2.new(0, 0, 0, 0)
    gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gloss.BackgroundTransparency = 0
    gloss.BorderSizePixel = 0
    gloss.ZIndex = 2
    gloss.Visible = config.Gloss

    local glossCorner = Instance.new("UICorner")
    glossCorner.CornerRadius = UDim.new(1, 0)
    glossCorner.Parent = gloss

    local glossGradient = Instance.new("UIGradient")
    glossGradient.Rotation = 90
    glossGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.94),
        NumberSequenceKeypoint.new(0.55, 0.985),
        NumberSequenceKeypoint.new(1, 1),
    })
    glossGradient.Parent = gloss

    local scaler = Instance.new("UIScale")
    scaler.Scale = 1
    scaler.Parent = root

    local idleDot = Instance.new("Frame")
    idleDot.Name = "IdleDot"
    idleDot.Parent = root
    idleDot.AnchorPoint = Vector2.new(0.5, 0.5)
    idleDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    idleDot.Size = UDim2.new(0, 8, 0, 8)
    idleDot.BackgroundColor3 = dynamicAccent()
    idleDot.BackgroundTransparency = 1
    idleDot.BorderSizePixel = 0
    idleDot.ZIndex = 2

    local idleDotCorner = Instance.new("UICorner")
    idleDotCorner.CornerRadius = UDim.new(1, 0)
    idleDotCorner.Parent = idleDot

    local idleRing = Instance.new("UIStroke")
    idleRing.Name = "IdleRing"
    idleRing.Color = Color3.fromRGB(255, 255, 255)
    idleRing.Thickness = 1
    idleRing.Transparency = 0.55
    idleRing.Parent = idleDot

    local idleScale = Instance.new("UIScale")
    idleScale.Scale = 1
    idleScale.Parent = idleDot

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Parent = root
    content.AnchorPoint = Vector2.new(0.5, 0.5)
    content.Position = UDim2.new(0.5, 0, 0.5, 0)
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ZIndex = 2

    local contentScale = Instance.new("UIScale")
    contentScale.Scale = 1
    contentScale.Parent = content

    local iconHolder = Instance.new("Frame")
    iconHolder.Name = "IconHolder"
    iconHolder.Parent = content
    iconHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    iconHolder.Position = UDim2.new(0, config.PaddingLeft + iconSize / 2, 0.5, 0)
    iconHolder.Size = UDim2.new(0, iconSize, 0, iconSize)
    iconHolder.BackgroundTransparency = 1
    iconHolder.BorderSizePixel = 0
    iconHolder.ZIndex = 3
    iconHolder.ClipsDescendants = false

    local artworkCorner = Instance.new("UICorner")
    artworkCorner.CornerRadius = dynamicArtworkUDim(config.CollapsedHeight, iconSize)
    artworkCorner.Parent = iconHolder

    local iconScale = Instance.new("UIScale")
    iconScale.Scale = 1
    iconScale.Parent = iconHolder

    local iconBackdrop = Instance.new("Frame")
    iconBackdrop.Name = "IconBackdrop"
    iconBackdrop.Parent = iconHolder
    iconBackdrop.AnchorPoint = Vector2.new(0.5, 0.5)
    iconBackdrop.Position = UDim2.new(0.5, 0, 0.5, 0)
    iconBackdrop.Size = UDim2.new(0, iconSize + 12, 0, iconSize + 12)
    iconBackdrop.BackgroundColor3 = dynamicAccent()
    iconBackdrop.BackgroundTransparency = 0.86
    iconBackdrop.BorderSizePixel = 0
    iconBackdrop.ZIndex = 1
    iconBackdrop.Visible = config.IconBackdrop

    local backdropCorner = Instance.new("UICorner")
    backdropCorner.CornerRadius = UDim.new(1, 0)
    backdropCorner.Parent = iconBackdrop

    local backdropStroke = Instance.new("UIStroke")
    backdropStroke.Color = dynamicAccent()
    backdropStroke.Thickness = 1
    backdropStroke.Transparency = 0.7
    backdropStroke.Parent = iconBackdrop

    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "IconImage"
    iconImage.Parent = iconHolder
    iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
    iconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    iconImage.Size = UDim2.new(1, 0, 1, 0)
    iconImage.BackgroundTransparency = 1
    iconImage.BorderSizePixel = 0
    iconImage.Image = ""
    iconImage.ScaleType = Enum.ScaleType.Fit
    iconImage.ImageTransparency = 1
    iconImage.ZIndex = 2

    local iconImageCorner = Instance.new("UICorner")
    iconImageCorner.CornerRadius = dynamicArtworkUDim(config.CollapsedHeight, iconSize)
    iconImageCorner.Parent = iconImage

    local iconDot = Instance.new("Frame")
    iconDot.Name = "IconDot"
    iconDot.Parent = iconHolder
    iconDot.AnchorPoint = Vector2.new(0.5, 0.5)
    iconDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    iconDot.Size = UDim2.new(1, 0, 1, 0)
    iconDot.BackgroundColor3 = dynamicAccent()
    iconDot.BackgroundTransparency = 1
    iconDot.BorderSizePixel = 0
    iconDot.ZIndex = 2

    local iconDotCorner = Instance.new("UICorner")
    iconDotCorner.CornerRadius = dynamicArtworkUDim(config.CollapsedHeight, iconSize)
    iconDotCorner.Parent = iconDot

    local iconDotStroke = Instance.new("UIStroke")
    iconDotStroke.Color = dynamicAccent()
    iconDotStroke.Thickness = 2
    iconDotStroke.Transparency = 1
    iconDotStroke.Parent = iconDot

    local iconGlyph = Instance.new("TextLabel")
    iconGlyph.Name = "IconGlyph"
    iconGlyph.Parent = iconHolder
    iconGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    iconGlyph.Position = UDim2.new(0.5, 0, 0.5, 0)
    iconGlyph.Size = UDim2.new(1, 0, 1, 0)
    iconGlyph.BackgroundTransparency = 1
    iconGlyph.BorderSizePixel = 0
    iconGlyph.Font = Enum.Font.GothamBold
    iconGlyph.Text = ""
    iconGlyph.TextSize = math.floor(iconSize * 0.6)
    iconGlyph.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconGlyph.TextTransparency = 1
    iconGlyph.RichText = false
    iconGlyph.AutoLocalize = false
    iconGlyph.ZIndex = 3

    local pingFrame = Instance.new("Frame")
    pingFrame.Name = "Ping"
    pingFrame.Parent = iconHolder
    pingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    pingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    pingFrame.Size = UDim2.new(1, 0, 1, 0)
    pingFrame.BackgroundTransparency = 1
    pingFrame.BorderSizePixel = 0

    local pingCorner = Instance.new("UICorner")
    pingCorner.CornerRadius = UDim.new(1, 0)
    pingCorner.Parent = pingFrame

    local pingStroke = Instance.new("UIStroke")
    pingStroke.Color = dynamicAccent()
    pingStroke.Thickness = 1.6
    pingStroke.Transparency = 1
    pingStroke.Parent = pingFrame

    local pingScale = Instance.new("UIScale")
    pingScale.Scale = 0.85
    pingScale.Parent = pingFrame

    local spinner = Instance.new("Frame")
    spinner.Name = "Spinner"
    spinner.Parent = iconHolder
    spinner.AnchorPoint = Vector2.new(0.5, 0.5)
    spinner.Position = UDim2.new(0.5, 0, 0.5, 0)
    spinner.Size = UDim2.new(1, 0, 1, 0)
    spinner.BackgroundTransparency = 1
    spinner.BorderSizePixel = 0
    spinner.Visible = false

    local spinnerDots = {}
    local radius = math.max(3, iconSize / 2 - 2)
    local dotSize = 2.4
    for index = 1, 8 do
        local angle = (index - 1) * math.pi / 4
        local dot = Instance.new("Frame")
        dot.Name = "Dot" .. index
        dot.Parent = spinner
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.new(
            0.5,
            math.cos(angle) * radius,
            0.5,
            math.sin(angle) * radius
        )
        dot.Size = UDim2.new(0, dotSize, 0, dotSize)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BackgroundTransparency = 0.15 + (index - 1) * 0.1
        dot.BorderSizePixel = 0

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        spinnerDots[index] = dot
    end

    local iconCanvas = Instance.new("Frame")
    iconCanvas.Name = "IconVectors"
    iconCanvas.Parent = iconHolder
    iconCanvas.AnchorPoint = Vector2.new(0.5, 0.5)
    iconCanvas.Position = UDim2.new(0.5, 0, 0.5, 0)
    iconCanvas.Size = UDim2.new(1, 0, 1, 0)
    iconCanvas.BackgroundTransparency = 1
    iconCanvas.BorderSizePixel = 0
    iconCanvas.ZIndex = 3

    local iconVectors = {}
    for kindName, spec in pairs(DYNAMIC_VECTOR_ICONS) do
        local group = Instance.new("Frame")
        group.Name = "Icon_" .. tostring(kindName)
        group.Parent = iconCanvas
        group.AnchorPoint = Vector2.new(0.5, 0.5)
        group.Position = UDim2.new(0.5, 0, 0.5, 0)
        group.Size = UDim2.new(1, 0, 1, 0)
        group.BackgroundTransparency = 1
        group.BorderSizePixel = 0
        group.Visible = false
        group.ZIndex = 3

        local groupScale = Instance.new("UIScale")
        groupScale.Scale = 1
        groupScale.Parent = group

        local parts = {}
        for index, part in ipairs(spec.Parts) do
            local shape = Instance.new("Frame")
            shape.Name = "P" .. tostring(index)
            shape.Parent = group
            shape.AnchorPoint = Vector2.new(0.5, 0.5)
            shape.Position = UDim2.new(part[1], 0, part[2], 0)
            shape.Size = UDim2.new(part[3], 0, part[4], 0)
            shape.Rotation = part[5] or 0
            shape.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            shape.BackgroundTransparency = 0.04
            shape.BorderSizePixel = 0
            shape.ZIndex = 3

            local shapeCorner = Instance.new("UICorner")
            shapeCorner.CornerRadius = UDim.new(0.5, 0)
            shapeCorner.Parent = shape

            parts[index] = shape
        end

        iconVectors[kindName] = {
            Group = group,
            Scale = groupScale,
            Parts = parts,
            Anim = spec.Anim or {},
        }
    end

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "IslandText"
    textLabel.Parent = content
    textLabel.BackgroundTransparency = 1
    textLabel.BorderSizePixel = 0
    textLabel.AnchorPoint = Vector2.new(0, 0.5)
    textLabel.Position = UDim2.new(0, dynamicTextLeft(), 0.5, 0)
    textLabel.Size = UDim2.new(1, -(dynamicTextLeft() + config.PaddingRight), 1, 0)
    textLabel.Font = config.Font or Enum.Font.GothamBold
    textLabel.Text = ""
    textLabel.TextSize = config.TextSize
    textLabel.TextColor3 = config.TextColor or dynamicTextColor()
    textLabel.TextTransparency = 1
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextWrapped = false
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd
    textLabel.RichText = false
    textLabel.AutoLocalize = false
    textLabel.Active = false
    textLabel.ZIndex = 3

    local textScale = Instance.new("UIScale")
    textScale.Scale = 1
    textScale.Parent = textLabel

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "IslandSubtitle"
    subtitle.Parent = content
    subtitle.BackgroundTransparency = 1
    subtitle.BorderSizePixel = 0
    subtitle.AnchorPoint = Vector2.new(0, 0.5)
    subtitle.Position = UDim2.new(0, dynamicTextLeft(), 0.5, 11)
    subtitle.Size = UDim2.new(1, -(dynamicTextLeft() + config.PaddingRight), 0, 16)
    subtitle.Font = config.Font or Enum.Font.GothamBold
    subtitle.Text = ""
    subtitle.TextSize = tonumber(config.SubtitleSize) or 13
    subtitle.TextColor3 = dynamicIsColor(config.SubtitleColor) and config.SubtitleColor
        or Color3.fromRGB(152, 152, 157)
    subtitle.TextTransparency = 1
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextYAlignment = Enum.TextYAlignment.Center
    subtitle.TextWrapped = false
    subtitle.TextTruncate = Enum.TextTruncate.AtEnd
    subtitle.RichText = false
    subtitle.AutoLocalize = false
    subtitle.Active = false
    subtitle.ZIndex = 3
    subtitle.Visible = false

    local textShine = Instance.new("UIGradient")
    textShine.Name = "Shine"
    textShine.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    textShine.Rotation = 15
    textShine.Offset = Vector2.new(-1, 0)
    textShine.Transparency = DYNAMIC_CLEAR_SEQ
    textShine.Parent = textLabel

    local textGhost = Instance.new("TextLabel")
    textGhost.Name = "IslandTextGhost"
    textGhost.Parent = content
    textGhost.BackgroundTransparency = 1
    textGhost.BorderSizePixel = 0
    textGhost.AnchorPoint = Vector2.new(0, 0.5)
    textGhost.Position = UDim2.new(0, dynamicTextLeft(), 0.5, 0)
    textGhost.Size = UDim2.new(1, -(dynamicTextLeft() + config.PaddingRight), 1, 0)
    textGhost.Font = config.Font or Enum.Font.GothamBold
    textGhost.Text = ""
    textGhost.TextSize = config.TextSize
    textGhost.TextColor3 = textLabel.TextColor3
    textGhost.TextTransparency = 1
    textGhost.TextXAlignment = Enum.TextXAlignment.Left
    textGhost.TextYAlignment = Enum.TextYAlignment.Center
    textGhost.TextWrapped = false
    textGhost.TextTruncate = Enum.TextTruncate.AtEnd
    textGhost.RichText = false
    textGhost.AutoLocalize = false
    textGhost.Active = false
    textGhost.ZIndex = 2

    local progressTrack = Instance.new("Frame")
    progressTrack.Name = "ProgressTrack"
    progressTrack.Parent = root
    progressTrack.AnchorPoint = Vector2.new(0.5, 1)
    local barThickness = math.clamp(tonumber(config.ProgressThickness) or 3, 2, 6)
    progressTrack.Position = UDim2.new(0.5, 0, 1, -(barThickness + 2))
    progressTrack.Size = UDim2.new(1, -22, 0, barThickness)
    progressTrack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressTrack.BackgroundTransparency = 1
    progressTrack.BorderSizePixel = 0
    progressTrack.ClipsDescendants = true
    progressTrack.ZIndex = 4

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = progressTrack

    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Parent = progressTrack
    progressFill.AnchorPoint = Vector2.new(0, 0.5)
    progressFill.Position = UDim2.new(0, 0, 0.5, 0)
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = dynamicAccent()
    progressFill.BackgroundTransparency = 0
    progressFill.BorderSizePixel = 0

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = progressFill

    local progressHead = Instance.new("Frame")
    progressHead.Name = "ProgressHead"
    progressHead.Parent = progressFill
    progressHead.AnchorPoint = Vector2.new(1, 0.5)
    progressHead.Position = UDim2.new(1, 0, 0.5, 0)
    progressHead.Size = UDim2.new(0, 4, 0, 4)
    progressHead.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressHead.BackgroundTransparency = 0.05
    progressHead.BorderSizePixel = 0

    local headCorner = Instance.new("UICorner")
    headCorner.CornerRadius = UDim.new(1, 0)
    headCorner.Parent = progressHead

    local headStroke = Instance.new("UIStroke")
    headStroke.Color = Color3.fromRGB(255, 255, 255)
    headStroke.Thickness = 1
    headStroke.Transparency = 0.55
    headStroke.Parent = progressHead

    local fillGradient = Instance.new("UIGradient")
    fillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 205, 220)),
    })
    fillGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(1, 0.35),
    })
    fillGradient.Parent = progressFill

    progressFill.ClipsDescendants = true
    local progressShine = Instance.new("Frame")
    progressShine.Name = "ProgressShine"
    progressShine.Parent = progressFill
    progressShine.AnchorPoint = Vector2.new(0.5, 0.5)
    progressShine.Position = UDim2.new(-0.3, 0, 0.5, 0)
    progressShine.Size = UDim2.new(0, 16, 1, 2)
    progressShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressShine.BackgroundTransparency = 0.55
    progressShine.BorderSizePixel = 0
    progressShine.ZIndex = 6
    progressShine.Rotation = 18

    local shineCorner = Instance.new("UICorner")
    shineCorner.CornerRadius = UDim.new(0.5, 0)
    shineCorner.Parent = progressShine

    local progressGlow = Instance.new("ImageLabel")
    progressGlow.Name = "ProgressGlow"
    progressGlow.Parent = root
    progressGlow.AnchorPoint = Vector2.new(0.5, 1)
    progressGlow.Position = UDim2.new(0.5, 0, 1, 1)
    progressGlow.Size = UDim2.new(1, -10, 0, 14)
    progressGlow.BackgroundTransparency = 1
    progressGlow.BorderSizePixel = 0
    progressGlow.Image = "rbxassetid://6014261993"
    progressGlow.SliceScale = 0.22
    progressGlow.ImageColor3 = dynamicAccent()
    progressGlow.ImageTransparency = 0.75
    progressGlow.ScaleType = Enum.ScaleType.Slice
    progressGlow.SliceCenter = Rect.new(49, 49, 450, 450)
    progressGlow.ZIndex = 3
    progressGlow.Visible = config.ProgressGlow

    progressTrack.Visible = config.ProgressBar
    progressGlow.Visible = config.ProgressBar and config.ProgressGlow

    local wave = Instance.new("Frame")
    wave.Name = "Waveform"
    wave.Parent = root
    wave.AnchorPoint = Vector2.new(1, 0.5)
    wave.Position = UDim2.new(1, -config.PaddingRight, 0.5, 0)
    wave.Size = UDim2.new(0, 20, 0, 16)
    wave.BackgroundTransparency = 1
    wave.BorderSizePixel = 0
    wave.Visible = false
    wave.ZIndex = 4

    local waveBars = {}
    for index = 1, 4 do
        local bar = Instance.new("Frame")
        bar.Name = "Bar" .. index
        bar.Parent = wave
        bar.AnchorPoint = Vector2.new(0.5, 1)
        bar.Position = UDim2.new(0, (index - 1) * 5 + 2.5, 1, 0)
        bar.Size = UDim2.new(0, 2, 0, 6)
        bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        bar.BackgroundTransparency = 0.08
        bar.BorderSizePixel = 0
        bar.ZIndex = 4

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = bar

        waveBars[index] = bar
    end

    local controlsRow = Instance.new("Frame")
    controlsRow.Name = "ControlsRow"
    controlsRow.Parent = root
    controlsRow.AnchorPoint = Vector2.new(0.5, 0.5)
    controlsRow.Position = UDim2.new(0.5, 0, 0.5, 30)
    controlsRow.Size = UDim2.new(1, -24, 0, 30)
    controlsRow.BackgroundTransparency = 1
    controlsRow.BorderSizePixel = 0
    controlsRow.Visible = false
    controlsRow.ZIndex = 9

    local controlLayout = Instance.new("UIListLayout")
    controlLayout.FillDirection = Enum.FillDirection.Horizontal
    controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    controlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    controlLayout.Padding = UDim.new(0, 18)
    controlLayout.SortOrder = Enum.SortOrder.LayoutOrder
    controlLayout.Parent = controlsRow

    local controlButtons = {}
    for index = 1, 3 do
        local button = Instance.new("TextButton")
        button.Name = "Control" .. index
        button.Parent = controlsRow
        button.AnchorPoint = Vector2.new(0.5, 0.5)
        button.Size = UDim2.new(0, 30, 0, 30)
        button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundTransparency = 0.88
        button.BorderSizePixel = 0
        button.AutoButtonColor = true
        button.Text = ""
        button.TextSize = 14
        button.Font = Enum.Font.GothamBold
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.LayoutOrder = index
        button.Visible = false
        button.ZIndex = 9

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = button

        local slot = index
        button.MouseButton1Click:Connect(function()
            local callback = DynamicIsland.ControlCallbacks and DynamicIsland.ControlCallbacks[slot]
            if type(callback) == "function" then
                local ok, err = pcall(callback)
                if not ok then
                    warn("[DynamicIsland] callback nút " .. slot .. " lỗi: " .. tostring(err))
                end
            end
        end)

        controlButtons[index] = button
    end

    local overlay = Instance.new("TextButton")
    overlay.Name = "TapArea"
    overlay.Parent = root
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Text = ""
    overlay.AutoButtonColor = false
    overlay.Modal = false
    overlay.ZIndex = 8

    island.Gui = gui
    island.Root = root
    island.Corner = rootCorner
    island.Scaler = scaler
    island.Stroke = rootStroke
    island.StrokeBase = config.StrokeBase or 0.72
    island.Glow = glow
    island.Gloss = gloss
    island.TextScale = textScale
    island.Shadow = shadow
    island.Burst = burst
    island.BurstStroke = burstStroke
    island.BurstScale = burstScale
    island.TextShine = textShine
    island.TextGhost = textGhost
    island.ProgressHead = progressHead
    island.ProgressShine = progressShine
    island.Content = content
    island.ContentScale = contentScale
    island.IconHolder = iconHolder
    island.ArtworkCorner = artworkCorner
    island.IconScale = iconScale
    island.PingFrame = pingFrame
    island.PingScale = pingScale
    island.PingStroke = pingStroke
    island.IconImage = iconImage
    island.IconDot = iconDot
    island.IconDotStroke = iconDotStroke
    island.IconGlyph = iconGlyph
    island.IconVectors = iconVectors
    island.IconCanvas = iconCanvas
    island.IconDotCorner = iconDotCorner
    island.IconImageCorner = iconImageCorner
    island.Spinner = spinner
    island.SpinnerDots = spinnerDots
    island.IdleDot = idleDot
    island.IdleScale = idleScale
    island.IdleRing = idleRing
    island.Text = textLabel
    island.Subtitle = subtitle
    island.Wave = wave
    island.WaveBars = waveBars
    island.ControlsRow = controlsRow
    island.ControlButtons = controlButtons
    island.ProgressTrack = progressTrack
    island.ProgressFill = progressFill
    island.ProgressGlow = progressGlow
    island.IconBackdrop = iconBackdrop
    island.IconBackdropStroke = backdropStroke
    island.TopHighlight = topHighlight
    island.Overlay = overlay
    island.NeedsIntro = true

    if island.Corner then
        island.Corner.CornerRadius = dynamicCornerUDim(config.CollapsedHeight)
    end
    local initialShape = dynamicArtworkUDim(config.CollapsedHeight, iconSize)
    if island.ArtworkCorner then
        island.ArtworkCorner.CornerRadius = initialShape
    end
    if island.IconDotCorner then
        island.IconDotCorner.CornerRadius = initialShape
    end
    if island.IconImageCorner then
        island.IconImageCorner.CornerRadius = initialShape
    end

    if config.Hover then
        overlay.MouseEnter:Connect(function()
            if not island.Enabled then
                return
            end
            island.Hovering = true
            dynamicCancelSiblings("strokeBreathe", "strokeFlash")
            if not island.ScaleBusy then
                dynamicTween("hoverScale", island.Scaler, { Scale = 1.015 }, DYNAMIC_EASE.Micro[1], StyleSine, DirOut)
            end
            dynamicTween(
                "hoverStroke",
                island.Stroke,
                { Transparency = (island.StrokeBase or 0.72) - 0.17 },
                DYNAMIC_EASE.Micro[1],
                StyleSine,
                DirOut
            )
        end)
        overlay.MouseLeave:Connect(function()
            if not island.Enabled then
                return
            end
            island.Hovering = false
            dynamicTween("hoverScale", island.Scaler, { Scale = 1 }, DYNAMIC_EASE.Micro[1], StyleSine, DirOut)
            dynamicTween(
                "hoverStroke",
                island.Stroke,
                { Transparency = island.StrokeBase or 0.72 },
                DYNAMIC_EASE.Micro[1],
                StyleSine,
                DirOut
            )
        end)
    end

    if config.Draggable then
        local function dragOffset(dy)
            if dy > 46 then
                return 46 + (dy - 46) * 0.45
            elseif dy < -46 then
                return -46 + (dy + 46) * 0.45
            end
            return dy
        end

        overlay.InputBegan:Connect(function(input)
            local inputType = input and input.UserInputType
            if inputType ~= Enum.UserInputType.Touch and inputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
            island.SuppressClick = false
            if not island.Enabled or island.Current == nil or DisableAnimation or not island.Root then
                return
            end
            island.DragInput = input
            island.DragStartY = input.Position and input.Position.Y or 0
            island.DragOrigin = dynamicOffsetY()
            island.DragMoved = false
            dynamicCancelSiblings("rootPos", "rootNudge", "introPos")
        end)

        local function dragMove(input)
            if not island.Enabled or island.Root == nil then
                return
            end
            if island.DragInput == nil or island.DragInput ~= input then
                return
            end
            local currentY = input.Position and input.Position.Y or 0
            local dy = currentY - (island.DragStartY or currentY)
            if math.abs(dy) > 4 then
                island.DragMoved = true
            end
            island.Root.Position = UDim2.new(0.5, 0, 0, (island.DragOrigin or dynamicOffsetY()) + dragOffset(dy))
        end

        local function dragEnd(input)
            if island.DragInput == nil or island.DragInput ~= input then
                return
            end
            island.DragInput = nil

            local root = island.Root
            local threshold = math.max(12, tonumber(config.DragThreshold) or 28)
            local currentY = input.Position and input.Position.Y or 0
            local dy = currentY - (island.DragStartY or currentY)
            local moved = island.DragMoved
            island.DragMoved = false

            if root == nil or not island.Enabled then
                return
            end

            if moved and dy >= threshold then
                island.SuppressClick = true
                Library:DynamicCollapse()
            elseif moved and dy <= -threshold then
                island.SuppressClick = true
                Library:DynamicOff()
            else
                if moved then
                    island.SuppressClick = true
                end
                dynamicCancelSiblings("rootNudge", "introPos", "rootPos")
                dynamicTween("rootPos", root, {
                    Position = UDim2.new(0.5, 0, 0, dynamicOffsetY()),
                }, 0.32, StyleBack, DirOut)
            end
        end

        overlay.InputChanged:Connect(dragMove)
        overlay.InputEnded:Connect(dragEnd)
        island.UISConns[#island.UISConns + 1] = uis.InputChanged:Connect(dragMove)
        island.UISConns[#island.UISConns + 1] = uis.InputEnded:Connect(dragEnd)
    end

    overlay.MouseButton1Click:Connect(function()
        local current = island.Current
        if not island.Enabled or current == nil then
            return
        end
        if island.SuppressClick then
            island.SuppressClick = false
            return
        end

        if island.Config.TapDip and not DisableAnimation and not island.ScaleBusy then
            dynamicTween("tapDip", island.Scaler, { Scale = 0.965 }, 0.06, StyleQuad, DirOut)
            task.delay(0.06, function()
                if island.Enabled then
                    local target = island.Hovering and 1.015 or 1
                    dynamicTween("tapDip", island.Scaler, { Scale = target }, 0.16, StyleBack, DirOut)
                end
            end)
        end

        local handled = false
        if type(current.OnTap) == "function" then
            local ok, result = pcall(current.OnTap)
            handled = ok and result == false
        end
        if handled or current.Dismissible == false or island.Config.TapToDismiss == false then
            return
        end
        Library:DynamicCollapse()
    end)

    dynamicBindViewport()

    if island.CameraConnection then
        pcall(function()
            island.CameraConnection:Disconnect()
        end)
    end
    local ok, cameraConnection = pcall(function()
        return workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            dynamicBindViewport()
            dynamicApplyLayout()
        end)
    end)
    if ok then
        island.CameraConnection = cameraConnection
    end

    return gui
end

local function dynamicShimmerTick(token)
    local island = DynamicIsland
    if
        not island.Enabled
        or island.Token ~= token
        or island.Current == nil
        or not island.ProgressShine
        or not island.Config.ProgressShimmer
        or not island.Config.ProgressBar
        or DisableAnimation
    then
        return
    end

    island.ProgressShine.Position = UDim2.new(-0.3, 0, 0.5, 0)
    local tweenObject = dynamicTween(
        "shimmer",
        island.ProgressShine,
        { Position = UDim2.new(1.3, 0, 0.5, 0) },
        1.15,
        StyleLinear,
        DirOut
    )

    if tweenObject then
        tweenObject.Completed:Connect(function(playbackState)
            if playbackState ~= Enum.PlaybackState.Completed then
                return
            end
            dynamicShimmerTick(token)
        end)
    else
        task.delay(1.15, function()
            dynamicShimmerTick(token)
        end)
    end
end

local DYNAMIC_WAVE_PATTERN = { 0.35, 0.95, 0.6, 1, 0.45, 0.8, 0.3, 0.7 }

local function dynamicWaveTick(token, index, step)
    local island = DynamicIsland
    local bar = island.WaveBars and island.WaveBars[index]
    if
        not bar
        or not island.Enabled
        or island.WaveToken ~= token
        or not dynamicWaveActive()
        or DisableAnimation
    then
        return
    end

    local pattern = DYNAMIC_WAVE_PATTERN[((step + index * 2) % #DYNAMIC_WAVE_PATTERN) + 1]
    local height = math.floor(4 + 12 * pattern)
    local tweenObject = dynamicTween(
        "wave" .. index,
        bar,
        { Size = UDim2.new(0, 2, 0, height) },
        0.24 + (index % 3) * 0.06,
        StyleSine,
        DirInOut
    )

    if tweenObject then
        tweenObject.Completed:Connect(function(playbackState)
            if playbackState ~= Enum.PlaybackState.Completed then
                return
            end
            dynamicWaveTick(token, index, step + 1)
        end)
    end
end

local function dynamicStartWave(token)
    local island = DynamicIsland
    if not island.Wave then
        return
    end
    island.WaveToken = (island.WaveToken or 0) + 1
    local waveToken = island.WaveToken
    island.Wave.Visible = true
    for index = 1, 4 do
        dynamicWaveTick(waveToken, index, index * 3)
    end
end

local function dynamicStopWave()
    local island = DynamicIsland
    island.WaveToken = (island.WaveToken or 0) + 1
    if island.WaveBars then
        for index = 1, 4 do
            dynamicCancel("wave" .. index)
            local bar = island.WaveBars[index]
            if bar then
                bar.Size = UDim2.new(0, 2, 0, 6)
            end
        end
    end
    if island.Wave then
        island.Wave.Visible = false
    end
end

local function dynamicStopShimmer()
    local island = DynamicIsland
    dynamicCancel("shimmer")
    if island.ProgressShine then
        island.ProgressShine.Position = UDim2.new(-0.3, 0, 0.5, 0)
    end
end

local function dynamicHideProgress()
    local island = DynamicIsland
    dynamicCancel("progress")
    dynamicCancel("progressFade")
    dynamicStopShimmer()
    if island.ProgressTrack then
        island.ProgressTrack.BackgroundTransparency = 1
    end
    if island.ProgressFill then
        dynamicTween("progressFade", island.ProgressFill, { BackgroundTransparency = 1 }, 0.12, StyleQuad, DirIn)
    end
    if island.ProgressGlow then
        dynamicTween("glowFade", island.ProgressGlow, { ImageTransparency = 1 }, 0.14, StyleQuad, DirIn)
    end
end

local function dynamicPlayProgress(token, duration, accent)
    local island = DynamicIsland
    local track = island.ProgressTrack
    local fill = island.ProgressFill
    if not track or not fill or not island.Config.ProgressBar then
        if duration and duration > 0 then
            task.delay(duration, function()
                if island.Enabled and island.Token == token then
                    Library:DynamicCollapse()
                end
            end)
        end
        return
    end

    dynamicCancel("progress")
    dynamicCancel("progressFade")

    fill.BackgroundColor3 = accent or dynamicAccent()

    if not duration or duration <= 0 then
        track.BackgroundTransparency = 1
        fill.BackgroundTransparency = 1
        if island.ProgressGlow then
            island.ProgressGlow.ImageTransparency = 1
        end
        return
    end

    track.BackgroundTransparency = 0.82
    fill.BackgroundTransparency = 1
    fill.Size = UDim2.new(1, 0, 1, 0)

    dynamicTween("progressFade", fill, { BackgroundTransparency = 0 }, 0.14, StyleQuad, DirOut)
    if island.ProgressGlow then
        island.ProgressGlow.ImageTransparency = 1
        dynamicTween("glowFade", island.ProgressGlow, { ImageTransparency = 1 - 0.25 }, 0.2, StyleQuad, DirOut)
    end

    dynamicStopShimmer()
    task.delay(0.16, function()
        dynamicShimmerTick(token)
    end)

    local barTween = dynamicTween("progress", fill, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear, DirOut)
    if barTween then
        barTween.Completed:Connect(function(playbackState)
            if playbackState ~= Enum.PlaybackState.Completed then
                return
            end
            if not island.Enabled or island.Token ~= token then
                return
            end
            Library:DynamicCollapse()
        end)
    else
        task.delay(duration, function()
            if island.Enabled and island.Token == token then
                Library:DynamicCollapse()
            end
        end)
    end
end

local dynamicRefineWidth

local function dynamicTypeText(token, typeEnabled, duration)
    local island = DynamicIsland
    local label = island.Text
    if not label then
        return
    end

    island.TypingToken = (island.TypingToken or 0) + 1
    local typingToken = island.TypingToken

    local function showFull()
        pcall(function()
            label.MaxVisibleGraphemes = -1
        end)
    end

    local config = island.Config
    local speed = tonumber(config.TypeSpeed) or 0
    local text = tostring(island.Current and island.Current.Text or label.Text)
    local length = #text
    if utf8 and utf8.len then
        length = utf8.len(text) or length
    end

    if not typeEnabled or DisableAnimation or speed <= 0 or length <= 0 then
        showFull()
        return
    end

    local total = length / speed
    local maxTime = tonumber(config.TypeTime) or 0.9
    if duration and duration > 0 then
        maxTime = math.min(maxTime, duration * 0.6)
    end
    total = math.min(total, math.max(maxTime, DYNAMIC_FRAME))

    local ticks = math.clamp(math.floor(total / DYNAMIC_FRAME), 1, 200)
    local perTick = total / ticks

    label.MaxVisibleGraphemes = 0

    task.spawn(function()
        for index = 1, ticks do
            if
                not island.Enabled
                or island.Token ~= token
                or island.TypingToken ~= typingToken
                or island.Current == nil
            then
                return
            end

            local visible = math.ceil(length * index / ticks)
            label.MaxVisibleGraphemes = math.min(visible, length)
            task.wait(perTick)
        end

        if island.Enabled and island.Token == token and island.TypingToken == typingToken and island.Current ~= nil then
            showFull()
            if dynamicRefineWidth then
                dynamicRefineWidth(token)
            end
        end
    end)
end

local function dynamicContentIn(token)
    local island = DynamicIsland
    local config = island.Config
    local left = dynamicTextLeft()
    local stagger = math.clamp(tonumber(config.StaggerTime) or 0.06, 0, 0.3)
    local typing = island.Current and island.Current.Type

    local primaryY = dynamicPrimaryY()

    island.ContentScale.Scale = 0.9
    island.IconScale.Scale = 0.62
    island.Text.Position = UDim2.new(0, left, 0.5, primaryY + 9)
    if island.Subtitle and island.Subtitle.Visible then
        island.Subtitle.TextTransparency = 1
        island.Subtitle.Position = UDim2.new(0, left, 0.5, dynamicSubtitleY() + 5)
    end

    if island.TextScale then
        island.TextScale.Scale = 1
    end
    if island.TextShine and island.Config.TextShine then
        dynamicCancel("shine")
        dynamicCancel("textWipe")
        island.TextShine.Transparency = DYNAMIC_CLEAR_SEQ
        island.TextShine.Offset = Vector2.new(-1, 0)
    end

    dynamicCancelSiblings("iconOut", "iconPulse")
    dynamicSpring("iconPop", island.IconScale, { Scale = 1.14 }, { Scale = 1 }, 0.38, StyleBack)
    dynamicShowIcon(0.12)
    dynamicPlayVectorIn()

    task.delay(stagger, function()
        if not island.Enabled or island.Token ~= token or island.Current == nil then
            return
        end

        local wiped = false
        if config.TextWipe and not typing and not DisableAnimation then
            island.Text.TextTransparency = 0
            wiped = dynamicTextWipe(token)
        end

        if not wiped then
            island.Text.TextTransparency = 1
            dynamicTween("textFade", island.Text, { TextTransparency = 0 }, 0.2, StyleQuad, DirOut)
            dynamicTextShine(token)
        end

        dynamicTween("textSlide", island.Text, {
            Position = UDim2.new(0, left, 0.5, primaryY),
        }, 0.36, StyleQuart, DirOut)

        if island.Subtitle and island.Subtitle.Visible then
            task.delay(0.05, function()
                if not island.Enabled or island.Token ~= token or island.Current == nil then
                    return
                end
                dynamicTween("subFade", island.Subtitle, { TextTransparency = 0 }, 0.22, StyleQuad, DirOut)
                dynamicTween("subSlide", island.Subtitle, {
                    Position = UDim2.new(0, left, 0.5, dynamicSubtitleY()),
                }, 0.3, StyleQuart, DirOut)
            end)
        end

        if island.TextScale and (tonumber(config.TextPop) or 0) > 1 then
            island.TextScale.Scale = config.TextPop
            dynamicTween(
                "textPop",
                island.TextScale,
                { Scale = 1 },
                DYNAMIC_EASE.Pop[1],
                DYNAMIC_EASE.Pop[2],
                DYNAMIC_EASE.Pop[3]
            )
        end
    end)

    dynamicSpring("contentScale", island.ContentScale, { Scale = 1.025 }, { Scale = 1 }, 0.44, StyleBack)

    dynamicBurst(token, island.Current and island.Current.AccentResolved)
end

local function dynamicContentOut(duration, onDone)
    local island = DynamicIsland
    duration = duration or 0.14
    local left = dynamicTextLeft()

    dynamicTween("contentScale", island.ContentScale, { Scale = 0.86 }, duration * 1.15, StyleQuart, DirIn)
    dynamicTween("textFade", island.Text, { TextTransparency = 1 }, duration, StyleQuad, DirIn)
    dynamicTween("textSlide", island.Text, {
        Position = UDim2.new(0, left - 8, 0.5, dynamicPrimaryY() - 3),
    }, duration, StyleQuart, DirIn)
    if island.Subtitle then
        dynamicTween("subFade", island.Subtitle, { TextTransparency = 1 }, duration, StyleQuad, DirIn)
    end
    if island.IconScale then
        dynamicCancelSiblings("iconPop", "iconOut")
        dynamicTween("iconOut", island.IconScale, { Scale = 0.55 }, duration, StyleQuart, DirIn)
    end
    dynamicGhostOut(duration)
    dynamicHideIcon(duration)

    if onDone then
        task.delay(duration, onDone)
    end
end

local function dynamicExpand(token, targetWidth, targetHeight)
    local island = DynamicIsland
    local config = island.Config
    local maxWidth = dynamicMaxWidth()
    local height = targetHeight or config.ExpandedHeight

    local peakWidth = math.min(targetWidth + 8, maxWidth)

    dynamicCancelSiblings("introPos", "rootNudge")

    if DisableAnimation then
        dynamicPillSize(targetWidth, height, 0, StyleQuart, DirOut)
        return
    end

    dynamicPillSize(peakWidth, height + 2, 0.2, StyleQuart, DirOut)

    task.delay(0.2, function()
        if not island.Enabled or island.Token ~= token or island.Root == nil then
            return
        end
        dynamicPillSize(
            targetWidth,
            height,
            DYNAMIC_EASE.Resize[1],
            DYNAMIC_EASE.Resize[2],
            DYNAMIC_EASE.Resize[3]
        )
    end)
end

dynamicRefineWidth = function(token)
    local island = DynamicIsland
    task.delay(0.03, function()
        if not island.Enabled or island.Token ~= token or island.Current == nil or not island.Text then
            return
        end
        if (tonumber(island.Text.MaxVisibleGraphemes) or -1) >= 0 then
            return
        end

        local ok, bounds = pcall(function()
            return island.Text.TextBounds
        end)
        if not ok or not bounds or not tonumber(bounds.X) or bounds.X <= 0 then
            return
        end

        local config = island.Config
        local fixedWidth = config.PaddingLeft + dynamicIconSize() + config.Gap + dynamicRightPad()
        local targetWidth = bounds.X
        if island.Subtitle and island.Subtitle.Visible then
            local okSub, subBounds = pcall(function()
                return island.Subtitle.TextBounds
            end)
            if okSub and subBounds and tonumber(subBounds.X) then
                targetWidth = math.max(targetWidth, subBounds.X)
            end
        end
        local target = math.clamp(math.ceil(targetWidth) + fixedWidth + 1, config.CollapsedWidth, dynamicMaxWidth())
        local currentWidth = island.Root.Size.X.Offset

        if math.abs(target - currentWidth) > 1 then
            dynamicPillSize(target, dynamicCardHeight(), 0.22, StyleQuart, DirOut)
        end
    end)
end

local function dynamicShowNotification(notification, token)
    local island = DynamicIsland
    local config = island.Config
    local isReplacing = island.Current ~= nil

    island.Current = notification
    notification.Token = token
    island.SuppressClick = false

    island.PulseToken = island.PulseToken + 1
    dynamicCancelSiblings("iconPulse", "pingScale", "pingFade", "strokeBreathe", "glowPulse")

    if island.NeedsIntro then
        island.NeedsIntro = false
        isReplacing = false
        dynamicCancel("rootNudge")
        dynamicCancel("rootPos")
        dynamicCancel("rootScale")
        island.Root.Position = UDim2.new(0.5, 0, 0, -(island.Config.CollapsedHeight + 40))
        island.Root.BackgroundTransparency = 1
        island.Scaler.Scale = 0.93
        dynamicTween("introPos", island.Root, {
            Position = UDim2.new(0.5, 0, 0, dynamicOffsetY()),
        }, DYNAMIC_EASE.Enter[1], DYNAMIC_EASE.Enter[2], DYNAMIC_EASE.Enter[3])
        dynamicTween("rootBg", island.Root, { BackgroundTransparency = island.Config.Glass and 0.04 or 0 }, 0.3, StyleQuad, DirOut)
        dynamicCancelSiblings("rootScale", "hoverScale", "tapDip")
        dynamicTween("introScale", island.Scaler, { Scale = 1 }, DYNAMIC_EASE.Spring[1], DYNAMIC_EASE.Spring[2], DYNAMIC_EASE.Spring[3])
    end

    local accent = notification.Accent or dynamicKindColor(notification.Kind)
    island.Current.AccentResolved = accent

    if island.ProgressFill then
        island.ProgressFill.BackgroundColor3 = accent
    end
    if island.PingStroke then
        island.PingStroke.Color = accent
    end
    if island.IconBackdrop then
        island.IconBackdrop.BackgroundColor3 = accent
    end
    if island.IconBackdropStroke then
        island.IconBackdropStroke.Color = accent
    end
    if island.ProgressGlow then
        island.ProgressGlow.ImageColor3 = accent
    end
    if island.Gloss then
        island.Gloss.Visible = config.Gloss
    end
    if island.Glow then
        island.Glow.Visible = config.Glow
    end

    local function applyIcon()
        local resolved = dynamicApplyIcon(notification)
        island.Current.AccentResolved = resolved
        if island.ProgressFill then
            island.ProgressFill.BackgroundColor3 = resolved
        end
        if island.PingStroke then
            island.PingStroke.Color = resolved
        end
        if island.IconBackdrop then
            island.IconBackdrop.BackgroundColor3 = resolved
        end
        if island.IconBackdropStroke then
            island.IconBackdropStroke.Color = resolved
        end
        if island.ProgressGlow then
            island.ProgressGlow.ImageColor3 = resolved
        end
    end

    if isReplacing and config.IconMorph and not DisableAnimation and island.IconScale then
        dynamicCancelSiblings("iconPulse", "iconOut", "iconPop")
        dynamicTween("iconOut", island.IconScale, { Scale = 0.68 }, 0.1, StyleQuad, DirIn)
        task.delay(0.1, function()
            if not island.Enabled or island.Token ~= token or island.Current == nil then
                return
            end
            applyIcon()
            dynamicSpring("iconPop", island.IconScale, { Scale = 1.16 }, { Scale = 1 }, 0.34, StyleBack)
        end)
    else
        applyIcon()
    end

    local function applyContent()
        if not island.Enabled or island.Token ~= token or not island.Root or island.Current == nil then
            return
        end

        pcall(function()
            island.Text.MaxVisibleGraphemes = -1
        end)

        if isReplacing and config.Crossfade and island.TextGhost and island.Text then
            local oldText = tostring(island.Text.Text or "")
            local visible = tonumber(island.Text.MaxVisibleGraphemes) or -1
            if visible >= 0 and visible < #oldText then
                oldText = string.sub(oldText, 1, visible)
            end
            island.TextGhost.Text = oldText
            island.TextGhost.Position = UDim2.new(0, dynamicTextLeft(), 0.5, dynamicPrimaryY())
            island.TextGhost.TextTransparency = 0
            dynamicGhostOut(0.24)
        end

        dynamicApplyTextLayout(notification.Subtitle == nil)
        dynamicApplyControls(notification)
        island.Text.Text = tostring(notification.Text or "")
        if island.Subtitle then
            island.Subtitle.Text = tostring(notification.Subtitle or "")
            island.Subtitle.Visible = notification.Subtitle ~= nil
        end

        dynamicIdleVisual(1, 1, 0.1, StyleQuad, DirIn)

        local height = dynamicCardHeight()
        if isReplacing then
            dynamicPillSize(
                dynamicMeasureWidth(notification.Text, notification.Subtitle),
                height,
                DYNAMIC_EASE.Resize[1],
                DYNAMIC_EASE.Resize[2],
                DYNAMIC_EASE.Resize[3]
            )
        else
            dynamicExpand(token, dynamicMeasureWidth(notification.Text, notification.Subtitle), height)
        end

        dynamicContentIn(token)
        if dynamicWaveActive() then
            dynamicStartWave(token)
        else
            dynamicStopWave()
        end
        dynamicPlayProgress(token, notification.Time, accent)
        dynamicTypeText(token, notification.Type, notification.Time)
        dynamicRefineWidth(token)
        dynamicStartPulse(0.42)
    end

    if isReplacing then
        dynamicCancel("progress")
        dynamicHideProgress()
        pcall(function()
            island.Text.MaxVisibleGraphemes = -1
        end)

        if config.Crossfade and not DisableAnimation then
            local overlap = math.clamp(tonumber(config.MorphOverlap) or 0.07, 0, 0.2)

            dynamicTween("contentScale", island.ContentScale, { Scale = 0.94 }, 0.14, StyleQuad, DirIn)
            dynamicTween("textFade", island.Text, { TextTransparency = 1 }, overlap + 0.04, StyleQuad, DirIn)
            dynamicTween("textSlide", island.Text, {
                Position = UDim2.new(0, dynamicTextLeft() - 5, 0.5, -4),
            }, overlap + 0.06, StyleQuart, DirIn)

            if config.Nudge and island.Root then
                dynamicCancelSiblings("rootPos", "introPos", "rootNudge")
                dynamicTween("rootNudge", island.Root, {
                    Position = UDim2.new(0.5, 0, 0, dynamicOffsetY() + 2),
                }, 0.08, StyleQuad, DirOut)
                task.delay(0.08, function()
                    if island.Enabled and island.Token == token and island.Root then
                        dynamicTween("rootNudge", island.Root, {
                            Position = UDim2.new(0.5, 0, 0, dynamicOffsetY()),
                        }, 0.28, StyleBack, DirOut)
                    end
                end)
            end

            task.delay(overlap, function()
                if not island.Enabled or island.Token ~= token then
                    return
                end
                applyContent()
            end)
        else
            dynamicContentOut(0.1, function()
                if not island.Enabled or island.Token ~= token then
                    return
                end
                applyContent()
            end)
        end
    else
        applyContent()
    end
end

function Library:DynamicOn()
    local island = DynamicIsland

    if island.Enabled then
        local ok = pcall(function()
            dynamicBuild()
            island.Gui.Enabled = true
            dynamicApplyLayout()
        end)
        return ok
    end

    local ok = pcall(function()
        local config = island.Config

        dynamicBuild()
        island.Enabled = true
        island.Token = island.Token + 1
        island.Current = nil
        island.Hovering = false

        island.Gui.Enabled = true
        dynamicCancelAll()
        island.NeedsIntro = false
        island.SuppressClick = false
        island.DragInput = nil

        island.Root.Size = UDim2.new(0, config.CollapsedWidth, 0, config.CollapsedHeight)
        island.Root.Position = UDim2.new(0.5, 0, 0, -(config.CollapsedHeight + 40))
        island.Root.BackgroundTransparency = 1
        island.ContentScale.Scale = 1
        island.IconScale.Scale = 1
        island.Text.Text = ""
        island.Text.MaxVisibleGraphemes = -1
        island.Text.TextTransparency = 1
        if island.Subtitle then
            island.Subtitle.Text = ""
            island.Subtitle.TextTransparency = 1
            island.Subtitle.Visible = false
        end
        if island.ControlsRow then
            island.ControlsRow.Visible = false
        end
        island.IdleDot.BackgroundTransparency = 1
        if island.IdleRing then
            island.IdleRing.Transparency = 1
        end
        if island.Stroke then
            island.StrokeBase = config.StrokeBase or 0.72
            island.Stroke.Transparency = island.StrokeBase
        end
        if island.TopHighlight then
            island.TopHighlight.Visible = config.Glass
        end
        if island.Glow then
            island.Glow.ImageTransparency = 0.92
            island.Glow.Visible = config.Glow
        end
        if island.Gloss then
            island.Gloss.Visible = config.Gloss
        end
        if island.TextScale then
            island.TextScale.Scale = 1
        end
        dynamicHideProgress()
        dynamicHideIcon(0)

        island.Root.Rotation = 0

        island.ScaleBusy = true
        dynamicCancelSiblings("hoverScale", "tapDip", "introScale")
        task.delay(math.clamp(tonumber(config.SpringTime) or 0.46, 0.1, 2) * 1.35, function()
            if island.Enabled then
                island.ScaleBusy = false
            end
        end)
        if DisableAnimation then
            dynamicCancel("rootScale")
            island.Scaler.Scale = 1
        else
            local spring = math.clamp(tonumber(config.SpringTime) or 0.46, 0.1, 2)
            local first = spring * 0.43
            local second = spring * 0.74

            island.Scaler.Scale = 0.88
            dynamicTween("rootScale", island.Scaler, { Scale = 1.05 }, first, StyleQuart, DirOut)
            task.delay(first, function()
                if island.Enabled then
                    dynamicTween("rootScale", island.Scaler, { Scale = 1 }, second, StyleQuart, DirOut)
                end
            end)
        end

        dynamicTween("rootPos", island.Root, {
            Position = UDim2.new(0.5, 0, 0, dynamicOffsetY()),
        }, DYNAMIC_EASE.Enter[1], DYNAMIC_EASE.Enter[2], DYNAMIC_EASE.Enter[3])
        dynamicTween("rootBg", island.Root, { BackgroundTransparency = island.Config.Glass and 0.04 or 0 }, 0.3, StyleQuad, DirOut)

        if island.Stroke and not island.Hovering then
            local base = island.StrokeBase or 0.72
            dynamicCancelSiblings("hoverStroke", "strokeBreathe")
            island.Stroke.Transparency = math.max(0, base - 0.5)
            dynamicTween("strokeFlash", island.Stroke, { Transparency = base }, 0.55, StyleQuint, DirOut)
        end

        if island.Shadow then
            island.Shadow.Visible = config.Shadow
            island.Shadow.ImageTransparency = 1
            dynamicSyncDecor(config.CollapsedWidth, config.CollapsedHeight, 0)
            dynamicTween("shadowFade", island.Shadow, { ImageTransparency = 0.78 }, 0.42, StyleQuad, DirOut)
        end

        task.delay(0.34, function()
            if island.Enabled then
                dynamicBurst(island.Token, dynamicAccent())
            end
        end)

        task.delay(0.3, function()
            if island.Enabled and island.Current == nil then
                dynamicStartIdleBreath()
            end
        end)

        local pending = island.Pending
        island.Pending = nil
        if pending then
            task.delay(0.36, function()
                if island.Enabled and island.Current == nil then
                    Library:DynamicUp(pending)
                end
            end)
        end
    end)

    if not ok then
        island.Enabled = false
        return false
    end
    return true
end

function Library:DynamicOff()
    local island = DynamicIsland

    if not island.Enabled then
        if island.Gui then
            pcall(function()
                island.Gui.Enabled = false
            end)
        end
        return false
    end

    local config = island.Config
    island.Enabled = false
    island.Current = nil
    island.Pending = nil
    island.Hovering = false
    island.Token = island.Token + 1
    local token = island.Token

    local ok = pcall(function()
        dynamicCancelAll()
        dynamicStopPulse()
        dynamicStopSpinner()
        dynamicStopIdleBreath()

        pcall(function()
            island.Text.MaxVisibleGraphemes = -1
        end)

        dynamicTween("textFade", island.Text, { TextTransparency = 1 }, 0.1, StyleQuad, DirIn)
        dynamicGhostClear()
        island.DragInput = nil
        dynamicHideIcon(0.1)
        dynamicHideProgress()
        dynamicCancel("idleRingFade")
        island.IdleDot.BackgroundTransparency = 1
        if island.IdleRing then
            island.IdleRing.Transparency = 1
        end

        island.Root.Rotation = 0

        island.ScaleBusy = true
        dynamicCancel("hoverScale")
        dynamicCancel("tapDip")
        dynamicTween("rootRotate", island.Root, { Rotation = -1.6 }, DYNAMIC_EASE.Exit[1], StyleQuad, DirOut)

        dynamicTween("rootScale", island.Scaler, { Scale = 0.88 }, DYNAMIC_EASE.Exit[1], DYNAMIC_EASE.Exit[2], DYNAMIC_EASE.Exit[3])
        dynamicPillSize(config.CollapsedWidth, config.CollapsedHeight, 0.24, StyleQuart, DirIn)
        dynamicCancelSiblings("rootNudge", "introPos", "rootPos")
        dynamicTween("rootPos", island.Root, {
            Position = UDim2.new(0.5, 0, 0, -(config.CollapsedHeight + 40)),
        }, 0.3, StyleBack, DirIn)
        dynamicTween("rootBg", island.Root, { BackgroundTransparency = 1 }, 0.26, StyleQuad, DirIn)

        if island.Shadow then
            dynamicTween("shadowFade", island.Shadow, { ImageTransparency = 1 }, 0.24, StyleQuad, DirIn)
        end

        task.delay(DisableAnimation and 0 or 0.34, function()
            if island.Token ~= token or island.Enabled then
                return
            end
            if island.Gui then
                island.Gui.Enabled = false
            end
            if island.Text then
                island.Text.Text = ""
            end
            if island.Scaler then
                island.Scaler.Scale = 1
            end
        end)
    end)

    return ok
end

local function dynamicGraphemeLength(text)
    if utf8 and utf8.len then
        local ok, length = pcall(utf8.len, text)
        if ok and length then
            return length
        end
    end
    return #text
end

local function dynamicTruncateText(text, maxLength)
    local length = dynamicGraphemeLength(text)
    if length <= maxLength then
        return text
    end

    local cut = math.max(1, maxLength - 3)
    local index

    if utf8 and utf8.offset then
        local ok, result = pcall(utf8.offset, text, cut + 1)
        if ok then
            index = result
        end
    end

    if not index then
        index = math.min(#text, cut) + 1
        while index > 1 do
            local byte = string.byte(text, index - 1)
            if byte == nil or byte < 0x80 or byte >= 0xC0 then
                break
            end
            index = index - 1
        end
    end

    return string.sub(text, 1, math.max(0, index - 1)) .. "..."
end

function Library:DynamicUp(options)
    local island = DynamicIsland
    local config = island.Config

    if type(options) ~= "table" then
        options = { Text = options }
    end

    local function clean(value)
        local out = tostring(value == nil and "" or value)
        out = string.gsub(out, "[%c]+", " ")
        out = string.gsub(out, "%s+", " ")
        out = string.gsub(out, "^%s+", "")
        out = string.gsub(out, "%s+$", "")
        return dynamicTruncateText(out, 180)
    end

    local title = options.Title or options.title
    local subtitle = options.Subtitle or options.subtitle
    local text
    if title ~= nil then
        title = clean(title)
        subtitle = clean(subtitle or options.Text or options.text or options.Message or "")
        if subtitle == "" then
            subtitle = nil
        end
        text = (title ~= "") and title or "..."
    else
        title = nil
        subtitle = nil
        text = clean(options.Text or options.text or options.Message)
    end
    if text == "" then
        text = "..."
    end

    local duration = tonumber(options.time or options.Time or options.Duration)
    if duration == nil then
        duration = config.DefaultTime
    end
    if duration < 0 then
        duration = 0
    elseif duration > 60 then
        duration = 60
    end

    local accent = options.Color or options.Accent or options.AccentColor
    if not dynamicIsColor(accent) then
        accent = nil
    end

    local kind = options.Kind or options.kind or options.Style
    if type(kind) == "string" then
        kind = string.lower(kind)
    end
    if not DYNAMIC_KINDS[kind] then
        kind = "info"
    end

    local notification = {
        Text = text,
        Title = title,
        Subtitle = subtitle,
        Wave = (options.Wave == true) or (DYNAMIC_KINDS[kind].Wave == true),
        Controls = (type(options.Controls) == "table") and options.Controls or nil,
        Time = duration,
        Icon = options.Icon or options.icon or options.Image,
        Accent = accent,
        Kind = kind,
        Type = options.Type ~= false and options.Instant ~= true,
        OnTap = options.OnTap or options.Callback,
        Dismissible = options.Dismissible ~= false,
    }

    if not island.Enabled then
        island.Pending = notification
        return false
    end

    island.Token = island.Token + 1
    local token = island.Token
    island.Pending = nil

    local ok = pcall(function()
        dynamicBuild()
        if not island.Gui.Enabled then
            island.Gui.Enabled = true
        end
        dynamicShowNotification(notification, token)
    end)

    if not ok then
        DynamicIsland.LastError = tostring(err)
        if DYNAMIC_DEBUG then
            warn("[DynamicIsland] " .. tostring(err))
        end
        return false
    end
    DynamicIsland.LastError = nil
    return true
end

function Library:DynamicLastError()
    return DynamicIsland.LastError
end

function Library:DynamicSelfTest(waitFn)
    local results = {}
    local wait = waitFn
    if type(wait) ~= "function" then
        wait = function(seconds)
            task.wait(seconds)
        end
    end
    local function check(name, fn)
        local ok, err = pcall(fn)
        if ok then
            results[#results + 1] = "[OK]   " .. name
        else
            results[#results + 1] = "[FAIL] " .. name .. " -> " .. tostring(err)
        end
        return ok
    end

    check("DynamicOn", function()
        assert(Library:DynamicOn() ~= false, "DynamicOn lỗi: " .. tostring(Library:DynamicLastError()))
    end)
    check("tin 1 dòng", function()
        assert(Library:DynamicUp({ Text = "SelfTest: 1 dòng", time = 4 }),
            "DynamicUp lỗi: " .. tostring(Library:DynamicLastError()))
    end)
    check("card 2 dòng", function()
        assert(Library:DynamicUp({ Title = "SelfTest", Subtitle = "card 2 dòng", time = 4 }),
            "DynamicUp lỗi: " .. tostring(Library:DynamicLastError()))
    end)
    check("Kind = loading", function()
        assert(Library:DynamicUp({ Kind = "loading", Text = "SelfTest: loading", time = 3 }),
            "DynamicUp lỗi: " .. tostring(Library:DynamicLastError()))
    end)
    check("Kind = music + hàng nút", function()
        assert(Library:DynamicUp({
            Kind = "music",
            Title = "SelfTest",
            Subtitle = "3 nút điều khiển",
            Controls = { { Icon = "<<" }, { Icon = "II" }, { Icon = ">>" } },
            time = 4,
        }), "DynamicUp lỗi: " .. tostring(Library:DynamicLastError()))
    end)
    check("hàng nút hiện + bấm được", function()
        pcall(function()
            wait(0.35)
        end)
        local island = DynamicIsland
        assert(island.ControlsRow and island.ControlsRow.Visible, "hàng nút không hiện (ControlsHeight?)")
        local pressed = false
        island.ControlCallbacks[1] = function()
            pressed = true
        end
        local button = island.ControlButtons[1]
        assert(button and button.Visible, "nút 1 không hiện")
        button.MouseButton1Click:Fire()
        assert(pressed, "bấm nút không gọi callback")
    end)
    check("icon vector + tròn", function()
        assert(Library:DynamicUp({ Kind = "success", Text = "SelfTest: icon", time = 3 }),
            "DynamicUp lỗi: " .. tostring(Library:DynamicLastError()))
        pcall(function()
            wait(0.2)
        end)
        local island = DynamicIsland
        assert(island.IconDotCorner and island.IconDotCorner.CornerRadius.Scale >= 0.499,
            "ô artwork chưa tròn (IconShape = circle)")
        assert(island.IconHolder and island.IconHolder.ClipsDescendants == false,
            "ô artwork còn cắt con -> quầng tròn bị gọt vuông")
        local entry = island.IconVectors and island.IconVectors.success
        assert(entry and entry.Group and entry.Group.Visible, "icon vector success không hiện")
        assert(#entry.Parts >= 2, "icon vector thiếu nét")
    end)
    check("đổi cấu hình", function()
        Library:DynamicConfig({ CornerRadius = 22 })
        Library:DynamicConfig({})
    end)
    check("thu gọn", function()
        Library:DynamicCollapse()
    end)

    print("=== DynamicIsland SelfTest ===")
    for _, line in ipairs(results) do
        print(line)
    end
    print("=============================")
    return results
end

function Library:DynamicCollapse()
    local island = DynamicIsland
    if not island.Enabled or not island.Root then
        return false
    end

    local config = island.Config
    island.Current = nil
    island.Token = island.Token + 1

    dynamicCancel("progress")
    dynamicStopPulse()
    dynamicStopSpinner()
    dynamicStopWave()
    dynamicHideProgress()
    if island.ControlsRow then
        island.ControlsRow.Visible = false
    end

    pcall(function()
        island.Text.MaxVisibleGraphemes = -1
    end)

    dynamicContentOut(0.14)
    dynamicGhostClear()

    dynamicCancelSiblings("rootNudge", "introPos", "rootPos")
    dynamicCancelSiblings("hoverScale", "tapDip", "introScale")
    dynamicTween("rootPos", island.Root, {
        Position = UDim2.new(0.5, 0, 0, dynamicOffsetY()),
    }, 0.26, StyleBack, DirOut)

    if island.TextScale then
        island.TextScale.Scale = 1
    end
    dynamicPillSize(
        config.CollapsedWidth,
        config.CollapsedHeight,
        DYNAMIC_EASE.Exit[1],
        DYNAMIC_EASE.Exit[2],
        DYNAMIC_EASE.Exit[3]
    )

    task.delay(DisableAnimation and 0 or 0.18, function()
        if not (island.Enabled and island.Current == nil) then
            return
        end
        if island.IdleDot then
            island.IdleDot.BackgroundTransparency = 1
        end
        if island.IdleRing then
            island.IdleRing.Transparency = 1
        end
        if island.IdleScale then
            dynamicCancelSiblings("idleScale")
            island.IdleScale.Scale = 0.2
            dynamicSpring("idlePop", island.IdleScale, { Scale = 1.35 }, { Scale = 1 }, 0.36, StyleBack)
        end
        task.delay(0.2, function()
            if island.Enabled and island.Current == nil then
                dynamicStartIdleBreath()
            end
        end)
    end)

    task.delay(0.42, function()
        if island.Enabled and island.Current == nil and island.Text then
            island.Text.Text = ""
        end
    end)

    return true
end

function Library:DynamicConfig(setting)
    local island = DynamicIsland
    if type(setting) ~= "table" then
        return island.Config
    end

    dynamicSanitizeConfig()
    for key, value in pairs(setting) do
        if key == "Accent" then
            if dynamicIsColor(value) then
                island.Config.Accent = value
            end
        elseif key == "TextColor" then
            if dynamicIsColor(value) then
                island.Config.TextColor = value
            end
        elseif key == "Font" then
            local isFont = false
            if typeof then
                isFont = (typeof(value) == "EnumItem")
            end
            if not isFont then
                isFont = type(value) == "table" and value.Name ~= nil
            end
            if isFont then
                island.Config.Font = value
            end
        elseif type(island.Config[key]) == "boolean" then
            island.Config[key] = value and true or false
        elseif type(island.Config[key]) == "number" then
            local number = tonumber(value)
            if number then
                island.Config[key] = number
            end
        elseif type(island.Config[key]) == "string" then
            island.Config[key] = tostring(value)
        end
    end

    dynamicSanitizeConfig()

    if island.Enabled then
        pcall(dynamicApplyLayout)
    end

    pcall(function()
        if island.Gloss then
            island.Gloss.Visible = island.Config.Gloss
        end
        if island.Glow then
            island.Glow.Visible = island.Config.Glow
            if not island.Config.Glow then
                island.Glow.ImageTransparency = 1
            end
        end
        if island.Spinner then
            local kindData = island.Current and DYNAMIC_KINDS[island.Current.Kind or "info"]
            local wantSpinner = island.Current ~= nil
                and kindData ~= nil
                and kindData.Spinner == true
                and island.Current.Icon == nil
            island.Spinner.Visible = wantSpinner
            if wantSpinner then
                dynamicStartSpinner(island.Current.Token or island.Token)
            else
                dynamicStopSpinner()
            end
        end
        if island.Shadow then
            island.Shadow.Visible = island.Config.Shadow
            island.Shadow.ImageTransparency = island.Config.Shadow and 0.78 or 1
        end
        if island.TopHighlight then
            island.TopHighlight.Visible = island.Config.Glass
        end
        if island.Stroke then
            island.Stroke.Enabled = (island.Config.Stroke == true)
        end
        local rootGradient
        if island.Root then
            for _, child in ipairs(island.Root:GetChildren()) do
                if child.ClassName == "UIGradient" then
                    rootGradient = child
                    break
                end
            end
        end
        if rootGradient then
            if island.Config.Glass then
                rootGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(44, 44, 52)),
                    ColorSequenceKeypoint.new(0.45, Color3.fromRGB(20, 20, 25)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 13)),
                })
                rootGradient.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.45, 0.04),
                    NumberSequenceKeypoint.new(1, 0.1),
                })
            else
                rootGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
                rootGradient.Transparency = NumberSequence.new(0)
            end
        end
        if island.IconBackdrop then
            island.IconBackdrop.Visible = island.Config.IconBackdrop
        end
        if island.ProgressGlow then
            island.ProgressGlow.Visible = island.Config.ProgressBar and island.Config.ProgressGlow
        end
        local fontSize = math.clamp(tonumber(island.Config.TextSize) or 13, 8, 24)
        if island.Text then
            island.Text.Font = island.Config.Font or Enum.Font.GothamBold
            island.Text.TextSize = fontSize
            island.Text.TextColor3 = island.Config.TextColor or dynamicTextColor()
        end
        if island.TextGhost then
            island.TextGhost.Font = island.Config.Font or Enum.Font.GothamBold
            island.TextGhost.TextSize = fontSize
            island.TextGhost.TextColor3 = island.Config.TextColor or dynamicTextColor()
        end
        if island.Current and island.Root then
            local measured = dynamicMeasureWidth(island.Current.Text, island.Current.Subtitle)
            local height = dynamicCardHeight()
            if math.abs(measured - (island.Root.Size.X.Offset or measured)) > 1
                or math.abs(height - (island.Root.Size.Y.Offset or height)) > 1
            then
                dynamicPillSize(measured, height, 0.22, StyleQuart, DirOut)
            end
        end
        if island.Stroke then
            island.StrokeBase = island.Config.StrokeBase or 0.72
            island.Stroke.Transparency = island.StrokeBase
        end
        if island.ProgressTrack then
            local thickness = math.clamp(tonumber(island.Config.ProgressThickness) or 3, 2, 6)
            island.ProgressTrack.Size = UDim2.new(1, -22, 0, thickness)
            island.ProgressTrack.Position = UDim2.new(0.5, 0, 1, -(thickness + 2))
            island.ProgressTrack.Visible = island.Config.ProgressBar
            if not island.Config.ProgressBar then
                island.ProgressTrack.BackgroundTransparency = 1
                if island.ProgressFill then
                    island.ProgressFill.BackgroundTransparency = 1
                end
                dynamicStopShimmer()
            end
        end
    end)

    dynamicSanitizeConfig()

    if island.Enabled and island.Current and island.Current.Accent == nil then
        pcall(function()
            local resolved = dynamicApplyIcon(island.Current)
            island.Current.AccentResolved = resolved
            if island.ProgressFill then
                island.ProgressFill.BackgroundColor3 = resolved
            end
            if island.ProgressGlow then
                island.ProgressGlow.ImageColor3 = resolved
            end
            if island.IconBackdrop then
                island.IconBackdrop.BackgroundColor3 = resolved
            end
            if island.IconBackdropStroke then
                island.IconBackdropStroke.Color = resolved
            end
            if island.PingStroke then
                island.PingStroke.Color = resolved
            end
        end)
    end

    if island.Enabled and island.Current and (setting.IconStyle ~= nil or setting.IconShape ~= nil) then
        pcall(function()
            dynamicApplyIcon(island.Current)
        end)
    end

    return island.Config
end

function Library:DynamicIsOn()
    local island = DynamicIsland
    if not island.Enabled then
        return false
    end
    if island.Gui ~= nil and island.Gui.Parent == nil then
        return false
    end
    return true
end

function Library:DynamicReset()
    local island = DynamicIsland

    island.Enabled = false
    island.Token = island.Token + 1
    island.TypingToken = island.TypingToken + 1
    island.PulseToken = island.PulseToken + 1
    island.IdleToken = island.IdleToken + 1
    island.SpinToken = island.SpinToken + 1
    island.Current = nil
    island.Pending = nil

    dynamicCancelAll()

    if island.ViewportConnection then
        pcall(function()
            island.ViewportConnection:Disconnect()
        end)
        island.ViewportConnection = nil
    end
    if island.CameraConnection then
        pcall(function()
            island.CameraConnection:Disconnect()
        end)
        island.CameraConnection = nil
    end

    if island.Gui then
        pcall(function()
            island.Gui:Destroy()
        end)
    end

    island.Gui = nil
    island.Root = nil
    island.Scaler = nil
    island.Stroke = nil
    island.Glow = nil
    island.Gloss = nil
    island.TextScale = nil
    island.Shadow = nil
    island.Burst = nil
    island.BurstStroke = nil
    island.BurstScale = nil
    island.TextShine = nil
    island.TextGhost = nil
    island.ProgressHead = nil
    island.ProgressShine = nil
    island.ProgressGlow = nil
    island.IconBackdrop = nil
    island.IconBackdropStroke = nil
    island.TopHighlight = nil
    island.IdleRing = nil
    island.StrokeBase = nil
    island.PropOwner = nil
    island.Hovering = false
    island.ScaleBusy = false
    island.TopInset = nil
    if island.UISConns then
        for _, conn in ipairs(island.UISConns) do
            pcall(function()
                conn:Disconnect()
            end)
        end
    end
    island.UISConns = nil
    island.DragInput = nil
    island.DragStartY = nil
    island.DragOrigin = nil
    island.DragMoved = false
    island.SuppressClick = false
    island.NeedsIntro = false
    island.Content = nil
    island.ContentScale = nil
    island.IconHolder = nil
    island.IconScale = nil
    island.PingFrame = nil
    island.PingScale = nil
    island.PingStroke = nil
    island.IconImage = nil
    island.IconDot = nil
    island.IconDotStroke = nil
    island.IconDotCorner = nil
    island.IconImageCorner = nil
    island.IconVectors = nil
    island.IconCanvas = nil
    island.IconVectorGroup = nil
    island.IconVectorKind = nil
    island.Spinner = nil
    island.SpinnerDots = {}
    island.IdleDot = nil
    island.IdleScale = nil
    island.Text = nil
    island.ProgressTrack = nil
    island.ProgressFill = nil
    island.Overlay = nil
    island.Tweens = {}
end

Library_Function.ResetDynamicIsland = function()
    pcall(function()
        Library:DynamicReset()
    end)
end

function Library:CreateWindow(Setting)
    Setting = Setting or {}
    local TitleNameMain = Setting.Title or "NatAov Hub"
    getgenv().TitleNameMain = TitleNameMain
    getgenv().MainDesc = Setting.Desc or Setting.Subtitle or ""

    if Setting.Image then
        getgenv().UIColor["Logo Image"] = Setting.Image
        if Library_Function.ToggleButtonIcon then
            Library_Function.ToggleButtonIcon.Image = Setting.Image
        end
    end

    local DEFAULT_MIN_SIZE = Vector2.new(380, 250)
    local DEFAULT_MAX_SIZE = Vector2.new(900, 650)
    local DEFAULT_WINDOW_SIZE = Vector2.new(629, 359)

    local WindowMinSize = typeof(Setting.MinSize) == "Vector2" and Setting.MinSize or DEFAULT_MIN_SIZE
    local WindowMaxSize = typeof(Setting.MaxSize) == "Vector2" and Setting.MaxSize or DEFAULT_MAX_SIZE
    if WindowMaxSize.X < WindowMinSize.X or WindowMaxSize.Y < WindowMinSize.Y then
        WindowMaxSize =
            Vector2.new(math.max(WindowMaxSize.X, WindowMinSize.X), math.max(WindowMaxSize.Y, WindowMinSize.Y))
    end

    local WindowSize = typeof(Setting.Size) == "Vector2" and Setting.Size or DEFAULT_WINDOW_SIZE
    WindowSize = Vector2.new(
        math.clamp(WindowSize.X, WindowMinSize.X, WindowMaxSize.X),
        math.clamp(WindowSize.Y, WindowMinSize.Y, WindowMaxSize.Y)
    )

    local Main = Instance.new("Frame")
    local maingui = Instance.new("ImageLabel")
    local MainCorner = Instance.new("UICorner")
    local TopMain = Instance.new("Frame")
    local Ruafimg = Instance.new("ImageLabel")
    local TextLabelMain = Instance.new("TextLabel")
    local PageControl = Instance.new("Frame")
    local UICorner = Instance.new("UICorner")
    local ControlList = Instance.new("ScrollingFrame")
    local UIListLayout = Instance.new("UIListLayout")
    local MainPage = Instance.new("Frame")
    local UIPage = Instance.new("UIPageLayout")
    local Concacontainer = Instance.new("Frame")
    local Concacmain = Instance.new("Frame")
    local MainContainer

    Main.Name = "Main"
    Main.Parent = Library_Function.Gui
    Main.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
    Main.BackgroundTransparency = 1.000
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Size = UDim2.new(0, WindowSize.X, 0, WindowSize.Y)
    Main.ClipsDescendants = false
    Library_Function.LastWindowSize = Main.Size

    maingui.Name = "maingui"
    maingui.Parent = Main
    maingui.AnchorPoint = Vector2.new(0.5, 0.5)
    maingui.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    maingui.BackgroundTransparency = 1.000
    maingui.Position = UDim2.new(0.5, 0, 0.5, 0)
    maingui.Selectable = true
    maingui.Size = UDim2.new(1, 30, 1, 30)
    maingui.Image = "rbxassetid://8068653048"
    maingui.ScaleType = Enum.ScaleType.Slice
    maingui.SliceCenter = Rect.new(15, 15, 175, 175)
    maingui.SliceScale = 1.300
    maingui.ImageColor3 = getgenv().UIColor["Border Color"]
    maingui.ImageTransparency = 1

    maingui.ImageColor3 = getgenv().UIColor["Title Text Color"]

    MainContainer = Instance.new("ImageLabel")
    MainContainer.Name = "MainContainer"
    MainContainer.Parent = Main
    MainContainer.BackgroundColor3 = getgenv().UIColor["Background Main Color"]
    MainContainer.Size = UDim2.new(1, 0, 1, 0)

    local uistr = Instance.new("UIStroke", MainContainer)
    uistr.Thickness = 1
    uistr.Color = getgenv().UIColor["Stroke Color"]

    local uigradient = Instance.new("UIGradient", MainContainer)
    uigradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
    })
    uigradient.Rotation = 90
    uigradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.92),
        NumberSequenceKeypoint.new(1, 0.92),
    })

    getgenv().ReadyForGuiLoaded = true

    MainCorner.CornerRadius = UDim.new(0, 5)
    MainCorner.Name = "MainCorner"
    MainCorner.Parent = MainContainer

    Concacontainer.Name = "Concacontainer"
    Concacontainer.Parent = MainContainer
    Concacontainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Concacontainer.BackgroundTransparency = 1.000
    Concacontainer.ClipsDescendants = true
    Concacontainer.Position = UDim2.new(0, 0, 0, 30)
    Concacontainer.Size = UDim2.new(1, 0, 1, -30)

    Concacmain.Name = "Concacmain"
    Concacmain.Parent = Concacontainer
    Concacmain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Concacmain.BackgroundTransparency = 1.000
    Concacmain.Selectable = true
    Concacmain.Size = UDim2.new(1, 0, 1, 0)

    TopMain.Name = "TopMain"
    TopMain.Parent = MainContainer
    TopMain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TopMain.BackgroundTransparency = 1.000
    TopMain.Size = UDim2.new(1, 0, 0, 25)
    TopMain.Active = true

    makeDraggable(TopMain, Main)

    local TopStroke = Instance.new("Frame", TopMain)
    TopStroke.Name = "TopStroke"
    TopStroke.BackgroundColor3 = getgenv().UIColor["Stroke Color"]
    TopStroke.BackgroundTransparency = 0.6
    TopStroke.BorderSizePixel = 0
    TopStroke.Position = UDim2.new(0, 0, 1, -1)
    TopStroke.Size = UDim2.new(1, 0, 0, 1)

    Ruafimg.Name = "Ruafimg"
    Ruafimg.Parent = TopMain
    Ruafimg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ruafimg.BackgroundTransparency = 1.000
    Ruafimg.Position = UDim2.new(0, 5, 0, 0)
    Ruafimg.Size = UDim2.new(0, 25, 0, 25)
    Ruafimg.Image = getgenv().UIColor["Logo Image"]

    TextLabelMain.Name = "TextLabelMain"
    TextLabelMain.Parent = TopMain
    TextLabelMain.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    TextLabelMain.BackgroundTransparency = 1.000

    TextLabelMain.AnchorPoint = Vector2.new(0.5, 0.5)
    TextLabelMain.Position = UDim2.new(0.5, 0, 0.5, 0)
    TextLabelMain.Size = UDim2.new(1, -80, 1, 0)
    TextLabelMain.Font = Enum.Font.GothamBold
    TextLabelMain.RichText = true
    TextLabelMain.TextSize = 16.000
    TextLabelMain.TextWrapped = true
    TextLabelMain.TextXAlignment = Enum.TextXAlignment.Center
    TextLabelMain.TextYAlignment = Enum.TextYAlignment.Center
    TextLabelMain.TextColor3 = getgenv().UIColor["GUI Text Color"]
    TextLabelMain.TextTruncate = Enum.TextTruncate.AtEnd

    do
        local tc = Library_Function.Getcolor(getgenv().UIColor["Title Text Color"])
        TextLabelMain.Text = '<font color="rgb('
            .. tc[1]
            .. ","
            .. tc[2]
            .. ","
            .. tc[3]
            .. ')">'
            .. tostring(TitleNameMain or "NatAov Hub")
            .. '</font> <font color="rgb(255,255,255)">'
            .. tostring(getgenv().MainDesc or "")
            .. "</font>"
    end
    PageControl.Name = "Background1"
    PageControl.Parent = Concacmain
    PageControl.Position = UDim2.new(0, 5, 0, 5)
    PageControl.Size = UDim2.new(0.24, -8, 1, -10)
    PageControl.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
    PageControl.BackgroundTransparency = 0.1

    local pageControlStroke = Instance.new("UIStroke", PageControl)
    pageControlStroke.Color = getgenv().UIColor["Stroke Color"]
    pageControlStroke.Thickness = 1

    local pageControlGradient = Instance.new("UIGradient", PageControl)
    pageControlGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 34)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 38, 46)),
    })
    pageControlGradient.Rotation = 90
    pageControlGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.06),
        NumberSequenceKeypoint.new(1, 0.12),
    })

    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = PageControl

    ControlList.Name = "ControlList"
    ControlList.Parent = PageControl
    ControlList.Active = true
    ControlList.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    ControlList.BackgroundTransparency = 1.000
    ControlList.BorderColor3 = Color3.fromRGB(27, 42, 53)
    ControlList.BorderSizePixel = 0
    ControlList.Position = UDim2.new(0, 0, 0, 38)
    ControlList.Size = UDim2.new(1, -5, 1, -38)
    ControlList.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    ControlList.CanvasSize = UDim2.new(0, 0, 0, 0)
    ControlList.ScrollBarThickness = 5
    ControlList.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

    UIListLayout.Parent = ControlList
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)

    local PageSearch = Instance.new("Frame")
    local PageSearchCorner = Instance.new("UICorner")
    local SearchFrame = Instance.new("Frame")
    local SearchIcon = Instance.new("ImageLabel")
    local SearchBox = Instance.new("TextBox")

    PageSearch.Name = "PageSearch"
    PageSearch.Parent = PageControl
    PageSearch.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
    PageSearch.Position = UDim2.new(0, 5, 0, 6)
    PageSearch.Size = UDim2.new(1, -10, 0, 26)
    PageSearch.ClipsDescendants = true

    PageSearchCorner.Parent = PageSearch
    PageSearchCorner.CornerRadius = UDim.new(0, 4)

    SearchFrame.Name = "SearchFrame"
    SearchFrame.Parent = PageSearch
    SearchFrame.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
    SearchFrame.BackgroundTransparency = 1
    SearchFrame.Size = UDim2.new(0, 25, 1, 0)

    SearchIcon.Name = "SearchIcon"
    SearchIcon.Parent = SearchFrame
    SearchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    SearchIcon.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    SearchIcon.Size = UDim2.new(0, 16, 0, 16)
    SearchIcon.Image = "rbxassetid://8154282545"
    SearchIcon.ImageColor3 = getgenv().UIColor["Search Icon Color"]

    SearchBox.Name = "SearchBox"
    SearchBox.Parent = PageSearch
    SearchBox.Active = true
    SearchBox.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
    SearchBox.BackgroundTransparency = 1
    SearchBox.CursorPosition = -1
    SearchBox.Position = UDim2.new(0, 30, 0, 0)
    SearchBox.Size = UDim2.new(1, -30, 1, 0)
    SearchBox.Font = Enum.Font.GothamBold
    SearchBox.PlaceholderColor3 = Color3.fromRGB(170, 170, 160)
    SearchBox.PlaceholderText = "Search section or Function..."
    SearchBox.Text = ""
    SearchBox.TextColor3 = Color3.fromRGB(235, 235, 230)
    SearchBox.TextSize = 14
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.TextTruncate = Enum.TextTruncate.AtEnd

    MainPage.Name = "MainPage"
    MainPage.Parent = Concacmain
    MainPage.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    MainPage.BackgroundTransparency = 1.000
    MainPage.ClipsDescendants = true
    MainPage.Position = UDim2.new(0.24, 8, 0, 5)
    MainPage.Size = UDim2.new(0.76, -16, 1, -10)

    UIPage.Name = "UIPage"
    UIPage.Parent = MainPage
    UIPage.FillDirection = Enum.FillDirection.Vertical
    UIPage.SortOrder = Enum.SortOrder.LayoutOrder
    UIPage.EasingDirection = Enum.EasingDirection.InOut
    UIPage.EasingStyle = Enum.EasingStyle.Quart
    UIPage.Padding = UDim.new(0, 10)
    UIPage.TweenTime = getgenv().UIColor["Tween Animation 1 Speed"]

    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ControlList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 5)
    end)

    local Shadow = Instance.new("ImageLabel", Main)
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
    Shadow.BackgroundTransparency = 1
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.ZIndex = 0
    Shadow.Image = "rbxassetid://5028857084"
    Shadow.ImageTransparency = 0.35
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(24, 24, 276, 276)

    local WindowFade = Instance.new("Frame")
    WindowFade.Name = "WindowFade"
    WindowFade.Parent = Main
    WindowFade.BackgroundColor3 = getgenv().UIColor["Background Main Color"]
    WindowFade.BackgroundTransparency = 1
    WindowFade.BorderSizePixel = 0
    WindowFade.Size = UDim2.new(1, 0, 1, 0)
    WindowFade.ZIndex = 50
    WindowFade.Active = false
    WindowFade.Visible = false
    local WindowFadeCorner = Instance.new("UICorner")
    WindowFadeCorner.CornerRadius = UDim.new(0, 5)
    WindowFadeCorner.Parent = WindowFade

    local ResizeGrip = Instance.new("TextButton")
    ResizeGrip.Name = "ResizeGrip"
    ResizeGrip.Parent = Main
    ResizeGrip.AnchorPoint = Vector2.new(1, 1)
    ResizeGrip.Position = UDim2.new(1, 0, 1, 0)
    ResizeGrip.Size = UDim2.new(0, 20, 0, 20)
    ResizeGrip.BackgroundTransparency = 1
    ResizeGrip.AutoButtonColor = false
    ResizeGrip.Text = ""
    ResizeGrip.ZIndex = 10

    local gripLines = {}
    for i = 1, 3 do
        local gripLine = Instance.new("Frame")
        gripLine.Name = "GripLine" .. i
        gripLine.Parent = ResizeGrip
        gripLine.AnchorPoint = Vector2.new(1, 1)
        gripLine.Position = UDim2.new(1, -4, 1, -4 - (i - 1) * 5)
        gripLine.Size = UDim2.new(0, 11 - (i - 1) * 3, 0, 2)
        gripLine.Rotation = -45
        gripLine.BackgroundColor3 = getgenv().UIColor["Search Icon Color"] or Color3.fromRGB(160, 160, 170)
        gripLine.BackgroundTransparency = 0.35
        gripLine.BorderSizePixel = 0
        local gripCorner = Instance.new("UICorner")
        gripCorner.CornerRadius = UDim.new(1, 0)
        gripCorner.Parent = gripLine
        table.insert(gripLines, gripLine)
    end

    ResizeGrip.MouseEnter:Connect(function()
        for _, line in ipairs(gripLines) do
            TweenService
                :Create(
                    line,
                    TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]),
                    { BackgroundTransparency = 0 }
                )
                :Play()
        end
    end)
    ResizeGrip.MouseLeave:Connect(function()
        for _, line in ipairs(gripLines) do
            TweenService:Create(
                line,
                TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]),
                { BackgroundTransparency = 0.35 }
            ):Play()
        end
    end)

    do
        local resizing = false
        local resizeStart, startSize

        ResizeGrip.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                resizing = true
                resizeStart = input.Position
                startSize = Main.Size
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        resizing = false
                    end
                end)
            end
        end)

        uis.InputChanged:Connect(function(input)
            if
                resizing
                and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                )
            then
                local delta = input.Position - resizeStart
                local newW = math.clamp(startSize.X.Offset + delta.X, WindowMinSize.X, WindowMaxSize.X)
                local newH = math.clamp(startSize.Y.Offset + delta.Y, WindowMinSize.Y, WindowMaxSize.Y)
                Main.Size = UDim2.new(0, newW, 0, newH)
                Library_Function.LastWindowSize = Main.Size
            end
        end)
    end

    local sectionInfo = {}

    local GlobalSearch
    GlobalSearch = function(searchText)
        searchText = string.lower(searchText)

        if searchText == "" then
            for _, control in pairs(getgenv().AllControls) do
                control.TabButton.Visible = true
                control.Section.Visible = true
                control.Element.Visible = true
            end
            for _, tab in pairs(ControlList:GetChildren()) do
                if not tab:IsA("UIListLayout") then
                    tab.Visible = true
                end
            end
            return
        end

        for _, control in pairs(getgenv().AllControls) do
            control.Section.Visible = false
            control.Element.Visible = false
        end

        for _, tab in pairs(ControlList:GetChildren()) do
            if not tab:IsA("UIListLayout") then
                tab.Visible = false
            end
        end

        local sectionsWithElements = {}
        local elementsInSection = {}

        for _, control in pairs(getgenv().AllControls) do
            local elementName = string.lower(control.Name or "")
            local sectionName = string.lower(control.SectionName or "")

            local elementFound = string.find(elementName, searchText, 1, true) ~= nil
            local sectionFound = string.find(sectionName, searchText, 1, true) ~= nil

            if not elementsInSection[control.Section] then
                elementsInSection[control.Section] = {}
            end
            table.insert(elementsInSection[control.Section], {
                control = control,
                elementFound = elementFound,
                sectionFound = sectionFound,
            })

            if elementFound then
                sectionsWithElements[control.Section] = true
            end
        end

        local foundTabs = {}

        for section, elements in pairs(elementsInSection) do
            local shouldShowSection = false
            local hasElementMatch = false

            for _, elementInfo in ipairs(elements) do
                if elementInfo.sectionFound then
                    shouldShowSection = true
                end
                if elementInfo.elementFound then
                    hasElementMatch = true
                end
            end

            for _, elementInfo in ipairs(elements) do
                local control = elementInfo.control

                if elementInfo.elementFound then
                    control.Element.Visible = true

                    if elementInfo.sectionFound or hasElementMatch then
                        control.Section.Visible = true
                    end

                    foundTabs[control.TabName] = true
                    control.TabButton.Visible = true
                elseif elementInfo.sectionFound and not hasElementMatch then
                    control.Section.Visible = true
                    control.Element.Visible = false

                    foundTabs[control.TabName] = true
                    control.TabButton.Visible = true
                end
            end
        end

        for tabName, _ in pairs(foundTabs) do
            for _, tab in pairs(ControlList:GetChildren()) do
                if not tab:IsA("UIListLayout") and string.find(tab.Name, tabName, 1, true) then
                    tab.Visible = true
                end
            end
        end
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        pcall(GlobalSearch, SearchBox.Text)
    end)

    local Main_Function = {}

    local LayoutOrderBut = -1
    local LayoutOrder = -1
    local PageCounter = 1

    function Main_Function:AddTab(PageName, IconId)
        local Page_Name = tostring(PageName)
        local Page_Title = Page_Name

        LayoutOrder = LayoutOrder + 1
        LayoutOrderBut = LayoutOrderBut + 1

        local PageNameControl = Instance.new("Frame")
        local Frame = Instance.new("Frame")
        local TabNameCorner = Instance.new("UICorner")
        local Line = Instance.new("Frame")
        local InLine = Instance.new("Frame")
        local LineCorner = Instance.new("UICorner")
        local TabTitleContainer = Instance.new("Frame")
        local TabTitle = Instance.new("TextLabel")
        local PageButton = Instance.new("TextButton")

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Name = "TabIcon"
        TabIcon.Parent = Frame
        TabIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabIcon.BackgroundTransparency = 1.000
        TabIcon.Position = UDim2.new(0, 10, 0.5, 0)
        TabIcon.AnchorPoint = Vector2.new(0, 0.5)
        TabIcon.Size = UDim2.new(0, 15, 0, 15)
        TabIcon.Image = IconId or ""

        if not IconId or IconId == "" then
            TabIcon.Visible = false
        end

        PageNameControl.Name = Page_Name .. "_Control"
        PageNameControl.Parent = ControlList
        PageNameControl.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        PageNameControl.BackgroundTransparency = 1.000
        PageNameControl.Size = UDim2.new(1, -10, 0, 25)
        PageNameControl.LayoutOrder = LayoutOrderBut

        Frame.Parent = PageNameControl
        Frame.BackgroundColor3 = getgenv().UIColor["Page Selected Color"]
        Frame.BackgroundTransparency = 1.000
        Frame.Position = UDim2.new(0, 5, 0, 0)
        Frame.Size = UDim2.new(1, -5, 1, 0)

        TabNameCorner.CornerRadius = UDim.new(0, 4)
        TabNameCorner.Name = "TabNameCorner"
        TabNameCorner.Parent = Frame

        Line.Name = "Line"
        Line.Parent = Frame
        Line.AnchorPoint = Vector2.new(0, 0.5)
        Line.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        Line.BackgroundTransparency = 1.000
        Line.Position = UDim2.new(0, 0, 0.5, 0)
        Line.Size = UDim2.new(0, 14, 1, 0)

        InLine.Name = "PageInLine"
        InLine.Parent = Line
        InLine.AnchorPoint = Vector2.new(0.5, 0.5)
        InLine.BorderSizePixel = 0
        InLine.Position = UDim2.new(0.5, 0, 0.5, 0)
        InLine.Size = UDim2.new(1, -10, 1, -10)
        InLine.BackgroundColor3 = getgenv().UIColor["Page Selected Color"]
        InLine.BackgroundTransparency = 1.000

        LineCorner.Name = "LineCorner"
        LineCorner.Parent = InLine

        TabTitleContainer.Name = "TabTitleContainer"
        TabTitleContainer.Parent = Frame
        TabTitleContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        TabTitleContainer.BackgroundTransparency = 1.000

        if IconId and IconId ~= "" then
            TabTitleContainer.Position = UDim2.new(0, 35, 0, 0)
            TabTitleContainer.Size = UDim2.new(1, -35, 1, 0)
        else
            TabTitleContainer.Position = UDim2.new(0, 15, 0, 0)
            TabTitleContainer.Size = UDim2.new(1, -15, 1, 0)
        end

        TabTitle.Name = "GUITextColor"
        TabTitle.Parent = TabTitleContainer
        TabTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        TabTitle.BackgroundTransparency = 1.000
        TabTitle.Size = UDim2.new(1, 0, 1, 0)
        TabTitle.Font = Enum.Font.GothamBold
        TabTitle.Text = Page_Name
        TabTitle.TextSize = 14.000
        TabTitle.TextXAlignment = Enum.TextXAlignment.Left
        TabTitle.TextTruncate = Enum.TextTruncate.AtEnd
        TabTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]

        PageButton.Name = "PageButton"
        PageButton.Parent = PageNameControl
        PageButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        PageButton.BackgroundTransparency = 1.000
        PageButton.Size = UDim2.new(1, 0, 1, 0)
        PageButton.Font = Enum.Font.SourceSans
        PageButton.Text = ""
        PageButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        PageButton.TextSize = 14.000

        PageButton.MouseEnter:Connect(function()
            tweenUI(Frame, { BackgroundTransparency = 0.88 }, "Tween Animation 3 Speed")
        end)
        PageButton.MouseLeave:Connect(function()
            tweenUI(Frame, { BackgroundTransparency = 1 }, "Tween Animation 3 Speed")
        end)

        local PageContainer = Instance.new("Frame")
        local UICorner = Instance.new("UICorner")
        local PageTitle = Instance.new("TextLabel")
        local PageList = Instance.new("ScrollingFrame")
        local Pagelistlayout = Instance.new("UIListLayout")

        local CurrentPage = PageCounter
        PageCounter = PageCounter + 1
        PageContainer.Name = "Page" .. CurrentPage
        PageContainer.Parent = MainPage
        PageContainer.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
        PageContainer.Position = UDim2.new(0, 0, 0, 0)
        PageContainer.Size = UDim2.new(1, 0, 1, 0)
        PageContainer.LayoutOrder = LayoutOrder
        PageContainer.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]

        UICorner.CornerRadius = UDim.new(0, 4)
        UICorner.Parent = PageContainer

        PageTitle.Name = "GUITextColor"
        PageTitle.Parent = PageContainer
        PageTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        PageTitle.BackgroundTransparency = 1.000
        PageTitle.Position = UDim2.new(0, 5, 0, 0)
        PageTitle.Size = UDim2.new(1, 0, 0, 25)
        PageTitle.Font = Enum.Font.GothamBold
        PageTitle.Text = Page_Title
        PageTitle.TextSize = 16.000
        PageTitle.TextXAlignment = Enum.TextXAlignment.Left
        PageTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]

        PageList.Name = "PageList"
        PageList.Parent = PageContainer
        PageList.Active = true
        PageList.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        PageList.BackgroundTransparency = 1.000
        PageList.BorderColor3 = Color3.fromRGB(27, 42, 53)
        PageList.BorderSizePixel = 0
        PageList.Position = UDim2.new(0, 5, 0, 30)
        PageList.Size = UDim2.new(1, -10, 1, -30)
        PageList.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
        PageList.ScrollBarThickness = 5
        PageList.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
        PageList.ScrollingEnabled = true
        PageList.VerticalScrollBarInset = Enum.ScrollBarInset.Always

        Pagelistlayout.Name = "Pagelistlayout"
        Pagelistlayout.Parent = PageList
        Pagelistlayout.SortOrder = Enum.SortOrder.LayoutOrder
        Pagelistlayout.Padding = UDim.new(0, 5)
        Pagelistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PageList.CanvasSize = UDim2.new(0, 0, 0, Pagelistlayout.AbsoluteContentSize.Y)
        end)

        local PageSearch = Instance.new("Frame")
        local PageSearchCorner = Instance.new("UICorner")
        local SearchFrame = Instance.new("Frame")
        local SearchIcon = Instance.new("ImageLabel")
        local SearchButton = Instance.new("TextButton")
        local SearchBox = Instance.new("TextBox")

        PageSearch.Name = "Page Search"
        PageSearch.Parent = PageContainer
        PageSearch.AnchorPoint = Vector2.new(1, 0)
        PageSearch.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
        PageSearch.Position = UDim2.new(1, -5, 0, 5)
        PageSearch.Size = UDim2.new(0, 20, 0, 20)
        PageSearch.ClipsDescendants = true

        PageSearchCorner.CornerRadius = UDim.new(0, 2)
        PageSearchCorner.Name = "PageSearchCorner"
        PageSearchCorner.Parent = PageSearch

        SearchFrame.Name = "SearchFrame"
        SearchFrame.Parent = PageSearch
        SearchFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SearchFrame.BackgroundTransparency = 1.000
        SearchFrame.Size = UDim2.new(0, 20, 0, 20)

        SearchIcon.Name = "SearchIcon"
        SearchIcon.Parent = SearchFrame
        SearchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        SearchIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SearchIcon.BackgroundTransparency = 1.000
        SearchIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
        SearchIcon.Size = UDim2.new(0, 16, 0, 16)
        SearchIcon.Image = "rbxassetid://8154282545"
        SearchIcon.ImageColor3 = getgenv().UIColor["Search Icon Color"]

        SearchButton.Name = "Search Button"
        SearchButton.Parent = SearchFrame
        SearchButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SearchButton.BackgroundTransparency = 1.000
        SearchButton.Size = UDim2.new(1, 0, 1, 0)
        SearchButton.Font = Enum.Font.SourceSans
        SearchButton.Text = ""
        SearchButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        SearchButton.TextSize = 14.000

        SearchBox.Name = "Search Box"
        SearchBox.Parent = PageSearch
        SearchBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SearchBox.BackgroundTransparency = 1.000
        SearchBox.Position = UDim2.new(0, 30, 0, 0)
        SearchBox.Size = UDim2.new(1, -30, 1, 0)
        SearchBox.Font = Enum.Font.GothamBold
        SearchBox.Text = ""
        SearchBox.TextSize = 14.000
        SearchBox.TextXAlignment = Enum.TextXAlignment.Left
        SearchBox.PlaceholderText = "Search Section name"
        SearchBox.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
        SearchBox.TextColor3 = getgenv().UIColor["Text Color"]

        local Openned = false

        SearchButton.MouseEnter:Connect(function()
            TweenService:Create(SearchIcon, TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]), {
                ImageColor3 = getgenv().UIColor["Search Icon Highlight Color"],
            }):Play()
        end)

        SearchButton.MouseLeave:Connect(function()
            TweenService:Create(SearchIcon, TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]), {
                ImageColor3 = getgenv().UIColor["Search Icon Color"],
            }):Play()
        end)

        SearchButton.MouseButton1Click:Connect(function()
            Openned = not Openned
            local size = Openned and UDim2.new(0, 175, 0, 20) or UDim2.new(0, 20, 0, 20)
            game.TweenService
                :Create(PageSearch, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                    Size = size,
                })
                :Play()
        end)

        local function hideOtherFrame()
            for i, v in next, PageList:GetChildren() do
                if not v:IsA("UIListLayout") then
                    v.Visible = false
                end
            end
        end

        local function showFrameName()
            for i, v in pairs(PageList:GetChildren()) do
                if not v:IsA("UIListLayout") then
                    if string.find(string.lower(v.Name), string.lower(SearchBox.Text), 1, true) then
                        v.Visible = true
                    end
                end
            end
        end

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            hideOtherFrame()
            showFrameName()
        end)

        for i, v in pairs(ControlList:GetChildren()) do
            if not (v:IsA("UIListLayout")) then
                if i == 2 then
                    v.Frame.Line.PageInLine.BackgroundTransparency = 0
                end
            end
        end

        PageButton.MouseButton1Click:Connect(function()
            if tostring(UIPage.CurrentPage) == PageContainer.Name then
                return
            end

            for i, v in pairs(MainPage:GetChildren()) do
                if not (v:IsA("UIPageLayout")) and not (v:IsA("UICorner")) then
                    v.Visible = false
                end
            end

            PageContainer.Visible = true
            UIPage:JumpTo(PageContainer)

            do
                local oldFade = PageContainer:FindFirstChild("TabSwitchFade")
                if oldFade then
                    oldFade:Destroy()
                end
                local switchFade = Instance.new("Frame")
                switchFade.Name = "TabSwitchFade"
                switchFade.Parent = PageContainer
                switchFade.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                switchFade.BackgroundTransparency = 0.35
                switchFade.BorderSizePixel = 0
                switchFade.Size = UDim2.new(1, 0, 1, 0)
                switchFade.ZIndex = 999
                local switchFadeCorner = Instance.new("UICorner")
                switchFadeCorner.CornerRadius = UDim.new(0, 4)
                switchFadeCorner.Parent = switchFade
                local switchFadeTween =
                    tweenUI(switchFade, { BackgroundTransparency = 1 }, "Tween Animation 2 Speed", StyleQuad, DirOut)
                if switchFadeTween then
                    switchFadeTween.Completed:Connect(function()
                        if switchFade then
                            switchFade:Destroy()
                        end
                    end)
                end
            end

            for i, v in next, ControlList:GetChildren() do
                if not (v:IsA("UIListLayout")) then
                    if v.Name == Page_Name .. "_Control" then
                        local pageInLine = v.Frame.Line.PageInLine
                        pageInLine.Size = UDim2.new(1, -10, 0, 0)
                        tweenUI(pageInLine, {
                            BackgroundTransparency = 0,
                            Size = UDim2.new(1, -10, 1, -10),
                        }, "Tween Animation 1 Speed", StyleQuart, DirOut)
                    else
                        tweenUI(v.Frame.Line.PageInLine, {
                            BackgroundTransparency = 1,
                        }, "Tween Animation 1 Speed")
                    end
                end
            end
        end)

        local pageFunction = {}

        function pageFunction:AddSection(Section_Name, Toggleable, SectionGap, SectionColor)
            local Toggleable = Toggleable or false
            local Section = Instance.new("Frame")
            local UICorner = Instance.new("UICorner")
            local Topsec = Instance.new("Frame")
            local Sectiontitle = Instance.new("TextLabel")
            local Linesec = Instance.new("Frame")
            local UIGradient = Instance.new("UIGradient")
            local SectionList = Instance.new("UIListLayout")

            Section.Name = Section_Name .. "_Dot"
            Section.Parent = PageList
            Section.Size = UDim2.new(1, -5, 0, 30)
            Section.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
            Section.BackgroundTransparency = 0.25
            Section.ClipsDescendants = true

            local sectionStroke = Instance.new("UIStroke", Section)
            sectionStroke.Color = getgenv().UIColor["Stroke Color"]
            sectionStroke.Thickness = 1

            local sectionGradient = Instance.new("UIGradient", Section)
            sectionGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 46)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(48, 48, 56)),
            })
            sectionGradient.Rotation = 90
            sectionGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(1, 0.15),
            })

            UICorner.CornerRadius = UDim.new(0, 4)
            UICorner.Parent = Section

            Topsec.Name = "Topsec"
            Topsec.Parent = Section
            Topsec.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            Topsec.BackgroundTransparency = 1.000
            Topsec.Size = UDim2.new(1, 0, 0, 30)

            Sectiontitle.Name = "Sectiontitle"
            Sectiontitle.Parent = Topsec
            Sectiontitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            Sectiontitle.BackgroundTransparency = 1.000
            Sectiontitle.Size = UDim2.new(1, 0, 1, 0)
            Sectiontitle.Font = Enum.Font.GothamBold
            Sectiontitle.Text = Section_Name
            Sectiontitle.TextSize = 14.000
            Sectiontitle.TextColor3 = getgenv().UIColor["Section Text Color"]

            Linesec.Name = "Linesec"
            Linesec.Parent = Topsec
            Linesec.AnchorPoint = Vector2.new(0.5, 1)
            Linesec.BorderSizePixel = 0
            Linesec.Position = UDim2.new(0.5, 0, 1, -2)
            Linesec.Size = UDim2.new(1, -10, 0, 2)
            Linesec.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]

            local LineShadow = Instance.new("ImageLabel", Linesec)
            LineShadow.Name = "LineShadow"
            LineShadow.AnchorPoint = Vector2.new(0.5, 0.5)
            LineShadow.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
            LineShadow.BackgroundTransparency = 1
            LineShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
            LineShadow.Size = UDim2.new(1, 8, 1, 8)
            LineShadow.ZIndex = 0
            LineShadow.Image = "rbxassetid://5028857084"
            LineShadow.ImageTransparency = 0.6
            LineShadow.ScaleType = Enum.ScaleType.Slice
            LineShadow.SliceCenter = Rect.new(24, 24, 276, 276)

            UIGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(0.51, 0.02),
                NumberSequenceKeypoint.new(1, 1),
            })
            UIGradient.Parent = Linesec

            SectionList.Name = "SectionList"
            SectionList.Parent = Section
            SectionList.SortOrder = Enum.SortOrder.LayoutOrder
            SectionList.Padding = UDim.new(0, 5)

            local SizeSectionY
            local sectionIsVisible = false
            if Toggleable then
                local VisibilitySectionFrame = Instance.new("Frame")
                local VisibilitySectionFrameCorner = Instance.new("UICorner")
                local visibility = Instance.new("ImageButton")
                local visibility_off = Instance.new("ImageButton")
                local VisibilityButton = Instance.new("TextButton")
                VisibilityButton.Name = "VisibilityButton"
                VisibilityButton.Parent = Topsec
                VisibilityButton.AnchorPoint = Vector2.new(1, 0.5)
                VisibilityButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                VisibilityButton.BackgroundTransparency = 1.000
                VisibilityButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                VisibilityButton.BorderSizePixel = 0
                VisibilityButton.Font = Enum.Font.SourceSans
                VisibilityButton.Text = ""
                VisibilityButton.TextColor3 = Color3.fromRGB(0, 0, 0)
                VisibilityButton.TextSize = 14.000
                VisibilityButton.ZIndex = 2
                VisibilityButton.Position = UDim2.new(1, -5, 0.5, 0)
                VisibilityButton.Size = UDim2.new(0, 20, 0, 20)
                VisibilitySectionFrame.Name = "VisibilitySectionFrame"
                VisibilitySectionFrame.Parent = Topsec
                VisibilitySectionFrame.AnchorPoint = Vector2.new(1, 0.5)
                VisibilitySectionFrame.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
                VisibilitySectionFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                VisibilitySectionFrame.BorderSizePixel = 0
                VisibilitySectionFrame.Position = UDim2.new(1, -5, 0.5, 0)
                VisibilitySectionFrame.Size = UDim2.new(0, 20, 0, 20)
                VisibilitySectionFrameCorner.CornerRadius = UDim.new(0, 4)
                VisibilitySectionFrameCorner.Name = "VisibilitySectionFrameCorner"
                VisibilitySectionFrameCorner.Parent = VisibilitySectionFrame
                visibility.Name = "visibility"
                visibility.Parent = VisibilitySectionFrame
                visibility.AnchorPoint = Vector2.new(0.5, 0.5)
                visibility.BackgroundTransparency = 1.000
                visibility.LayoutOrder = 4
                visibility.Position = UDim2.new(0.5, 0, 0.5, 0)
                visibility.Size = UDim2.new(1, -4, 1, -4)
                visibility.ZIndex = 2
                visibility.Image = "rbxassetid://3926307971"
                visibility.ImageRectOffset = Vector2.new(84, 44)
                visibility.ImageRectSize = Vector2.new(36, 36)
                visibility.ImageTransparency = 1
                visibility_off.Name = "visibility_off"
                visibility_off.Parent = VisibilitySectionFrame
                visibility_off.AnchorPoint = Vector2.new(0.5, 0.5)
                visibility_off.BackgroundTransparency = 1.000
                visibility_off.LayoutOrder = 4
                visibility_off.Position = UDim2.new(0.5, 0, 0.5, 0)
                visibility_off.Size = UDim2.new(1, -4, 1, -4)
                visibility_off.ZIndex = 2
                visibility_off.Image = "rbxassetid://3926307971"
                visibility_off.ImageRectOffset = Vector2.new(564, 44)
                visibility_off.ImageRectSize = Vector2.new(36, 36)
                visibility_off.ImageTransparency = 0
                VisibilityButton.MouseButton1Down:Connect(function()
                    sectionIsVisible = not sectionIsVisible
                    TweenService:Create(visibility, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"] / 2), {
                        ImageTransparency = sectionIsVisible and 0 or 1,
                    }):Play()
                    wait(getgenv().UIColor["Tween Animation 1 Speed"] / 4)
                    TweenService
                        :Create(visibility_off, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"] / 2), {
                            ImageTransparency = sectionIsVisible and 1 or 0,
                        })
                        :Play()
                    TweenService
                        :Create(Section, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
                            Size = UDim2.new(1, -5, 0, (sectionIsVisible and SizeSectionY or 30)),
                        })
                        :Play()
                end)
            end
            if SectionGap then
                local SectionGap = Instance.new("Frame")
                SectionGap.Name = "SectionGap"
                SectionGap.Parent = PageList
                SectionGap.Size = UDim2.new(1, -5, 0, 30)
                SectionGap.ClipsDescendants = true
                SectionGap.Transparency = 1
            end

            SectionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if not Toggleable then
                    Section.Size = UDim2.new(1, -5, 0, SectionList.AbsoluteContentSize.Y + 5)
                end
                SizeSectionY = SectionList.AbsoluteContentSize.Y + 5
                if sectionIsVisible then
                    TweenService:Create(Section, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
                        Size = UDim2.new(1, -5, 0, SizeSectionY),
                    }):Play()
                end
            end)
            local sectionFunction = {}
            function sectionFunction:AddToggle(idk, Setting)
                if type(idk) == "table" and Setting == nil then
                    Setting = idk
                end
                Setting = Setting or {}
                local Title = tostring(Setting.Text or Setting.Title or "")
                if Title == "nil" then
                    Title = ""
                end
                local Desc = Setting.Desc or Setting.Description
                local Default = Setting.Default
                if Default == nil then
                    Default = false
                end
                local Callback = Setting.Callback
                local ToggleFrame = Instance.new("Frame")
                local TogFrame1 = Instance.new("Frame")
                local checkbox = Instance.new("ImageLabel")
                local check = Instance.new("Frame")
                local ToggleDesc = Instance.new("TextLabel")
                local ToggleTitle = Instance.new("TextLabel")
                local ToggleBg = Instance.new("Frame")
                local ToggleCorner = Instance.new("UICorner")
                local ToggleButton = Instance.new("TextButton")
                local ToggleList = Instance.new("UIListLayout")
                local ToggleStroke = Instance.new("UIStroke")
                local ToggleScale = Instance.new("UIScale")

                ToggleFrame.Name = "ToggleFrame"
                ToggleFrame.Parent = Section
                ToggleFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                ToggleFrame.BackgroundTransparency = 1.000

                if Desc and Desc ~= "" then
                    ToggleFrame.AutomaticSize = Enum.AutomaticSize.Y
                    ToggleFrame.Size = UDim2.new(1, 0, 0, 0)
                else
                    ToggleFrame.AutomaticSize = Enum.AutomaticSize.None
                    ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
                end

                TogFrame1.Name = "TogFrame1"
                TogFrame1.Parent = ToggleFrame
                TogFrame1.AnchorPoint = Vector2.new(0.5, 0.5)
                TogFrame1.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                TogFrame1.BackgroundTransparency = 1.000
                TogFrame1.Position = UDim2.new(0.5, 0, 0.5, 0)
                if Desc and Desc ~= "" then
                    TogFrame1.AutomaticSize = Enum.AutomaticSize.Y
                    TogFrame1.Size = UDim2.new(1, -10, 0, 0)
                else
                    TogFrame1.Size = UDim2.new(1, -10, 1, 0)
                end

                checkbox.Name = "checkbox"
                checkbox.Parent = TogFrame1
                checkbox.AnchorPoint = Vector2.new(1, 0.5)
                checkbox.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                checkbox.BackgroundTransparency = 1.000
                checkbox.Position = UDim2.new(1, -5, 0.5, 0)
                checkbox.Size = UDim2.new(0, 20, 0, 20)
                checkbox.Image = "rbxassetid://4552505888"
                checkbox.ImageColor3 = getgenv().UIColor["Toggle Border Color"]

                check.Name = "check"
                check.Parent = checkbox
                check.AnchorPoint = Vector2.new(0.5, 0.5)
                check.BackgroundColor3 = getgenv().UIColor["Toggle Checked Color"]
                check.BorderSizePixel = 0
                check.Position = UDim2.new(0.5, 0, 0.5, 0)

                if Desc and Desc ~= "" then
                    ToggleDesc.Name = "ToggleDesc"
                    ToggleDesc.Parent = TogFrame1
                    ToggleDesc.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    ToggleDesc.BackgroundTransparency = 1.000
                    ToggleDesc.Position = UDim2.new(0, 10, 0, 25)
                    ToggleDesc.Size = UDim2.new(1, -50, 0, 0)
                    ToggleDesc.Font = Enum.Font.Gotham
                    ToggleDesc.Text = Desc
                    ToggleDesc.TextSize = 12.000
                    ToggleDesc.TextWrapped = true
                    ToggleDesc.TextXAlignment = Enum.TextXAlignment.Left
                    ToggleDesc.RichText = true
                    ToggleDesc.AutomaticSize = Enum.AutomaticSize.Y
                    ToggleDesc.TextColor3 = getgenv().UIColor["Toggle Desc Color"]
                end

                ToggleTitle.Name = "TextColor"
                ToggleTitle.Parent = TogFrame1
                ToggleTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                ToggleTitle.BackgroundTransparency = 1.000

                if Desc and Desc ~= "" then
                    ToggleTitle.Position = UDim2.new(0, 10, 0, 5)
                    ToggleTitle.Size = UDim2.new(1, -50, 0, 20)
                else
                    ToggleTitle.Position = UDim2.new(0, 10, 0, 0)
                    ToggleTitle.Size = UDim2.new(1, -50, 1, 0)
                end

                ToggleTitle.Font = Enum.Font.GothamBlack
                ToggleTitle.Text = Title
                ToggleTitle.TextSize = 14.000
                ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
                ToggleTitle.TextYAlignment = Enum.TextYAlignment.Center
                ToggleTitle.RichText = true
                ToggleTitle.TextColor3 = getgenv().UIColor["Text Color"]

                ToggleBg.Name = "Background1"
                ToggleBg.Parent = TogFrame1
                ToggleBg.Size = UDim2.new(1, 0, 1, 0)
                ToggleBg.ZIndex = 0
                ToggleBg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                ToggleBg.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]

                ToggleCorner.CornerRadius = UDim.new(0, 10)
                ToggleCorner.Name = "ToggleCorner"
                ToggleCorner.Parent = ToggleBg

                ToggleScale.Parent = ToggleBg
                ToggleScale.Scale = 1

                ToggleStroke.Parent = ToggleBg
                ToggleStroke.Color = getgenv().UIColor["Stroke Color"]
                ToggleStroke.Transparency = 0.6
                ToggleStroke.Thickness = 1

                ToggleButton.Name = "ToggleButton"
                ToggleButton.Parent = TogFrame1
                ToggleButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                ToggleButton.BackgroundTransparency = 1.000

                ToggleButton.AnchorPoint = Vector2.new(1, 0.5)
                ToggleButton.Size = UDim2.new(0, 30, 0, 30)
                ToggleButton.Position = UDim2.new(1, 0, 0.5, 0)
                ToggleButton.Font = Enum.Font.SourceSans
                ToggleButton.Text = ""
                ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
                ToggleButton.TextSize = 14.000

                ToggleList.Name = "ToggleList"
                ToggleList.Parent = ToggleFrame
                ToggleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
                ToggleList.SortOrder = Enum.SortOrder.LayoutOrder
                ToggleList.VerticalAlignment = Enum.VerticalAlignment.Center
                ToggleList.Padding = UDim.new(0, 5)

                local function ChangeStage(val)
                    local csize = val and UDim2.new(0.6, 0, 0.6, 0) or UDim2.new(0, 0, 0, 0)
                    TweenService:Create(check, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
                        Size = csize,
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                    }):Play()
                end

                ChangeStage(Default)
                if Callback then
                    pcall(Callback, Default)
                end

                local function ButtonClick()
                    Default = not Default
                    ChangeStage(Default)
                    ToggleScale.Scale = 0.96
                    tween(ToggleScale, { Scale = 1 }, animDuration("Tween Animation 1 Speed", 0.16), StyleQuart, DirOut)
                    if Callback then
                        pcall(Callback, Default)
                    end
                end

                ToggleButton.MouseEnter:Connect(function()
                    tweenUI(ToggleStroke, { Transparency = 0.35 }, "Tween Animation 3 Speed")
                end)
                ToggleButton.MouseLeave:Connect(function()
                    tweenUI(ToggleStroke, { Transparency = 0.6 }, "Tween Animation 3 Speed")
                end)
                ToggleButton.MouseButton1Click:Connect(ButtonClick)

                local toggleFunction = {}
                function toggleFunction.SetStage(value)
                    if value ~= Default then
                        ButtonClick()
                    end
                end

                local controlData = {
                    Name = Title,
                    Section = Section,
                    Element = ToggleFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                }
                table.insert(getgenv().AllControls, controlData)

                return flexibleApi(toggleFunction)
            end
            function sectionFunction:AddButton(Setting, Callback)
                Setting = Setting or {}
                local Title = Setting.Title or Setting.Text or ""
                local Desc = Setting.Desc or Setting.Description
                local Callback = Setting.Callback or Setting.Func or function() end

                local Button = Instance.new("Frame")
                local RowBG_1 = Instance.new("Frame")
                local UICorner_1 = Instance.new("UICorner")
                local RowHover_1 = Instance.new("Frame")
                local UICorner_2 = Instance.new("UICorner")
                local TextColor_1 = Instance.new("TextLabel")
                local TextDesc = Instance.new("TextLabel")
                local ClickArea_1 = Instance.new("Frame")
                local UICorner_3 = Instance.new("UICorner")
                local UIGradient_1 = Instance.new("UIGradient")
                local ImageLabel_1 = Instance.new("ImageLabel")
                local Frame_1 = Instance.new("Frame")
                local UICorner_4 = Instance.new("UICorner")
                local UIScale_1 = Instance.new("UIScale")
                local Button_1 = Instance.new("TextButton")

                Button.Name = "Button"
                Button.Parent = Section
                Button.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
                Button.BackgroundTransparency = 1

                if Desc and Desc ~= "" then
                    Button.AutomaticSize = Enum.AutomaticSize.Y
                    Button.Size = UDim2.new(1, 0, 0, 0)
                else
                    Button.Size = UDim2.new(1, 0, 0, 30)
                end

                RowBG_1.Name = "RowBG"
                RowBG_1.Parent = Button
                RowBG_1.AnchorPoint = Vector2.new(0.5, 0.5)
                RowBG_1.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                RowBG_1.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
                RowBG_1.Position = UDim2.new(0.5, 0, 0.5, 0)
                if Desc and Desc ~= "" then
                    RowBG_1.AutomaticSize = Enum.AutomaticSize.Y
                    RowBG_1.Size = UDim2.new(1, -10, 0, 0)
                else
                    RowBG_1.Size = UDim2.new(1, -10, 1, 0)
                end

                UICorner_1.Parent = RowBG_1
                UICorner_1.CornerRadius = UDim.new(0, 10)

                RowHover_1.Name = "RowHover"
                RowHover_1.Parent = RowBG_1
                RowHover_1.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
                RowHover_1.BackgroundTransparency = 1
                RowHover_1.Size = UDim2.new(1, 0, 1, 0)
                RowHover_1.ZIndex = 2

                UICorner_2.Parent = RowHover_1
                UICorner_2.CornerRadius = UDim.new(0, 10)

                TextColor_1.Name = "TextColor"
                TextColor_1.Parent = RowBG_1
                TextColor_1.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
                TextColor_1.BackgroundTransparency = 1

                if Desc and Desc ~= "" then
                    TextColor_1.Position = UDim2.new(0, 12, 0, 5)
                    TextColor_1.Size = UDim2.new(1, -110, 0, 20)
                else
                    TextColor_1.Position = UDim2.new(0, 12, 0, 0)
                    TextColor_1.Size = UDim2.new(1, -110, 1, 0)
                end

                TextColor_1.Font = Enum.Font.GothamBold
                TextColor_1.Text = Title
                TextColor_1.TextColor3 = getgenv().UIColor["GUI Text Color"]
                TextColor_1.TextSize = 14
                TextColor_1.TextStrokeTransparency = 0.85
                TextColor_1.TextXAlignment = Enum.TextXAlignment.Left

                if Desc and Desc ~= "" then
                    TextDesc.Name = "Description"
                    TextDesc.Parent = RowBG_1
                    TextDesc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    TextDesc.BackgroundTransparency = 1
                    TextDesc.Position = UDim2.new(0, 12, 0, 22)
                    TextDesc.Size = UDim2.new(1, -110, 0, 0)
                    TextDesc.AutomaticSize = Enum.AutomaticSize.Y
                    TextDesc.Font = Enum.Font.Gotham
                    TextDesc.Text = Desc
                    TextDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
                    TextDesc.TextSize = 12
                    TextDesc.TextWrapped = true
                    TextDesc.TextXAlignment = Enum.TextXAlignment.Left
                end

                ClickArea_1.Name = "ClickArea"
                ClickArea_1.Parent = RowBG_1
                ClickArea_1.AnchorPoint = Vector2.new(1, 0.5)
                ClickArea_1.BackgroundColor3 = getgenv().UIColor["Button Color"]
                ClickArea_1.Position = UDim2.new(1, -8, 0.5, 0)
                ClickArea_1.Size = UDim2.new(0, 94, 0, 30)
                ClickArea_1.ClipsDescendants = true

                UICorner_3.Parent = ClickArea_1
                UICorner_3.CornerRadius = UDim.new(0, 12)

                UIGradient_1.Parent = ClickArea_1
                UIGradient_1.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(240, 240, 240)),
                    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(230, 230, 230)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 220, 220)),
                })
                UIGradient_1.Rotation = 90

                ImageLabel_1.Parent = ClickArea_1
                ImageLabel_1.AnchorPoint = Vector2.new(0.5, 0.5)
                ImageLabel_1.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
                ImageLabel_1.BackgroundTransparency = 1
                ImageLabel_1.Position = UDim2.new(0.5, 0, 0.5, 0)
                ImageLabel_1.Size = UDim2.new(1, 14, 1, 14)
                ImageLabel_1.ZIndex = 0
                ImageLabel_1.Image = "rbxassetid://5028857084"
                ImageLabel_1.ImageTransparency = 0.7
                ImageLabel_1.ScaleType = Enum.ScaleType.Slice
                ImageLabel_1.SliceCenter = Rect.new(24, 24, 276, 276)

                Frame_1.Parent = ClickArea_1
                Frame_1.AnchorPoint = Vector2.new(0.5, 0)
                Frame_1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Frame_1.BackgroundTransparency = 0.8
                Frame_1.Position = UDim2.new(0.5, 0, 0, 2)
                Frame_1.Size = UDim2.new(1, -6, 0, 10)
                Frame_1.ZIndex = 2

                UICorner_4.Parent = Frame_1
                UICorner_4.CornerRadius = UDim.new(0, 10)

                UIScale_1.Parent = ClickArea_1

                Button_1.Name = "Button"
                Button_1.Parent = ClickArea_1
                Button_1.Active = true
                Button_1.AutoButtonColor = false
                Button_1.BackgroundColor3 = getgenv().UIColor["Button Color"]
                Button_1.BackgroundTransparency = 1
                Button_1.Size = UDim2.new(1, 0, 1, 0)
                Button_1.Font = Enum.Font.GothamBold
                Button_1.Text = "Click"
                Button_1.TextColor3 = Color3.fromRGB(40, 40, 40)
                Button_1.TextSize = 13

                Button_1.MouseEnter:Connect(function()
                    tween(UIScale_1, { Scale = 1.06 }, 0.12, StyleSine, DirOut)
                end)
                Button_1.MouseLeave:Connect(function()
                    tween(UIScale_1, { Scale = 1 }, 0.12, StyleSine, DirOut)
                end)

                Button_1.MouseButton1Click:Connect(function()
                    local ripple = Instance.new("Frame")
                    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
                    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
                    ripple.Size = UDim2.new(0, 0, 0, 0)
                    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ripple.BackgroundTransparency = 0.6
                    ripple.ZIndex = 20
                    ripple.Parent = ClickArea_1

                    local rippleCorner = Instance.new("UICorner")
                    rippleCorner.CornerRadius = UICorner_3.CornerRadius
                    rippleCorner.Parent = ripple

                    local rippleTween = TweenService:Create(
                        ripple,
                        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                        }
                    )
                    rippleTween:Play()
                    rippleTween.Completed:Connect(function()
                        ripple:Destroy()
                    end)

                    pcall(Callback)
                end)

                local f = {}
                function f:SetTitle(vl)
                    TextColor_1.Text = vl
                end

                local controlData = {
                    Name = Title,
                    Section = Section,
                    Element = Button,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                }
                table.insert(getgenv().AllControls, controlData)
                return f
            end

            function sectionFunction:AddLabel(text)
                local Title = ""
                local Description = ""
                if type(text) == "table" then
                    Title = tostring(text.Title or text.Text or "")
                    Description = tostring(text.Description or text.Desc or "")
                else
                    Title = tostring(text or "")
                end

                local LabelFrame = Instance.new("Frame")
                local LabelBG = Instance.new("Frame")
                local UICorner = Instance.new("UICorner")
                local LabelPadding = Instance.new("UIPadding")
                local LabelLayout = Instance.new("UIListLayout")
                local TitleLabel = Instance.new("TextLabel")
                local DescLabel = Instance.new("TextLabel")

                LabelFrame.Name = "LabelFrame"
                LabelFrame.Parent = Section
                LabelFrame.AutomaticSize = Enum.AutomaticSize.Y
                LabelFrame.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
                LabelFrame.BackgroundTransparency = 1
                LabelFrame.Size = UDim2.new(1, 0, 0, 0)

                LabelBG.Name = "LabelBG"
                LabelBG.Parent = LabelFrame
                LabelBG.AnchorPoint = Vector2.new(0.5, 0)
                LabelBG.AutomaticSize = Enum.AutomaticSize.Y
                LabelBG.BackgroundColor3 = getgenv().UIColor["Label Color"]
                LabelBG.BackgroundTransparency = 0.25
                LabelBG.Position = UDim2.new(0.5, 0, 0, 0)
                LabelBG.Size = UDim2.new(1, -10, 0, 0)

                UICorner.Parent = LabelBG
                UICorner.CornerRadius = UDim.new(0, 6)

                LabelPadding.Parent = LabelBG
                LabelPadding.PaddingTop = UDim.new(0, 6)
                LabelPadding.PaddingBottom = UDim.new(0, 6)
                LabelPadding.PaddingLeft = UDim.new(0, 12)
                LabelPadding.PaddingRight = UDim.new(0, 12)

                LabelLayout.Parent = LabelBG
                LabelLayout.SortOrder = Enum.SortOrder.LayoutOrder
                LabelLayout.Padding = UDim.new(0, 2)

                TitleLabel.Name = "TitleLabel"
                TitleLabel.Parent = LabelBG
                TitleLabel.AutomaticSize = Enum.AutomaticSize.Y
                TitleLabel.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.Size = UDim2.new(1, 0, 0, 0)
                TitleLabel.Font = Enum.Font.GothamBold
                TitleLabel.Text = Title
                TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TitleLabel.TextSize = 14
                TitleLabel.TextWrapped = true
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.LayoutOrder = 1

                DescLabel.Name = "DescLabel"
                DescLabel.Parent = LabelBG
                DescLabel.AutomaticSize = Enum.AutomaticSize.Y
                DescLabel.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
                DescLabel.BackgroundTransparency = 1
                DescLabel.Size = UDim2.new(1, 0, 0, 0)
                DescLabel.Font = Enum.Font.GothamMedium
                DescLabel.Text = Description
                DescLabel.TextColor3 = Color3.fromRGB(170, 170, 178)
                DescLabel.TextSize = 13
                DescLabel.TextWrapped = true
                DescLabel.TextXAlignment = Enum.TextXAlignment.Left
                DescLabel.LayoutOrder = 2
                DescLabel.Visible = Description ~= ""

                local labelFunction = {}
                function labelFunction:SetText(newText)
                    TitleLabel.Text = tostring(newText or "")
                end
                function labelFunction:SetTitle(newTitle)
                    TitleLabel.Text = tostring(newTitle or "")
                end
                function labelFunction.SetColor(color)
                    TitleLabel.TextColor3 = color
                end

                function labelFunction:SetDescription(newDesc)
                    newDesc = tostring(newDesc or "")
                    local shouldShow = newDesc ~= ""
                    DescLabel.Text = newDesc
                    if shouldShow and not DescLabel.Visible then
                        DescLabel.TextTransparency = 1
                        DescLabel.Visible = true
                        TweenService
                            :Create(
                                DescLabel,
                                TweenInfo.new(
                                    getgenv().UIColor["Tween Animation 2 Speed"],
                                    Enum.EasingStyle.Quad,
                                    Enum.EasingDirection.Out
                                ),
                                {
                                    TextTransparency = 0,
                                }
                            )
                            :Play()
                    elseif not shouldShow then
                        DescLabel.Visible = false
                    end
                end
                local controlData = {
                    Name = Title,
                    Section = Section,
                    Element = LabelFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                }
                table.insert(getgenv().AllControls, controlData)

                return flexibleApi(labelFunction, { "SetDescription", "SetText", "SetTitle" })
            end
            function sectionFunction:AddDropdownSection(Setting)
                local Title = tostring(Setting.Text or Setting.Title or "")
                if Title == "nil" then
                    Title = ""
                end
                local Search = Setting.Search or false

                local DropdownFrame = Instance.new("Frame")
                local Dropdownbg = Instance.new("Frame")
                local Dropdowncorner = Instance.new("UICorner")
                local Topdrop = Instance.new("Frame")
                local UICorner = Instance.new("UICorner")
                local ImgDrop = Instance.new("ImageLabel")
                local DropdownButton = Instance.new("TextButton")
                local Dropdownlisttt = Instance.new("Frame")
                local DropdownScroll = Instance.new("ScrollingFrame")
                local ScrollContainer = Instance.new("Frame")
                local ScrollContainerList = Instance.new("UIListLayout")

                DropdownFrame.Name = Title .. "DropdownSectionFrame"
                DropdownFrame.Parent = Section
                DropdownFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                DropdownFrame.BackgroundTransparency = 1.000
                DropdownFrame.Position = UDim2.new(0, 0, 0.473684222, 0)
                DropdownFrame.Size = UDim2.new(1, 0, 0, 25)

                Dropdownbg.Name = "Background1"
                Dropdownbg.Parent = DropdownFrame
                Dropdownbg.AnchorPoint = Vector2.new(0.5, 0.5)
                Dropdownbg.Position = UDim2.new(0.5, 0, 0.5, 0)
                Dropdownbg.Size = UDim2.new(1, -10, 1, 0)
                Dropdownbg.ClipsDescendants = true
                Dropdownbg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                Dropdownbg.BackgroundTransparency = 0.25

                Dropdowncorner.CornerRadius = UDim.new(0, 4)
                Dropdowncorner.Name = "Dropdowncorner"
                Dropdowncorner.Parent = Dropdownbg

                Topdrop.Name = "Background2"
                Topdrop.Parent = Dropdownbg
                Topdrop.Size = UDim2.new(1, 0, 0, 25)
                Topdrop.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
                Topdrop.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]

                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Topdrop

                local Dropdowntitle
                if Search then
                    Dropdowntitle = Instance.new("TextBox")
                    Dropdowntitle.PlaceholderText = Title
                    Dropdowntitle.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
                else
                    Dropdowntitle = Instance.new("TextLabel")
                    Dropdowntitle.Text = Title
                end

                Dropdowntitle.Name = "TextColorPlaceholder"
                Dropdowntitle.Parent = Topdrop
                Dropdowntitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                Dropdowntitle.BackgroundTransparency = 1.000
                Dropdowntitle.Position = UDim2.new(0, 10, 0, 0)
                Dropdowntitle.Size = UDim2.new(1, -40, 1, 0)
                Dropdowntitle.Font = Enum.Font.GothamBlack
                Dropdowntitle.TextSize = 14.000
                Dropdowntitle.TextXAlignment = Enum.TextXAlignment.Left
                Dropdowntitle.ClipsDescendants = true
                Dropdowntitle.TextWrapped = false
                Dropdowntitle.TextTruncate = Enum.TextTruncate.AtEnd
                Dropdowntitle.TextColor3 = getgenv().UIColor["Text Color"]

                ImgDrop.Name = "ImgDrop"
                ImgDrop.Parent = Topdrop
                ImgDrop.AnchorPoint = Vector2.new(1, 0.5)
                ImgDrop.BackgroundTransparency = 1.000
                ImgDrop.BorderColor3 = Color3.fromRGB(27, 42, 53)
                ImgDrop.Position = UDim2.new(1, -6, 0.5, 0)
                ImgDrop.Size = UDim2.new(0, 15, 0, 15)
                ImgDrop.Image = "rbxassetid://6954383209"
                ImgDrop.ImageColor3 = getgenv().UIColor["Dropdown Icon Color"]

                DropdownButton.Name = "DropdownButton"
                DropdownButton.Parent = Topdrop
                DropdownButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                DropdownButton.BackgroundTransparency = 1.000
                DropdownButton.Size = Search and UDim2.new(0, 30, 0, 30) or UDim2.new(1, 0, 1, 0)
                DropdownButton.Position = Search and UDim2.new(1, -35, 0, 0) or UDim2.new(0, 0, 0, 0)
                DropdownButton.Font = Enum.Font.GothamBold
                DropdownButton.Text = ""
                DropdownButton.TextColor3 = Color3.fromRGB(230, 230, 230)
                DropdownButton.TextSize = 14.000

                Dropdownlisttt.Name = "Dropdownlisttt"
                Dropdownlisttt.Parent = Dropdownbg
                Dropdownlisttt.BackgroundTransparency = 1.000
                Dropdownlisttt.BorderSizePixel = 0
                Dropdownlisttt.Position = UDim2.new(0, 0, 0, 25)
                Dropdownlisttt.Size = UDim2.new(1, 0, 0, 0)
                Dropdownlisttt.BackgroundColor3 = Color3.fromRGB(230, 230, 230)

                DropdownScroll.Name = "DropdownScroll"
                DropdownScroll.Parent = Dropdownlisttt
                DropdownScroll.Active = true
                DropdownScroll.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                DropdownScroll.BackgroundTransparency = 1.000
                DropdownScroll.BorderSizePixel = 0
                DropdownScroll.Size = UDim2.new(1, 0, 1, 0)
                DropdownScroll.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                DropdownScroll.ScrollBarThickness = 5
                DropdownScroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                DropdownScroll.ScrollingEnabled = true
                DropdownScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always

                ScrollContainer.Name = "ScrollContainer"
                ScrollContainer.Parent = DropdownScroll
                ScrollContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                ScrollContainer.BackgroundTransparency = 1.000
                ScrollContainer.Position = UDim2.new(0, 5, 0, 5)
                ScrollContainer.Size = UDim2.new(1, -15, 1, -5)

                ScrollContainerList.Name = "ScrollContainerList"
                ScrollContainerList.Parent = ScrollContainer
                ScrollContainerList.SortOrder = Enum.SortOrder.LayoutOrder
                ScrollContainerList.Padding = UDim.new(0, 5)

                local InternalSection = Instance.new("Frame")
                InternalSection.Name = "InternalSection"
                InternalSection.Parent = ScrollContainer
                InternalSection.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                InternalSection.BackgroundTransparency = 1.000
                InternalSection.Size = UDim2.new(1, 0, 0, 0)
                InternalSection.AutomaticSize = Enum.AutomaticSize.Y

                local InternalList = Instance.new("UIListLayout")
                InternalList.Name = "InternalList"
                InternalList.Parent = InternalSection
                InternalList.SortOrder = Enum.SortOrder.LayoutOrder
                InternalList.Padding = UDim.new(0, 5)

                local isOpen = false

                local function toggleDropdownSection()
                    isOpen = not isOpen

                    local listsize = isOpen and UDim2.new(1, 0, 0, 200) or UDim2.new(1, 0, 0, 0)
                    local mainsize = isOpen and UDim2.new(1, 0, 0, 230) or UDim2.new(1, 0, 0, 25)
                    local DropCRotation = isOpen and 90 or 0

                    local openDur = animDuration("Tween Animation 2 Speed", 0.22)
                    tween(
                        Dropdownlisttt,
                        { Size = listsize },
                        isOpen and openDur or openDur * 0.75,
                        isOpen and StyleQuart or StyleQuad,
                        isOpen and DirOut or DirIn
                    )
                    tween(
                        DropdownFrame,
                        { Size = mainsize },
                        isOpen and openDur or openDur * 0.75,
                        isOpen and StyleQuart or StyleQuad,
                        isOpen and DirOut or DirIn
                    )
                    tween(
                        ImgDrop,
                        { Rotation = DropCRotation },
                        isOpen and (openDur + 0.06) or openDur * 0.75,
                        isOpen and StyleBack or StyleQuad,
                        isOpen and DirOut or DirIn
                    )
                end

                DropdownButton.MouseButton1Click:Connect(toggleDropdownSection)

                ScrollContainerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 10 + ScrollContainerList.AbsoluteContentSize.Y + 5)
                end)

                InternalList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    local contentHeight = math.min(InternalList.AbsoluteContentSize.Y + 10, 300)
                    local listsize = isOpen and UDim2.new(1, 0, 0, contentHeight) or UDim2.new(1, 0, 0, 0)
                    local mainsize = isOpen and UDim2.new(1, 0, 0, contentHeight + 25) or UDim2.new(1, 0, 0, 25)

                    if isOpen then
                        tweenUI(Dropdownlisttt, { Size = listsize }, "Tween Animation 2 Speed", StyleQuart, DirOut)
                        tweenUI(DropdownFrame, { Size = mainsize }, "Tween Animation 2 Speed", StyleQuart, DirOut)
                    end
                end)

                local dropdownSectionFunction = {}

                function dropdownSectionFunction:AddSlider(Setting)
                    local TitleText = tostring(Setting.Text or Setting.Title) or ""
                    local minValue = tonumber(Setting.Min) or 0
                    local maxValue = tonumber(Setting.Max) or 100
                    if maxValue <= minValue then
                        maxValue = minValue + 1
                    end
                    local Precise = Setting.Precise or false
                    local DefaultValue = tonumber(Setting.Default) or 0
                    local Callback = Setting.Callback
                    local Rounding = tonumber(Setting.Rouding or Setting.Rounding)
                    if Rounding then
                        Rounding = math.floor(Rounding)
                        if Rounding < 0 then
                            Rounding = 0
                        elseif Rounding > 10 then
                            Rounding = 10
                        end
                    end

                    local SliderFrame = Instance.new("Frame")
                    local SliderCorner = Instance.new("UICorner")
                    local SliderBG = Instance.new("Frame")
                    local SliderBGCorner = Instance.new("UICorner")
                    local SliderTitle = Instance.new("TextLabel")
                    local SliderBar = Instance.new("Frame")
                    local SliderButton = Instance.new("TextButton")
                    local SliderBarCorner = Instance.new("UICorner")
                    local Bar = Instance.new("Frame")
                    local BarCorner = Instance.new("UICorner")
                    local Sliderboxframe = Instance.new("Frame")
                    local Sliderbox = Instance.new("UICorner")
                    local Sliderbox_2 = Instance.new("TextBox")

                    SliderFrame.Name = TitleText
                    SliderFrame.Parent = InternalSection
                    SliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    SliderFrame.BackgroundTransparency = 1.000
                    SliderFrame.Size = UDim2.new(1, 0, 0, 50)

                    SliderCorner.CornerRadius = UDim.new(0, 4)
                    SliderCorner.Name = "SliderCorner"
                    SliderCorner.Parent = SliderFrame

                    SliderBG.Name = "Background1"
                    SliderBG.Parent = SliderFrame
                    SliderBG.AnchorPoint = Vector2.new(0.5, 0.5)
                    SliderBG.Position = UDim2.new(0.5, 0, 0.5, 0)
                    SliderBG.Size = UDim2.new(1, -5, 1, 0)
                    SliderBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                    SliderBG.BackgroundTransparency = 0.25

                    SliderBGCorner.CornerRadius = UDim.new(0, 4)
                    SliderBGCorner.Name = "SliderBGCorner"
                    SliderBGCorner.Parent = SliderBG

                    SliderTitle.Name = "TextColor"
                    SliderTitle.Parent = SliderBG
                    SliderTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    SliderTitle.BackgroundTransparency = 1.000
                    SliderTitle.Position = UDim2.new(0, 10, 0, 0)
                    SliderTitle.Size = UDim2.new(0.65, -10, 0, 25)
                    SliderTitle.Font = Enum.Font.GothamBlack
                    SliderTitle.Text = TitleText
                    SliderTitle.TextSize = 14.000
                    SliderTitle.RichText = true
                    SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
                    SliderTitle.TextColor3 = getgenv().UIColor["Text Color"]

                    SliderBar.Name = "SliderBar"
                    SliderBar.Parent = SliderFrame
                    SliderBar.AnchorPoint = Vector2.new(0.5, 0.5)
                    SliderBar.Position = UDim2.new(0.5, 0, 0.5, 14)
                    SliderBar.Size = UDim2.new(0.9, 0, 0, 6)
                    SliderBar.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]

                    SliderButton.Name = "SliderButton"
                    SliderButton.Parent = SliderBar
                    SliderButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    SliderButton.BackgroundTransparency = 1.000
                    SliderButton.AnchorPoint = Vector2.new(0, 0.5)
                    SliderButton.Position = UDim2.new(0, 0, 0.5, 0)
                    SliderButton.Size = UDim2.new(1, 0, 0, 22)
                    SliderButton.Font = Enum.Font.GothamBold
                    SliderButton.Text = ""
                    SliderButton.TextColor3 = Color3.fromRGB(230, 230, 230)
                    SliderButton.TextSize = 14.000

                    SliderBarCorner.CornerRadius = UDim.new(1, 0)
                    SliderBarCorner.Name = "SliderBarCorner"
                    SliderBarCorner.Parent = SliderBar

                    Bar.Name = "Bar"
                    Bar.BorderSizePixel = 0
                    Bar.Parent = SliderBar
                    Bar.Size = UDim2.new(0, 0, 1, 0)

                    Bar.BackgroundColor3 = getgenv().UIColor["Slider Highlight Color"]

                    BarCorner.CornerRadius = UDim.new(1, 0)
                    BarCorner.Name = "BarCorner"
                    BarCorner.Parent = Bar

                    local SliderKnob = Instance.new("Frame")
                    SliderKnob.Name = "SliderKnob"
                    SliderKnob.Parent = SliderBar
                    SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
                    SliderKnob.Position = UDim2.new(0, 0, 0.5, 0)
                    SliderKnob.Size = UDim2.new(0, 14, 0, 14)
                    SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    SliderKnob.BorderSizePixel = 0
                    SliderKnob.ZIndex = 3

                    local SliderKnobCorner = Instance.new("UICorner")
                    SliderKnobCorner.CornerRadius = UDim.new(1, 0)
                    SliderKnobCorner.Parent = SliderKnob

                    local SliderKnobStroke = Instance.new("UIStroke")
                    SliderKnobStroke.Color = getgenv().UIColor["Slider Highlight Color"]
                    SliderKnobStroke.Thickness = 2
                    SliderKnobStroke.Parent = SliderKnob

                    local dropSliderDisplayPct = 0

                    Sliderboxframe.Name = "Background2"
                    Sliderboxframe.Parent = SliderFrame
                    Sliderboxframe.AnchorPoint = Vector2.new(1, 0)
                    Sliderboxframe.Position = UDim2.new(1, -10, 0, 5)
                    Sliderboxframe.Size = UDim2.new(0.25, 0, 0, 25)
                    Sliderboxframe.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]

                    Sliderbox.CornerRadius = UDim.new(0, 4)
                    Sliderbox.Name = "Sliderbox"
                    Sliderbox.Parent = Sliderboxframe

                    Sliderbox_2.Name = "TextColor"
                    Sliderbox_2.Parent = Sliderboxframe
                    Sliderbox_2.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    Sliderbox_2.BackgroundTransparency = 1.000
                    Sliderbox_2.Size = UDim2.new(1, 0, 1, 0)
                    Sliderbox_2.Font = Enum.Font.GothamBold
                    Sliderbox_2.Text = ""
                    Sliderbox_2.TextSize = 14.000
                    Sliderbox_2.TextColor3 = getgenv().UIColor["Text Color"]

                    SliderButton.MouseEnter:Connect(function()
                        TweenService
                            :Create(SliderBar, TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]), {
                                BackgroundColor3 = getgenv().UIColor["Background 2 Color"]:Lerp(
                                    Color3.new(1, 1, 1),
                                    0.18
                                ),
                            })
                            :Play()
                    end)

                    SliderButton.MouseLeave:Connect(function()
                        TweenService
                            :Create(SliderBar, TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]), {
                                BackgroundColor3 = getgenv().UIColor["Background 2 Color"],
                            })
                            :Play()
                    end)

                    local callBackAndSetText = function(val)
                        Sliderbox_2.Text = tostring(val)
                        pcall(Callback, tonumber(val))
                    end
                    if DefaultValue then
                        if DefaultValue <= minValue then
                            DefaultValue = minValue
                        elseif DefaultValue >= maxValue then
                            DefaultValue = maxValue
                        end
                        local initPct = math.clamp(1 - ((maxValue - DefaultValue) / (maxValue - minValue)), 0, 1)
                        Bar.Size = UDim2.new(initPct, 0, 0, 6)
                        dropSliderDisplayPct = initPct
                        SliderKnob.Position = UDim2.new(initPct, 0, 0.5, 0)
                        Sliderbox_2.Text = tostring(DefaultValue)
                    end

                    local function applyDropSectionSlider(input)
                        local barWidth = SliderBar.AbsoluteSize.X
                        if barWidth <= 0 then
                            return
                        end
                        local percentage =
                            math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / barWidth, 0, 1)
                        local value = minValue + (maxValue - minValue) * percentage
                        if Rounding then
                            value = tonumber(string.format("%." .. Rounding .. "f", value))
                        elseif not Precise then
                            value = math.floor(value)
                        end
                        value = math.clamp(value, minValue, maxValue)
                        pcall(callBackAndSetText, value)
                        dropSliderDisplayPct = percentage
                        Bar.Size = UDim2.new(percentage, 0, 1, 0)
                        SliderKnob.Position = UDim2.new(percentage, 0, 0.5, 0)
                    end
                    bindSliderDrag(SliderButton, applyDropSectionSlider, function()
                        tweenUI(
                            SliderKnob,
                            { Size = UDim2.new(0, 18, 0, 18) },
                            "Tween Animation 3 Speed",
                            StyleBack,
                            DirOut
                        )
                    end, function()
                        tweenUI(SliderKnob, { Size = UDim2.new(0, 14, 0, 14) }, "Tween Animation 3 Speed")
                    end)

                    local function GetSliderValue(Value)
                        Value = tonumber(Value) or minValue
                        Value = math.clamp(Value, minValue, maxValue)

                        if Rounding then
                            Value = tonumber(string.format("%." .. Rounding .. "f", Value))
                        elseif not Precise then
                            Value = math.floor(Value)
                        end

                        local percentage = math.clamp((Value - minValue) / (maxValue - minValue), 0, 1)
                        dropSliderDisplayPct = percentage

                        TweenService
                            :Create(Bar, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                                Size = UDim2.new(percentage, 0, 1, 0),
                            })
                            :Play()
                        TweenService
                            :Create(SliderKnob, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                                Position = UDim2.new(percentage, 0, 0.5, 0),
                            })
                            :Play()
                        callBackAndSetText(Value)
                    end

                    Sliderbox_2.FocusLost:Connect(function()
                        GetSliderValue(Sliderbox_2.Text)
                    end)

                    local slider_function = {}
                    function slider_function.SetValue(Value)
                        GetSliderValue(Value)
                    end

                    function slider_function.GetValue()
                        return tonumber(Sliderbox_2.Text) or minValue
                    end

                    return flexibleApi(slider_function, { "SetRange" })
                end

                function dropdownSectionFunction:SetOpen(state)
                    if state ~= isOpen then
                        toggleDropdownSection()
                    end
                end

                function dropdownSectionFunction:GetOpen()
                    return isOpen
                end

                function dropdownSectionFunction:SetTitle(newTitle)
                    if Search then
                        Dropdowntitle.PlaceholderText = newTitle
                    else
                        Dropdowntitle.Text = newTitle
                    end
                end

                local controlData = {
                    Name = Title,
                    Section = Section,
                    Element = DropdownFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                }
                table.insert(getgenv().AllControls, controlData)

                return flexibleApi(dropdownSectionFunction, { "AddSlider", "GetOpen", "SetOpen", "SetTitle" })
            end

            function sectionFunction:AddDropdown(idk, Setting)
                if type(idk) == "table" and Setting == nil then
                    Setting = idk
                end
                Setting = Setting or {}
                local Title = tostring(Setting.Text or Setting.Title or "")
                if Title == "nil" then
                    Title = ""
                end
                local List = Setting.Values or Setting.List or Setting.Options or {}
                local Search = Setting.Search or false
                local Selected = Setting.Selected or Setting.Multi or false
                local Slider = Setting.Slider or false
                local SliderRelease = Setting.SliderRelease or false
                local Default = (function()
                    if Setting.Default then
                        if type(Setting.Default) == "number" then
                            return List[Setting.Default]
                        elseif type(Setting.Default) == "string" then
                            return Setting.Default
                        elseif type(Setting.Default) == "table" then
                            return Setting.Default
                        end
                    end
                    return nil
                end)()
                local Callback = Setting.Callback
                local pairs = Setting.SortPairs or pairs
                local DropdownFrame = Instance.new("Frame")
                local Dropdownbg = Instance.new("Frame")
                local Dropdowncorner = Instance.new("UICorner")
                local Topdrop = Instance.new("Frame")
                local UICorner = Instance.new("UICorner")
                local ImgDrop = Instance.new("ImageLabel")
                local DropdownButton = Instance.new("TextButton")
                local Dropdownlisttt = Instance.new("Frame")
                local DropdownScroll = Instance.new("ScrollingFrame")
                local ScrollContainer = Instance.new("Frame")
                local ScrollContainerList = Instance.new("UIListLayout")
                local dropdownLeave = false
                local Dropdowntitle
                if Search then
                    Dropdowntitle = Instance.new("TextBox")
                else
                    Dropdowntitle = Instance.new("TextLabel")
                end
                DropdownFrame.Name = Title .. "DropdownFrame"
                DropdownFrame.Parent = Section
                DropdownFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                DropdownFrame.BackgroundTransparency = 1.000
                DropdownFrame.Position = UDim2.new(0, 0, 0.473684222, 0)
                DropdownFrame.Size = UDim2.new(1, 0, 0, 25)
                Dropdownbg.Name = "Background1"
                Dropdownbg.Parent = DropdownFrame
                Dropdownbg.AnchorPoint = Vector2.new(0.5, 0.5)
                Dropdownbg.Position = UDim2.new(0.5, 0, 0.5, 0)
                Dropdownbg.Size = UDim2.new(1, -10, 1, 0)
                Dropdownbg.ClipsDescendants = true
                Dropdownbg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                Dropdownbg.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
                Dropdowncorner.CornerRadius = UDim.new(0, 4)
                Dropdowncorner.Name = "Dropdowncorner"
                Dropdowncorner.Parent = Dropdownbg
                Topdrop.Name = "Background2"
                Topdrop.Parent = Dropdownbg
                Topdrop.Size = UDim2.new(1, 0, 0, 25)
                Topdrop.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
                Topdrop.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Topdrop
                Dropdowntitle.Name = "TextColorPlaceholder"
                Dropdowntitle.Parent = Topdrop
                Dropdowntitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                Dropdowntitle.BackgroundTransparency = 1.000
                Dropdowntitle.Position = UDim2.new(0, 10, 0, 0)
                Dropdowntitle.Size = UDim2.new(1, -40, 1, 0)
                Dropdowntitle.Font = Enum.Font.GothamBlack
                Dropdowntitle.Text = ""
                Dropdowntitle.TextSize = 14.000
                Dropdowntitle.TextXAlignment = Enum.TextXAlignment.Left
                Dropdowntitle.ClipsDescendants = true
                local Sel = Instance.new("StringValue", Dropdowntitle)
                Sel.Value = ""
                if Default and table.find(List, Default) then
                    Sel.Value = Default
                end
                if not Selected then
                    if Search then
                        Dropdowntitle.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
                        Dropdowntitle.PlaceholderText = Title .. ": " .. tostring(Default or "")
                    else
                        Dropdowntitle.Text = Title .. ": " .. tostring(Default or "")
                    end
                    if Default and Callback then
                        task.spawn(function()
                            pcall(Callback, Default)
                        end)
                    end
                elseif Search then
                    Dropdowntitle.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
                end
                Dropdowntitle.TextColor3 = getgenv().UIColor["Text Color"]
                Dropdowntitle.AutoLocalize = false
                ImgDrop.Name = "ImgDrop"
                ImgDrop.Parent = Topdrop
                ImgDrop.AnchorPoint = Vector2.new(1, 0.5)
                ImgDrop.BackgroundTransparency = 1.000
                ImgDrop.BorderColor3 = Color3.fromRGB(27, 42, 53)
                ImgDrop.Position = UDim2.new(1, -6, 0.5, 0)
                ImgDrop.Size = UDim2.new(0, 15, 0, 15)
                ImgDrop.Image = "rbxassetid://6954383209"
                ImgDrop.ImageColor3 = getgenv().UIColor["Dropdown Icon Color"]
                DropdownButton.Name = "DropdownButton"
                DropdownButton.Parent = Topdrop
                DropdownButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                DropdownButton.BackgroundTransparency = 1.000
                DropdownButton.Size = Search and UDim2.new(0, 30, 0, 30) or UDim2.new(1, 0, 1, 0)
                DropdownButton.Position = Search and UDim2.new(1, -35, 0, 0) or UDim2.new(0, 0, 0, 0)
                DropdownButton.Font = Enum.Font.GothamBold
                DropdownButton.Text = ""
                DropdownButton.TextColor3 = Color3.fromRGB(230, 230, 230)
                DropdownButton.TextSize = 14.000
                Dropdownlisttt.Name = "Dropdownlisttt"
                Dropdownlisttt.Parent = Dropdownbg
                Dropdownlisttt.BackgroundTransparency = 1.000
                Dropdownlisttt.BorderSizePixel = 0
                Dropdownlisttt.Position = UDim2.new(0, 0, 0, 25)
                Dropdownlisttt.Size = UDim2.new(1, 0, 0, 25)
                Dropdownlisttt.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                DropdownScroll.Name = "DropdownScroll"
                DropdownScroll.Parent = Dropdownlisttt
                DropdownScroll.Active = true
                DropdownScroll.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                DropdownScroll.BackgroundTransparency = 1.000
                DropdownScroll.BorderSizePixel = 0
                DropdownScroll.Size = UDim2.new(1, 0, 1, 0)
                DropdownScroll.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                DropdownScroll.ScrollBarThickness = 5
                DropdownScroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                DropdownScroll.ScrollingEnabled = true
                DropdownScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
                ScrollContainer.Name = "ScrollContainer"
                ScrollContainer.Parent = DropdownScroll
                ScrollContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                ScrollContainer.BackgroundTransparency = 1.000
                ScrollContainer.Position = UDim2.new(0, 5, 0, 5)
                ScrollContainer.Size = UDim2.new(1, -15, 1, -5)
                ScrollContainerList.Name = "ScrollContainerList"
                ScrollContainerList.Parent = ScrollContainer
                ScrollContainerList.SortOrder = Enum.SortOrder.LayoutOrder
                ScrollContainerList.Padding = UDim.new(0, 5)
                ScrollContainerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 10 + ScrollContainerList.AbsoluteContentSize.Y + 5)
                end)
                local isbusy = false
                local found = {}
                local searchtable = {}
                local function edit()
                    for i in pairs(found) do
                        found[i] = nil
                    end
                    for h, l in pairs(ScrollContainer:GetChildren()) do
                        if not l:IsA("UIListLayout") and not l:IsA("UIPadding") and not l:IsA("UIGridLayout") then
                            l.Visible = false
                        end
                    end
                    Dropdowntitle.Text = string.lower(Dropdowntitle.Text)
                end
                local function SearchDropdown()
                    local Results = {}
                    for i, v in pairs(searchtable) do
                        if string.find(v, Dropdowntitle.Text, 1, true) then
                            table.insert(found, v)
                        end
                    end
                    for a, b in pairs(ScrollContainer:GetChildren()) do
                        for c, d in pairs(found) do
                            if d == b.Name then
                                b.Visible = true
                            end
                        end
                    end
                end
                local function clear_object_in_list()
                    local doomed = {}
                    for _, v in ipairs(ScrollContainer:GetChildren()) do
                        if v:IsA("Frame") then
                            table.insert(doomed, v)
                        end
                    end
                    for _, v in ipairs(doomed) do
                        v:Destroy()
                    end
                end
                local ListNew
                local OrderedList = {}
                if Selected then
                    ListNew = {}
                    local defaultLookup = nil
                    if type(Default) == "table" then
                        defaultLookup = {}
                        for defaultKey, defaultValue in pairs(Default) do
                            if type(defaultKey) == "number" then
                                defaultLookup[defaultValue] = true
                            else
                                defaultLookup[defaultKey] = (defaultValue == true)
                            end
                        end
                    end
                    for _, value in ipairs(List) do
                        if defaultLookup then
                            ListNew[value] = (defaultLookup[value] == true)
                        else
                            ListNew[value] = (value == Default)
                        end
                        table.insert(OrderedList, value)
                    end
                    if Default and Callback then
                        if type(Default) == "table" then
                            task.spawn(function()
                                for optionName, optionState in pairs(ListNew) do
                                    if optionState == true then
                                        pcall(Callback, optionName, true)
                                    end
                                end
                            end)
                        else
                            task.spawn(function()
                                pcall(Callback, Default, true)
                            end)
                        end
                    end
                else
                    ListNew = List
                end
                local DROPDOWN_TITLE_BUDGET = 46

                local function getSelectedList()
                    local picked = {}
                    for _, optionName in ipairs(OrderedList) do
                        if ListNew[optionName] == true then
                            table.insert(picked, tostring(optionName))
                        end
                    end
                    return picked
                end

                local function summarizeSelection()
                    if not Selected then
                        return tostring(Sel.Value or "")
                    end

                    local picked = getSelectedList()
                    local total = #picked
                    if total == 0 then
                        return ""
                    end

                    local budget = DROPDOWN_TITLE_BUDGET - #tostring(Title) - 2
                    if budget < 12 then
                        budget = 12
                    end

                    local full = table.concat(picked, ", ")
                    if #full <= budget then
                        return full
                    end

                    local shown = ""
                    local count = 0
                    for index = 1, total do
                        local candidate = (index == 1) and picked[index] or (shown .. ", " .. picked[index])
                        if #candidate > budget - 6 then
                            break
                        end
                        shown = candidate
                        count = index
                    end

                    if shown == "" then
                        local room = budget - 6
                        if room < 1 then
                            room = 1
                        end
                        shown = picked[1]:sub(1, room)
                        count = 1
                    end

                    local remaining = total - count
                    if remaining > 0 then
                        return shown .. " +" .. remaining
                    end
                    return shown
                end

                local function refreshDropdownTitle()
                    local summary = summarizeSelection()
                    local text
                    if tostring(Title) == "" then
                        text = summary
                    else
                        text = tostring(Title) .. ": " .. summary
                    end

                    if Search then
                        if Dropdowntitle.PlaceholderText ~= text then
                            Dropdowntitle.PlaceholderText = text
                        end
                        if summary ~= "" then
                            Dropdowntitle.PlaceholderColor3 = getgenv().UIColor["Text Color"]
                        else
                            Dropdowntitle.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
                        end
                    elseif Dropdowntitle.Text ~= text then
                        Dropdowntitle.Text = text
                    end
                end

                if Selected then
                    refreshDropdownTitle()
                end
                local function refreshlist(SortPairs)
                    pairs = SortPairs or pairs
                    clear_object_in_list()
                    searchtable = {}
                    for i, v in pairs(ListNew) do
                        if Selected then
                            table.insert(searchtable, string.lower(i))
                        elseif Slider then
                            table.insert(searchtable, string.lower(v["Title"]))
                        else
                            table.insert(searchtable, string.lower(tostring(v)))
                        end
                    end
                    if Selected then
                        for _, i in ipairs(OrderedList) do
                            local v = ListNew[i]
                            local SampleItem = Instance.new("Frame")
                            local SampleItemCorner = Instance.new("UICorner")
                            local SampleItemBG = Instance.new("Frame")
                            local SampleItemBGCorner = Instance.new("UICorner")
                            local SampleItemTitle = Instance.new("TextLabel")
                            local SampleItemCheck = Instance.new("ImageButton")
                            local SampleItemButton = Instance.new("TextButton")
                            SampleItem.Name = string.lower(tostring(i))
                            SampleItem.Parent = ScrollContainer
                            SampleItem.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                            SampleItem.BackgroundTransparency = 1.000
                            SampleItem.BorderColor3 = Color3.fromRGB(27, 42, 53)
                            SampleItem.LayoutOrder = 1
                            SampleItem.Position = UDim2.new(0, 0, 0.208333328, 0)
                            SampleItem.Size = UDim2.new(1, 0, 0, 25)
                            SampleItemCorner.CornerRadius = UDim.new(0, 4)
                            SampleItemCorner.Name = "SampleItemCorner"
                            SampleItemCorner.Parent = SampleItem
                            SampleItemBG.Name = "SampleItemBG"
                            SampleItemBG.Parent = SampleItem
                            SampleItemBG.AnchorPoint = Vector2.new(0.5, 0.5)
                            SampleItemBG.BackgroundColor3 = v and getgenv().UIColor["Dropdown Selected Check Color"]
                                or Color3.fromRGB(255, 255, 255)
                            SampleItemBG.BackgroundTransparency = v and 0.5 or 1
                            SampleItemBG.BorderColor3 = Color3.fromRGB(27, 42, 53)
                            SampleItemBG.Position = UDim2.new(0.5, 0, 0.5, 0)
                            SampleItemBG.Size = UDim2.new(1, 0, 1, 0)
                            SampleItemBGCorner.CornerRadius = UDim.new(0, 4)
                            SampleItemBGCorner.Name = "SampleItemBGCorner"
                            SampleItemBGCorner.Parent = SampleItemBG
                            SampleItemTitle.Name = "SampleItemTitle"
                            SampleItemTitle.Parent = SampleItemBG
                            SampleItemTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            SampleItemTitle.BackgroundTransparency = 1.000
                            SampleItemTitle.BorderColor3 = Color3.fromRGB(27, 42, 53)
                            SampleItemTitle.Position = UDim2.new(0, 10, 0, 0)
                            SampleItemTitle.Size = UDim2.new(1, -40, 0, 25)
                            SampleItemTitle.Font = Enum.Font.GothamBlack
                            SampleItemTitle.Text = tostring(i)
                            SampleItemTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                            SampleItemTitle.TextSize = 14.000
                            SampleItemTitle.TextStrokeTransparency = 0.500
                            SampleItemTitle.TextXAlignment = Enum.TextXAlignment.Left
                            SampleItemCheck.Name = "SampleItemCheck"
                            SampleItemCheck.Parent = SampleItemBG
                            SampleItemCheck.AnchorPoint = Vector2.new(1, 0.5)
                            SampleItemCheck.BackgroundTransparency = 1.000
                            SampleItemCheck.Position = UDim2.new(1, 0, 0.5, 0)
                            SampleItemCheck.Size = UDim2.new(0, 25, 0, 25)
                            SampleItemCheck.ZIndex = 2
                            SampleItemCheck.Image = "rbxassetid://3926305904"
                            SampleItemCheck.ImageColor3 = getgenv().UIColor["Dropdown Selected Check Color"]
                            SampleItemCheck.ImageRectOffset = Vector2.new(312, 4)
                            SampleItemCheck.ImageRectSize = Vector2.new(24, 24)
                            SampleItemCheck.ImageTransparency = v and 0 or 1
                            SampleItemButton.Name = "SampleItemButton"
                            SampleItemButton.Parent = SampleItem
                            SampleItemButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            SampleItemButton.BackgroundTransparency = 1.000
                            SampleItemButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                            SampleItemButton.BorderSizePixel = 0
                            SampleItemButton.Size = UDim2.new(1, 0, 1, 0)
                            SampleItemButton.Font = Enum.Font.SourceSans
                            SampleItemButton.TextColor3 = getgenv().UIColor["Text Color"]
                            SampleItemButton.TextSize = 14.000
                            SampleItemButton.TextTransparency = 1.000
                            SampleItemButton.MouseEnter:Connect(function()
                                if v then
                                    return
                                end
                                TweenService
                                    :Create(SampleItemBG, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    })
                                    :Play()
                                TweenService
                                    :Create(SampleItemBG, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
                                        BackgroundTransparency = 0.7,
                                    })
                                    :Play()
                            end)
                            SampleItemButton.MouseLeave:Connect(function()
                                if v then
                                    return
                                end
                                TweenService
                                    :Create(SampleItemBG, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    })
                                    :Play()
                                TweenService
                                    :Create(SampleItemBG, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
                                        BackgroundTransparency = 1,
                                    })
                                    :Play()
                            end)
                            SampleItemButton.MouseButton1Click:Connect(function()
                                v = not v

                                ListNew[i] = v
                                refreshDropdownTitle()

                                pcall(function()
                                    local speed = getgenv().UIColor["Tween Animation 1 Speed"]
                                    TweenService:Create(SampleItemCheck, TweenInfo.new(speed), {
                                        ImageTransparency = v and 0 or 1,
                                    }):Play()
                                    TweenService:Create(SampleItemBG, TweenInfo.new(speed), {
                                        BackgroundColor3 = v and getgenv().UIColor["Dropdown Selected Check Color"]
                                            or Color3.fromRGB(255, 255, 255),
                                    }):Play()
                                    TweenService:Create(SampleItemBG, TweenInfo.new(speed), {
                                        BackgroundTransparency = v and 0.5 or 1,
                                    }):Play()
                                end)

                                if Callback then
                                    pcall(Callback, i, v)
                                end
                            end)
                        end
                    elseif Slider then
                        for i, v in pairs(ListNew) do
                            local TitleText = tostring(v.Title or "")
                            local minValue = tonumber(v.Min) or 0
                            local maxValue = tonumber(v.Max) or 100
                            if maxValue <= minValue then
                                maxValue = minValue + 1
                            end
                            local Precise = v.Precise or false
                            local DefaultValue = tonumber(v.Default) or minValue
                            local SliderFrame = Instance.new("Frame")
                            local SliderCorner = Instance.new("UICorner")
                            local SliderBG = Instance.new("Frame")
                            local SliderBGCorner = Instance.new("UICorner")
                            local SliderTitle = Instance.new("TextLabel")
                            local SliderBar = Instance.new("Frame")
                            local SliderButton = Instance.new("TextButton")
                            local SliderBarCorner = Instance.new("UICorner")
                            local Bar = Instance.new("Frame")
                            local BarCorner = Instance.new("UICorner")
                            local Sliderboxframe = Instance.new("Frame")
                            local Sliderbox = Instance.new("UICorner")
                            local Sliderbox_2 = Instance.new("TextBox")
                            SliderFrame.Name = string.lower(v["Title"])
                            SliderFrame.Parent = ScrollContainer
                            SliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                            SliderFrame.BackgroundTransparency = 1.000
                            SliderFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
                            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
                            SliderCorner.CornerRadius = UDim.new(0, 4)
                            SliderCorner.Name = "SliderCorner"
                            SliderCorner.Parent = SliderFrame
                            SliderBG.Name = "Background1"
                            SliderBG.Parent = SliderFrame
                            SliderBG.AnchorPoint = Vector2.new(0.5, 0.5)
                            SliderBG.Position = UDim2.new(0.5, 0, 0.5, 0)
                            SliderBG.Size = UDim2.new(1, -10, 1, 0)
                            SliderBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                            SliderBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
                            SliderBGCorner.CornerRadius = UDim.new(0, 4)
                            SliderBGCorner.Name = "SliderBGCorner"
                            SliderBGCorner.Parent = SliderBG
                            SliderTitle.Name = "TextColor"
                            SliderTitle.Parent = SliderBG
                            SliderTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                            SliderTitle.BackgroundTransparency = 1.000
                            SliderTitle.Position = UDim2.new(0, 10, 0, 0)
                            SliderTitle.Size = UDim2.new(1, -10, 0, 25)
                            SliderTitle.Font = Enum.Font.GothamBlack
                            SliderTitle.Text = TitleText
                            SliderTitle.TextSize = 14.000
                            SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
                            SliderTitle.TextColor3 = getgenv().UIColor["Text Color"]
                            SliderBar.Name = "SliderBar"
                            SliderBar.Parent = SliderFrame
                            SliderBar.AnchorPoint = Vector2.new(0.5, 0.5)
                            SliderBar.Position = UDim2.new(0.5, 0, 0.5, 14)
                            SliderBar.Size = UDim2.new(1, -20, 0, 6)
                            SliderBar.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
                            SliderButton.Name = "SliderButton "
                            SliderButton.Parent = SliderBar
                            SliderButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                            SliderButton.BackgroundTransparency = 1.000
                            SliderButton.Size = UDim2.new(1, 0, 1, 0)
                            SliderButton.Font = Enum.Font.GothamBold
                            SliderButton.Text = ""
                            SliderButton.TextColor3 = Color3.fromRGB(230, 230, 230)
                            SliderButton.TextSize = 14.000
                            SliderBarCorner.CornerRadius = UDim.new(1, 0)
                            SliderBarCorner.Name = "SliderBarCorner"
                            SliderBarCorner.Parent = SliderBar
                            Bar.Name = "Bar"
                            Bar.BorderSizePixel = 0
                            Bar.Parent = SliderBar
                            Bar.Size = UDim2.new(0, 0, 1, 0)
                            Bar.BackgroundColor3 = getgenv().UIColor["Slider Highlight Color"]
                            BarCorner.CornerRadius = UDim.new(1, 0)
                            BarCorner.Name = "BarCorner"
                            BarCorner.Parent = Bar
                            Sliderboxframe.Name = "Background2"
                            Sliderboxframe.Parent = SliderFrame
                            Sliderboxframe.AnchorPoint = Vector2.new(1, 0)
                            Sliderboxframe.Position = UDim2.new(1, -10, 0, 5)
                            Sliderboxframe.Size = UDim2.new(0, 150, 0, 25)
                            Sliderboxframe.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
                            Sliderbox.CornerRadius = UDim.new(0, 4)
                            Sliderbox.Name = "Sliderbox"
                            Sliderbox.Parent = Sliderboxframe
                            Sliderbox_2.Name = "TextColor"
                            Sliderbox_2.Parent = Sliderboxframe
                            Sliderbox_2.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                            Sliderbox_2.BackgroundTransparency = 1.000
                            Sliderbox_2.Size = UDim2.new(1, 0, 1, 0)
                            Sliderbox_2.Font = Enum.Font.GothamBold
                            Sliderbox_2.Text = ""
                            Sliderbox_2.TextSize = 14.000
                            Sliderbox_2.TextColor3 = getgenv().UIColor["Text Color"]
                            SliderButton.MouseEnter:Connect(function()
                                TweenService
                                    :Create(SliderBar, TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]), {
                                        BackgroundColor3 = getgenv().UIColor["Background 2 Color"]:Lerp(
                                            Color3.new(1, 1, 1),
                                            0.18
                                        ),
                                    })
                                    :Play()
                            end)
                            SliderButton.MouseLeave:Connect(function()
                                TweenService
                                    :Create(SliderBar, TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]), {
                                        BackgroundColor3 = getgenv().UIColor["Background 2 Color"],
                                    })
                                    :Play()
                            end)
                            local callBackAndSetText = function(val)
                                Sliderbox_2.Text = tostring(val)
                                if ListNew[i] then
                                    ListNew[i].Default = val
                                end
                                if Callback then
                                    pcall(Callback, i, val)
                                end
                            end
                            if DefaultValue then
                                if DefaultValue <= minValue then
                                    DefaultValue = minValue
                                elseif DefaultValue >= maxValue then
                                    DefaultValue = maxValue
                                end
                                Bar.Size = UDim2.new(1 - ((maxValue - DefaultValue) / (maxValue - minValue)), 0, 0, 6)
                                callBackAndSetText(DefaultValue)
                            end
                            local function applyDropSliderFromInput(input)
                                local barWidth = SliderBar.AbsoluteSize.X
                                if barWidth <= 0 then
                                    return
                                end
                                local percentage =
                                    math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / barWidth, 0, 1)
                                local value = minValue + (maxValue - minValue) * percentage
                                if Precise then
                                    value = tonumber(string.format("%.1f", value)) or value
                                else
                                    value = math.floor(value + 0.5)
                                end
                                value = math.clamp(value, minValue, maxValue)
                                pcall(callBackAndSetText, value)
                                Bar.Size = UDim2.new(percentage, 0, 1, 0)
                            end
                            bindSliderDrag(SliderButton, applyDropSliderFromInput)

                            local function GetSliderValue(Value)
                                local vnum = tonumber(Value)
                                if not vnum then
                                    return
                                end
                                vnum = math.clamp(vnum, minValue, maxValue)
                                local percentage = (vnum - minValue) / (maxValue - minValue)
                                Bar.Size = UDim2.new(percentage, 0, 1, 0)
                                callBackAndSetText(vnum)
                            end
                            Sliderbox_2.FocusLost:Connect(function()
                                GetSliderValue(Sliderbox_2.Text)
                            end)
                        end
                    else
                        for i, v in pairs(ListNew) do
                            if typeof(v) == "string" then
                                local SampleItem = Instance.new("Frame")
                                local SampleItemCorner = Instance.new("UICorner")
                                local SampleItemBG = Instance.new("Frame")
                                local SampleItemBGCorner = Instance.new("UICorner")
                                local SampleItemTitle = Instance.new("TextLabel")
                                local SampleItemCheck = Instance.new("ImageButton")
                                local SampleItemButton = Instance.new("TextButton")
                                SampleItem.Name = string.lower(v)
                                SampleItem.Parent = ScrollContainer
                                SampleItem.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                                SampleItem.BackgroundTransparency = 1.000
                                SampleItem.BorderColor3 = Color3.fromRGB(27, 42, 53)
                                SampleItem.LayoutOrder = 1
                                SampleItem.Position = UDim2.new(0, 0, 0.208333328, 0)
                                SampleItem.Size = UDim2.new(1, 0, 0, 25)
                                SampleItemCorner.CornerRadius = UDim.new(0, 4)
                                SampleItemCorner.Name = "SampleItemCorner"
                                SampleItemCorner.Parent = SampleItem
                                SampleItemBG.Name = "SampleItemBG"
                                SampleItemBG.Parent = SampleItem
                                SampleItemBG.AnchorPoint = Vector2.new(0.5, 0.5)
                                SampleItemBG.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                SampleItemBG.BackgroundTransparency = 1
                                SampleItemBG.BorderColor3 = Color3.fromRGB(27, 42, 53)
                                SampleItemBG.Position = UDim2.new(0.5, 0, 0.5, 0)
                                SampleItemBG.Size = UDim2.new(1, 0, 1, 0)
                                SampleItemBGCorner.CornerRadius = UDim.new(0, 4)
                                SampleItemBGCorner.Name = "SampleItemBGCorner"
                                SampleItemBGCorner.Parent = SampleItemBG
                                SampleItemTitle.Name = "SampleItemTitle"
                                SampleItemTitle.Parent = SampleItemBG
                                SampleItemTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                SampleItemTitle.BackgroundTransparency = 1.000
                                SampleItemTitle.BorderColor3 = Color3.fromRGB(27, 42, 53)
                                SampleItemTitle.Position = UDim2.new(0, 10, 0, 0)
                                SampleItemTitle.Size = UDim2.new(1, -40, 0, 25)
                                SampleItemTitle.Font = Enum.Font.GothamBlack
                                SampleItemTitle.Text = v
                                SampleItemTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                                SampleItemTitle.TextSize = 14.000
                                SampleItemTitle.TextStrokeTransparency = 0.500
                                SampleItemTitle.TextXAlignment = Enum.TextXAlignment.Left
                                SampleItemCheck.Name = "SampleItemCheck"
                                SampleItemCheck.Parent = SampleItemBG
                                SampleItemCheck.AnchorPoint = Vector2.new(1, 0.5)
                                SampleItemCheck.BackgroundTransparency = 1.000
                                SampleItemCheck.Position = UDim2.new(1, 0, 0.5, 0)
                                SampleItemCheck.Size = UDim2.new(0, 25, 0, 25)
                                SampleItemCheck.ZIndex = 2
                                SampleItemCheck.Image = "rbxassetid://3926305904"
                                SampleItemCheck.ImageColor3 = getgenv().UIColor["Dropdown Selected Check Color"]
                                SampleItemCheck.ImageRectOffset = Vector2.new(312, 4)
                                SampleItemCheck.ImageRectSize = Vector2.new(24, 24)
                                SampleItemCheck.ImageTransparency = 1
                                SampleItemButton.Name = "SampleItemButton"
                                SampleItemButton.Parent = SampleItem
                                SampleItemButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                SampleItemButton.BackgroundTransparency = 1.000
                                SampleItemButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                                SampleItemButton.BorderSizePixel = 0
                                SampleItemButton.Size = UDim2.new(1, 0, 1, 0)
                                SampleItemButton.Font = Enum.Font.SourceSans
                                SampleItemButton.TextColor3 = getgenv().UIColor["Text Color"]
                                SampleItemButton.TextSize = 14.000
                                SampleItemButton.TextTransparency = 1.000
                                SampleItemButton.MouseEnter:Connect(function()
                                    if Sel.Value == tostring(v) then
                                        return
                                    end
                                    TweenService
                                        :Create(
                                            SampleItemBG,
                                            TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),
                                            {
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            }
                                        )
                                        :Play()
                                    TweenService
                                        :Create(
                                            SampleItemBG,
                                            TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),
                                            {
                                                BackgroundTransparency = 0.7,
                                            }
                                        )
                                        :Play()
                                end)
                                SampleItemButton.MouseLeave:Connect(function()
                                    if Sel.Value == tostring(v) then
                                        return
                                    end
                                    TweenService
                                        :Create(
                                            SampleItemBG,
                                            TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),
                                            {
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            }
                                        )
                                        :Play()
                                    TweenService
                                        :Create(
                                            SampleItemBG,
                                            TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),
                                            {
                                                BackgroundTransparency = 1,
                                            }
                                        )
                                        :Play()
                                end)
                                SampleItemButton.MouseButton1Click:Connect(function()
                                    Sel.Value = tostring(v)
                                    if Search then
                                        Dropdowntitle.PlaceholderText = tostring(Title) .. ": " .. tostring(v)
                                    else
                                        Dropdowntitle.Text = tostring(Title) .. ": " .. tostring(v)
                                    end
                                    TweenService
                                        :Create(
                                            SampleItemBG,
                                            TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),
                                            {
                                                BackgroundColor3 = getgenv().UIColor["Dropdown Selected Check Color"],
                                            }
                                        )
                                        :Play()
                                    TweenService
                                        :Create(
                                            SampleItemBG,
                                            TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),
                                            {
                                                BackgroundTransparency = 0.5,
                                            }
                                        )
                                        :Play()
                                    if Callback then
                                        pcall(Callback, v)
                                    end
                                    if Search then
                                        Dropdowntitle.Text = ""
                                    end
                                    refreshlist()
                                end)
                                if Sel.Value == tostring(v) then
                                    SampleItemBG.BackgroundTransparency = 0.5
                                    SampleItemBG.BackgroundColor3 = getgenv().UIColor["Dropdown Selected Check Color"]
                                    SampleItem.LayoutOrder = 0
                                end
                            end
                        end
                    end
                    if Selected then
                        refreshDropdownTitle()
                    end
                end
                if Search then
                    Dropdowntitle:GetPropertyChangedSignal("Text"):Connect(function()
                        edit()
                        SearchDropdown()
                    end)
                end
                if Slider then
                    Dropdowntitle.Text = ""
                    Dropdowntitle.PlaceholderText = Title .. ": "
                elseif Selected then
                    refreshDropdownTitle()
                else
                    local shown = (typeof(Default) == "table") and "" or tostring(Default or "")
                    if Search then
                        Dropdowntitle.PlaceholderText = Title .. ": " .. shown
                    else
                        Dropdowntitle.Text = Title .. ": " .. shown
                    end
                end
                DropdownButton.MouseButton1Click:Connect(function()
                    refreshlist()
                    isbusy = not isbusy
                    local listsize = isbusy and UDim2.new(1, 0, 0, 170) or UDim2.new(1, 0, 0, 0)
                    local mainsize = isbusy and UDim2.new(1, 0, 0, 200) or UDim2.new(1, 0, 0, 25)
                    local DropCRotation = isbusy and 90 or 0

                    local openDur = animDuration("Tween Animation 2 Speed", 0.22)
                    tween(
                        Dropdownlisttt,
                        { Size = listsize },
                        isbusy and openDur or openDur * 0.75,
                        isbusy and StyleQuart or StyleQuad,
                        isbusy and DirOut or DirIn
                    )
                    tween(
                        DropdownFrame,
                        { Size = mainsize },
                        isbusy and openDur or openDur * 0.75,
                        isbusy and StyleQuart or StyleQuad,
                        isbusy and DirOut or DirIn
                    )
                    tween(
                        ImgDrop,
                        { Rotation = DropCRotation },
                        isbusy and (openDur + 0.06) or openDur * 0.75,
                        isbusy and StyleBack or StyleQuad,
                        isbusy and DirOut or DirIn
                    )
                end)
                local dropdownFunction = {
                    rf = refreshlist,
                }
                function dropdownFunction:ClearText(v)
                    if v ~= nil then
                        local text = tostring(Title) .. ": " .. tostring(v)
                        if Search then
                            Dropdowntitle.PlaceholderText = text
                        else
                            Dropdowntitle.Text = text
                        end
                        return
                    end

                    if not Selected then
                        Sel.Value = ""
                    end
                    refreshDropdownTitle()
                end

                function dropdownFunction:GetNewList(List)
                    List = List or {}
                    Sel.Value = ""
                    found = {}
                    searchtable = {}
                    isbusy = false
                    local listsize = UDim2.new(1, 0, 0, 0)
                    local mainsize = UDim2.new(1, 0, 0, 25)
                    local DropCRotation = 0

                    local closeDur = animDuration("Tween Animation 2 Speed", 0.22) * 0.75
                    tween(Dropdownlisttt, { Size = listsize }, closeDur, StyleQuad, DirIn)
                    tween(DropdownFrame, { Size = mainsize }, closeDur, StyleQuad, DirIn)
                    tween(ImgDrop, { Rotation = DropCRotation }, closeDur, StyleQuad, DirIn)

                    if Selected then
                        local isArray = (#List > 0) and (List[1] ~= nil)
                        local newListNew = {}
                        local newOrdered = {}
                        if isArray then
                            for _, name in ipairs(List) do
                                newListNew[name] = false
                                table.insert(newOrdered, name)
                            end
                        else
                            for name, checked in pairs(List) do
                                newListNew[name] = checked and true or false
                                table.insert(newOrdered, name)
                            end
                        end
                        ListNew = newListNew
                        OrderedList = newOrdered
                    else
                        ListNew = {}
                        ListNew = List
                    end
                    refreshlist()
                    refreshDropdownTitle()
                end
                function dropdownFunction:SetValue(value)
                    if value == nil then
                        return
                    end

                    if not Selected then
                        local match = nil
                        for _, item in ipairs(ListNew) do
                            if tostring(item) == tostring(value) then
                                match = item
                                break
                            end
                        end
                        value = match and tostring(match) or nil
                        if value and table.find(ListNew, match) then
                            Sel.Value = value
                            refreshDropdownTitle()
                            if Callback then
                                pcall(Callback, value)
                            end
                            refreshlist()
                        end
                        return
                    end

                    local function findKey(name)
                        if ListNew[name] ~= nil then
                            return name
                        end
                        local wanted = tostring(name)
                        for key in next, ListNew do
                            if tostring(key) == wanted then
                                return key
                            end
                        end
                        return nil
                    end

                    local function applyOne(name)
                        local key = findKey(name)
                        if key ~= nil then
                            ListNew[key] = true
                            if Callback then
                                pcall(Callback, key, true)
                            end
                            return true
                        end
                        return false
                    end

                    local changed = false
                    if type(value) == "table" then
                        for name in next, ListNew do
                            ListNew[name] = false
                        end
                        for _, name in ipairs(value) do
                            if applyOne(name) then
                                changed = true
                            end
                        end
                    else
                        changed = applyOne(value)
                    end

                    if changed then
                        refreshlist()
                    end
                    refreshDropdownTitle()
                end

                function dropdownFunction:GetValue()
                    if not Selected then
                        return Sel.Value
                    else
                        local result = {}
                        for key, val in pairs(ListNew) do
                            if val == true then
                                table.insert(result, key)
                            end
                        end
                        return result
                    end
                end
                local controlData = {
                    Name = Title,
                    Section = Section,
                    Element = DropdownFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                    SetValue = dropdownFunction.SetValue,
                    GetValue = dropdownFunction.GetValue,
                }
                table.insert(getgenv().AllControls, controlData)

                return flexibleApi(dropdownFunction, { "ClearText", "GetNewList", "GetValue", "SetValue" })
            end

            function sectionFunction:AddKeyBind(Setting, Callback)
                Setting = Setting or {}
                local TitleText = tostring(Setting.Title or Setting.Text or "")
                if TitleText == "nil" then
                    TitleText = ""
                end
                local Default = Setting.Default or Setting.Key or "F"
                local Mode = Setting.Mode or "Toggle"
                local Callback = Setting.Callback or Callback or function() end

                local function GetKeyString(key)
                    local keyStr = tostring(key)
                    keyStr = keyStr:gsub("Enum.UserInputType.", "")
                    keyStr = keyStr:gsub("Enum.KeyCode.", "")
                    return keyStr
                end

                local CurrentKey = GetKeyString(Default)
                local CurrentMode = Mode
                local Picking = false
                local ToggleState = false
                local HoldActive = false

                local BindFrame = Instance.new("Frame")
                local BindCorner = Instance.new("UICorner")
                local BindBG = Instance.new("Frame")
                local ButtonCorner = Instance.new("UICorner")
                local BindButtonTitle = Instance.new("TextLabel")
                local BindCor = Instance.new("Frame")
                local ButtonCorner_2 = Instance.new("UICorner")
                local Bindkey = Instance.new("TextButton")

                BindFrame.Name = TitleText .. "bguvl"
                BindFrame.Parent = Section
                BindFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                BindFrame.BackgroundTransparency = 1.000
                BindFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
                BindFrame.Size = UDim2.new(1, 0, 0, 35)

                BindCorner.CornerRadius = UDim.new(0, 4)
                BindCorner.Name = "BindCorner"
                BindCorner.Parent = BindFrame

                BindBG.Name = "Background1"
                BindBG.Parent = BindFrame
                BindBG.AnchorPoint = Vector2.new(0.5, 0.5)
                BindBG.Position = UDim2.new(0.5, 0, 0.5, 0)
                BindBG.Size = UDim2.new(1, -10, 1, 0)
                BindBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                BindBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]

                ButtonCorner.CornerRadius = UDim.new(0, 4)
                ButtonCorner.Name = "ButtonCorner"
                ButtonCorner.Parent = BindBG

                BindButtonTitle.Name = "TextColor"
                BindButtonTitle.Parent = BindBG
                BindButtonTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                BindButtonTitle.BackgroundTransparency = 1.000
                BindButtonTitle.Position = UDim2.new(0, 10, 0, 0)
                BindButtonTitle.Size = UDim2.new(1, -10, 1, 0)
                BindButtonTitle.Font = Enum.Font.GothamBlack
                BindButtonTitle.Text = TitleText
                BindButtonTitle.TextSize = 14.000
                BindButtonTitle.TextXAlignment = Enum.TextXAlignment.Left
                BindButtonTitle.TextColor3 = getgenv().UIColor["Text Color"]

                BindCor.Name = "Background2"
                BindCor.Parent = BindBG
                BindCor.AnchorPoint = Vector2.new(1, 0.5)
                BindCor.Position = UDim2.new(1, -5, 0.5, 0)
                BindCor.Size = UDim2.new(0, 150, 0, 25)
                BindCor.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]

                ButtonCorner_2.CornerRadius = UDim.new(0, 4)
                ButtonCorner_2.Name = "ButtonCorner"
                ButtonCorner_2.Parent = BindCor

                Bindkey.Name = "Bindkey"
                Bindkey.Parent = BindCor
                Bindkey.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                Bindkey.BackgroundTransparency = 1.000
                Bindkey.Size = UDim2.new(1, 0, 1, 0)
                Bindkey.Font = Enum.Font.GothamBold
                Bindkey.Text = CurrentKey
                Bindkey.TextSize = 14.000
                Bindkey.TextColor3 = getgenv().UIColor["Text Color"]

                local function setPickingVisual(active)
                    TweenService
                        :Create(BindCor, TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]), {
                            BackgroundColor3 = active and getgenv().UIColor["Slider Highlight Color"]
                                or getgenv().UIColor["Background 2 Color"],
                        })
                        :Play()
                end

                Bindkey.MouseButton1Click:Connect(function()
                    if Picking then
                        return
                    end

                    Picking = true
                    Bindkey.Text = "..."
                    setPickingVisual(true)

                    local Connection, EscConnection
                    local finished = false

                    local function stopPicking(newKey)
                        if finished then
                            return
                        end
                        finished = true
                        Picking = false
                        setPickingVisual(false)
                        if newKey then
                            CurrentKey = newKey
                        end
                        Bindkey.Text = CurrentKey
                        if Connection then
                            Connection:Disconnect()
                        end
                        if EscConnection then
                            EscConnection:Disconnect()
                        end
                    end

                    Connection = uis.InputBegan:Connect(function(input)
                        if not Picking or finished then
                            return
                        end
                        local Key

                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Escape then
                                stopPicking(nil)
                                return
                            end
                            Key = input.KeyCode.Name
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Key = "MouseLeft"
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                            Key = "MouseRight"
                        end

                        if Key then
                            stopPicking(Key)
                        end
                    end)

                    task.delay(8, function()
                        stopPicking(nil)
                    end)
                end)

                uis.InputBegan:Connect(function(input, gpe)
                    if gpe or Picking then
                        return
                    end
                    if uis:GetFocusedTextBox() then
                        return
                    end

                    local pressedKey
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        pressedKey = input.KeyCode.Name
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        pressedKey = "MouseLeft"
                    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                        pressedKey = "MouseRight"
                    end

                    if pressedKey == CurrentKey then
                        if CurrentMode == "Toggle" then
                            ToggleState = not ToggleState
                            pcall(Callback, ToggleState)
                        elseif CurrentMode == "Hold" then
                            HoldActive = true
                            pcall(Callback, true)
                        end
                    end
                end)

                uis.InputEnded:Connect(function(input)
                    if Picking then
                        return
                    end
                    if uis:GetFocusedTextBox() then
                        return
                    end

                    local releasedKey
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        releasedKey = input.KeyCode.Name
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        releasedKey = "MouseLeft"
                    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                        releasedKey = "MouseRight"
                    end

                    if releasedKey == CurrentKey and CurrentMode == "Hold" and HoldActive then
                        HoldActive = false
                        pcall(Callback, false)
                    end
                end)

                local controlData = {
                    Name = TitleText,
                    Section = Section,
                    Element = BindFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                }
                table.insert(getgenv().AllControls, controlData)

                local keybindFunction = {}

                function keybindFunction:Set(newKey)
                    CurrentKey = GetKeyString(newKey)
                    Bindkey.Text = CurrentKey
                end

                function keybindFunction:Get()
                    return CurrentKey
                end

                function keybindFunction:SetMode(mode)
                    if mode == "Hold" or mode == "Toggle" then
                        CurrentMode = mode
                        ToggleState = false
                        HoldActive = false
                    end
                end

                function keybindFunction:GetMode()
                    return CurrentMode
                end

                function keybindFunction:GetState()
                    if CurrentMode == "Toggle" then
                        return ToggleState
                    elseif CurrentMode == "Hold" then
                        return HoldActive
                    end
                    return false
                end

                return flexibleApi(keybindFunction, { "Get", "GetMode", "GetState", "Set", "SetMode" })
            end
            function sectionFunction:AddInput(idk, Setting)
                if type(idk) == "table" and Setting == nil then
                    Setting = idk
                end
                Setting = Setting or {}
                local TitleText = tostring(Setting.Text or Setting.Title or "")
                if TitleText == "nil" then
                    TitleText = ""
                end
                local Desc = Setting.Desc or Setting.Description
                local Placeholder = Setting.Placeholder ~= nil and tostring(Setting.Placeholder) or ""
                local Default = Setting.Default or false
                local Number_Only = Setting.Numeric or false
                local Callback = Setting.Callback

                local BoxFrame = Instance.new("Frame")
                local BoxCorner = Instance.new("UICorner")
                local BoxBG = Instance.new("Frame")
                local ButtonCorner = Instance.new("UICorner")
                local Boxtitle = Instance.new("TextLabel")
                local BoxCor = Instance.new("Frame")
                local ButtonCorner_2 = Instance.new("UICorner")
                local Boxxx = Instance.new("TextBox")
                local Lineeeee = Instance.new("Frame")
                local UICorner = Instance.new("UICorner")

                BoxFrame.Name = "BoxFrame"
                BoxFrame.Parent = Section
                BoxFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                BoxFrame.BackgroundTransparency = 1.000

                if Desc and Desc ~= "" then
                    BoxFrame.AutomaticSize = Enum.AutomaticSize.Y
                    BoxFrame.Size = UDim2.new(1, 0, 0, 0)
                else
                    BoxFrame.Size = UDim2.new(1, 0, 0, 40)
                end

                BoxCorner.CornerRadius = UDim.new(0, 4)
                BoxCorner.Name = "BoxCorner"
                BoxCorner.Parent = BoxFrame

                BoxBG.Name = "Background1"
                BoxBG.Parent = BoxFrame
                BoxBG.AnchorPoint = Vector2.new(0.5, 0.5)
                BoxBG.Position = UDim2.new(0.5, 0, 0.5, 0)
                if Desc and Desc ~= "" then
                    BoxBG.AutomaticSize = Enum.AutomaticSize.Y
                    BoxBG.Size = UDim2.new(1, -10, 0, 0)
                else
                    BoxBG.Size = UDim2.new(1, -10, 1, 0)
                end
                BoxBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                BoxBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]

                ButtonCorner.CornerRadius = UDim.new(0, 4)
                ButtonCorner.Name = "ButtonCorner"
                ButtonCorner.Parent = BoxBG

                Boxtitle.Name = "TextColor"
                Boxtitle.Parent = BoxBG
                Boxtitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                Boxtitle.BackgroundTransparency = 1.000

                if Desc and Desc ~= "" then
                    Boxtitle.Position = UDim2.new(0, 10, 0, 5)
                    Boxtitle.Size = UDim2.new(1, -10, 0, 20)
                else
                    Boxtitle.Position = UDim2.new(0, 10, 0, 0)
                    Boxtitle.Size = UDim2.new(0.5, 0, 1, 0)
                end

                Boxtitle.Font = Enum.Font.GothamBlack
                Boxtitle.Text = TitleText
                Boxtitle.TextSize = 14.000
                Boxtitle.TextXAlignment = Enum.TextXAlignment.Left
                Boxtitle.TextColor3 = getgenv().UIColor["Text Color"]

                if Desc and Desc ~= "" then
                    local TextDesc = Instance.new("TextLabel")
                    TextDesc.Parent = BoxBG
                    TextDesc.BackgroundTransparency = 1
                    TextDesc.Position = UDim2.new(0, 10, 0, 25)
                    TextDesc.Size = UDim2.new(1, -20, 0, 0)
                    TextDesc.AutomaticSize = Enum.AutomaticSize.Y
                    TextDesc.Font = Enum.Font.Gotham
                    TextDesc.Text = Desc
                    TextDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
                    TextDesc.TextSize = 12
                    TextDesc.TextWrapped = true
                    TextDesc.TextXAlignment = Enum.TextXAlignment.Left
                end

                BoxCor.Name = "Background2"
                BoxCor.Parent = BoxBG
                BoxCor.AnchorPoint = Vector2.new(1, 0.5)
                BoxCor.ClipsDescendants = true

                BoxCor.Position = UDim2.new(1, -5, 0.5, 0)
                BoxCor.Size = UDim2.new(0, 120, 0, 25)

                BoxCor.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]

                ButtonCorner_2.CornerRadius = UDim.new(0, 4)
                ButtonCorner_2.Name = "ButtonCorner"
                ButtonCorner_2.Parent = BoxCor

                Boxxx.Name = "TextColorPlaceholder"
                Boxxx.Parent = BoxCor
                Boxxx.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                Boxxx.BackgroundTransparency = 1.000
                Boxxx.Position = UDim2.new(0, 5, 0, 0)
                Boxxx.Size = UDim2.new(1, -5, 1, 0)
                Boxxx.Font = Enum.Font.GothamBold
                Boxxx.PlaceholderText = Placeholder
                Boxxx.Text = ""
                Boxxx.TextSize = 14.000
                Boxxx.TextXAlignment = Enum.TextXAlignment.Left
                Boxxx.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
                Boxxx.TextColor3 = getgenv().UIColor["Text Color"]
                Boxxx.ClearTextOnFocus = false

                Lineeeee.Name = "TextNSBoxLineeeee"
                Lineeeee.Parent = BoxCor
                Lineeeee.BackgroundTransparency = 1.000
                Lineeeee.Position = UDim2.new(0, 0, 1, -2)
                Lineeeee.Size = UDim2.new(1, 0, 0, 6)
                Lineeeee.BackgroundColor3 = getgenv().UIColor["Box Highlight Color"]

                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Lineeeee

                Boxxx.Focused:Connect(function()
                    TweenService:Create(Lineeeee, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                        BackgroundTransparency = 0,
                    }):Play()
                end)

                if Number_Only then
                    Boxxx:GetPropertyChangedSignal("Text"):Connect(function()
                        local txt = Boxxx.Text
                        if txt == "" or txt == "-" or txt == "." or txt == "-." then
                            return
                        end
                        if not tonumber(txt) then
                            Boxxx.Text = txt:gsub("[^%d%.%-]", "")
                        end
                    end)
                end

                Boxxx.FocusLost:Connect(function()
                    TweenService:Create(Lineeeee, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                        BackgroundTransparency = 1,
                    }):Play()
                    if Callback then
                        pcall(Callback, Boxxx.Text)
                    end
                end)

                local textbox_function = {}
                if Default ~= false and Default ~= nil then
                    Boxxx.Text = tostring(Default)
                    task.spawn(function()
                        if Callback then
                            pcall(Callback, Boxxx.Text)
                        end
                    end)
                end
                function textbox_function.SetValue(Value)
                    Boxxx.Text = tostring(Value)
                    if Callback then
                        pcall(Callback, Boxxx.Text)
                    end
                end

                local controlData = {
                    Name = TitleText,
                    Section = Section,
                    Element = BoxFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                }
                table.insert(getgenv().AllControls, controlData)
                return flexibleApi(textbox_function)
            end

            function sectionFunction:AddTextbox(idk, Setting)
                if type(idk) == "table" and Setting == nil then
                    Setting = idk
                end
                Setting = Setting or {}
                local TitleText = tostring(Setting.Text or Setting.Title or "")
                if TitleText == "nil" then
                    TitleText = ""
                end
                local Desc = Setting.Desc or Setting.Description
                local Placeholder = Setting.Placeholder ~= nil and tostring(Setting.Placeholder) or ""
                local Default = Setting.Default
                local Number_Only = Setting.Numeric or false
                local ClearOnFocus = Setting.ClearTextOnFocus or false
                local Callback = Setting.Callback

                local hasDesc = Desc ~= nil and Desc ~= ""
                local titleHeight = 20
                local descHeight = hasDesc and 16 or 0
                local boxHeight = 30
                local totalHeight = 8 + titleHeight + descHeight + 4 + boxHeight + 8

                local TextboxFrame = Instance.new("Frame")
                local TextboxBG = Instance.new("Frame")
                local TextboxBGCorner = Instance.new("UICorner")
                local TextboxTitle = Instance.new("TextLabel")
                local TextboxArea = Instance.new("Frame")
                local TextboxAreaCorner = Instance.new("UICorner")
                local TextboxStroke = Instance.new("UIStroke")
                local TextboxInput = Instance.new("TextBox")

                TextboxFrame.Name = "TextboxFrame"
                TextboxFrame.Parent = Section
                TextboxFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                TextboxFrame.BackgroundTransparency = 1.000
                TextboxFrame.Size = UDim2.new(1, 0, 0, totalHeight)

                TextboxBG.Name = "Background1"
                TextboxBG.Parent = TextboxFrame
                TextboxBG.AnchorPoint = Vector2.new(0.5, 0.5)
                TextboxBG.Position = UDim2.new(0.5, 0, 0.5, 0)
                TextboxBG.Size = UDim2.new(1, -10, 1, 0)
                TextboxBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                TextboxBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]

                TextboxBGCorner.CornerRadius = UDim.new(0, 4)
                TextboxBGCorner.Parent = TextboxBG

                TextboxTitle.Name = "TextColor"
                TextboxTitle.Parent = TextboxBG
                TextboxTitle.BackgroundTransparency = 1.000
                TextboxTitle.Position = UDim2.new(0, 10, 0, 8)
                TextboxTitle.Size = UDim2.new(1, -20, 0, titleHeight)
                TextboxTitle.Font = Enum.Font.GothamBlack
                TextboxTitle.Text = TitleText
                TextboxTitle.TextSize = 14.000
                TextboxTitle.TextXAlignment = Enum.TextXAlignment.Left
                TextboxTitle.TextYAlignment = Enum.TextYAlignment.Center
                TextboxTitle.RichText = true
                TextboxTitle.TextColor3 = getgenv().UIColor["Text Color"]

                if hasDesc then
                    local TextboxDesc = Instance.new("TextLabel")
                    TextboxDesc.Name = "TextboxDesc"
                    TextboxDesc.Parent = TextboxBG
                    TextboxDesc.BackgroundTransparency = 1
                    TextboxDesc.Position = UDim2.new(0, 10, 0, 8 + titleHeight)
                    TextboxDesc.Size = UDim2.new(1, -20, 0, descHeight)
                    TextboxDesc.Font = Enum.Font.Gotham
                    TextboxDesc.Text = Desc
                    TextboxDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
                    TextboxDesc.TextSize = 12
                    TextboxDesc.TextXAlignment = Enum.TextXAlignment.Left
                    TextboxDesc.TextYAlignment = Enum.TextYAlignment.Center
                    TextboxDesc.RichText = true
                end

                TextboxArea.Name = "Background2"
                TextboxArea.Parent = TextboxBG
                TextboxArea.ClipsDescendants = true
                TextboxArea.Position = UDim2.new(0, 10, 0, 8 + titleHeight + descHeight + 4)
                TextboxArea.Size = UDim2.new(1, -20, 0, boxHeight)
                TextboxArea.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]

                TextboxAreaCorner.CornerRadius = UDim.new(0, 4)
                TextboxAreaCorner.Parent = TextboxArea

                TextboxStroke.Parent = TextboxArea
                TextboxStroke.Color = getgenv().UIColor["Box Highlight Color"]
                TextboxStroke.Thickness = 1
                TextboxStroke.Transparency = 0.8

                TextboxInput.Name = "TextColorPlaceholder"
                TextboxInput.Parent = TextboxArea
                TextboxInput.BackgroundTransparency = 1.000
                TextboxInput.Position = UDim2.new(0, 8, 0, 0)
                TextboxInput.Size = UDim2.new(1, -16, 1, 0)
                TextboxInput.Font = Enum.Font.GothamBold
                TextboxInput.PlaceholderText = Placeholder
                TextboxInput.Text = ""
                TextboxInput.TextSize = 14.000
                TextboxInput.TextXAlignment = Enum.TextXAlignment.Left
                TextboxInput.TextTruncate = Enum.TextTruncate.AtEnd
                TextboxInput.ClearTextOnFocus = ClearOnFocus
                TextboxInput.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
                TextboxInput.TextColor3 = getgenv().UIColor["Text Color"]

                TextboxInput.Focused:Connect(function()
                    TweenService:Create(TextboxStroke, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                        Transparency = 0,
                    }):Play()
                end)

                if Number_Only then
                    TextboxInput:GetPropertyChangedSignal("Text"):Connect(function()
                        local txt = TextboxInput.Text
                        if txt == "" or txt == "-" or txt == "." or txt == "-." then
                            return
                        end
                        if not tonumber(txt) then
                            TextboxInput.Text = txt:gsub("[^%d%.%-]", "")
                        end
                    end)
                end

                TextboxInput.FocusLost:Connect(function()
                    TweenService:Create(TextboxStroke, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                        Transparency = 0.8,
                    }):Play()
                    if Callback then
                        pcall(Callback, TextboxInput.Text)
                    end
                end)

                local textbox_function = {}

                if Default ~= nil and Default ~= false and tostring(Default) ~= "" then
                    TextboxInput.Text = tostring(Default)
                    task.spawn(function()
                        if Callback then
                            pcall(Callback, TextboxInput.Text)
                        end
                    end)
                end

                function textbox_function.SetValue(Value)
                    TextboxInput.Text = tostring(Value or "")
                    if Callback then
                        pcall(Callback, TextboxInput.Text)
                    end
                end
                textbox_function.Set = textbox_function.SetValue

                function textbox_function.GetValue()
                    return TextboxInput.Text
                end
                textbox_function.Get = textbox_function.GetValue

                function textbox_function.SetTitle(Value)
                    TextboxTitle.Text = tostring(Value or "")
                end

                function textbox_function.SetPlaceholder(Value)
                    TextboxInput.PlaceholderText = tostring(Value or "")
                end

                function textbox_function.ClearText()
                    TextboxInput.Text = ""
                end

                local controlData = {
                    Name = TitleText,
                    Section = Section,
                    Element = TextboxFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                }
                table.insert(getgenv().AllControls, controlData)
                return flexibleApi(textbox_function)
            end

            sectionFunction.AddTextBox = sectionFunction.AddTextbox
            sectionFunction.AddTextbix = sectionFunction.AddTextbox

            function sectionFunction:AddSlider(Setting)
                Setting = Setting or {}
                local TitleText = tostring(Setting.Text or Setting.Title or "")
                local minValue = tonumber(Setting.Min) or 0
                local maxValue = tonumber(Setting.Max) or 100
                if maxValue <= minValue then
                    maxValue = minValue + 1
                end
                local Precise = Setting.Precise or false
                local Rounding = tonumber(Setting.Rouding or Setting.Rounding)
                if Rounding then
                    Rounding = math.floor(Rounding)
                    if Rounding < 0 then
                        Rounding = 0
                    elseif Rounding > 10 then
                        Rounding = 10
                    end
                end
                local DefaultValue = tonumber(Setting.Default) or minValue
                local Callback = Setting.Callback or function() end

                local SliderFrame = Instance.new("Frame")
                local SliderCorner = Instance.new("UICorner")
                local SliderBG = Instance.new("Frame")
                local SliderBGCorner = Instance.new("UICorner")
                local SliderTitle = Instance.new("TextLabel")
                local SliderBar = Instance.new("Frame")
                local SliderButton = Instance.new("TextButton")
                local SliderBarCorner = Instance.new("UICorner")
                local Bar = Instance.new("Frame")
                local BarCorner = Instance.new("UICorner")
                local Sliderboxframe = Instance.new("Frame")
                local Sliderbox = Instance.new("UICorner")
                local Sliderbox_2 = Instance.new("TextBox")

                SliderFrame.Name = TitleText .. "_SliderFrame"
                SliderFrame.Parent = Section
                SliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
                SliderFrame.Size = UDim2.new(1, 0, 0, 50)

                SliderCorner.CornerRadius = UDim.new(0, 4)
                SliderCorner.Name = "SliderCorner"
                SliderCorner.Parent = SliderFrame

                SliderBG.Name = "Background1"
                SliderBG.Parent = SliderFrame
                SliderBG.AnchorPoint = Vector2.new(0.5, 0.5)
                SliderBG.Position = UDim2.new(0.5, 0, 0.5, 0)
                SliderBG.Size = UDim2.new(1, -10, 1, 0)
                SliderBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                SliderBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]

                SliderBGCorner.CornerRadius = UDim.new(0, 4)
                SliderBGCorner.Name = "SliderBGCorner"
                SliderBGCorner.Parent = SliderBG

                SliderTitle.Name = "TextColor"
                SliderTitle.Parent = SliderBG
                SliderTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                SliderTitle.BackgroundTransparency = 1
                SliderTitle.Position = UDim2.new(0, 10, 0, 0)
                SliderTitle.Size = UDim2.new(1, -10, 0, 25)
                SliderTitle.Font = Enum.Font.GothamBlack
                SliderTitle.Text = TitleText
                SliderTitle.TextSize = 14
                SliderTitle.RichText = true
                SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
                SliderTitle.TextColor3 = getgenv().UIColor["Text Color"]

                SliderBar.Name = "SliderBar"
                SliderBar.Parent = SliderBG
                SliderBar.AnchorPoint = Vector2.new(0, 0.5)
                SliderBar.Position = UDim2.new(0, 10, 1, -12)
                SliderBar.Size = UDim2.new(1, -20, 0, 6)
                SliderBar.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
                SliderBar.BorderSizePixel = 0

                SliderBarCorner.CornerRadius = UDim.new(1, 0)
                SliderBarCorner.Name = "SliderBarCorner"
                SliderBarCorner.Parent = SliderBar

                Bar.Name = "Bar"
                Bar.Parent = SliderBar
                Bar.BorderSizePixel = 0
                Bar.Size = UDim2.new(0, 0, 1, 0)
                Bar.BackgroundColor3 = getgenv().UIColor["Slider Highlight Color"]

                BarCorner.CornerRadius = UDim.new(1, 0)
                BarCorner.Name = "BarCorner"
                BarCorner.Parent = Bar

                local SliderKnob = Instance.new("Frame")
                SliderKnob.Name = "SliderKnob"
                SliderKnob.Parent = SliderBar
                SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
                SliderKnob.Position = UDim2.new(0, 0, 0.5, 0)
                SliderKnob.Size = UDim2.new(0, 14, 0, 14)
                SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SliderKnob.BorderSizePixel = 0
                SliderKnob.ZIndex = 3

                local SliderKnobCorner = Instance.new("UICorner")
                SliderKnobCorner.CornerRadius = UDim.new(1, 0)
                SliderKnobCorner.Parent = SliderKnob

                local SliderKnobStroke = Instance.new("UIStroke")
                SliderKnobStroke.Color = getgenv().UIColor["Slider Highlight Color"]
                SliderKnobStroke.Thickness = 2
                SliderKnobStroke.Parent = SliderKnob

                SliderButton.Name = "SliderButton"
                SliderButton.Parent = SliderBar
                SliderButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                SliderButton.BackgroundTransparency = 1
                SliderButton.AnchorPoint = Vector2.new(0, 0.5)
                SliderButton.Position = UDim2.new(0, 0, 0.5, 0)
                SliderButton.Size = UDim2.new(1, 0, 0, 22)
                SliderButton.Font = Enum.Font.GothamBold
                SliderButton.Text = ""
                SliderButton.TextColor3 = Color3.fromRGB(230, 230, 230)
                SliderButton.TextSize = 14

                Sliderboxframe.Name = "Background2"
                Sliderboxframe.Parent = SliderBG
                Sliderboxframe.AnchorPoint = Vector2.new(1, 0)
                Sliderboxframe.Position = UDim2.new(1, -10, 0, 3)
                Sliderboxframe.Size = UDim2.new(0, 60, 0, 20)
                Sliderboxframe.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]

                Sliderbox.CornerRadius = UDim.new(0, 4)
                Sliderbox.Name = "Sliderbox"
                Sliderbox.Parent = Sliderboxframe

                Sliderbox_2.Name = "TextColor"
                Sliderbox_2.Parent = Sliderboxframe
                Sliderbox_2.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                Sliderbox_2.BackgroundTransparency = 1
                Sliderbox_2.Size = UDim2.new(1, 0, 1, 0)
                Sliderbox_2.Font = Enum.Font.GothamBold
                Sliderbox_2.Text = ""
                Sliderbox_2.TextSize = 13
                Sliderbox_2.TextColor3 = getgenv().UIColor["Text Color"]
                Sliderbox_2.ClearTextOnFocus = false

                SliderButton.MouseEnter:Connect(function()
                    TweenService
                        :Create(SliderBar, TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]), {
                            BackgroundColor3 = getgenv().UIColor["Background 2 Color"]:Lerp(Color3.new(1, 1, 1), 0.18),
                        })
                        :Play()

                    TweenService:Create(
                        SliderKnob,
                        TweenInfo.new(
                            getgenv().UIColor["Tween Animation 3 Speed"],
                            Enum.EasingStyle.Back,
                            Enum.EasingDirection.Out
                        ),
                        {
                            Size = UDim2.new(0, 18, 0, 18),
                        }
                    ):Play()
                end)

                SliderButton.MouseLeave:Connect(function()
                    TweenService
                        :Create(SliderBar, TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]), {
                            BackgroundColor3 = getgenv().UIColor["Background 2 Color"],
                        })
                        :Play()
                    TweenService:Create(SliderKnob, TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]), {
                        Size = UDim2.new(0, 14, 0, 14),
                    }):Play()
                end)

                local function roundValue(v)
                    if Rounding then
                        return tonumber(string.format("%." .. tostring(Rounding) .. "f", v)) or v
                    elseif Precise then
                        return tonumber(string.format("%.2f", v)) or v
                    else
                        return math.floor(v + 0.5)
                    end
                end

                local currentValue = math.clamp(DefaultValue, minValue, maxValue)

                local function callBackAndSetText(val)
                    val = math.clamp(val, minValue, maxValue)
                    val = roundValue(val)
                    currentValue = val
                    Sliderbox_2.Text = tostring(val)
                    pcall(Callback, tonumber(val))
                end

                local displayPercentage = 0
                local targetPercentage = 0
                local barVisualTween = nil

                local function valueToPercentage(v)
                    local range = (maxValue - minValue)
                    if range > 0 then
                        return math.clamp((v - minValue) / range, 0, 1)
                    end
                    return 0
                end

                local function applyVisual(percentage)
                    percentage = math.clamp(percentage, 0, 1)
                    Bar.Size = UDim2.new(percentage, 0, 1, 0)
                    SliderKnob.Position = UDim2.new(percentage, 0, 0.5, 0)
                end

                local function updateBarByValue(v)
                    targetPercentage = valueToPercentage(v)
                    displayPercentage = targetPercentage
                    if barVisualTween then
                        barVisualTween:Cancel()
                    end
                    barVisualTween = TweenService:Create(
                        Bar,
                        TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                        {
                            Size = UDim2.new(targetPercentage, 0, 1, 0),
                        }
                    )
                    barVisualTween:Play()
                    TweenService
                        :Create(SliderKnob, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                            Position = UDim2.new(targetPercentage, 0, 0.5, 0),
                        })
                        :Play()
                end

                updateBarByValue(currentValue)
                Sliderbox_2.Text = tostring(currentValue)
                task.spawn(function()
                    pcall(Callback, tonumber(currentValue))
                end)

                local function applySliderFromInput(input)
                    if barVisualTween then
                        barVisualTween:Cancel()
                        barVisualTween = nil
                    end
                    local barWidth = SliderBar.AbsoluteSize.X
                    if barWidth <= 0 then
                        return
                    end
                    local percentage = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / barWidth, 0, 1)
                    local value = minValue + (maxValue - minValue) * percentage
                    callBackAndSetText(value)
                    displayPercentage = percentage
                    targetPercentage = percentage
                    applyVisual(percentage)
                end

                bindSliderDrag(SliderButton, applySliderFromInput, function()
                    tweenUI(
                        SliderKnob,
                        { Size = UDim2.new(0, 18, 0, 18) },
                        "Tween Animation 3 Speed",
                        StyleBack,
                        DirOut
                    )
                end, function()
                    tweenUI(
                        SliderKnob,
                        { Size = UDim2.new(0, 14, 0, 14) },
                        "Tween Animation 3 Speed",
                        StyleQuad,
                        DirOut
                    )
                end)

                local function SetSliderValue(Value)
                    local v = tonumber(Value) or minValue
                    v = math.clamp(v, minValue, maxValue)
                    callBackAndSetText(v)
                    updateBarByValue(currentValue)
                end

                Sliderbox_2.FocusLost:Connect(function()
                    SetSliderValue(Sliderbox_2.Text)
                end)

                local slider_function = {}
                function slider_function.SetValue(Value)
                    SetSliderValue(Value)
                end
                function slider_function.GetValue()
                    return currentValue
                end
                function slider_function:SetRange(newMin, newMax)
                    if tonumber(newMin) then
                        minValue = tonumber(newMin)
                    end
                    if tonumber(newMax) then
                        maxValue = tonumber(newMax)
                    end
                    SetSliderValue(currentValue)
                end

                local controlData = {
                    Name = TitleText,
                    Section = Section,
                    Element = SliderFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                    SetValue = slider_function.SetValue,
                    GetValue = slider_function.GetValue,
                }
                table.insert(getgenv().AllControls, controlData)

                return flexibleApi(slider_function, { "SetRange" })
            end

            function sectionFunction:AddDiscordInvite(Setting)
                local Title = tostring(Setting.Title or Setting.Text or "Discord Server")
                local Description = tostring(Setting.Description or Setting.Desc or "")
                local Invite = tostring(Setting.Invite or Setting.Link or "https://discord.gg/")
                local Icon = Setting.Icon or Setting.Image or Setting.Logo or getgenv().UIColor["Logo Image"]
                local Banner = Setting.Banner or Setting.BannerColor or getgenv().UIColor["Border Color"]
                local Online = tonumber(Setting.Online or Setting.MembersOnline)
                local Members = tonumber(Setting.Members or Setting.TotalMembers)

                assert(type(Invite) == "string", "AddDiscordInvite.Invite: 'string' expected")

                local function formatNumber(n)
                    local s = tostring(math.floor(n))
                    local k
                    while true do
                        s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
                        if k == 0 then
                            break
                        end
                    end
                    return s
                end

                local DiscordFrame = Instance.new("Frame")
                DiscordFrame.Name = "DiscordInviteFrame"
                DiscordFrame.Parent = Section
                DiscordFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                DiscordFrame.BackgroundTransparency = 1
                DiscordFrame.Size = UDim2.new(1, 0, 0, 130)

                local DiscordBG = Instance.new("Frame")
                DiscordBG.Name = "Background1"
                DiscordBG.Parent = DiscordFrame
                DiscordBG.AnchorPoint = Vector2.new(0.5, 0.5)
                DiscordBG.Position = UDim2.new(0.5, 0, 0.5, 0)
                DiscordBG.Size = UDim2.new(1, -10, 1, -5)
                DiscordBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                DiscordBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
                DiscordBG.ClipsDescendants = true
                DiscordBG.BorderSizePixel = 0

                local DiscordCorner = Instance.new("UICorner")
                DiscordCorner.CornerRadius = UDim.new(0, 8)
                DiscordCorner.Parent = DiscordBG

                local DiscordStroke = Instance.new("UIStroke")
                DiscordStroke.Parent = DiscordBG
                DiscordStroke.Color = getgenv().UIColor["Border Color"]
                DiscordStroke.Thickness = 1
                DiscordStroke.Transparency = 0.6

                local BannerFrame = Instance.new("Frame")
                BannerFrame.Name = "Banner"
                BannerFrame.Parent = DiscordBG
                BannerFrame.Size = UDim2.new(1, 0, 0, 55)
                BannerFrame.BackgroundColor3 = typeof(Banner) == "Color3" and Banner
                    or getgenv().UIColor["Border Color"]
                BannerFrame.BorderSizePixel = 0

                if type(Banner) == "string" and Banner ~= "" then
                    local BannerImg = Instance.new("ImageLabel")
                    BannerImg.Parent = BannerFrame
                    BannerImg.Size = UDim2.new(1, 0, 1, 0)
                    BannerImg.BackgroundTransparency = 1
                    BannerImg.Image = Banner
                    BannerImg.ScaleType = Enum.ScaleType.Crop
                else
                    local BannerGradient = Instance.new("UIGradient")
                    BannerGradient.Parent = BannerFrame
                    BannerGradient.Rotation = -20
                    local baseColor = typeof(Banner) == "Color3" and Banner or getgenv().UIColor["Border Color"]
                    BannerGradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0.00, baseColor),
                        ColorSequenceKeypoint.new(1.00, baseColor:Lerp(Color3.new(0, 0, 0), 0.35)),
                    })
                end

                local BannerOverlay = Instance.new("Frame")
                BannerOverlay.Parent = BannerFrame
                BannerOverlay.Size = UDim2.new(1, 0, 1, 0)
                BannerOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                BannerOverlay.BackgroundTransparency = 0.7
                BannerOverlay.BorderSizePixel = 0

                local IconFrame = Instance.new("Frame")
                IconFrame.Name = "IconFrame"
                IconFrame.Parent = DiscordBG
                IconFrame.AnchorPoint = Vector2.new(0, 0.5)
                IconFrame.Position = UDim2.new(0, 10, 0, 55)
                IconFrame.Size = UDim2.new(0, 42, 0, 42)
                IconFrame.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                IconFrame.BorderSizePixel = 0

                local IconFrameCorner = Instance.new("UICorner")
                IconFrameCorner.CornerRadius = UDim.new(1, 0)
                IconFrameCorner.Parent = IconFrame

                local IconStroke = Instance.new("UIStroke")
                IconStroke.Parent = IconFrame
                IconStroke.Color = getgenv().UIColor["Border Color"]
                IconStroke.Thickness = 2
                IconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                local IconImage = Instance.new("ImageLabel")
                IconImage.Parent = IconFrame
                IconImage.Size = UDim2.new(1, -4, 1, -4)
                IconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
                IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
                IconImage.BackgroundTransparency = 1
                IconImage.Image = tostring(Icon or "")

                local IconImageCorner = Instance.new("UICorner")
                IconImageCorner.CornerRadius = UDim.new(1, 0)
                IconImageCorner.Parent = IconImage

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "Title"
                TitleLabel.Parent = DiscordBG
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.Position = UDim2.new(0, 60, 0, 60)
                TitleLabel.Size = UDim2.new(1, -70, 0, 16)
                TitleLabel.Font = Enum.Font.GothamBlack
                TitleLabel.Text = Title
                TitleLabel.TextSize = 14
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.TextColor3 = getgenv().UIColor["Text Color"]

                local StatusFrame
                if Online or Members then
                    StatusFrame = Instance.new("Frame")
                    StatusFrame.Name = "Status"
                    StatusFrame.Parent = DiscordBG
                    StatusFrame.BackgroundTransparency = 1
                    StatusFrame.Position = UDim2.new(0, 60, 0, 78)
                    StatusFrame.Size = UDim2.new(1, -70, 0, 12)

                    local layout = Instance.new("UIListLayout")
                    layout.Parent = StatusFrame
                    layout.FillDirection = Enum.FillDirection.Horizontal
                    layout.Padding = UDim.new(0, 8)
                    layout.VerticalAlignment = Enum.VerticalAlignment.Center

                    local function addStat(dotColor, text)
                        local item = Instance.new("Frame")
                        item.Parent = StatusFrame
                        item.BackgroundTransparency = 1
                        item.Size = UDim2.new(0, 0, 1, 0)
                        item.AutomaticSize = Enum.AutomaticSize.X

                        local dot = Instance.new("Frame")
                        dot.Parent = item
                        dot.AnchorPoint = Vector2.new(0, 0.5)
                        dot.Position = UDim2.new(0, 0, 0.5, 0)
                        dot.Size = UDim2.new(0, 6, 0, 6)
                        dot.BackgroundColor3 = dotColor
                        dot.BorderSizePixel = 0
                        local dc = Instance.new("UICorner", dot)
                        dc.CornerRadius = UDim.new(1, 0)

                        local lbl = Instance.new("TextLabel")
                        lbl.Parent = item
                        lbl.Position = UDim2.new(0, 12, 0, 0)
                        lbl.Size = UDim2.new(0, 0, 1, 0)
                        lbl.AutomaticSize = Enum.AutomaticSize.X
                        lbl.BackgroundTransparency = 1
                        lbl.Font = Enum.Font.Gotham
                        lbl.Text = text
                        lbl.TextSize = 11
                        lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
                        lbl.TextXAlignment = Enum.TextXAlignment.Left
                    end

                    if Online then
                        addStat(Color3.fromRGB(67, 181, 129), formatNumber(Online) .. " Online")
                    end
                    if Members then
                        addStat(Color3.fromRGB(120, 130, 140), formatNumber(Members) .. " Members")
                    end
                end

                local DescLabel = Instance.new("TextLabel")
                DescLabel.Name = "Description"
                DescLabel.Parent = DiscordBG
                DescLabel.BackgroundTransparency = 1
                DescLabel.Position = UDim2.new(0, 10, 0, StatusFrame and 95 or 85)
                DescLabel.Size = UDim2.new(1, -110, 0, 30)
                DescLabel.Font = Enum.Font.Gotham
                DescLabel.Text = Description
                DescLabel.TextSize = 11
                DescLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                DescLabel.TextXAlignment = Enum.TextXAlignment.Left
                DescLabel.TextYAlignment = Enum.TextYAlignment.Top
                DescLabel.TextWrapped = true

                local JoinButton = Instance.new("TextButton")
                JoinButton.Name = "JoinButton"
                JoinButton.Parent = DiscordBG
                JoinButton.AnchorPoint = Vector2.new(1, 1)
                JoinButton.Position = UDim2.new(1, -10, 1, -8)
                JoinButton.Size = UDim2.new(0, 90, 0, 26)
                JoinButton.BackgroundColor3 = getgenv().UIColor["Border Color"]
                JoinButton.BorderSizePixel = 0
                JoinButton.Font = Enum.Font.GothamBold
                JoinButton.Text = "Join Server"
                JoinButton.TextSize = 12
                JoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                JoinButton.AutoButtonColor = false

                local JoinCorner = Instance.new("UICorner")
                JoinCorner.CornerRadius = UDim.new(0, 6)
                JoinCorner.Parent = JoinButton

                JoinButton.MouseEnter:Connect(function()
                    TweenService
                        :Create(JoinButton, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
                            BackgroundColor3 = getgenv().UIColor["Search Icon Highlight Color"],
                        })
                        :Play()
                end)
                JoinButton.MouseLeave:Connect(function()
                    TweenService:Create(JoinButton, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
                        BackgroundColor3 = getgenv().UIColor["Border Color"],
                    }):Play()
                end)

                local cooldown = 0
                JoinButton.MouseButton1Click:Connect(function()
                    if tick() - cooldown < 3 then
                        return
                    end
                    cooldown = tick()

                    local ok = pcall(function()
                        if setclipboard then
                            setclipboard(Invite)
                        elseif toclipboard then
                            toclipboard(Invite)
                        end
                    end)

                    local originalText = JoinButton.Text
                    JoinButton.Text = ok and "Copied!" or "Failed"
                    task.delay(2, function()
                        JoinButton.Text = originalText
                    end)
                end)

                local controlData = {
                    Name = Title,
                    Section = Section,
                    Element = DiscordFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                }
                table.insert(getgenv().AllControls, controlData)

                local discord_function = {}
                function discord_function:SetInvite(link)
                    Invite = tostring(link)
                end
                function discord_function:SetTitle(newTitle)
                    TitleLabel.Text = tostring(newTitle)
                end
                function discord_function:SetDescription(newDesc)
                    DescLabel.Text = tostring(newDesc)
                end
                function discord_function:SetIcon(newIcon)
                    IconImage.Image = tostring(newIcon)
                end

                return flexibleApi(discord_function, { "SetDescription", "SetIcon", "SetInvite", "SetTitle" })
            end

            function sectionFunction:AddSeperator(text)
                local SeparatorFrame = Instance.new("Frame")
                SeparatorFrame.Name = "Separator"
                SeparatorFrame.Parent = Section
                SeparatorFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SeparatorFrame.BackgroundTransparency = 1.000
                SeparatorFrame.Size = UDim2.new(1, 0, 0, 25)

                if text and text ~= "" then
                    local SeparatorLabel = Instance.new("TextLabel")
                    SeparatorLabel.Name = "Title"
                    SeparatorLabel.Parent = SeparatorFrame
                    SeparatorLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    SeparatorLabel.BackgroundTransparency = 1.000
                    SeparatorLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    SeparatorLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                    SeparatorLabel.AutomaticSize = Enum.AutomaticSize.X
                    SeparatorLabel.Size = UDim2.new(0, 0, 1, 0)
                    SeparatorLabel.Font = Enum.Font.GothamBold
                    SeparatorLabel.Text = text
                    SeparatorLabel.TextColor3 = getgenv().UIColor["Section Text Color"]
                    SeparatorLabel.TextSize = 14.000

                    local LeftLine = Instance.new("Frame")
                    LeftLine.Name = "LeftLine"
                    LeftLine.Parent = SeparatorFrame
                    LeftLine.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]
                    LeftLine.BorderSizePixel = 0
                    LeftLine.AnchorPoint = Vector2.new(1, 0.5)
                    LeftLine.Position = UDim2.new(0.5, -5, 0.5, 0)
                    LeftLine.Size = UDim2.new(0.5, -10, 0, 1)

                    local LeftGradient = Instance.new("UIGradient")
                    LeftGradient.Parent = LeftLine
                    LeftGradient.Rotation = 180
                    LeftGradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 0.8),
                    })

                    local RightLine = Instance.new("Frame")
                    RightLine.Name = "RightLine"
                    RightLine.Parent = SeparatorFrame
                    RightLine.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]
                    RightLine.BorderSizePixel = 0
                    RightLine.AnchorPoint = Vector2.new(0, 0.5)
                    RightLine.Position = UDim2.new(0.5, 5, 0.5, 0)
                    RightLine.Size = UDim2.new(0.5, -10, 0, 1)

                    local RightGradient = Instance.new("UIGradient")
                    RightGradient.Parent = RightLine
                    RightGradient.Rotation = 0
                    RightGradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 0.8),
                    })

                    local function UpdateSeparator()
                        local textWidth = SeparatorLabel.TextBounds.X
                        local padding = 8
                        local side = math.max(0, textWidth / 2 + padding)

                        LeftLine.AnchorPoint = Vector2.new(0, 0.5)
                        LeftLine.Position = UDim2.new(0, 10, 0.5, 0)
                        LeftLine.Size = UDim2.new(0.5, -side - 10, 0, 1)

                        RightLine.AnchorPoint = Vector2.new(1, 0.5)
                        RightLine.Position = UDim2.new(1, -10, 0.5, 0)
                        RightLine.Size = UDim2.new(0.5, -side - 10, 0, 1)
                    end

                    SeparatorLabel:GetPropertyChangedSignal("TextBounds"):Connect(UpdateSeparator)
                    UpdateSeparator()
                else
                    local SeparatorLine = Instance.new("Frame")
                    SeparatorLine.Name = "Line"
                    SeparatorLine.Parent = SeparatorFrame
                    SeparatorLine.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]
                    SeparatorLine.BorderSizePixel = 0
                    SeparatorLine.Position = UDim2.new(0, 10, 0.5, 0)
                    SeparatorLine.Size = UDim2.new(1, -20, 0, 1)

                    local LineGradient = Instance.new("UIGradient")
                    LineGradient.Parent = SeparatorLine
                    LineGradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.2, 0),
                        NumberSequenceKeypoint.new(0.8, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                end

                local controlData = {
                    Name = text or "Separator",
                    Section = Section,
                    Element = SeparatorFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageNameControl,
                }
                table.insert(getgenv().AllControls, controlData)
            end

            return sectionFunction
        end
        local pagefunc = {}
        function pagefunc:AddLeftGroupbox(name)
            return pageFunction:AddSection(name)
        end
        function pagefunc:AddRightGroupbox(name)
            return pageFunction:AddSection(name)
        end

        function pagefunc:AddSection(Section_Name, Toggleable, SectionGap, SectionColor)
            return pageFunction:AddSection(Section_Name, Toggleable, SectionGap, SectionColor)
        end
        return pagefunc
    end

    return Main_Function
end

return Library
