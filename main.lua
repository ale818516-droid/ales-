-- ==================== SETUP INICIAL ====================
repeat task.wait() until game:IsLoaded()

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/azurelw/azurehub/refs/heads/main/main.lua"))()

-- Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==================== CONFIGURACIÓN DE UI ====================
local Window = WindUI:CreateWindow({
    Title = "ALexHub",
    Icon = "rbxassetid://4483345906",
    Author = "Alexx Hub",
    Folder = "MM2_New_Project"
})

-- Tema profesional
WindUI:AddTheme({
    ["Name"] = "Dark",
    ["Accent"] = "#18181b",
    ["Background"] = "#0e0e10"
})

-- ==========================================================
-- 1. CREACIÓN DE PESTAÑA Y SECCIÓN (¡IMPORTANTE!)
-- ==========================================================
local FarmTab = Window:Tab({Title = "Auto Farm", Icon = "rocket"})
local SecGun = FarmTab:Section({Title = "Gun Tools"}) -- AQUÍ SE CREA SecGun

-- ==========================================================
-- 2. LÓGICA OPTIMIZADA
-- ==========================================================
local function GetGunFast()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return false end
    
    local gun = Workspace:FindFirstChild("GunDrop", true)
    
    if gun and gun:IsA("BasePart") then
        firetouchinterest(hrp, gun, 0)
        task.wait()
        firetouchinterest(hrp, gun, 1)
        return true
    end
    return false
end

-- ==========================================================
-- 3. BUCLE DE ALTA VELOCIDAD (Ahora sí funciona porque SecGun existe)
-- ==========================================================
SecGun:Toggle({
    Title = "Auto Get Gun [FAST]",
    Default = false,
    Callback = function(state)
        _G.AutoGun = state
        if state then
            task.spawn(function()
                while _G.AutoGun do
                    local success = GetGunFast()
                    if success then
                        WindUI:Notify({Title = "¡Arma recogida!", Content = "Recogida instantánea.", Duration = 1})
                    end
                    task.wait(0.1) 
                end
            end)
        end
    end
})
-- ==========================================================
-- ESTRUCTURA FARM (Arreglado: bolsa llena se resetea por ronda)
-- ==========================================================
local FarmSection = FarmTab:Section({ Title = "Configuración de Farm" })

_G.autofarmEnabled = false
local currentSpeed = 20
local farmCoinType = "Egg"
local farming = true
local bag_full = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- Toggle
FarmSection:Toggle({
    Title = "Auto Farm",
    Default = false,
    Callback = function(state)
        _G.autofarmEnabled = state
    end
})

-- Slider
FarmSection:Slider({
    Title = "Velocidad de Farm",
    Value = { Min = 5, Max = 100, Default = 20 },
    Callback = function(v)
        currentSpeed = v
    end
})

FarmSection:Dropdown({
    Title = "Tipo de Moneda",
    Values = {"Egg", "Coin"},
    Value = "Egg",
    Callback = function(v)
        farmCoinType = v
    end
})

-- Lógica de recolección
task.spawn(function()
    local CoinCollected = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("CoinCollected")
    local RoundStart = ReplicatedStorage.Remotes.Gameplay:WaitForChild("RoundStart")
    local RoundEnd = ReplicatedStorage.Remotes.Gameplay:WaitForChild("RoundEndFade")

    local currentTween = nil

    local function get_nearest_coin(hrp)
        local closest_coin, min_distance = nil, math.huge
        for _, model in pairs(workspace:GetChildren()) do
            local cc = model:FindFirstChild("CoinContainer")
            if cc then
                for _, coin in pairs(cc:GetChildren()) do
                    if coin:GetAttribute("CoinID") == farmCoinType and coin:FindFirstChild("TouchInterest") then
                        local d = (hrp.Position - coin.Position).Magnitude
                        if d < min_distance then
                            closest_coin = coin
                            min_distance = d
                        end
                    end
                end
            end
        end
        return closest_coin, min_distance
    end

    -- Bolsa llena
    CoinCollected.OnClientEvent:Connect(function(coin_type, current, max)
        if coin_type == farmCoinType and current == max then
            bag_full = true
            WindUI:Notify({
                Title = "Bolsa Llena",
                Content = "Esperando a que se vacíe...",
                Duration = 4
            })
            repeat task.wait(1) until not bag_full
        end
    end)

    -- Reset al empezar nueva ronda
    RoundStart.OnClientEvent:Connect(function()
        farming = true
        bag_full = false  -- ←←← ESTO ERA EL PROBLEMA
    end)

    RoundEnd.OnClientEvent:Connect(function()
        farming = false
    end)

    -- Bucle principal
    while true do
        task.wait(0.03)

        if _G.autofarmEnabled and farming and not bag_full then
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local coin, dist = get_nearest_coin(hrp)
                if coin then
                    if currentTween then currentTween:Cancel() end

                    if dist > 150 then
                        hrp.CFrame = coin.CFrame
                    else
                        currentTween = TweenService:Create(hrp, TweenInfo.new(dist / math.max(1, currentSpeed), Enum.EasingStyle.Linear), {CFrame = coin.CFrame})
                        currentTween:Play()
                        repeat task.wait() until not coin:FindFirstChild("TouchInterest") or not _G.autofarmEnabled or not farming or bag_full
                        if currentTween then currentTween:Cancel() end
                    end
                end
            end
        end
    end
end)
-- Toggle para Anti-Murderer
FarmSection:Toggle({
    Title = "Anti-Murderer [No ir hacia él]",
    Default = false,
    Callback = function(state)
        _G.AntiMurderer = state
        WindUI:Notify({
            Title = "Anti-Murderer",
            Content = state and "Activado - No se acerca" or "Desactivado",
            Duration = 3
        })
    end
})

-- Lógica simple y fuerte
task.spawn(function()
    while task.wait(0.1) do
        if not _G.AntiMurderer then continue end

        local myChar = LP.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local humanoid = myChar and myChar:FindFirstChild("Humanoid")
        if not myHrp or not humanoid then continue end

        local closestMurderer = nil
        local closestDist = math.huge

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                local isMurderer = player:GetAttribute("Role") == "Murderer" 
                    or player.Backpack:FindFirstChild("Knife") 
                    or (player.Character and player.Character:FindFirstChild("Knife"))

                if isMurderer then
                    local mHrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if mHrp then
                        local dist = (myHrp.Position - mHrp.Position).Magnitude
                        if dist < closestDist and dist < 40 then
                            closestDist = dist
                            closestMurderer = mHrp
                        end
                    end
                end
            end
        end

        if closestMurderer then
            local directionToMurder = (closestMurderer.Position - myHrp.Position).Unit
            local currentMove = humanoid.MoveDirection

            -- Si intentas moverte hacia el asesino, lo bloqueamos
            if currentMove.Magnitude > 0.2 then
                if currentMove:Dot(directionToMurder) > 0.4 then
                    -- Cancela el movimiento hacia él
                    humanoid:MoveTo(myHrp.Position + currentMove * 8)
                end
            end
        end
    end
end)
-- ==========================================
-- ALEXX HUB - ROLE ESP SYSTEM
-- ==========================================

_G.ESP_Enabled = false
_G.LatestPlayerData = {}
_G.IsRefiningMode = false

local VisualsTab = Window:Tab({Title = "Visuals", Icon = "eye"})
local RoleSection = VisualsTab:Section({Title = "Role ESP System"})

-- Función para limpiar etiquetas y highlights
local function cleanESP(char)
    if char:FindFirstChild("RoleHighlight") then char.RoleHighlight:Destroy() end
    if char:FindFirstChild("Head") and char.Head:FindFirstChild("RoleTag") then char.Head.RoleTag:Destroy() end
end

-- Función principal de marcado
local function applyESP(player, role)
    local char = player.Character
    if not char then return end
    
    local color = (role == "Sheriff" and Color3.fromRGB(0, 170, 255)) or 
                  (role == "Murderer" and Color3.fromRGB(255, 85, 85)) or 
                  Color3.fromRGB(85, 255, 127)
    
    -- Aplicar Highlight
    local existing = char:FindFirstChild("RoleHighlight")
    if not existing then
        local h = Instance.new("Highlight")
        h.Name = "RoleHighlight"
        h.Adornee = char
        h.Parent = char
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.OutlineColor = color
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    elseif existing.OutlineColor ~= color then
        existing.OutlineColor = color
    end

    -- Aplicar Etiqueta [ASESINO]
local head = char:FindFirstChild("Head")
if head then
    if role == "Murderer" then
        if not head:FindFirstChild("RoleTag") then
            local bill = Instance.new("BillboardGui")
            bill.Name = "RoleTag"
            bill.Adornee = head
            
            -- AJUSTE PARA MANTENER LA RECTITUD:
            -- Con SizeOffset o configurando el tamaño en modo absoluto, 
            -- pero lo más efectivo es fijar el tamaño y limitar la escala.
            bill.Size = UDim2.new(0, 150, 0, 40) 
            bill.StudsOffset = Vector3.new(0, 2.5, 0)
            bill.AlwaysOnTop = true
            
            -- ESTA PROPIEDAD MANTIENE EL TAMAÑO FIJO Y RECTO
            -- Hace que la etiqueta no se haga gigante al acercarse o mini al alejarse
            bill.SizeOffset = Vector2.new(0, 0) 
            
            bill.Parent = head
            
            local label = Instance.new("TextLabel")
            label.Parent = bill
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "[ASESINO]" -- Simplificado para que no se deforme con nombres largos
            label.TextColor3 = color
            label.TextStrokeTransparency = 0
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 18
            
            -- Mantiene el texto perfectamente centrado y recto
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center
        end
    else
        if head:FindFirstChild("RoleTag") then head.RoleTag:Destroy() end
      end
   end
end

-- 1. EVENTO INICIAL (Siempre activo para recibir data)
game:GetService("ReplicatedStorage").Remotes.Gameplay.PlayerDataChanged.OnClientEvent:Connect(function(data)
    _G.LatestPlayerData = data
end)

-- 2. TEMPORIZADOR (10 segundos para modo objetos)
task.spawn(function()
    task.wait(10)
    _G.IsRefiningMode = true
end)

-- 3. BUCLE PRINCIPAL (Híbrido)
task.spawn(function()
    while task.wait(0.5) do
        if _G.ESP_Enabled then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player.Character then
                    local data = _G.LatestPlayerData and _G.LatestPlayerData[player.Name]
                    local role = data and data.Role or "Innocent"
                    
                    -- A los 10 segundos, forzamos corrección por inventario
                    if _G.IsRefiningMode then
                        if player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") then
                            role = "Sheriff"
                        elseif player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then
                            role = "Murderer"
                        end
                    end
                    
                    applyESP(player, role)
                else
                    -- Limpiar si el personaje desaparece
                    if player.Character then cleanESP(player.Character) end
                end
            end
        end
    end
end)

-- 4. TOGGLE
RoleSection:Toggle({
    Title = "Role ESP",
    Default = false,
    Callback = function(Value)
        _G.ESP_Enabled = Value
        if not Value then
            for _, p in pairs(game.Players:GetPlayers()) do
                if p.Character then cleanESP(p.Character) end
            end
        end
    end
})
-- Agrega esto justo debajo de tu RoleSection existente
local GunEspSection = VisualsTab:Section({Title = "Gun ESP"})

GunEspSection:Toggle({
    Title = "Highlight Gun Drop (Dorado)",
    Default = false,
    Callback = function(state)
        _G.HighlightGun = state
    end
})

-- Gun Highlight Loop
task.spawn(function()
    while true do
        if _G.HighlightGun then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == "GunDrop" then
                    local hl = obj:FindFirstChild("GunHighlightNet")
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "GunHighlightNet"
                        hl.FillColor = Color3.fromRGB(255, 215, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 165, 0)
                        hl.OutlineTransparency = 0
                        hl.FillTransparency = 0.5
                        hl.Parent = obj
                    end
                end
            end
        else
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == "GunDrop" then
                    local hl = obj:FindFirstChild("GunHighlightNet")
                    if hl then hl:Destroy() end
                end
            end
        end
        task.wait(0.7)
    end
end)

-- ==========================================================
-- HITBOX FÍSICA PARA SHERIFF + INOCENTES
-- ==========================================================

local HitboxSettings = {
    ["Hitbox"] = {
        ["Enabled"] = false,
        ["Size"] = 10
    }
}

local function UpdateHitboxes()
    if HitboxSettings.Hitbox.Enabled then
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer then
                local Character = Player.Character
                if Character then
                    local RootPart = Character:FindFirstChild("HumanoidRootPart")
                    if RootPart then
                        
                        -- Detección: Sheriff o Inocente (no Asesino)
                        local isMurderer = Character:FindFirstChild("Knife") or 
                                          (Player.Backpack and Player.Backpack:FindFirstChild("Knife")) or
                                          (Character:FindFirstChild("Role") and Character.Role.Value == "Murderer")
                        
                        if not isMurderer then
                            RootPart.Size = Vector3.new(HitboxSettings.Hitbox.Size, HitboxSettings.Hitbox.Size, HitboxSettings.Hitbox.Size)
                            RootPart.Transparency = 0.7
                            RootPart.CanCollide = false
                        end
                    end
                end
            end
        end
    end
end

RoleSection:Toggle({
    ["Title"] = "Hitbox (Sheriff + Inocentes)",
    ["Value"] = false,
    ["Callback"] = function(State)
        HitboxSettings.Hitbox.Enabled = State
        if State then
            if not HitboxSettings.Hitbox.Connection then
                HitboxSettings.Hitbox.Connection = RunService.Heartbeat:Connect(UpdateHitboxes)
            end
        else
            if HitboxSettings.Hitbox.Connection then
                HitboxSettings.Hitbox.Connection:Disconnect()
                HitboxSettings.Hitbox.Connection = nil
            end
            -- Restaurar tamaño normal al desactivar
            for _, Player in pairs(Players:GetPlayers()) do
                if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    local root = Player.Character.HumanoidRootPart
                    root.Size = Vector3.new(2, 2, 1)
                    root.Transparency = 0
                    root.CanCollide = true
                end
            end
        end
    end
})

RoleSection:Slider({
    ["Title"] = "Hitbox Size",
    ["step"] = 0.5,
    ["Value"] = {
        ["Min"] = 2,
        ["Max"] = 60,
        ["Default"] = 10
    },
    ["Callback"] = function(Value)
        HitboxSettings.Hitbox.Size = Value
    end
})

-- ==========================================================
-- SPECTATE SYSTEM (MISMA LÓGICA EXACTA DEL ARCHIVO ORIGINAL)
-- ==========================================================

local SelectedPlayer = nil
local DeathNotifyConnection = nil
local OriginalCameraSubject = workspace.CurrentCamera.CameraSubject

local function SendPlayerNotification(Title, Text)
    SendNexoraNotification(Title or "Spectate", Text or "", 5)
end

local function FindMurdererCharacter()
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            if Player.Backpack:FindFirstChild("Knife") or Player.Character:FindFirstChild("Knife") then
                return Player.Character
            end
        end
    end
    return nil
end

local function FindSheriffCharacter()
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            if Player.Backpack:FindFirstChild("Gun") or Player.Character:FindFirstChild("Gun") then
                return Player.Character
            end
        end
    end
    return nil
end

-- Sección Spectate dentro de RoleSection
RoleSection:Section({Title = "Spectate"})

RoleSection:Button({
    ["Title"] = "Spectate Murderer",
    ["Callback"] = function()
        local MurdererCharacter = FindMurdererCharacter()
        if MurdererCharacter and MurdererCharacter:FindFirstChild("Humanoid") then
            workspace.CurrentCamera.CameraSubject = MurdererCharacter:FindFirstChild("Humanoid")
            SendPlayerNotification("Spectate", "Mirando al Murderer")
        else
            SendPlayerNotification("Spectate", "Murderer no encontrado")
        end
    end
})

RoleSection:Button({
    ["Title"] = "Spectate Sheriff",
    ["Callback"] = function()
        local SheriffCharacter = FindSheriffCharacter()
        if SheriffCharacter and SheriffCharacter:FindFirstChild("Humanoid") then
            workspace.CurrentCamera.CameraSubject = SheriffCharacter:FindFirstChild("Humanoid")
            SendPlayerNotification("Spectate", "Mirando al Sheriff")
        else
            SendPlayerNotification("Spectate", "Sheriff no encontrado")
        end
    end
})

RoleSection:Button({
    ["Title"] = "Spectate Random",
    ["Callback"] = function()
        local AllPlayers = Players:GetPlayers()
        if #AllPlayers <= 1 then
            SendPlayerNotification("Spectate", "Necesitas al menos 2 jugadores")
            return
        end
        local RandomPlayer
        repeat
            RandomPlayer = AllPlayers[math.random(1, #AllPlayers)]
        until RandomPlayer ~= LocalPlayer and RandomPlayer.Character and RandomPlayer.Character:FindFirstChild("Humanoid")
        
        workspace.CurrentCamera.CameraSubject = RandomPlayer.Character:FindFirstChild("Humanoid")
        SendPlayerNotification("Spectate", "Mirando a: " .. RandomPlayer.Name)
    end
})

RoleSection:Button({
    ["Title"] = "Stop Spectating",
    ["Callback"] = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
            SendPlayerNotification("Spectate", "Espectador detenido")
        end
    end
})
-- ==========================================================
-- KILL BUTTONS (Murderer Tools) - Misma lógica del script grande
-- ==========================================================

local MurderTab = Window:Tab({Title = "Murder Tools", Icon = "sword"})

local KillSection = MurderTab:Section({Title = "Kill Options (Hold Knife)"})

-- ==========================================================
-- ULTRA KILL AURA (Misma lógica exacta - en Murder Tools)
-- ==========================================================

_G.UltraKillAura = false

task.spawn(function()
    while true do
        if _G.UltraKillAura then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local humanoid = myChar and myChar:FindFirstChild("Humanoid")
            
            if myRoot and humanoid then
                local knife = myChar:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
                
                if knife then
                    -- 1. ATRAER Y HACER INTANGIBLES
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local targetChar = player.Character
                            local targetRoot = targetChar.HumanoidRootPart
                            local targetHumanoid = targetChar:FindFirstChild("Humanoid")
                            
                            if targetHumanoid and targetHumanoid.Health > 0 then
                                -- Intangibles
                                for _, part in pairs(targetChar:GetDescendants()) do
                                    if part:IsA("BasePart") then part.CanCollide = false end
                                end
                                -- Traer al frente
                                targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -2)
                            end
                        end
                    end
                    
                    -- 2. EJECUTAR ATAQUE MASIVO
                    if knife.Parent ~= myChar then
                        humanoid:EquipTool(knife)
                    end
                    
                    task.wait(0.05)
                    
                    local stabEvent = knife:FindFirstChild("Events") and knife.Events:FindFirstChild("KnifeStabbed")
                    if stabEvent then
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                local targetRoot = player.Character.HumanoidRootPart
                                stabEvent:FireServer(targetRoot)
                            end
                        end
                    end
                    
                    -- 3. FINALIZAR
                    knife.Parent = LocalPlayer.Backpack
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Toggle en tu sección Kill Options
KillSection:Toggle({
    ["Title"] = "Kill Aura (Instant Bring)",
    ["Value"] = false,
    ["Callback"] = function(state)
        _G.UltraKillAura = state
        SendNexoraNotification("Ultra Kill Aura", state and "Activado" or "Desactivado", 3, state and "sword" or "x")
    end
})
-- ==========================================================
-- AUTO KILL SHERIFF (Misma lógica exacta)
-- ==========================================================

_G.SheriffKillAura = false

task.spawn(function()
    while true do
        if _G.SheriffKillAura then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local knife = myChar and (myChar:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife"))
            
            if myRoot and knife then
                -- Buscamos al Sheriff
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local hasGun = player.Backpack:FindFirstChild("Gun") or player.Character:FindFirstChild("Gun")
                        if hasGun then
                            local targetRoot = player.Character.HumanoidRootPart
                            local targetHumanoid = player.Character:FindFirstChild("Humanoid")
                            
                            if targetHumanoid and targetHumanoid.Health > 0 then
                                -- Atraer al Sheriff
                                targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
                                
                                -- Equipar cuchillo
                                if knife.Parent ~= myChar then
                                    myChar:FindFirstChild("Humanoid"):EquipTool(knife)
                                end
                                
                                -- Ataque
                                local stabEvent = knife:FindFirstChild("Events") and knife.Events:FindFirstChild("KnifeStabbed")
                                if stabEvent then
                                    stabEvent:FireServer(targetRoot)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

-- Toggle en tu sección Kill Options
KillSection:Toggle({
    ["Title"] = "Auto Kill Sheriff",
    ["Value"] = false,
    ["Callback"] = function(state)
        _G.SheriffKillAura = state
        SendNexoraNotification("Auto Kill Sheriff", state and "Activado" or "Desactivado", 3, state and "sword" or "x")
    end
})
local KillSection = MurderTab:Section({Title = "Sheriff"})
-- ==========================================================
-- COMBO: SEGUIMIENTO + SILENT AIM (TU LÓGICA ORIGINAL)
-- ==========================================================
local Camera = Workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

_G.AimbotComboEnabled = false -- Auto Shoot
-- TU LÓGICA ORIGINAL getMurderer
local function getMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hasKnife = player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife")
            if hasKnife then
                if player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
                    if player.Character.Humanoid.Health > 0 then
                        return player.Character
                    end
                end
            end
        end
    end
    return nil
end

-- TU LÓGICA DE DISPARO ORIGINAL (Centralizada)
local function executeOriginalShootLogic()
    local char = LocalPlayer.Character
    local gun = char and char:FindFirstChild("Gun")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if gun and gun:FindFirstChild("Shoot") and root then
        local murdererChar = getMurderer()
        if murdererChar and murdererChar:FindFirstChild("HumanoidRootPart") then
            local targetHRP = murdererChar.HumanoidRootPart
            local direction = (targetHRP.Position - root.Position)
            
            -- TU RAYCAST ORIGINAL
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char, Camera}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(root.Position, direction, rayParams)
            
            if result and result.Instance:IsDescendantOf(murdererChar) then
                -- TU CÁLCULO MATEMÁTICO ORIGINAL
                local vel = targetHRP.AssemblyLinearVelocity
                local dist = direction.Magnitude
                local prediction = vel * (dist / 500) * 0.30
                local targetPos = targetHRP.CFrame + prediction
                
                gun.Shoot:FireServer(root.CFrame, targetPos)
            end
        end
    end
end

-- SEGUIMIENTO DE CÁMARA (TU LÓGICA ORIGINAL)
RunService.RenderStepped:Connect(function()
    if not _G.AimbotComboEnabled and not _G.AimbotManualEnabled then return end
    local char = LocalPlayer.Character
    local hasGunEquipped = char and char:FindFirstChild("Gun")
    
    if hasGunEquipped then
        local murderer = getMurderer()
        if murderer then
            local targetPart = murderer:FindFirstChild("UpperTorso") or murderer:FindFirstChild("Torso") or murderer:FindFirstChild("HumanoidRootPart")
            if targetPart then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            end
        end
    end
end)

-- BUCLE AUTOSHOOT (TU LÓGICA ORIGINAL)
coroutine.wrap(function()
    while true do
        if _G.AimbotComboEnabled then
            executeOriginalShootLogic()
            task.wait(0.15)
        end
        task.wait(0.02)
    end
end)()

-- DISPARO MANUAL (USA TU MISMA LÓGICA)
LocalPlayer:GetMouse().Button1Down:Connect(function()
    if _G.AimbotManualEnabled then
        executeOriginalShootLogic()
    end
end)

-- TUS TOGGLES
KillSection:Toggle({
    ["Title"] = "Auto Shoot (Murder)",
    ["Value"] = false,
    ["Callback"] = function(state)
        _G.AimbotComboEnabled = state
    end
})

-- ==========================================================
-- CAMERA HARD-LOCK GUI (Solo Sheriff y Asesino)
-- ==========================================================
local AimbotMasterToggle = false
local AimbotActive = false
local AimbotConnection = nil
local CurrentTarget = nil
local screenGui = nil

-- Función modificada: Solo busca Sheriff o Murderer
local function GetClosestRoleToCursor()
    local Target = nil
    local ShortestDistance = math.huge
    local MousePos = Camera.ViewportSize / 2

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            
            -- Detectar rol
            local isSheriff = Player.Backpack:FindFirstChild("Gun") or Player.Character:FindFirstChild("Gun")
            local isMurderer = Player.Backpack:FindFirstChild("Knife") or Player.Character:FindFirstChild("Knife")
            
            if isSheriff or isMurderer then
                local RootPart = Player.Character.HumanoidRootPart
                local Pos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)

                if OnScreen then
                    local Distance = (Vector2.new(Pos.X, Pos.Y) - MousePos).Magnitude
                    if Distance < ShortestDistance then
                        Target = Player
                        ShortestDistance = Distance
                    end
                end
            end
        end
    end
    return Target
end

local function StartAimbot()
    if AimbotConnection then AimbotConnection:Disconnect() end
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if AimbotMasterToggle and AimbotActive then
            CurrentTarget = GetClosestRoleToCursor()
            
            if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("Head") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, CurrentTarget.Character.Head.Position)
            end
        end
    end)
end

-- Toggle Camera Hard-Lock (Solo Roles Importantes)
KillSection:Toggle({
    ["Title"] = "Camera Hard-Lock (Solo Sheriff / Asesino)",
    ["Value"] = false,
    ["Callback"] = function(State)
        AimbotMasterToggle = State
        
        if State then
            -- Crear GUI flotante
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
            screenGui = Instance.new("ScreenGui")
            screenGui.Name = "CustomJumpGui"
            screenGui.ResetOnSpawn = false
            screenGui.Parent = PlayerGui

            local VERTICAL_OFFSET = 0.10

            local jumpButton = Instance.new("TextButton")
            jumpButton.Name = "JumpButton"
            jumpButton.Size = UDim2.new(0, 90, 0, 90)
            jumpButton.AnchorPoint = Vector2.new(1, 0.5) 
            jumpButton.Position = UDim2.new(1, -10, VERTICAL_OFFSET, 0)
            jumpButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
            jumpButton.BackgroundTransparency = 0.5
            jumpButton.Text = ""
            jumpButton.AutoButtonColor = true
            jumpButton.Parent = screenGui

            local uiCorner = Instance.new("UICorner", jumpButton)
            uiCorner.CornerRadius = UDim.new(1, 0)

            local insetStrokeFrame = Instance.new("Frame", jumpButton)
            insetStrokeFrame.Name = "InsetStroke"
            insetStrokeFrame.Size = UDim2.new(0.9, 0, 0.9, 0) 
            insetStrokeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            insetStrokeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            insetStrokeFrame.BackgroundTransparency = 1 

            local insetCorner = Instance.new("UICorner", insetStrokeFrame)
            insetCorner.CornerRadius = UDim.new(1, 0)

            local uiStroke = Instance.new("UIStroke", insetStrokeFrame)
            uiStroke.Thickness = 2 
            uiStroke.Color = Color3.fromRGB(255, 255, 255) 
            uiStroke.Transparency = 0.5 
            uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

            local arrowIcon = Instance.new("ImageLabel", jumpButton)
            arrowIcon.Name = "ArrowIcon"
            arrowIcon.Size = UDim2.new(0.7, 0, 0.7, 0) 
            arrowIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
            arrowIcon.AnchorPoint = Vector2.new(0.5, 0.5)
            arrowIcon.BackgroundTransparency = 1
            arrowIcon.Image = "rbxassetid://17544521115"
            arrowIcon.ImageColor3 = Color3.fromRGB(255, 255, 255) 
            arrowIcon.ImageTransparency = 0.5 

            -- Click
            jumpButton.MouseButton1Click:Connect(function()
                AimbotActive = not AimbotActive
                if AimbotActive then
                    arrowIcon.ImageColor3 = Color3.fromRGB(255, 0, 0)
                    WindUI:Notify({Title = "Hard-Lock", Content = "Activado (Solo Roles)", Duration = 2})
                    if not AimbotConnection then StartAimbot() end
                else
                    arrowIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
                    CurrentTarget = nil
                end
            end)
        else
            -- Cleanup
            AimbotActive = false
            CurrentTarget = nil
            if screenGui then screenGui:Destroy() screenGui = nil end
            if AimbotConnection then AimbotConnection:Disconnect() AimbotConnection = nil end
        end
    end
})

-- ==========================================================
-- MOBILE MURDERER BUTTON (LÓGICA EXACTA DEL ARCHIVO ORIGINAL)
-- ==========================================================
local AutoShootEnabled = false
local currentScreenGui = nil
local inventoryCheckConnection = nil
local hasNotifiedSuccess = false
local hasNotifiedFailure = false

local function Notify(title, text)
    WindUI:Notify({Title = title, Content = text, Duration = 3})
end

local function GetMurderer()
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Knife = Player.Backpack:FindFirstChild("Knife") or Player.Character:FindFirstChild("Knife")
            if Knife then return Player end
        end
    end
    return nil
end

local function InstantShootSequence()
    local Character = LocalPlayer.Character
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not Character or not Backpack then return end

    local Gun = Backpack:FindFirstChild("Gun") or Character:FindFirstChild("Gun")
    
    if Gun then
        Gun.Parent = Character
        task.wait()
        
        local ShootRemote = Gun:FindFirstChild("Shoot")
        local Murderer = GetMurderer()
        
        if ShootRemote and Murderer and Murderer.Character:FindFirstChild("HumanoidRootPart") then
            local TargetRoot = Murderer.Character.HumanoidRootPart
            local MyRoot = Character:FindFirstChild("HumanoidRootPart")
            
            if MyRoot then
                local PredictedPos = TargetRoot.CFrame + (TargetRoot.Velocity * 0.125)
                local args = { MyRoot.CFrame, PredictedPos }
                ShootRemote:FireServer(unpack(args))
            end
        end
        
        task.wait()
        Gun.Parent = Backpack
    end
end

local function CreateCombatGui()
    if currentScreenGui then return end
    
    currentScreenGui = Instance.new("ScreenGui")
    currentScreenGui.Name = "CustomJumpGui"
    currentScreenGui.ResetOnSpawn = false
    currentScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local jumpButton = Instance.new("TextButton")
    jumpButton.Name = "JumpButton"
    jumpButton.Size = UDim2.new(0, 90, 0, 90)
    jumpButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
    jumpButton.BackgroundTransparency = 0.5
    jumpButton.Text = ""
    jumpButton.AutoButtonColor = true
    jumpButton.Parent = currentScreenGui

    -- Posicionamiento exacto del archivo original
    local function alignToMobile()
        local touchGui = LocalPlayer.PlayerGui:FindFirstChild("TouchGui")
        if touchGui then
            local controlFrame = touchGui:FindFirstChild("TouchControlFrame")
            local jumpControl = controlFrame and controlFrame:FindFirstChild("JumpButton")
            if jumpControl then
                jumpButton.Position = UDim2.new(
                    jumpControl.Position.X.Scale, 
                    jumpControl.Position.X.Offset - 110, 
                    jumpControl.Position.Y.Scale, 
                    jumpControl.Position.Y.Offset - 110
                )
            end
        else
            jumpButton.Position = UDim2.new(0.85, 0, 0.7, 0)
        end
    end
    alignToMobile()

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = jumpButton

    local insetStrokeFrame = Instance.new("Frame")
    insetStrokeFrame.Name = "InsetStroke"
    insetStrokeFrame.Size = UDim2.new(0.9, 0, 0.9, 0) 
    insetStrokeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    insetStrokeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    insetStrokeFrame.BackgroundTransparency = 1 
    insetStrokeFrame.Parent = jumpButton

    local insetCorner = Instance.new("UICorner")
    insetCorner.CornerRadius = UDim.new(1, 0)
    insetCorner.Parent = insetStrokeFrame

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = 2 
    uiStroke.Color = Color3.fromRGB(255, 255, 255) 
    uiStroke.Transparency = 0.5 
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Parent = insetStrokeFrame

    local arrowIcon = Instance.new("ImageLabel")
    arrowIcon.Name = "ArrowIcon"
    arrowIcon.Size = UDim2.new(0.7, 0, 0.7, 0) 
    arrowIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    arrowIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    arrowIcon.BackgroundTransparency = 1
    arrowIcon.Image = "rbxassetid://139650104834071"  -- Icono exacto del archivo
    arrowIcon.ImageColor3 = Color3.fromRGB(255, 255, 255) 
    arrowIcon.ImageTransparency = 0.5 
    arrowIcon.Parent = jumpButton

    jumpButton.MouseButton1Click:Connect(function()
        InstantShootSequence()
    end)
end

-- Toggle principal (igual al original)
KillSection:Toggle({
    ["Title"] = "Mobile Murderer Button",
    ["Value"] = false,
    ["Callback"] = function(State)
        AutoShootEnabled = State
        hasNotifiedSuccess = false
        hasNotifiedFailure = false
        
        if State then
            inventoryCheckConnection = RunService.Heartbeat:Connect(function()
                if not AutoShootEnabled then return end
                
                local Backpack = LocalPlayer:FindFirstChild("Backpack")
                local Character = LocalPlayer.Character
                local Gun = (Backpack and Backpack:FindFirstChild("Gun")) or (Character and Character:FindFirstChild("Gun"))
                
                if Gun then
                    if not currentScreenGui then
                        CreateCombatGui()
                        if not hasNotifiedSuccess then
                            Notify("Eliana Hub", "Gun Detected: Combat Button is now visible.")
                            hasNotifiedSuccess = true
                            hasNotifiedFailure = false
                        end
                    end
                else
                    if currentScreenGui then
                        currentScreenGui:Destroy()
                        currentScreenGui = nil
                    end
                    if not hasNotifiedFailure then
                        Notify("Project Nexora", "Gun Needed: You need a Gun to use this feature.")
                        hasNotifiedFailure = true
                        hasNotifiedSuccess = false
                    end
                end
            end)
        else
            if inventoryCheckConnection then inventoryCheckConnection:Disconnect() end
            if currentScreenGui then currentScreenGui:Destroy() currentScreenGui = nil end
        end
    end
})

local KillSection = MurderTab:Section({Title = "Fling & Timer"})
-- ==========================================================
-- TOUCH FLING (MISMA LÓGICA EXACTA DEL ARCHIVO ORIGINAL)
-- ==========================================================

local TouchFlingEnabled = false

local function TouchFlingLoop()
    local Character = nil
    local RootPart = nil
    local ToggleValue = 0.1
    while TouchFlingEnabled do
        RunService.Heartbeat:Wait()
        while TouchFlingEnabled and not (Character and (Character.Parent and (RootPart and RootPart.Parent))) do
            RunService.Heartbeat:Wait()
            Character = LocalPlayer.Character
            RootPart = Character:FindFirstChild("HumanoidRootPart") or (Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso"))
        end
        if TouchFlingEnabled then
            local CurrentVelocity = RootPart.Velocity
            RootPart.Velocity = CurrentVelocity * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            if Character and (Character.Parent and (RootPart and RootPart.Parent)) then
                RootPart.Velocity = CurrentVelocity
            end
            RunService.Stepped:Wait()
            if Character and (Character.Parent and (RootPart and RootPart.Parent)) then
                RootPart.Velocity = CurrentVelocity + Vector3.new(0, ToggleValue, 0)
                ToggleValue = ToggleValue * -1
            end
        end
    end
end

-- Toggle en tu sección Kill Options
KillSection:Toggle({
    ["Title"] = "Touch Fling",
    ["Value"] = false,
    ["Callback"] = function(state)
        TouchFlingEnabled = state
        if state then
            coroutine.wrap(TouchFlingLoop)()
            SendNexoraNotification("Touch Fling", "Activado", 3, "sword")
        else
            SendNexoraNotification("Touch Fling", "Desactivado", 3, "x")
        end
    end
})

-- ==========================================================
-- ANTI FLING V2 (MISMA LÓGICA EXACTA)
-- ==========================================================

local AntiFlingEnabled = false

local function setCanCollideOfModelDescendants(model, bval)
    if not model then return end
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = bval
        end
    end
end

RunService.Stepped:Connect(function()
    if AntiFlingEnabled then
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character then
                setCanCollideOfModelDescendants(v.Character, false)
            end
        end
    end
end)

-- Toggle en KillSection
KillSection:Toggle({
    ["Title"] = "Anti Fling",
    ["Value"] = false,
    ["Callback"] = function(state)
        AntiFlingEnabled = state
        SendNexoraNotification("Anti Fling V2", state and "Activado" or "Desactivado", 3, state and "shield" or "x")

        if not AntiFlingEnabled then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer and v.Character then
                    setCanCollideOfModelDescendants(v.Character, true)
                end
            end
        end
    end
})
-- ==========================================================
-- CONTADOR DE RONDA EN PANTALLA (Auto + Preciso)
-- ==========================================================

local TimerEnabled = false
local TimerGui = nil
local RoundToken = 0
local isInRound = false

local function CreateRoundTimer()
    if TimerGui then return end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    TimerGui = Instance.new("ScreenGui")
    TimerGui.Name = "RoundTimerGui"
    TimerGui.ResetOnSpawn = false
    TimerGui.Enabled = false
    TimerGui.Parent = playerGui

    local label = Instance.new("TextLabel")
    label.Name = "TimerLabel"
    label.Parent = TimerGui
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.Position = UDim2.new(0.5, 0, 0.08, 0)
    label.Size = UDim2.new(0, 180, 0, 55)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Text = ""
    label.TextColor3 = Color3.fromRGB(180, 120, 255)
    label.TextStrokeTransparency = 0.3
    label.TextStrokeColor3 = Color3.fromRGB(40, 0, 70)
    label.Visible = false
end

local function UpdateRoundTimer(seconds)
    if not TimerGui or not TimerGui.Enabled then return end

    local label = TimerGui:FindFirstChild("TimerLabel")
    if not label then return end

    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60

    if seconds <= 30 then
        label.TextColor3 = Color3.fromRGB(255, 60, 60)
        label.Text = "🔴 " .. string.format("%d:%02d", minutes, secs)
    elseif seconds <= 60 then
        label.TextColor3 = Color3.fromRGB(255, 200, 60)
        label.Text = "🟡 " .. string.format("%d:%02d", minutes, secs)
    else
        label.TextColor3 = Color3.fromRGB(180, 120, 255)
        label.Text = "🟢 " .. string.format("%d:%02d", minutes, secs)
    end
    label.Visible = true
end

KillSection:Toggle({
    Title = "Show Round Timer",
    Default = false,
    Callback = function(state)
        TimerEnabled = state
        if state then
            CreateRoundTimer()
            WindUI:Notify({Title = "Timer", Content = "Round Timer Activado (Auto)", Duration = 3})
        else
            if TimerGui then
                TimerGui:Destroy()
                TimerGui = nil
            end
        end
    end
})

-- ==========================================================
-- LÓGICA DEL CONTADOR (Funciona incluso si entras a media ronda)
-- ==========================================================

local function FindTimerObject()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:GetAttribute("Time") ~= nil then
            return obj
        end
    end
    return nil
end

local TimerObject = nil
local TimerConnection = nil

local function StopRound()
    isInRound = false
    RoundToken += 1

    if TimerGui then
        TimerGui.Enabled = false

        local label = TimerGui:FindFirstChild("TimerLabel")
        if label then
            label.Visible = false
            label.Text = ""
        end
    end
end

local function ConnectTimer(obj)
    if TimerConnection then
        TimerConnection:Disconnect()
        TimerConnection = nil
    end

    TimerObject = obj

    if not TimerObject then
        return
    end

    local function Update()
        if not TimerEnabled or not TimerGui then
            return
        end

        local time = TimerObject:GetAttribute("Time")

        if typeof(time) == "number" and time > 0 then
            isInRound = true
            TimerGui.Enabled = true
            UpdateRoundTimer(math.floor(time))
        else
            StopRound()
        end
    end

    Update()

    TimerConnection = TimerObject:GetAttributeChangedSignal("Time"):Connect(Update)
end

task.spawn(function()
    while task.wait(1) do
        if not TimerEnabled then
            continue
        end

        if not TimerObject or not TimerObject.Parent then
            local obj = FindTimerObject()
            if obj then
                ConnectTimer(obj)
            end
        end
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if obj:GetAttribute("Time") ~= nil then
        ConnectTimer(obj)
    end
end)

-- Conectar remotes SOLO si existen
task.spawn(function()
    local Gameplay = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Gameplay")

    local RoundEndFade = Gameplay:FindFirstChild("RoundEndFade")
    if RoundEndFade then
        RoundEndFade.OnClientEvent:Connect(StopRound)
    end

    local GameOver = Gameplay:FindFirstChild("GameOver")
    if GameOver then
        GameOver.OnClientEvent:Connect(StopRound)
    end
end)

-- Auto-detección por si el evento falla
task.spawn(function()
    while task.wait(3) do
        if TimerEnabled and not isInRound then
            for _, obj in ipairs(workspace:GetDescendants()) do
                local time = obj:GetAttribute("Time")
                if typeof(time) == "number" and time > 10 then
                    isInRound = true
                    if TimerGui then
                        TimerGui.Enabled = true
                    end
                    break
                end
            end
        end
    end
end)

-- ==========================================================
-- NUEVA PESTAÑA: ROLE FLING
-- ==========================================================
local FlingTab = Window:Tab({Title = "Role Fling", Icon = "wind"})

local FlingSection = FlingTab:Section({Title = "Fling por Rol"})

-- ==========================================================
-- ROLE FLING (Misma lógica SkidFling)
-- ==========================================================

_G.FlingSheriff = false
_G.FlingMurderer = false
_G.FlingAllInnocents = false

local savedPosition = nil

local function SavePosition()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        savedPosition = root.CFrame
        getgenv().OldPos = root.CFrame
    end
end

local function ResetPosition()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if root and savedPosition then
        root.CFrame = savedPosition
        root.Velocity = Vector3.new()
        root.RotVelocity = Vector3.new()
        root.AssemblyLinearVelocity = Vector3.new()
    end
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        workspace.CurrentCamera.CameraSubject = hum
    end
    workspace.FallenPartsDestroyHeight = getgenv().FPDH or 0
end

local function getRole(player)
    if not player or not player.Character then return "Innocent" end
    local data = _G.LatestPlayerData and _G.LatestPlayerData[player.Name]
    local role = data and data.Role or "Innocent"
    if player.Backpack:FindFirstChild("Gun") or player.Character:FindFirstChild("Gun") then
        return "Sheriff"
    elseif player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife") then
        return "Murderer"
    end
    return role
end

local function SkidFling(TargetPlayer)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter or not RootPart then return end
    
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    
    if THumanoid and THumanoid.Sit then return end
    
    getgenv().OldPos = getgenv().OldPos or RootPart.CFrame
    workspace.FallenPartsDestroyHeight = 0/0
    
    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end
    
    local SFBasePart = function(BasePart)
        local Time = tick()
        local Angle = 0
        repeat
            if BasePart.Velocity.Magnitude < 50 then
                Angle = Angle + 100
                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
            else
                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                task.wait()
            end
        until tick() - Time > 2 or not (_G.FlingSheriff or _G.FlingMurderer or _G.FlingAllInnocents)
    end
    
    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(0, 0, 0)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    
    if TRootPart then
        SFBasePart(TRootPart)
    elseif THead then
        SFBasePart(THead)
    end
    
    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = Humanoid
end

-- Bucle principal
task.spawn(function()
    while task.wait(0.3) do
        if not (_G.FlingSheriff or _G.FlingMurderer or _G.FlingAllInnocents) then 
            continue 
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or not player.Character then continue end
            local role = getRole(player)
            if (role == "Sheriff" and _G.FlingSheriff) or 
               (role == "Murderer" and _G.FlingMurderer) or 
               (role == "Innocent" and _G.FlingAllInnocents) then
                SkidFling(player)
                task.wait(role == "Innocent" and 0.2 or 0.4)
            end
        end
    end
end)

-- Toggles
FlingSection:Toggle({
    Title = "Fling Sheriff",
    Default = false,
    Callback = function(state)
        _G.FlingSheriff = state
        if state then
            SavePosition()
        else
            task.wait(0.1)
            ResetPosition()
            task.wait(0.2)
            ResetPosition()
        end
        WindUI:Notify({Title = "Role Fling", Content = "Fling Sheriff " .. (state and "✅ Activado" or "❌ Desactivado + Reset"), Duration = 3})
    end
})

FlingSection:Toggle({
    Title = "Fling Asesino (Murderer)",
    Default = false,
    Callback = function(state)
        _G.FlingMurderer = state
        if state then
            SavePosition()
        else
            task.wait(0.1)
            ResetPosition()
            task.wait(0.2)
            ResetPosition()
        end
        WindUI:Notify({Title = "Role Fling", Content = "Fling Asesino " .. (state and "✅ Activado" or "❌ Desactivado + Reset"), Duration = 3})
    end
})

FlingSection:Toggle({
    Title = "Fling ALL Inocentes",
    Default = false,
    Callback = function(state)
        _G.FlingAllInnocents = state
        if state then
            SavePosition()
        else
            task.wait(0.1)
            ResetPosition()
            task.wait(0.2)
            ResetPosition()
        end
        WindUI:Notify({Title = "Role Fling", Content = "Fling ALL Inocentes " .. (state and "✅ Activado (Masivo)" or "❌ Desactivado + Reset"), Duration = 3})
    end
})
-- ==========================================================
-- SECCIÓN: EXPONER ROLES EN CHAT
-- ==========================================================
local VisualsTab = Window:Tab({Title = "Exponer", Icon = "eye"}) -- Si ya la tienes, usa la variable existente
local ExposeSection = VisualsTab:Section({Title = "Exponer Roles"})

local function GetRolePlayer(roleType)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if roleType == "Sheriff" and (player.Backpack:FindFirstChild("Gun") or player.Character:FindFirstChild("Gun")) then
                return player.Name
            elseif roleType == "Murderer" and (player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife")) then
                return player.Name
            end
        end
    end
    return nil
end

local function SendChatMessage(message)
    local args = {
        [1] = message,
        [2] = "All"
    }
    local chatRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") 
                       and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
    
    if chatRemote then
        chatRemote:FireServer(unpack(args))
    else
        -- Fallback si el sistema de chat es el nuevo de Roblox
        game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(message)
    end
end

ExposeSection:Button({
    Title = "Exponer al Sheriff",
    Callback = function()
        local name = GetRolePlayer("Sheriff")
        if name then
            SendChatMessage("¡Cuidado! El Sheriff es: " .. name)
            WindUI:Notify({Title = "Expositor", Content = "Mensaje enviado: Sheriff es " .. name, Duration = 3})
        else
            WindUI:Notify({Title = "Error", Content = "Sheriff no encontrado todavía.", Duration = 3})
        end
    end
})

ExposeSection:Button({
    Title = "Exponer al Asesino",
    Callback = function()
        local name = GetRolePlayer("Murderer")
        if name then
            SendChatMessage("¡EL ASESINO ES: " .. name .. "!")
            WindUI:Notify({Title = "Expositor", Content = "Mensaje enviado: Asesino es " .. name, Duration = 3})
        else
            WindUI:Notify({Title = "Error", Content = "Asesino no encontrado todavía.", Duration = 3})
        end
    end
})

-- ==========================================================
-- PESTAÑA: PLAYERS (Control de Velocidad)
-- ==========================================================
local PlayersTab = Window:Tab({Title = "Players", Icon = "user"})
local SpeedSection = PlayersTab:Section({Title = "Movement"})

_G.PlayerSpeed = 16

-- Slider para ajustar velocidad
SpeedSection:Slider({
    Title = "Velocidad de Caminata",
    Value = { Min = 16, Max = 100, Default = 16 },
    Callback = function(v)
        _G.PlayerSpeed = v
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = v
        end
    end
})

-- Botón para resetear velocidad
SpeedSection:Button({
    Title = "Resetear Velocidad (16)",
    Callback = function()
        _G.PlayerSpeed = 16
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
        end
        WindUI:Notify({Title = "Players", Content = "Velocidad restaurada a 16", Duration = 2})
    end
})

-- Asegurar que la velocidad se mantenga al respawnear
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = _G.PlayerSpeed
    end
end)

-- ==========================================================
-- INTEGRACIÓN: AUTO JUMP EN PESTAÑA PLAYERS
-- ==========================================================

-- Asegúrate de que el toggle esté bajo SpeedSection (o crea una nueva sección llamada "Movimiento Extra")
SpeedSection:Toggle({
    Title = "Auto Jump",
    Default = false,
    Callback = function(state)
        _G.AutoJumpEnabled = state
    end
})

-- La lógica de abajo es global, así que no necesitas cambiarla de lugar,
-- solo asegúrate de que esté debajo de tu configuración de UI.
task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoJumpEnabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            -- Salta solo si está en el suelo
            if hum and hum.FloorMaterial ~= Enum.Material.Air then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)


-- ==========================================================
-- NOCLIP + PISO DE SEGURIDAD (Posición Y fija)
-- ==========================================================
local RunService = game:GetService("RunService")
local FloorPart = nil
local LockedY = nil -- Nueva variable para fijar la altura

SpeedSection:Toggle({
    Title = "No Clip",
    Default = false,
    Callback = function(state)
        _G.NoclipEnabled = state
        
        if state then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then LockedY = hrp.Position.Y - 3.5 end -- Fijamos la altura al activar
            
            FloorPart = Instance.new("Part")
            FloorPart.Name = "AntiFallFloor"
            FloorPart.Size = Vector3.new(5, 1, 5)
            FloorPart.Transparency = 1 
            FloorPart.Anchored = true
            FloorPart.CanCollide = true
            FloorPart.Parent = workspace
        else
            if FloorPart then FloorPart:Destroy() FloorPart = nil end
            LockedY = nil -- Limpiamos la altura fija
        end
    end
})

RunService.Stepped:Connect(function()
    if _G.NoclipEnabled and FloorPart and LockedY then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Mantenemos X y Z dinámicos para que te siga, pero Y fijo para que no suba
            FloorPart.Position = Vector3.new(hrp.Position.X, LockedY, hrp.Position.Z)
            
            -- Lógica de colisión intacta
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ==========================================================
-- INFINITE JUMP (Toggle para la sección)
-- ==========================================================
_G.InfiniteJumpEnabled = false

SpeedSection:Toggle({
    Title = "Salto Infinito",
    Default = false,
    Callback = function(state)
        _G.InfiniteJumpEnabled = state
    end
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if _G.InfiniteJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum:ChangeState("Jumping")
        end
    end
end)

local SpeedSection = PlayersTab:Section({Title = "Fly"})
-- // VARIABLES GLOBALES
local nowe = false
local speeds = 1
local tpwalking = false

-- // FLY (Toggle)
SpeedSection:Toggle({
    Title = "Fly",
    Default = false,
    Callback = function(state)
        nowe = state
        local speaker = game:GetService("Players").LocalPlayer
        
        if nowe == false then
            tpwalking = false
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,true)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,true)
            speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        else 
            for i = 1, speeds do
                spawn(function()
                    local hb = game:GetService("RunService").Heartbeat	
                    tpwalking = true
                    local chr = speaker.Character
                    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                    while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                        if hum.MoveDirection.Magnitude > 0 then
                            chr:TranslateBy(hum.MoveDirection)
                        end
                    end
                end)
            end
            speaker.Character.Animate.Disabled = true
            local Hum = speaker.Character:FindFirstChildOfClass("Humanoid") or speaker.Character:FindFirstChildOfClass("AnimationController")
            for i,v in next, Hum:GetPlayingAnimationTracks() do
                v:AdjustSpeed(0)
            end
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
            speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
            speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)

            if speaker.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then
                local torso = speaker.Character.Torso
                local bg = Instance.new("BodyGyro", torso)
                bg.P = 9e4
                bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.cframe = torso.CFrame
                local bv = Instance.new("BodyVelocity", torso)
                bv.velocity = Vector3.new(0,0.1,0)
                bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
                speaker.Character.Humanoid.PlatformStand = true
                spawn(function()
                    while nowe == true do
                        game:GetService("RunService").RenderStepped:Wait()
                        bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame
                    end
                    bg:Destroy()
                    bv:Destroy()
                    speaker.Character.Humanoid.PlatformStand = false
                    speaker.Character.Animate.Disabled = false
                end)
            else
                local UpperTorso = speaker.Character.UpperTorso
                local bg = Instance.new("BodyGyro", UpperTorso)
                bg.P = 9e4
                bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.cframe = UpperTorso.CFrame
                local bv = Instance.new("BodyVelocity", UpperTorso)
                bv.velocity = Vector3.new(0,0.1,0)
                bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
                speaker.Character.Humanoid.PlatformStand = true
                spawn(function()
                    while nowe == true do
                        wait()
                        bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame
                    end
                    bg:Destroy()
                    bv:Destroy()
                    speaker.Character.Humanoid.PlatformStand = false
                    speaker.Character.Animate.Disabled = false
                end)
            end
        end
    end
})


-- // SLIDER VELOCIDAD DE VUELO
SpeedSection:Slider({
    Title = "Velocidad de Vuelo",
    Value = { Min = 1, Max = 10, Default = 1 },
    Callback = function(v)
        speeds = v
    end
})

-- // VARIABLES GLOBALES (Asegúrate de poner esto fuera de la sección)
local FloorPart = nil

-- // SLIDER VELOCIDAD SIGILOSA
_G.StealthSpeed = 1 

-- // TOGGLE: MOVIMIENTO SIGILOSO + PISO ESTÁTICO
SpeedSection:Toggle({
    Title = "Movimiento Sigiloso + Piso",
    Default = false,
    Callback = function(state)
        _G.SilentMove = state
        local player = game:GetService("Players").LocalPlayer
        
        -- Lógica de Sigilo
        local function applyStealth(char)
            local animate = char:FindFirstChild("Animate")
            if animate then animate.Disabled = _G.SilentMove end
        end

        if state then
            -- 1. Capturamos la posición completa (X, Y, Z) al activar
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local FixedPos = hrp and hrp.Position - Vector3.new(0, 3.5, 0) or Vector3.new(0,0,0)
            
            -- Crear el Piso en la posición fija
            FloorPart = Instance.new("Part")
            FloorPart.Name = "AntiFallFloor"
            FloorPart.Size = Vector3.new(20, 1, 20) -- Un poco más grande para mayor seguridad
            FloorPart.Transparency = 0.8 -- Le puse 0.8 para que veas dónde está, cámbialo a 1 para invisible
            FloorPart.Anchored = true
            FloorPart.CanCollide = true
            FloorPart.Position = FixedPos -- Se queda aquí para siempre
            FloorPart.Parent = workspace
            
            -- Lógica de movimiento sigiloso (Sin mover el piso)
            spawn(function()
                while _G.SilentMove do
                    local char = player.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    
                    if char and hum and hum.MoveDirection.Magnitude > 0 then
                        char:TranslateBy(hum.MoveDirection * (_G.StealthSpeed * 0.1))
                    end
                    game:GetService("RunService").Heartbeat:Wait()
                end
            end)
        else
            -- Destruir el Piso al desactivar
            if FloorPart then FloorPart:Destroy() FloorPart = nil end
        end

        if player.Character then applyStealth(player.Character) end
    end
})

SpeedSection:Slider({
    Title = "Velocidad Sigilosa",
    Value = { Min = 1, Max = 28, Default = 1 },
    Callback = function(v)
        _G.StealthSpeed = v 
    end
})

local SpeedSection = PlayersTab:Section({Title = "TELEPOR LOBBY & TELEPORT ORIGINAL POSITION"})
-- // Variable global para guardar la posición de origen
_G.LastPosition = nil

-- // BOTÓN 1: Ir al punto de la foto (y guardar de dónde venías)
SpeedSection:Button({
    Title = "Teleport a Punto Fijo",
    Callback = function()
        local char = game:GetService("Players").LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            -- Guardamos dónde estabas ANTES de irte
            _G.LastPosition = char.HumanoidRootPart.CFrame
            
            -- Hacemos el TP a las coordenadas de la foto
            char.HumanoidRootPart.CFrame = CFrame.new(14.156, 511.381, -25.143)
        end
    end
})

-- // BOTÓN 2: Volver a donde estabas
SpeedSection:Button({
    Title = "Volver a mi posición",
    Callback = function()
        if _G.LastPosition then
            local char = game:GetService("Players").LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = _G.LastPosition
            end
        end
    end
})

-- // Variable para guardar la posición en segundo plano
local AutoSavedPos = game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame

-- // 1. Bucle en segundo plano (guarda tu posición cada 3 segundos)
spawn(function()
    while true do
        task.wait(3)
        local char = game:GetService("Players").LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            AutoSavedPos = hrp.CFrame
        end
    end
end)

-- ==========================================================
-- NUEVA PESTAÑA: EXTRAER
-- ==========================================================
local ExtraerTab = Window:Tab({Title = "Extraer", Icon = "download"})

local DupeSection = ExtraerTab:Section({Title = "Dupeo"})

DupeSection:Button({
    Title = "Cargar Dupeo Script",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/hQpalSvb/raw"))()
        SendNexoraNotification("Dupeo", "Script cargado correctamente", 4, "check")
    end
})

local DupeSection = ExtraerTab:Section({Title = "Animacion&Emotes"})

DupeSection:Button({
    Title = "Cargar Animaciones Mods",
    Description = "Ejecuta el script Universal JAnimacionesMods", -- opcional
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-FREE-BUNDLES-l-FE-241758"))()
        -- Notificación opcional para confirmar
        WindUI:Notify({
            Title = "Animaciones",
            Content = "Script de animaciones cargado correctamente",
            Duration = 3
        })
    end
})
-- ==========================================================
-- KORBLOX (EXACTAMENTE IGUAL AL ARCHIVO ORIGINAL)
-- ==========================================================
local KorbloxSection = ExtraerTab:Section({Title = "Korblox"})

--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Asset IDs
local KORBLOX_MESH_ID = "rbxassetid://101851696"
local KORBLOX_TEXTURE_ID = "rbxassetid://101851254"
local DARK_GREY_COLOR = Color3.fromRGB(64, 64, 64)

local function applyKorblox()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if hum.RigType == Enum.HumanoidRigType.R15 then
        local rf = char:FindFirstChild("RightFoot")
        local rl = char:FindFirstChild("RightLowerLeg")
        local ru = char:FindFirstChild("RightUpperLeg")

        if ru and rl and rf then
            rf.Transparency = 1
            rl.Transparency = 1
            
            ru.MeshId = "http://www.roblox.com/asset/?id=902942096"
            ru.TextureID = "http://roblox.com/asset/?id=902843398"
            ru.Color = Color3.new(1, 1, 1)
            ru.Transparency = 0
        end
    else
        local rightLeg = char:FindFirstChild("Right Leg")
        if rightLeg then
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                    v:Destroy()
                end
            end
            
            local mesh = rightLeg:FindFirstChildOfClass("SpecialMesh")
            if not mesh then
                mesh = Instance.new("SpecialMesh")
                mesh.Parent = rightLeg
            end
            
            rightLeg.Color = DARK_GREY_COLOR
            rightLeg.Transparency = 0
            
            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId = KORBLOX_MESH_ID
            mesh.TextureId = KORBLOX_TEXTURE_ID
            mesh.Scale = Vector3.new(1, 1, 1)
        end
    end
end

KorbloxSection:Button({
    Title = "Activar Korblox",
    Callback = function()
        if player.Character then
            applyKorblox()
        end
    end
})
print("✅ 3 Botones de Kill agregados correctamente (Murder Tools)")
print("✅ Nexora Framework migrado a WindUI correctamente.")
