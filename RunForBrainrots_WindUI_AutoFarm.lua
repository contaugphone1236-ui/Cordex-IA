--[[
    CORRA PARA BRAINROTS! / RUN FOR BRAINROTS!
    WINDUI AUTO FARM
    PlaceId: 94702395375549
    UniverseId: 9671940985
    Pesquisa cruzada:
    - Estrutura pública do jogo e descrição da experiência
    - Código público de comunidade para RunForBrainrots
    - Estrutura atual do WindUI
    Estruturas utilizadas:
    Workspace.Zones
    Workspace.ItemSpawners
    Workspace.Plot_<LocalPlayer.Name>
    Workspace.<LocalPlayer.Name>.CarryVisuals
    PlayerGui.GUI.Frames.Index.Scrolling
    ReplicatedStorage.Events.PurchaseSpeed
    ReplicatedStorage.Events.PurchaseCarry
    ReplicatedStorage.Events.RequestBaseUpgrade
    ReplicatedStorage.Events.RequestRebirth
    ReplicatedStorage.Events.RequestSell
    IMPORTANTE:
    Alguns RemoteEvents podem exigir argumentos diferentes em futuras atualizações.
    Por isso os recursos opcionais ficam separados do Auto Farm principal.
]]
if game.PlaceId ~= 94702395375549 then
    warn("[CORRA PARA BRAINROTS] PlaceId incorreto:", game.PlaceId)
    return
end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local WINDUI_URL = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
local WindUI = loadstring(game:HttpGet(WINDUI_URL))()
local Window = WindUI:CreateWindow({
    Title = "CORRA PARA BRAINROTS",
    Author = "Auto Farm",
    Size = UDim2.fromOffset(560, 470),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 180,
    ScrollBarEnabled = true,
})
local CONFIG = {
    PromptAttempts = 18,
    PromptDelay = 0.12,
    FarmDelay = 0.08,
    CollectDelay = 0.35,
    ReturnDelay = 0.15,
    SpeedDelay = 0.18,
    CarryDelay = 0.90,
    BaseUpgradeDelay = 1.00,
    SellDelay = 2.00,
    BaseWaitTimeout = 12,
}
local RARITY_ORDER = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
    Mythical = 6,
    Celestial = 7,
    Secret = 8,
    Cosmic = 9,
    Divine = 10,
    Ethereal = 11,
}
local State = {
    AutoFarm = false,
    AutoCollect = false,
    AutoSpeed = false,
    AutoCarry = false,
    AutoBaseUpgrade = false,
    AutoSell = false,
    SelectedZone = "All",
    SelectedItems = {},
    SpeedAmount = 10,
    RunningFarm = false,
    RunningCollect = false,
    RunningSpeed = false,
    RunningCarry = false,
    RunningUpgrade = false,
    RunningSell = false,
    CurrentZone = "-",
    CurrentItem = "-",
    CurrentAction = "Aguardando",
    LastError = "-",
    InteractionMethod = "-",
    PromptCalls = 0,
    FarmCycles = 0,
    MoneyCollections = 0,
    StartedAt = os.clock(),
}
local function trim(value)
    if value == nil then
        return ""
    end
    return tostring(value):gsub("^%s*(.-)%s*$", "%1")
end
local function getCharacter()
    return LocalPlayer.Character
end
local function getHumanoidRootPart()
    local character = getCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
end
local function getHumanoid()
    local character = getCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end
local function updateState(action, zone, item)
    if action ~= nil then
        State.CurrentAction = action
    end
    if zone ~= nil then
        State.CurrentZone = zone
    end
    if item ~= nil then
        State.CurrentItem = item
    end
end
local function getBasePart(instance)
    if not instance then
        return nil
    end
    if instance:IsA("BasePart") then
        return instance
    end
    if instance:IsA("Model") and instance.PrimaryPart then
        return instance.PrimaryPart
    end
    local rootPart = instance:FindFirstChild("RootPart", true)
    if rootPart and rootPart:IsA("BasePart") then
        return rootPart
    end
    return instance:FindFirstChildWhichIsA("BasePart", true)
end
local function teleportTo(instance)
    local root = getHumanoidRootPart()
    if not root or not instance then
        return false
    end
    local targetPart = getBasePart(instance)
    if not targetPart then
        return false
    end
    local ok = pcall(function()
        root.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
    end)
    return ok
end
local function getZonesFolder()
    return workspace:FindFirstChild("Zones")
end
local function getZoneNames()
    local folder = getZonesFolder()
    local result = {}
    if not folder then
        return result
    end
    for _, zone in ipairs(folder:GetChildren()) do
        table.insert(result, zone.Name)
    end
    table.sort(result, function(a, b)
        local ar = RARITY_ORDER[a] or 999
        local br = RARITY_ORDER[b] or 999
        if ar == br then
            return a:lower() < b:lower()
        end
        return ar < br
    end)
    return result
end
local function getZone(zoneName)
    local folder = getZonesFolder()
    if not folder then
        return nil
    end
    return folder:FindFirstChild(zoneName)
end
local function getZonePart(zone)
    if not zone then
        return nil
    end
    return getBasePart(zone)
end
local function getSpawnerRoot(spawner)
    if not spawner then
        return nil
    end
    local root = spawner:FindFirstChild("RootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    root = spawner:FindFirstChild("RootPart", true)
    if root and root:IsA("BasePart") then
        return root
    end
    return getBasePart(spawner)
end
local function getSpawnerPrompt(spawner)
    if not spawner then
        return nil
    end
    local root = spawner:FindFirstChild("RootPart")
    if root then
        local prompt = root:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            return prompt
        end
    end
    return spawner:FindFirstChildWhichIsA("ProximityPrompt", true)
end
local function getSpawnerName(spawner)
    if not spawner then
        return ""
    end
    return tostring(
        spawner:GetAttribute("OriginalName")
            or spawner:GetAttribute("DisplayName")
            or spawner.Name
    )
end
local function getItemSpawnersFolder()
    return workspace:FindFirstChild("ItemSpawners")
end
local function getZoneSpawners(zoneName)
    local folder = getItemSpawnersFolder()
    if not folder then
        return {}
    end
    local zoneFolder = folder:FindFirstChild(zoneName)
    if zoneFolder then
        return zoneFolder:GetChildren()
    end
    local result = {}
    for _, descendant in ipairs(folder:GetDescendants()) do
        if descendant:GetAttribute("Zone") == zoneName then
            table.insert(result, descendant)
        end
    end
    return result
end
local function isItemSelected(name)
    if not name or name == "" then
        return false
    end
    local selected = State.SelectedItems
    if next(selected) == nil then
        return true
    end
    return selected[name] == true
end
local function getIndexEntries(zoneFilter)
    local entries = {}
    local seen = {}
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local gui = playerGui and playerGui:FindFirstChild("GUI")
    local frames = gui and gui:FindFirstChild("Frames")
    local index = frames and frames:FindFirstChild("Index")
    local scrolling = index and index:FindFirstChild("Scrolling")
    if not scrolling then
        return entries
    end
    for _, item in ipairs(scrolling:GetChildren()) do
        local rarity = item:FindFirstChild("Rarity", true)
        local rarityText = rarity and rarity:IsA("TextLabel") and trim(rarity.Text) or ""
        if item.Name ~= "Grid"
            and not item:IsA("UIGridLayout")
            and not item:IsA("UIListLayout")
            and not item:IsA("UIPadding")
            and item.Name ~= ""
            and not seen[item.Name]
        then
            if zoneFilter == nil or zoneFilter == "All" or rarityText == zoneFilter then
                seen[item.Name] = true
                table.insert(entries, {
                    Name = item.Name,
                    Rarity = rarityText,
                })
            end
        end
    end
    table.sort(entries, function(a, b)
        local ar = RARITY_ORDER[a.Rarity] or 999
        local br = RARITY_ORDER[b.Rarity] or 999
        if ar == br then
            return a.Name:lower() < b.Name:lower()
        end
        return ar < br
    end)
    return entries
end
local function getCarryContainer()
    local playerFolder = workspace:FindFirstChild(LocalPlayer.Name)
    if not playerFolder then
        return nil
    end
    return playerFolder:FindFirstChild("CarryVisuals")
end
local function getCarryCount()
    local carry = getCarryContainer()
    if not carry then
        return 0
    end
    return #carry:GetChildren()
end
local function getMaxCarry()
    local value = LocalPlayer:GetAttribute("MaxCarry")
    if typeof(value) == "number" and value > 0 then
        return value
    end
    return 1
end
local function isCarryFull()
    return getCarryCount() >= getMaxCarry()
end
local function getPlot()
    return workspace:FindFirstChild("Plot_" .. LocalPlayer.Name)
end
local function getPlotSlots()
    local plot = getPlot()
    local slots = {}
    if not plot then
        return slots
    end
    for _, floor in ipairs(plot:GetChildren()) do
        if floor.Name:match("^Floor") then
            local folder = floor:FindFirstChild("Slots")
            if folder then
                for _, slot in ipairs(folder:GetChildren()) do
                    table.insert(slots, slot)
                end
            end
        end
    end
    return slots
end
local function slotHasItem(slot)
    local spawn = slot and slot:FindFirstChild("Spawn")
    if not spawn then
        return false
    end
    for _, child in ipairs(spawn:GetChildren()) do
        if not child:IsA("ProximityPrompt") then
            return true
        end
    end
    return false
end
local function getCollectTouch(slot)
    if not slot then
        return nil
    end
    return slot:FindFirstChild("CollectTouch", true)
end
local function collectSlot(slot)
    local touchPart = getCollectTouch(slot)
    if not touchPart then
        return false
    end
    local root = getHumanoidRootPart()
    if not root then
        return false
    end
    if typeof(firetouchinterest) == "function" then
        local ok = pcall(function()
            firetouchinterest(root, touchPart, 0)
            task.wait()
            firetouchinterest(root, touchPart, 1)
        end)
        if ok then
            return true
        end
    end
    return teleportTo(touchPart)
end
local function collectMoneyOnce()
    local collected = 0
    for _, slot in ipairs(getPlotSlots()) do
        if slotHasItem(slot) then
            if collectSlot(slot) then
                collected += 1
                State.MoneyCollections += 1
                task.wait(CONFIG.CollectDelay)
            end
        end
    end
    return collected
end
local function collectUntilEmpty()
    local deadline = os.clock() + CONFIG.BaseWaitTimeout
    repeat
        collectMoneyOnce()
        if getCarryCount() <= 0 then
            return true
        end
        task.wait(0.20)
    until os.clock() >= deadline
    return getCarryCount() <= 0
end
local function returnToBase()
    local plot = getPlot()
    if not plot then
        State.LastError = "Plot_" .. LocalPlayer.Name .. " não encontrado"
        return false
    end
    updateState("Voltando para base", "Base", "-")
    local ok = teleportTo(plot)
    if ok then
        task.wait(CONFIG.ReturnDelay)
        collectUntilEmpty()
    end
    return ok
end
local function activatePrompt(prompt)
    if not prompt or not prompt.Parent then
        return false
    end
    State.PromptCalls += 1
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(function()
            fireproximityprompt(prompt)
        end)
        if ok then
            State.InteractionMethod = "fireproximityprompt"
            return true
        end
    end
    local ok = pcall(function()
        local originalHold = prompt.HoldDuration
        prompt.HoldDuration = 0
        prompt:InputHoldBegin()
        task.wait(0.04)
        prompt:InputHoldEnd()
        prompt.HoldDuration = originalHold
    end)
    if ok then
        State.InteractionMethod = "InputHold"
        return true
    end
    State.InteractionMethod = "Falhou"
    return false
end
local function getTargetList(zoneName)
    local targets = {}
    for _, spawner in ipairs(getZoneSpawners(zoneName)) do
        local itemName = getSpawnerName(spawner)
        if isItemSelected(itemName) then
            local prompt = getSpawnerPrompt(spawner)
            local part = getSpawnerRoot(spawner)
            if prompt and part then
                table.insert(targets, {
                    Spawner = spawner,
                    Prompt = prompt,
                    Part = part,
                    Name = itemName,
                })
            end
        end
    end
    return targets
end
local function farmTarget(target, zoneName)
    if not target then
        return
    end
    if not target.Spawner.Parent or not target.Prompt.Parent then
        return
    end
    if isCarryFull() then
        returnToBase()
        if not State.AutoFarm then
            return
        end
        task.wait(CONFIG.ReturnDelay)
    end
    updateState("Pegando Brainrot", zoneName, target.Name)
    teleportTo(target.Part)
    task.wait(0.08)
    for _ = 1, CONFIG.PromptAttempts do
        if not State.AutoFarm then
            break
        end
        if not target.Spawner.Parent or not target.Prompt.Parent then
            break
        end
        teleportTo(target.Part)
        activatePrompt(target.Prompt)
        task.wait(CONFIG.PromptDelay)
        if isCarryFull() then
            break
        end
        if getCarryCount() > 0 then
            break
        end
    end
    task.wait(CONFIG.FarmDelay)
end
local function getFarmZones()
    if State.SelectedZone ~= "All" then
        if getZone(State.SelectedZone) then
            return { State.SelectedZone }
        end
        return {}
    end
    return getZoneNames()
end
local function autoFarmLoop()
    if State.RunningFarm then
        return
    end
    State.RunningFarm = true
    while State.AutoFarm do
        local zones = getFarmZones()
        if #zones == 0 then
            State.LastError = "Nenhuma zona encontrada"
            task.wait(1)
        else
            for _, zoneName in ipairs(zones) do
                if not State.AutoFarm then
                    break
                end
                local zone = getZone(zoneName)
                local zonePart = getZonePart(zone)
                updateState("Indo para zona", zoneName, "-")
                if zonePart then
                    teleportTo(zonePart)
                    task.wait(0.12)
                end
                local targets = getTargetList(zoneName)
                for _, target in ipairs(targets) do
                    if not State.AutoFarm then
                        break
                    end
                    if isCarryFull() then
                        returnToBase()
                        if not State.AutoFarm then
                            break
                        end
                        if zonePart then
                            teleportTo(zonePart)
                            task.wait(0.12)
                        end
                    end
                    farmTarget(target, zoneName)
                end
            end
            if State.AutoFarm then
                State.FarmCycles += 1
            end
        end
        task.wait(CONFIG.FarmDelay)
    end
    State.RunningFarm = false
    updateState("Auto Farm parado", "-", "-")
end
local function autoCollectLoop()
    if State.RunningCollect then
        return
    end
    State.RunningCollect = true
    while State.AutoCollect do
        pcall(collectMoneyOnce)
        task.wait(CONFIG.CollectDelay)
    end
    State.RunningCollect = false
end
local function getEventsFolder()
    return ReplicatedStorage:FindFirstChild("Events")
end
local function getRemote(name)
    local events = getEventsFolder()
    if not events then
        return nil
    end
    return events:FindFirstChild(name)
end
local function fireRemote(name, ...)
    local remote = getRemote(name)
    if not remote then
        State.LastError = "Remote não encontrado: " .. name
        return false
    end
    if not remote:IsA("RemoteEvent") then
        State.LastError = name .. " não é RemoteEvent"
        return false
    end
    local ok = pcall(function()
        remote:FireServer(...)
    end)
    if not ok then
        State.LastError = "Falha ao chamar " .. name
    end
    return ok
end
local function autoSpeedLoop()
    if State.RunningSpeed then
        return
    end
    State.RunningSpeed = true
    while State.AutoSpeed do
        fireRemote("PurchaseSpeed", State.SpeedAmount)
        task.wait(CONFIG.SpeedDelay)
    end
    State.RunningSpeed = false
end
local function autoCarryLoop()
    if State.RunningCarry then
        return
    end
    State.RunningCarry = true
    while State.AutoCarry do
        fireRemote("PurchaseCarry")
        task.wait(CONFIG.CarryDelay)
    end
    State.RunningCarry = false
end
local function autoBaseUpgradeLoop()
    if State.RunningUpgrade then
        return
    end
    State.RunningUpgrade = true
    while State.AutoBaseUpgrade do
        fireRemote("RequestBaseUpgrade")
        task.wait(CONFIG.BaseUpgradeDelay)
    end
    State.RunningUpgrade = false
end
local function autoSellLoop()
    if State.RunningSell then
        return
    end
    State.RunningSell = true
    while State.AutoSell do
        fireRemote("RequestSell", "Inventory")
        task.wait(CONFIG.SellDelay)
    end
    State.RunningSell = false
end
local function updateZoneDropdown(dropdown)
    local values = { "All" }
    for _, zoneName in ipairs(getZoneNames()) do
        table.insert(values, zoneName)
    end
    pcall(function()
        dropdown:Refresh(values)
    end)
end
local function updateItemDropdown(dropdown)
    local values = {}
    for _, entry in ipairs(getIndexEntries(State.SelectedZone)) do
        table.insert(values, entry.Name)
    end
    pcall(function()
        dropdown:Refresh(values)
    end)
end
local function stopEverything()
    State.AutoFarm = false
    State.AutoCollect = false
    State.AutoSpeed = false
    State.AutoCarry = false
    State.AutoBaseUpgrade = false
    State.AutoSell = false
end
local AutoTab = Window:Tab({
    Title = "Auto Farm",
})
AutoTab:Paragraph({
    Title = "Run For Brainrots",
    Content = "Farm automático por Zones + ItemSpawners + ProximityPrompt + base dinâmica.",
})
local zoneDropdown = AutoTab:Dropdown({
    Title = "Zona",
    Values = { "All" },
    Value = "All",
    Callback = function(value)
        State.SelectedZone = value or "All"
        State.SelectedItems = {}
    end,
})
AutoTab:Toggle({
    Title = "Auto Farm",
    Desc = "Coleta Brainrots automaticamente.",
    Value = false,
    Callback = function(value)
        State.AutoFarm = value
        if value then
            task.spawn(autoFarmLoop)
        end
    end,
})
AutoTab:Toggle({
    Title = "Auto Collect Money",
    Desc = "Coleta as slots da sua base.",
    Value = false,
    Callback = function(value)
        State.AutoCollect = value
        if value then
            task.spawn(autoCollectLoop)
        end
    end,
})
AutoTab:Button({
    Title = "Atualizar zonas",
    Callback = function()
        updateZoneDropdown(zoneDropdown)
    end,
})
AutoTab:Button({
    Title = "Ir para base + coletar",
    Callback = function()
        task.spawn(returnToBase)
    end,
})
AutoTab:Button({
    Title = "Parar tudo",
    Callback = stopEverything,
})
local BrainrotTab = Window:Tab({
    Title = "Brainrots",
})
BrainrotTab:Paragraph({
    Title = "Filtro",
    Content = "Sem seleção = todos. A lista usa PlayerGui.GUI.Frames.Index.Scrolling.",
})
local itemDropdown = BrainrotTab:Dropdown({
    Title = "Selecionar Brainrots",
    Values = {},
    Multi = true,
    Callback = function(values)
        State.SelectedItems = {}
        if typeof(values) == "table" then
            for key, value in pairs(values) do
                local selected = type(key) == "number" and value or key
                if type(selected) == "string" and selected ~= "" then
                    State.SelectedItems[selected] = true
                end
            end
        elseif typeof(values) == "string" and values ~= "" then
            State.SelectedItems[values] = true
        end
    end,
})
BrainrotTab:Button({
    Title = "Atualizar Brainrots",
    Callback = function()
        updateItemDropdown(itemDropdown)
    end,
})
BrainrotTab:Button({
    Title = "Limpar filtro",
    Callback = function()
        State.SelectedItems = {}
        pcall(function()
            itemDropdown:Select({})
        end)
    end,
})
BrainrotTab:Button({
    Title = "Recarregar zonas + Brainrots",
    Callback = function()
        updateZoneDropdown(zoneDropdown)
        updateItemDropdown(itemDropdown)
    end,
})
local UpgradeTab = Window:Tab({
    Title = "Upgrade",
})
UpgradeTab:Paragraph({
    Title = "Compras",
    Content = "Os RemoteEvents ficam separados do Auto Farm para facilitar teste.",
})
UpgradeTab:Input({
    Title = "Quantidade de Speed",
    Desc = "Valores usados publicamente incluem 1, 5 e 10.",
    Value = "10",
    Placeholder = "1-100",
    Callback = function(value)
        local n = tonumber(value)
        if n then
            State.SpeedAmount = math.clamp(math.floor(n), 1, 100)
        end
    end,
})
UpgradeTab:Button({
    Title = "Comprar Speed",
    Callback = function()
        fireRemote("PurchaseSpeed", State.SpeedAmount)
    end,
})
UpgradeTab:Button({
    Title = "Comprar Carry",
    Callback = function()
        fireRemote("PurchaseCarry")
    end,
})
UpgradeTab:Button({
    Title = "Upgrade Base",
    Callback = function()
        fireRemote("RequestBaseUpgrade")
    end,
})
UpgradeTab:Button({
    Title = "Rebirth",
    Callback = function()
        fireRemote("RequestRebirth")
    end,
})
UpgradeTab:Button({
    Title = "Sell Inventory",
    Callback = function()
        fireRemote("RequestSell", "Inventory")
    end,
})
UpgradeTab:Toggle({
    Title = "Auto Speed",
    Desc = "Compra Speed continuamente.",
    Value = false,
    Callback = function(value)
        State.AutoSpeed = value
        if value then
            task.spawn(autoSpeedLoop)
        end
    end,
})
UpgradeTab:Toggle({
    Title = "Auto Carry",
    Desc = "Compra Carry continuamente.",
    Value = false,
    Callback = function(value)
        State.AutoCarry = value
        if value then
            task.spawn(autoCarryLoop)
        end
    end,
})
UpgradeTab:Toggle({
    Title = "Auto Base Upgrade",
    Desc = "Tenta atualizar a base automaticamente.",
    Value = false,
    Callback = function(value)
        State.AutoBaseUpgrade = value
        if value then
            task.spawn(autoBaseUpgradeLoop)
        end
    end,
})
UpgradeTab:Toggle({
    Title = "Auto Sell",
    Desc = "Tenta vender o inventário automaticamente.",
    Value = false,
    Callback = function(value)
        State.AutoSell = value
        if value then
            task.spawn(autoSellLoop)
        end
    end,
})
local TeleportTab = Window:Tab({
    Title = "Teleport",
})
TeleportTab:Paragraph({
    Title = "Zonas",
    Content = "As posições são procuradas dinamicamente em Workspace.Zones.",
})
for _, zoneName in ipairs(getZoneNames()) do
    TeleportTab:Button({
        Title = zoneName,
        Callback = function()
            local zone = getZone(zoneName)
            local part = getZonePart(zone)
            if part then
                updateState("Teleportando", zoneName, "-")
                teleportTo(part)
            else
                State.LastError = "Parte da zona não encontrada: " .. zoneName
            end
        end,
    })
end
TeleportTab:Button({
    Title = "Base",
    Callback = function()
        returnToBase()
    end,
})
local ScannerTab = Window:Tab({
    Title = "Scanner",
})
local scannerParagraph = ScannerTab:Paragraph({
    Title = "Diagnóstico",
    Content = "Clique em Atualizar Scanner.",
})
local function buildScannerText()
    local zones = getZoneNames()
    local spawnerCount = 0
    local promptCount = 0
    local events = {}
    local index = getIndexEntries("All")
    local spawners = getItemSpawnersFolder()
    if spawners then
        for _, descendant in ipairs(spawners:GetDescendants()) do
            if descendant:IsA("ProximityPrompt") then
                promptCount += 1
            end
        end
        for _, zoneName in ipairs(zones) do
            spawnerCount += #getTargetList(zoneName)
        end
    end
    local eventFolder = getEventsFolder()
    if eventFolder then
        for _, event in ipairs(eventFolder:GetChildren()) do
            if event:IsA("RemoteEvent") then
                table.insert(events, event.Name)
            end
        end
    end
    local eventText = #events > 0 and table.concat(events, ", ") or "Nenhum"
    return table.concat({
        "Zonas: " .. tostring(#zones),
        "Spawners com prompt: " .. tostring(spawnerCount),
        "Prompts: " .. tostring(promptCount),
        "Brainrots no Index: " .. tostring(#index),
        "Carry: " .. tostring(getCarryCount()) .. " / " .. tostring(getMaxCarry()),
        "Base: " .. (getPlot() and "ENCONTRADA" or "NÃO ENCONTRADA"),
        "Eventos: " .. eventText,
    }, "\n")
end
ScannerTab:Button({
    Title = "Atualizar Scanner",
    Callback = function()
        pcall(function()
            scannerParagraph:SetDesc(buildScannerText())
        end)
    end,
})
ScannerTab:Button({
    Title = "Testar primeiro Prompt",
    Callback = function()
        local zones = getZoneNames()
        for _, zoneName in ipairs(zones) do
            local targets = getTargetList(zoneName)
            if #targets > 0 then
                local target = targets[1]
                updateState("Testando Prompt", zoneName, target.Name)
                teleportTo(target.Part)
                task.wait(0.15)
                activatePrompt(target.Prompt)
                break
            end
        end
    end,
})
ScannerTab:Button({
    Title = "Atualizar listas",
    Callback = function()
        updateZoneDropdown(zoneDropdown)
        updateItemDropdown(itemDropdown)
    end,
})
local StatusTab = Window:Tab({
    Title = "Status",
})
local statusParagraph = StatusTab:Paragraph({
    Title = "Status atual",
    Content = "Iniciando...",
})
local function buildStatusText()
    local runningFor = math.floor(os.clock() - State.StartedAt)
    return table.concat({
        "Auto Farm: " .. (State.AutoFarm and "ON" or "OFF"),
        "Auto Collect: " .. (State.AutoCollect and "ON" or "OFF"),
        "Auto Speed: " .. (State.AutoSpeed and "ON" or "OFF"),
        "Auto Carry: " .. (State.AutoCarry and "ON" or "OFF"),
        "Auto Base: " .. (State.AutoBaseUpgrade and "ON" or "OFF"),
        "Auto Sell: " .. (State.AutoSell and "ON" or "OFF"),
        "",
        "Ação: " .. State.CurrentAction,
        "Zona: " .. State.CurrentZone,
        "Brainrot: " .. State.CurrentItem,
        "Método: " .. State.InteractionMethod,
        "Carry: " .. tostring(getCarryCount()) .. " / " .. tostring(getMaxCarry()),
        "Ciclos: " .. tostring(State.FarmCycles),
        "Coletas: " .. tostring(State.MoneyCollections),
        "Prompts: " .. tostring(State.PromptCalls),
        "Tempo: " .. tostring(runningFor) .. "s",
        "Erro: " .. State.LastError,
    }, "\n")
end
local function refreshStatus()
    pcall(function()
        statusParagraph:SetDesc(buildStatusText())
    end)
end
StatusTab:Button({
    Title = "Atualizar Status",
    Callback = refreshStatus,
})
StatusTab:Button({
    Title = "Ir para Base",
    Callback = function()
        returnToBase()
    end,
})
StatusTab:Button({
    Title = "Parar tudo",
    Callback = stopEverything,
})
StatusTab:Button({
    Title = "Recarregar interface",
    Callback = function()
        updateZoneDropdown(zoneDropdown)
        updateItemDropdown(itemDropdown)
        refreshStatus()
    end,
})
task.spawn(function()
    task.wait(1)
    updateZoneDropdown(zoneDropdown)
    updateItemDropdown(itemDropdown)
end)
task.spawn(function()
    while task.wait(1) do
        refreshStatus()
    end
end)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if State.AutoFarm then
        updateState("Recuperando após respawn", State.CurrentZone, State.CurrentItem)
    end
end)
refreshStatus()
print("========================================")
print(" CORRA PARA BRAINROTS - WINDUI AUTO FARM")
print(" PlaceId:", game.PlaceId)
print(" WindUI:", WINDUI_URL)
print("========================================")
