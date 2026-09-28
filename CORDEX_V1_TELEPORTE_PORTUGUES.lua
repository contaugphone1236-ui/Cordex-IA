--[[
    CORDEX V1 - SCRIPT COMPLETO
    Interface + Egg Scanner + Auto Farm Core + Bridge + Teleporte Direto + Teleporte
    Tudo em um único script.
]]


local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GlobalEnv
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then
        GlobalEnv = result
    end
end
GlobalEnv = GlobalEnv or _G

GlobalEnv.CORDEX_V1_CONTEXT = GlobalEnv.CORDEX_V1_CONTEXT or {}
local Context = GlobalEnv.CORDEX_V1_CONTEXT
Context.State = Context.State or {}
Context.Modules = Context.Modules or {}
Context.InternalAPI = Context.InternalAPI or {}
Context.PatchSystem = Context.PatchSystem or {}

local Estado = Context.State

Context.InternalAPI.SetPatchAuthorized = Context.InternalAPI.SetPatchAuthorized or function(Value)
    Context.PatchAuthorized = Value == true
end

Context.InternalAPI.IsPatchAuthorized = Context.InternalAPI.IsPatchAuthorized or function()
    return Context.PatchAuthorized == true
end

Estado.AutoFarm = Estado.AutoFarm == true
Estado.ModoMovimento = "Teleporte Direto"
Estado.FarmSpeed = tonumber(Estado.FarmSpeed) or 50
Estado.SelectedEggs = Estado.SelectedEggs or {}
Estado.SelectedRarities = Estado.SelectedRarities or {}
Estado.PrioridadeSorte = Estado.PrioridadeSorte == true
Estado.WalkSpeed = tonumber(Estado.WalkSpeed) or 16
Estado.JumpPower = tonumber(Estado.JumpPower) or 50
Estado.FlySpeed = tonumber(Estado.FlySpeed) or 50
Estado.AutoCompraComida = Estado.AutoCompraComida == true
Estado.AutoCompraRadar = Estado.AutoCompraRadar == true
Estado.AutoRejoin = Estado.AutoRejoin == true
Estado.Performance = Estado.Performance == true
Estado.Animacoes = Estado.Animacoes ~= false

local WindUI
local ok, result = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not ok or not result then
    warn("[CORDEX V1] Não foi possível carregar a WindUI.")
    return
end
WindUI = result

local Icons = {
    Home="home", Player="user", Egg="egg", Speed="zap", Jump="move-up",
    Fly="wind", Shop="shopping-cart", Radar="radar", Refresh="refresh-cw",
    Settings="settings", Monitor="monitor", Activity="activity", Map="map",
    Target="crosshair", Luck="sparkles", Filter="filter",
    Navigation="navigation"
}

local EggNames = {
    "Ovo Branco","Ovo Marrom","Ovo Rachado","Ovo de Páscoa","Ovo de Pedra",
    "Ovo de Folha","Ovo de Cogumelo","Ovo de Flor","Ovo de Slime","Ovo de Gelo",
    "Ovo de Vidro","Ovo Dourado","Ovo de Cristal","Ovo de Caveira","Ovo Dominus",
    "Ovo Flamejante","Ovo Sinistro","Ovo da Alma","Ovo Aurora","Ovo Galáxia",
    "Ovo Buraco Negro","Ovo Solaris","Ovo Cherub","Ovo Vulcânico","Ovo Bloom"
}

local RarityNames = {
    "Comum","Incomum","Raro","Épico","Lendário","Mítico","Divino","Secreto","Eterno"
}

local success, Window = pcall(function()
    return WindUI:CreateWindow({
        Title="CORDEX V1", Icon="sparkles", Author="CORDEX",
        Folder="CORDEX_V1", Size=UDim2.fromOffset(580,480),
        Transparent=true, Theme="Dark", Resizable=true, SideBarWidth=190
    })
end)

if not success or not Window then
    warn("[CORDEX V1] Falha ao criar Window.")
    return
end

Context.Window = Window

local MainTab = Window:Tab({Title="Main", Icon=Icons.Home})
local PlayerTab = Window:Tab({Title="Player", Icon=Icons.Player})
local AutoCompraTab = Window:Tab({Title="Auto Compra", Icon=Icons.Shop})
local DiversosTab = Window:Tab({Title="Diversos", Icon=Icons.Settings})

Context.MainTab = MainTab
Context.PlayerTab = PlayerTab
Context.AutoCompraTab = AutoCompraTab
Context.DiversosTab = DiversosTab

MainTab:Section({Title="AUTO FARM"})

MainTab:Toggle({
    Title="Coleta Automática", Desc="Ativa a coleta automática dos ovos.",
    Icon=Icons.Egg, Value=Estado.AutoFarm,
    Callback=function(Value)
        Estado.AutoFarm = Value == true
        local Core = Context.Core
        if Core then
            if Estado.AutoFarm and type(Core.StartFarm)=="function" then
                pcall(Core.StartFarm)
            elseif not Estado.AutoFarm and type(Core.StopFarm)=="function" then
                pcall(Core.StopFarm)
            end
        end
    end
})

MainTab:Slider({
    Title="Velocidade da Coleta", Desc="Velocidade usada pelo sistema de coleta.",
    Icon=Icons.Speed, Value={Min=1,Max=500,Default=math.clamp(tonumber(Estado.FarmSpeed) or 50,1,500)},
    Callback=function(Value) Estado.FarmSpeed=math.clamp(tonumber(Value) or 50,1,500) end
})

MainTab:Dropdown({
    Title="Selecionar Ovos", Desc="Escolha quais ovos serão coletados.",
    Icon=Icons.Egg, Values=EggNames, Multi=true, Value=Estado.SelectedEggs,
    Callback=function(Value) Estado.SelectedEggs=type(Value)=="table" and Value or {} end
})

MainTab:Section({Title="FILTRO DE RARIDADE"})

MainTab:Dropdown({
    Title="Selecionar Raridade", Desc="Filtra os ovos pela raridade.",
    Icon=Icons.Filter, Values=RarityNames, Multi=true, Value=Estado.SelectedRarities,
    Callback=function(Value) Estado.SelectedRarities=type(Value)=="table" and Value or {} end
})

MainTab:Toggle({
    Title="Priorizar Sorte", Desc="Prioriza os ovos com maior sorte.",
    Icon=Icons.Luck, Value=Estado.PrioridadeSorte,
    Callback=function(Value) Estado.PrioridadeSorte=Value==true end
})

MainTab:Section({Title="NAVEGAÇÃO"})

MainTab:Button({
    Title="Ir para o Rancho", Desc="Teleporta até o seu rancho, sua base.", Icon=Icons.Map,
    Callback=function()
        local Start=os.clock()
        while not Context.CoreReady and os.clock()-Start<5 do
            task.wait(0.05)
        end
        local Core=Context.Core
        if Core and type(Core.TeleportToRanch)=="function" then
            pcall(Core.TeleportToRanch)
        end
    end
})

MainTab:Button({
    Title="Ir para o Ovo Atual", Desc="Teleporta até o ovo escolhido.", Icon=Icons.Target,
    Callback=function()
        local Start=os.clock()
        while not Context.CoreReady and os.clock()-Start<5 do
            task.wait(0.05)
        end
        local Core=Context.Core
        if Core and type(Core.TeleportToCurrentEgg)=="function" then
            pcall(Core.TeleportToCurrentEgg)
        end
    end
})

PlayerTab:Section({Title="MOVIMENTO"})

PlayerTab:Slider({
    Title="Velocidade", Desc="Velocidade do personagem.", Icon=Icons.Speed,
    Value={Min=1,Max=500,Default=math.clamp(tonumber(Estado.WalkSpeed) or 16,1,500)},
    Callback=function(Value)
        Estado.WalkSpeed=math.clamp(tonumber(Value) or 16,1,500)
        local Character=LocalPlayer.Character
        local Humanoid=Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then Humanoid.WalkSpeed=Estado.WalkSpeed end
    end
})

PlayerTab:Slider({
    Title="Força do Pulo", Desc="Força do pulo.", Icon=Icons.Jump,
    Value={Min=1,Max=500,Default=math.clamp(tonumber(Estado.JumpPower) or 50,1,500)},
    Callback=function(Value)
        Estado.JumpPower=math.clamp(tonumber(Value) or 50,1,500)
        local Character=LocalPlayer.Character
        local Humanoid=Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then Humanoid.UseJumpPower=true Humanoid.JumpPower=Estado.JumpPower end
    end
})

PlayerTab:Slider({
    Title="Velocidade do Voo", Desc="Velocidade do sistema de voo.", Icon=Icons.Fly,
    Value={Min=1,Max=500,Default=math.clamp(tonumber(Estado.FlySpeed) or 50,1,500)},
    Callback=function(Value) Estado.FlySpeed=math.clamp(tonumber(Value) or 50,1,500) end
})

AutoCompraTab:Section({Title="COMPRAS AUTOMÁTICAS"})

AutoCompraTab:Toggle({
    Title="Comprar Comida Automaticamente", Desc="Ativa a opção de compra automática de comida.",
    Icon=Icons.Shop, Value=Estado.AutoCompraComida,
    Callback=function(Value) Estado.AutoCompraComida=Value==true end
})

AutoCompraTab:Toggle({
    Title="Comprar Radar Automaticamente", Desc="Ativa a opção de compra automática de radar.",
    Icon=Icons.Radar, Value=Estado.AutoCompraRadar,
    Callback=function(Value) Estado.AutoCompraRadar=Value==true end
})

DiversosTab:Section({Title="DIVERSOS"})

DiversosTab:Toggle({
    Title="Reconectar Automaticamente", Desc="Mantém a preferência de reconexão ativada.",
    Icon=Icons.Refresh, Value=Estado.AutoRejoin,
    Callback=function(Value) Estado.AutoRejoin=Value==true end
})

DiversosTab:Toggle({
    Title="Desempenho", Desc="Reduz alguns efeitos visuais para melhorar desempenho.",
    Icon=Icons.Monitor, Value=Estado.Performance,
    Callback=function(Value)
        Estado.Performance=Value==true
        if not Estado.Performance then return end
        pcall(function()
            local Lighting=game:GetService("Lighting")
            Lighting.GlobalShadows=false
            for _,Object in ipairs(Lighting:GetChildren()) do
                if Object:IsA("BlurEffect") or Object:IsA("BloomEffect") or Object:IsA("SunRaysEffect") or Object:IsA("ColorCorrectionEffect") then
                    Object.Enabled=false
                end
            end
        end)
    end
})

DiversosTab:Toggle({
    Title="Animações", Desc="Controla a preferência de animações.",
    Icon=Icons.Activity, Value=Estado.Animacoes,
    Callback=function(Value) Estado.Animacoes=Value==true end
})

DiversosTab:Section({Title="STATUS"})

DiversosTab:Button({
    Title="Verificar Sistema", Desc="Verifica o estado das partes do CORDEX.",
    Icon=Icons.Activity,
    Callback=function()
        print("========== CORDEX V1 ==========")
        print("UI:",Context.UIReady)
        print("Scanner:",Context.EggScannerReady)
        print("Core:",Context.CoreReady)
        print("Movement:",Context.MovementReady)
        print("Bridge:",Context.BridgeReady)
        print("Patch:",Context.PatchAuthorized)
        print("AutoFarm:",Estado.AutoFarm)
        print("Modo:",Estado.ModoMovimento)
        print("Farm Speed:",Estado.FarmSpeed)
        print("===============================")
    end
})

Context.UIAPI = {
    GetWindow=function() return Context.Window end,
    GetState=function() return Context.State end,
    GetMainTab=function() return Context.MainTab end,
    GetPlayerTab=function() return Context.PlayerTab end,
    GetAutoCompraTab=function() return Context.AutoCompraTab end,
    GetDiversosTab=function() return Context.DiversosTab end,
    GetEstado=function(Key) return Estado[Key] end,
    SetEstado=function(Key,Value) Estado[Key]=Value return true end
}

if Context.CharacterConnection then pcall(function() Context.CharacterConnection:Disconnect() end) end
Context.CharacterConnection=LocalPlayer.CharacterAdded:Connect(function(Character)
    task.wait(0.5)
    local Humanoid=Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        pcall(function()
            Humanoid.WalkSpeed=Estado.WalkSpeed
            Humanoid.UseJumpPower=true
            Humanoid.JumpPower=Estado.JumpPower
        end)
    end
end)

Context.UIReady=true
Context.Modules.Part1={Name="Part1",Type="UI",Version=1,API=Context.UIAPI}

print("[CORDEX V1] PARTE 1 CARREGADA")

-- CARREGAMENTO RÁPIDO:
-- A interface termina primeiro e os módulos internos continuam em segundo plano.
-- Isso evita que o scanner/core bloqueiem a primeira renderização da WindUI.
task.defer(function()
    task.wait()


local Context=getgenv().CORDEX_V1_CONTEXT
if not Context then warn("[CORDEX V1] Parte 2: Context não encontrado. Execute a Parte 1 primeiro.") return end

local Players=game:GetService("Players")
local LocalPlayer=Players.LocalPlayer
local Workspace=game:GetService("Workspace")

Context.Modules=Context.Modules or {}

local OvosMap={
    ["Ovo Branco"]="White Egg",["Ovo Marrom"]="Brown Egg",["Ovo Rachado"]="Cracked Egg",
    ["Ovo de Páscoa"]="Easter Egg",["Ovo de Pedra"]="Stone Egg",["Ovo de Folha"]="Leaf Egg",
    ["Ovo de Cogumelo"]="Mushroom Egg",["Ovo de Flor"]="Flower Egg",["Ovo de Slime"]="Slime Egg",
    ["Ovo de Gelo"]="Ice Egg",["Ovo de Vidro"]="Glass Egg",["Ovo Dourado"]="Golden Egg",
    ["Ovo de Cristal"]="Crystal Egg",["Ovo de Caveira"]="Skull Egg",["Ovo Dominus"]="Dominus Egg",
    ["Ovo Flamejante"]="Flaming Egg",["Ovo Sinistro"]="Sinister Egg",["Ovo da Alma"]="Soul Egg",
    ["Ovo Aurora"]="Aurora Egg",["Ovo Galáxia"]="Galaxy Egg",["Ovo Buraco Negro"]="Blackhole Egg",
    ["Ovo Solaris"]="Solaris Egg",["Ovo Cherub"]="Cherub Egg",["Ovo Vulcânico"]="Volcanic Egg",
    ["Ovo Bloom"]="Bloom Egg"
}

local LuckDosOvos={
    ["Blackhole Egg"]=100,["Solaris Egg"]=90,["Cherub Egg"]=80,["Bloom Egg"]=70
}

local Raridades={
    ["Blackhole Egg"]="Eterno",["Solaris Egg"]="Divino",
    ["Cherub Egg"]="Mítico",["Bloom Egg"]="Lendário"
}

local ProcessedEggs=setmetatable({}, {__mode="k"})

local function NormalizeName(Name)
    return tostring(Name or ""):gsub("@Plant%d+$","")
end

local function GetEggPosition(Egg)
    if Egg:IsA("Model") then
        local ok,cf=pcall(function() return Egg:GetPivot() end)
        if ok and cf then return cf.Position end
    elseif Egg:IsA("BasePart") then
        return Egg.Position
    end
    return nil
end

local function IsValidEgg(Egg)
    return Egg and (Egg:IsA("Model") or Egg:IsA("BasePart"))
end

local function IsSelectedEgg(EggName)
    local Selected=Context.State.SelectedEggs or {}
    if #Selected==0 then return true end
    local GameName=OvosMap[EggName] or EggName
    for _,Value in pairs(Selected) do
        if Value==EggName or Value==GameName then return true end
    end
    return false
end

local function IsSelectedRarity(GameName)
    local Selected=Context.State.SelectedRarities or {}
    if #Selected==0 then return true end
    local Rarity=Raridades[GameName]
    if not Rarity then return true end
    for _,Value in pairs(Selected) do
        if Value==Rarity then return true end
    end
    return false
end

local function ScanEggs()
    local Folder=Workspace:FindFirstChild("RenderedEggs")
    local Results={}
    if not Folder then return Results end

    for _,Egg in ipairs(Folder:GetChildren()) do
        if IsValidEgg(Egg) then
            local RawName=NormalizeName(Egg.Name)
            if IsSelectedEgg(RawName) then
                local GameName=OvosMap[RawName] or RawName
                if IsSelectedRarity(GameName) then
                    local Position=GetEggPosition(Egg)
                    if Position then
                        table.insert(Results,{
                            Object=Egg,Name=RawName,GameName=GameName,
                            Position=Position,Luck=LuckDosOvos[GameName] or 0,
                            Rarity=Raridades[GameName]
                        })
                    end
                end
            end
        end
    end
    return Results
end

local function FindBestEgg()
    local Eggs=ScanEggs()
    local Root
    local Character=LocalPlayer.Character
    if Character then Root=Character:FindFirstChild("HumanoidRootPart") end

    table.sort(Eggs,function(A,B)
        if Context.State.PrioridadeSorte then
            if A.Luck~=B.Luck then return A.Luck>B.Luck end
        end
        if Root then
            return (A.Position-Root.Position).Magnitude < (B.Position-Root.Position).Magnitude
        end
        return false
    end)

    for _,Egg in ipairs(Eggs) do
        if not ProcessedEggs[Egg.Object] then return Egg end
    end
    return nil
end

local function FindRanch()
    local Plots=Workspace:FindFirstChild("Plots")
    if not Plots then return nil end

    for _,Plot in ipairs(Plots:GetChildren()) do
        local Data=Plot:FindFirstChild("Data")
        local Owner=Data and Data:FindFirstChild("Owner")
        if Owner then
            if Owner:IsA("ObjectValue") and Owner.Value==LocalPlayer then return Plot end
            if Owner:IsA("StringValue") and Owner.Value==LocalPlayer.Name then return Plot end
        end
    end
    return nil
end

local function GetRanchCFrame()
    local Ranch=FindRanch()
    if not Ranch then return nil end
    if Ranch:IsA("Model") then
        local ok,cf=pcall(function() return Ranch:GetPivot() end)
        if ok then return cf end
    elseif Ranch:IsA("BasePart") then
        return Ranch.CFrame
    end
    return nil
end

local function FindPickupPrompt(Egg)
    if not Egg then return nil end
    return Egg:FindFirstChildWhichIsA("ProximityPrompt",true)
end

local function GetPickupPosition(Egg)
    local Prompt=FindPickupPrompt(Egg)
    if not Prompt then return nil end

    local Parent=Prompt.Parent
    if Parent and Parent:IsA("Attachment") then
        return Parent.WorldPosition
    end
    if Parent and Parent:IsA("BasePart") then
        return Parent.Position
    end

    local Part=Prompt:FindFirstAncestorWhichIsA("BasePart")
    if Part then return Part.Position end
    return nil
end

local function CollectEgg(EggData)
    if not EggData or not EggData.Object then return false end
    local Prompt=FindPickupPrompt(EggData.Object)
    if not Prompt then return false end

    local ok=pcall(function()
        Prompt:InputHoldBegin()
        task.wait(math.max(Prompt.HoldDuration or 0,0.05))
        Prompt:InputHoldEnd()
    end)
    return ok
end

local function GetCharacter() return LocalPlayer.Character end
local function GetHumanoid()
    local Character=GetCharacter()
    return Character and Character:FindFirstChildOfClass("Humanoid")
end
local function GetRoot()
    local Character=GetCharacter()
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

Context.EggScannerReady=true
Context.EggScanner={
    ScanEggs=ScanEggs,FindBestEgg=FindBestEgg,FindRanch=FindRanch,
    GetRanchCFrame=GetRanchCFrame,GetPickupPosition=GetPickupPosition,FindPickupPrompt=FindPickupPrompt,
    CollectEgg=CollectEgg,GetCharacter=GetCharacter,
    GetHumanoid=GetHumanoid,GetRoot=GetRoot,
    MarkProcessed=function(Egg) if Egg then ProcessedEggs[Egg]=true end end
}

Context.Modules.Part2={Name="Part2",Type="EggScanner",Version=1,API=Context.EggScanner}
print("[CORDEX V1] SCANNER PRONTO")


local Context=getgenv().CORDEX_V1_CONTEXT
if not Context then warn("[CORDEX V1] Parte 3: Context não encontrado.") return end

local Players=game:GetService("Players")
local LocalPlayer=Players.LocalPlayer

local Running=false
local FarmToken=0
local FarmThread=nil
local CurrentTarget=nil
local CurrentStage="Parado"

local function Scanner() return Context.EggScanner end

local function DirectTeleport(Position)
    if typeof(Position)~="Vector3" then return false end

    local Character=LocalPlayer.Character
    local Root=Character and Character:FindFirstChild("HumanoidRootPart")
    if not Character or not Root then return false end

    local Destination=Position+Vector3.new(0,3,0)
    local Look=Root.CFrame.LookVector
    local TargetCFrame=CFrame.lookAt(Destination,Destination+Look)
    CurrentStage="Teleportando para o ovo"

    -- Teleporte direto: não depende de MoveTo, WalkSpeed ou TeleGuiado.
    for Attempt=1,5 do
        Character=LocalPlayer.Character
        Root=Character and Character:FindFirstChild("HumanoidRootPart")
        if not Character or not Root then
            task.wait(0.1)
        else
            local ok=pcall(function()
                if Character:IsA("Model") then
                    Character:PivotTo(TargetCFrame)
                end
                Root.CFrame=TargetCFrame
            end)

            if ok then
                task.wait(0.08)
                Character=LocalPlayer.Character
                Root=Character and Character:FindFirstChild("HumanoidRootPart")
                if Root then
                    local Distance=(Root.Position-Destination).Magnitude
                    if Distance<=8 then
                        CurrentStage="Chegou ao destino"
                        return true
                    end
                end
            end
        end
        task.wait(0.08)
    end

    CurrentStage="Falha no teleporte"
    return false
end

local function MoveToPosition(Position)
    if typeof(Position)~="Vector3" then return false end

    local Mode="Teleporte Direto"

    local Character=LocalPlayer.Character
    local Humanoid=Character and Character:FindFirstChildOfClass("Humanoid")
    local Root=Character and Character:FindFirstChild("HumanoidRootPart")
    if not Root then return false end

    local Destination=Position+Vector3.new(0,3,0)

    if Mode=="Teleporte Direto" or Mode=="Teleporte" then
        return DirectTeleport(Position)
    end

    -- TeleGuiado permanece com a movimentação normal que já existia.
    if not Humanoid then return false end
    local OldWalkSpeed=Humanoid.WalkSpeed
    local Start=os.clock()
    while Running and os.clock()-Start<12 do
        Humanoid:MoveTo(Destination)
        Root=Character:FindFirstChild("HumanoidRootPart")
        if Root and (Root.Position-Destination).Magnitude<=4 then
            Humanoid.WalkSpeed=OldWalkSpeed
            return true
        end
        task.wait(0.05)
    end
    Humanoid.WalkSpeed=OldWalkSpeed
    return false
end

local function TeleportToEgg(Target)
    if not Target or not Target.Object then return false end
    CurrentStage="Indo para o ovo"

    local ScannerAPI=Scanner()
    local Destination=ScannerAPI and ScannerAPI.GetPickupPosition and ScannerAPI.GetPickupPosition(Target.Object)
    Destination=Destination or Target.Position
    return DirectTeleport(Destination)
end

local function GetRanch()
    local ScannerAPI=Scanner()
    return ScannerAPI and ScannerAPI.GetRanchCFrame and ScannerAPI.GetRanchCFrame()
end

local function TeleportToRanch()
    local Ranch=GetRanch()
    if not Ranch then return false end
    CurrentStage="Voltando para o rancho"
    return DirectTeleport(Ranch.Position+Vector3.new(0,4,0))
end

local function TeleportToCurrentEgg()
    local ScannerAPI=Scanner()
    local Target=ScannerAPI and ScannerAPI.FindBestEgg and ScannerAPI.FindBestEgg()
    if not Target then return false end
    CurrentTarget=Target
    return TeleportToEgg(Target)
end

local function WaitForEggToDisappear(Target,Timeout)
    local Start=os.clock()
    while os.clock()-Start<Timeout do
        if not Target or not Target.Object or not Target.Object.Parent then
            return true
        end

        local Prompt=Target.Object:FindFirstChildWhichIsA("ProximityPrompt",true)
        if not Prompt or Prompt.Enabled==false then
            return true
        end

        task.wait(0.1)
    end
    return false
end

local function CollectTarget(Target)
    local ScannerAPI=Scanner()
    if not ScannerAPI or type(ScannerAPI.CollectEgg)~="function" then return false end
    if not Target or not Target.Object then return false end

    CurrentStage="Pegando o ovo"
    local Started=ScannerAPI.CollectEgg(Target)
    if not Started then
        return false
    end

    local Collected=WaitForEggToDisappear(Target,6)
    if Collected and ScannerAPI.MarkProcessed then
        ScannerAPI.MarkProcessed(Target.Object)
    end
    return Collected
end

local function FarmCycle(Token)
    local ScannerAPI=Scanner()
    if not ScannerAPI then return end
    local Target=ScannerAPI.FindBestEgg()
    if not Target then
        CurrentStage="Procurando ovo"
        return
    end
    CurrentTarget=Target
    if not TeleportToEgg(Target) then return end
    if Token~=FarmToken or not Running then return end
    local Collected=CollectTarget(Target)
    if Token~=FarmToken or not Running then return end

    -- Se a coleta falhar, não marca o ovo como concluído.
    -- O próximo ciclo poderá tentar novamente.
    if not Collected then
        CurrentStage="Tentando pegar novamente"
        task.wait(0.25)
        return
    end

    TeleportToRanch()
    CurrentTarget=nil
    CurrentStage="Parado"
end

local function FarmLoop(Token)
    while Running and Token==FarmToken do
        pcall(function() FarmCycle(Token) end)
        task.wait(0.15)
    end
end

local function StartFarm()
    if Running then return true end
    Running=true
    FarmToken+=1
    local Token=FarmToken
    FarmThread=task.spawn(function() FarmLoop(Token) end)
    return true
end

local function StopFarm()
    Running=false
    FarmToken+=1
    FarmThread=nil
    CurrentTarget=nil
    CurrentStage="Parado"
    return true
end

Context.Core={
    StartFarm=StartFarm,StopFarm=StopFarm,
    DirectTeleport=DirectTeleport,TeleportToRanch=TeleportToRanch,TeleportToCurrentEgg=TeleportToCurrentEgg,
    IsRunning=function() return Running end,
    GetCurrentTarget=function() return CurrentTarget end,
    GetStage=function() return CurrentStage end
}

Context.CoreReady=true
Context.Modules.Part3={Name="Part3",Type="AutoFarmCore",Version=1,API=Context.Core}
print("[CORDEX V1] AUTO FARM PRONTO")


local Context=getgenv().CORDEX_V1_CONTEXT
if not Context then warn("[CORDEX V1] Parte 4: Context não encontrado.") return end

local Players=game:GetService("Players")
local LocalPlayer=Players.LocalPlayer

local function GetCore() return Context.Core end
local function GetScanner() return Context.EggScanner end
local function GetMovement() return Context.GuidedMovement end

local function StartFarm()
    local Core=GetCore()
    if Core and type(Core.StartFarm)=="function" then return Core.StartFarm() end
    return false
end

local function StopFarm()
    local Core=GetCore()
    if Core and type(Core.StopFarm)=="function" then return Core.StopFarm() end
    return false
end

local function UpdateFarm()
    local Core=GetCore()
    if not Core then return end

    if Context.State.AutoFarm then
        if not Core.IsRunning() then StartFarm() end
    else
        if Core.IsRunning() then StopFarm() end
    end
end

local function GetFullStatus()
    local Core=GetCore()
    return {
        UIReady=Context.UIReady==true,
        ScannerReady=Context.EggScannerReady==true,
        CoreReady=Context.CoreReady==true,
        MovementReady=Context.MovementReady==true,
        BridgeReady=Context.BridgeReady==true,
        Ready=Context.UIReady and Context.EggScannerReady and Context.CoreReady,
        AutoFarm=Context.State.AutoFarm==true,
        FarmRunning=Core and Core.IsRunning() or false,
        Stage=Core and Core.GetStage() or "Unavailable"
    }
end

local function UpdateReadyState()
    Context.Ready=
        Context.UIReady==true
        and Context.EggScannerReady==true
        and Context.CoreReady==true
end

if Context.CharacterConnectionPart4 then
    pcall(function() Context.CharacterConnectionPart4:Disconnect() end)
end

Context.CharacterConnectionPart4=LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    UpdateReadyState()
end)

Context.FinalAPI={
    StartFarm=StartFarm,
    StopFarm=StopFarm,
    UpdateFarm=UpdateFarm,
    GetFullStatus=GetFullStatus,
    UpdateReadyState=UpdateReadyState,
    GetCore=GetCore,
    GetScanner=GetScanner,
    GetMovement=GetMovement
}

Context.BridgeReady=true
UpdateReadyState()
Context.Modules.Part4={Name="Part4",Type="Bridge",Version=1,API=Context.FinalAPI}
print("[CORDEX V1] BRIDGE PRONTO")


local Context=getgenv().CORDEX_V1_CONTEXT
if not Context then warn("[CORDEX V1] Parte 5: Context não encontrado.") return end

local Players=game:GetService("Players")
local LocalPlayer=Players.LocalPlayer

local Running=false
local MovementToken=0
local CurrentTarget=nil
local CurrentDestination=nil
local CurrentStage="Parado"

local DEFAULT_SPEED=50
local MIN_SPEED=1
local MAX_SPEED=500
local ARRIVAL_DISTANCE=4
local HEIGHT_OFFSET=3
local UPDATE_INTERVAL=0.05

local function GetCharacter() return LocalPlayer.Character end
local function GetHumanoid()
    local Character=GetCharacter()
    return Character and Character:FindFirstChildOfClass("Humanoid")
end
local function GetRoot()
    local Character=GetCharacter()
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetSpeed()
    return math.clamp(
        tonumber(Context.State.FarmSpeed) or DEFAULT_SPEED,
        MIN_SPEED,MAX_SPEED
    )
end

local function GetDestinationPosition(Position)
    if typeof(Position)~="Vector3" then return nil end
    return Position+Vector3.new(0,HEIGHT_OFFSET,0)
end

local function CancelMovement()
    MovementToken+=1
    Running=false
    CurrentTarget=nil
    CurrentDestination=nil
    CurrentStage="Parado"
end

local function MoveToPosition(Position)
    local Destination=GetDestinationPosition(Position)
    if not Destination then return false end

    local Humanoid=GetHumanoid()
    local Root=GetRoot()
    if not Humanoid or not Root then return false end

    MovementToken+=1
    local Token=MovementToken
    Running=true
    CurrentDestination=Destination
    CurrentStage="Moving"

    local OldWalkSpeed=Humanoid.WalkSpeed
    local Speed=GetSpeed()
    Humanoid.WalkSpeed=math.clamp(Speed/10,8,100)

    Humanoid:MoveTo(Destination)

    while Running and Token==MovementToken do
        Root=GetRoot()
        Humanoid=GetHumanoid()
        if not Root or not Humanoid then break end

        local Distance=(Root.Position-Destination).Magnitude
        if Distance<=ARRIVAL_DISTANCE then
            Running=false
            CurrentStage="Arrived"
            Humanoid.WalkSpeed=OldWalkSpeed
            return true
        end

        Humanoid:MoveTo(Destination)
        task.wait(UPDATE_INTERVAL)
    end

    if Humanoid then Humanoid.WalkSpeed=OldWalkSpeed end
    Running=false
    CurrentStage="Parado"
    return false
end

local function GoToEgg(EggData)
    if not EggData or not EggData.Position then return false end
    CurrentTarget=EggData
    return MoveToPosition(EggData.Position)
end

local function GoToRanch(RanchCFrame)
    if not RanchCFrame then return false end
    CurrentTarget=nil
    return MoveToPosition(RanchCFrame.Position)
end

local function WaitUntilArrived(Timeout)
    local Start=os.clock()
    while Running and os.clock()-Start<(Timeout or 10) do
        task.wait(UPDATE_INTERVAL)
    end
    return not Running
end

local GuidedMovement={
    MoveToPosition=MoveToPosition,
    GoToEgg=GoToEgg,
    GoToRanch=GoToRanch,
    WaitUntilArrived=WaitUntilArrived,
    Cancel=CancelMovement,
    Stop=CancelMovement,
    IsRunning=function() return Running end,
    GetCurrentTarget=function() return CurrentTarget end,
    GetCurrentDestination=function() return CurrentDestination end,
    GetStage=function() return CurrentStage end,
    GetSpeed=GetSpeed
}

Context.GuidedMovement=GuidedMovement
Context.MovementReady=true
Context.Modules.Part5={Name="Part5",Type="GuidedMovement",Version=1,API=GuidedMovement}
print("[CORDEX V1] MOVIMENTO PRONTO")

end)
