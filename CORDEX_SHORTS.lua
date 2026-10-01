--[[
    CORDEX SHORTS
    Roblox Shorts-style video feed
    Mobile + PC
    Swipe up/down + search
    Sem comentários / curtidas
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local CONFIG = {
    GUI_NAME = "CORDEX_SHORTS",
    DESTROY_OLD = true,

    -- Procura VideoFrames existentes no jogo.
    SCAN_GAME_VIDEOS = true,

    -- Feed opcional via JSON.
    USE_REMOTE_FEED = false,
    REMOTE_FEED_URL = "",

    SWIPE_DISTANCE = 75,
    TRANSITION_TIME = 0.28,
    VIDEO_LOAD_TIMEOUT = 4,
    VOLUME = 1,
}

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then
        return result
    end
    return nil
end

local function getUIParent()
    local parent

    if typeof(gethui) == "function" then
        parent = safeCall(gethui)
    end

    if not parent then
        parent = safeCall(function()
            return game:GetService("CoreGui")
        end)
    end

    return parent
end

local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    if parent then
        object.Parent = parent
    end

    return object
end

local function addCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, parent)
end

local function addStroke(parent, thickness, transparency)
    return create("UIStroke", {
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, parent)
end

local function normalizeVideoId(value)
    if typeof(value) ~= "string" then
        return nil
    end

    if value == "" then
        return nil
    end

    if value:match("^rbxassetid://%d+$") then
        return value
    end

    local id = value:match("rbxassetid://(%d+)")
        or value:match("[?&]id=(%d+)")
        or value:match("/(%d+)$")

    if id then
        return "rbxassetid://" .. id
    end

    if value:match("^%d+$") then
        return "rbxassetid://" .. value
    end

    return value
end

local Feed = {}

local function addFeedItem(title, creator, video)
    video = normalizeVideoId(video)

    if not video then
        return
    end

    table.insert(Feed, {
        title = tostring(title or "Vídeo"),
        creator = tostring(creator or "Desconhecido"),
        video = video,
    })
end

-- Exemplos. Troque pelos IDs de vídeo Roblox que você possui.
addFeedItem("CORDEX SHORTS", "@Cordex", "rbxassetid://5608384572")
addFeedItem("Vídeo de exemplo", "@Cordex", "rbxassetid://5608384572")
addFeedItem("Outro vídeo", "@Cordex", "rbxassetid://5608384572")

local function scanGameVideos()
    if not CONFIG.SCAN_GAME_VIDEOS then
        return
    end

    local seen = {}

    for _, item in ipairs(Feed) do
        seen[item.video] = true
    end

    local descendants = game:GetDescendants()

    for _, object in ipairs(descendants) do
        if object:IsA("VideoFrame") then
            local video = normalizeVideoId(object.Video)

            if video and not seen[video] then
                seen[video] = true

                local title = object.Name
                local creator = object.Parent and object.Parent.Name or "Jogo"

                addFeedItem(title, creator, video)
            end
        end
    end
end

local function executorHttpGet(url)
    if not url or url == "" then
        return nil
    end

    local result = safeCall(function()
        return game:HttpGet(url)
    end)

    if result then
        return result
    end

    local requestFunctions = {
        request,
        http_request,
        syn and syn.request,
    }

    for _, requestFunction in ipairs(requestFunctions) do
        if typeof(requestFunction) == "function" then
            local response = safeCall(function()
                return requestFunction({
                    Url = url,
                    Method = "GET",
                })
            end)

            if response then
                if typeof(response) == "table" then
                    return response.Body or response.body
                end

                if typeof(response) == "string" then
                    return response
                end
            end
        end
    end

    return nil
end

local function loadRemoteFeed()
    if not CONFIG.USE_REMOTE_FEED then
        return
    end

    if CONFIG.REMOTE_FEED_URL == "" then
        return
    end

    local body = executorHttpGet(CONFIG.REMOTE_FEED_URL)

    if not body then
        warn("[CORDEX SHORTS] Não foi possível acessar o feed remoto.")
        return
    end

    local data = safeCall(function()
        return HttpService:JSONDecode(body)
    end)

    if typeof(data) ~= "table" then
        warn("[CORDEX SHORTS] JSON inválido.")
        return
    end

    for _, item in ipairs(data) do
        if typeof(item) == "table" then
            addFeedItem(
                item.title or item.name or "Vídeo",
                item.creator or item.author or "Desconhecido",
                item.video or item.videoId
            )
        end
    end
end

scanGameVideos()
loadRemoteFeed()

local uiParent = getUIParent()

if not uiParent then
    error("[CORDEX SHORTS] Não foi possível encontrar CoreGui/gethui.")
end

if CONFIG.DESTROY_OLD then
    local old = uiParent:FindFirstChild(CONFIG.GUI_NAME)

    if old then
        old:Destroy()
    end
end

local ScreenGui = create("ScreenGui", {
    Name = CONFIG.GUI_NAME,
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, uiParent)

pcall(function()
    ScreenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end)

local Main = create("Frame", {
    Name = "Main",
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    Position = UDim2.fromScale(0, 0),
}, ScreenGui)

local Header = create("Frame", {
    Name = "Header",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 64),
    Position = UDim2.fromOffset(0, 0),
    ZIndex = 20,
}, Main)

local Logo = create("TextLabel", {
    Name = "Logo",
    BackgroundTransparency = 1,
    Text = "SHORTS",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 25,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Size = UDim2.new(0, 120, 1, 0),
    Position = UDim2.fromOffset(16, 0),
    ZIndex = 21,
}, Header)

local SearchBox = create("TextBox", {
    Name = "SearchBox",
    BackgroundColor3 = Color3.fromRGB(28, 28, 30),
    BackgroundTransparency = 0.08,
    PlaceholderText = "Pesquisar vídeos...",
    PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
    Text = "",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 15,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
    Size = UDim2.new(1, -150, 0, 42),
    Position = UDim2.new(0, 130, 0.5, -21),
    ZIndex = 21,
}, Header)

addCorner(SearchBox, 21)
addStroke(SearchBox, 1, 0.45)

local SearchIcon = create("TextLabel", {
    Name = "SearchIcon",
    BackgroundTransparency = 1,
    Text = "⌕",
    TextColor3 = Color3.fromRGB(220, 220, 220),
    TextSize = 25,
    Font = Enum.Font.Gotham,
    Size = UDim2.fromOffset(35, 42),
    Position = UDim2.fromOffset(8, 0),
    ZIndex = 22,
}, SearchBox)

SearchBox.TextXAlignment = Enum.TextXAlignment.Left

local ClearSearch = create("TextButton", {
    Name = "ClearSearch",
    BackgroundTransparency = 1,
    Text = "×",
    TextColor3 = Color3.fromRGB(190, 190, 190),
    TextSize = 25,
    Font = Enum.Font.Gotham,
    AutoButtonColor = false,
    Size = UDim2.fromOffset(40, 42),
    Position = UDim2.new(1, -42, 0, 0),
    ZIndex = 23,
}, SearchBox)

local FeedViewport = create("Frame", {
    Name = "FeedViewport",
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Size = UDim2.new(1, 0, 1, -64),
    Position = UDim2.fromOffset(0, 64),
    ZIndex = 1,
}, Main)

local function createVideoPage(name)
    local page = create("Frame", {
        Name = name,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        ClipsDescendants = true,
        ZIndex = 2,
    }, FeedViewport)

    local videoFrame = create("VideoFrame", {
        Name = "Video",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        Video = "",
        Loop = true,
        Volume = CONFIG.VOLUME,
        ZIndex = 2,
    }, page)

    local bottom = create("Frame", {
        Name = "Bottom",
        BackgroundTransparency = 0.25,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 155),
        Position = UDim2.new(0, 0, 1, -155),
        ZIndex = 5,
    }, page)

    local gradient = create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, bottom)

    local info = create("Frame", {
        Name = "Info",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -32, 1, -25),
        Position = UDim2.fromOffset(16, 10),
        ZIndex = 6,
    }, bottom)

    local title = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        Size = UDim2.new(1, 0, 0, 55),
        Position = UDim2.fromOffset(0, 0),
        ZIndex = 7,
    }, info)

    local creator = create("TextLabel", {
        Name = "Creator",
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(205, 205, 205),
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.fromOffset(0, 60),
        ZIndex = 7,
    }, info)

    local counter = create("TextLabel", {
        Name = "Counter",
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.fromOffset(0, 88),
        ZIndex = 7,
    }, info)

    local loading = create("TextLabel", {
        Name = "Loading",
        BackgroundTransparency = 1,
        Text = "Carregando...",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 15,
        Font = Enum.Font.GothamMedium,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(220, 35),
        ZIndex = 10,
    }, page)

    return {
        root = page,
        video = videoFrame,
        title = title,
        creator = creator,
        counter = counter,
        loading = loading,
    }
end

local PageA = createVideoPage("PageA")
local PageB = createVideoPage("PageB")

PageB.root.Visible = false

local CurrentPage = PageA
local NextPage = PageB

local FilteredFeed = {}
local CurrentIndex = 1
local IsTransitioning = false
local PageTokens = {
    [PageA] = 0,
    [PageB] = 0,
}

local EmptyState = create("Frame", {
    Name = "EmptyState",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Position = UDim2.fromScale(0, 0),
    Visible = false,
    ZIndex = 15,
}, FeedViewport)

local EmptyIcon = create("TextLabel", {
    BackgroundTransparency = 1,
    Text = "⌕",
    TextColor3 = Color3.fromRGB(170, 170, 170),
    TextSize = 45,
    Font = Enum.Font.Gotham,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.42),
    Size = UDim2.fromOffset(80, 70),
    ZIndex = 16,
}, EmptyState)

local EmptyTitle = create("TextLabel", {
    BackgroundTransparency = 1,
    Text = "Nenhum vídeo encontrado",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 19,
    Font = Enum.Font.GothamBold,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.52),
    Size = UDim2.new(1, -40, 0, 35),
    ZIndex = 16,
}, EmptyState)

local EmptySubtitle = create("TextLabel", {
    BackgroundTransparency = 1,
    Text = "Tente pesquisar por outro nome.",
    TextColor3 = Color3.fromRGB(170, 170, 170),
    TextSize = 14,
    Font = Enum.Font.Gotham,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.59),
    Size = UDim2.new(1, -40, 0, 30),
    ZIndex = 16,
}, EmptyState)

local function rebuildFilter()
    FilteredFeed = {}

    local query = string.lower(SearchBox.Text or "")

    for _, item in ipairs(Feed) do
        local title = string.lower(item.title or "")
        local creator = string.lower(item.creator or "")

        if query == ""
            or string.find(title, query, 1, true)
            or string.find(creator, query, 1, true) then

            table.insert(FilteredFeed, item)
        end
    end

    if #FilteredFeed == 0 then
        CurrentIndex = 1
    elseif CurrentIndex > #FilteredFeed then
        CurrentIndex = 1
    end
end

local function loadVideoIntoPage(page, item, counterText)
    PageTokens[page] += 1

    local token = PageTokens[page]

    page.title.Text = item.title or "Vídeo"
    page.creator.Text = item.creator or "Desconhecido"
    page.counter.Text = counterText or ""
    page.loading.Text = "Carregando..."
    page.loading.Visible = true

    page.video:Pause()
    page.video.Video = ""

    task.wait()

    if PageTokens[page] ~= token then
        return false
    end

    page.video.Video = item.video

    local startTime = os.clock()
    local loaded = false

    while os.clock() - startTime < CONFIG.VIDEO_LOAD_TIMEOUT do
        if PageTokens[page] ~= token then
            return false
        end

        if page.video.IsLoaded then
            loaded = true
            break
        end

        task.wait(0.1)
    end

    if PageTokens[page] ~= token then
        return false
    end

    if loaded then
        page.loading.Visible = false
        page.video.TimePosition = 0
        page.video.Volume = CONFIG.VOLUME
        page.video.Looped = true
        page.video:Play()
        return true
    end

    page.loading.Text = "Não foi possível carregar"
    page.loading.Visible = true

    return false
end

local function stopPage(page)
    PageTokens[page] += 1

    page.video:Pause()
    page.video.Video = ""
    page.loading.Visible = false
end

local function showCurrent()
    if #FilteredFeed == 0 then
        CurrentPage.root.Visible = false
        NextPage.root.Visible = false
        EmptyState.Visible = true
        return
    end

    EmptyState.Visible = false

    CurrentPage.root.Visible = true
    NextPage.root.Visible = false

    local item = FilteredFeed[CurrentIndex]

    loadVideoIntoPage(
        CurrentPage,
        item,
        tostring(CurrentIndex) .. " / " .. tostring(#FilteredFeed)
    )

    stopPage(NextPage)
end

local function changeVideo(direction)
    if IsTransitioning then
        return
    end

    if #FilteredFeed <= 1 then
        return
    end

    local newIndex = CurrentIndex + direction

    if newIndex > #FilteredFeed then
        newIndex = 1
    elseif newIndex < 1 then
        newIndex = #FilteredFeed
    end

    local item = FilteredFeed[newIndex]

    IsTransitioning = true

    NextPage.root.Visible = true
    NextPage.root.Position = UDim2.fromScale(0, direction)

    loadVideoIntoPage(
        NextPage,
        item,
        tostring(newIndex) .. " / " .. tostring(#FilteredFeed)
    )

    local oldPage = CurrentPage
    local incomingPage = NextPage

    local outgoingPosition = UDim2.fromScale(0, -direction)
    local incomingPosition = UDim2.fromScale(0, 0)

    local tweenInfo = TweenInfo.new(
        CONFIG.TRANSITION_TIME,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )

    local outgoingTween = TweenService:Create(
        oldPage.root,
        tweenInfo,
        {Position = outgoingPosition}
    )

    local incomingTween = TweenService:Create(
        incomingPage.root,
        tweenInfo,
        {Position = incomingPosition}
    )

    outgoingTween:Play()
    incomingTween:Play()

    incomingTween.Completed:Wait()

    stopPage(oldPage)

    oldPage.root.Position = UDim2.fromScale(0, 0)
    oldPage.root.Visible = false

    CurrentPage = incomingPage
    NextPage = oldPage
    CurrentIndex = newIndex

    IsTransitioning = false
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    rebuildFilter()
    showCurrent()
end)

ClearSearch.MouseButton1Click:Connect(function()
    SearchBox.Text = ""
    SearchBox:ReleaseFocus()
end)

local touchStart = nil

FeedViewport.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        touchStart = input.Position
    end
end)

FeedViewport.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    if not touchStart then
        return
    end

    local delta = input.Position - touchStart
    touchStart = nil

    local dx = math.abs(delta.X)
    local dy = math.abs(delta.Y)

    if dy < CONFIG.SWIPE_DISTANCE then
        return
    end

    if dx > dy * 1.25 then
        return
    end

    if delta.Y < 0 then
        changeVideo(1)
    else
        changeVideo(-1)
    end
end)

FeedViewport.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        if input.Position.Z < 0 then
            changeVideo(1)
        elseif input.Position.Z > 0 then
            changeVideo(-1)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.Down then
        changeVideo(1)
    elseif input.KeyCode == Enum.KeyCode.Up then
        changeVideo(-1)
    end
end)

rebuildFilter()
showCurrent()

print("[CORDEX SHORTS] Interface carregada.")
print("[CORDEX SHORTS] Vídeos encontrados:", #Feed)
print("[CORDEX SHORTS] Swipe para cima/baixo para trocar.")
