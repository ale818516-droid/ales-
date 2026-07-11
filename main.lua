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
    Title = "MM2 Helper [PRO]",
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
    Title = "Anti-Murderer [Evasion]",
    Default = false,
    Callback = function(state)
        _G.AntiMurderer = state
        WindUI:Notify({
            Title = "Anti-Murderer",
            Content = state and "Activado (Modo Seguro)" or "Desactivado",
            Duration = 2
        })
    end
})

-- Lógica Anti-Murderer Mejorada
task.spawn(function()
    while task.wait(0.15) do
        if not _G.AntiMurderer then continue end

        local myChar = LP.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then continue end

        local closestMurderer = nil
        local closestDist = math.huge

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                local role = player:GetAttribute("Role") or "Innocent"
                
                -- Mejor detección de Murderer
                if role == "Murderer" or player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife") then
                    local mHrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if mHrp then
                        local dist = (myHrp.Position - mHrp.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestMurderer = mHrp
                        end
                    end
                end
            end
        end

        if closestMurderer and closestDist < 35 then  -- Radio de detección
            local direction = (myHrp.Position - closestMurderer.Position).Unit
            local newCFrame = myHrp.CFrame + (direction * 12)  -- Menos agresivo
            
            -- Movimiento suave
            myHrp.CFrame = CFrame.new(newCFrame.Position, closestMurderer.Position)
            
            -- Pequeño impulso para alejarse
            if myChar:FindFirstChild("Humanoid") then
                myChar.Humanoid:MoveTo(myHrp.Position + direction * 25)
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
                bill.Size = UDim2.new(0, 200, 0, 50)
                bill.StudsOffset = Vector3.new(0, 3, 0)
                bill.AlwaysOnTop = true
                bill.Parent = head
                local label = Instance.new("TextLabel")
                label.Parent = bill
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = player.Name .. "\n[ASESINO]"
                label.TextColor3 = color
                label.TextStrokeTransparency = 0
                label.Font = Enum.Font.SourceSansBold
                label.TextSize = 25
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
    Title = "Activar Role ESP",
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

-- ==========================================================
-- HITBOX (EXACTO del archivo original)
-- ==========================================================

local HitboxSettings = {
    ["Hitbox"] = {
        ["Enabled"] = false,
        ["Size"] = 5,
        ["Color"] = Color3.new(1, 0, 0),
        ["Adornments"] = {},
        ["Connection"] = nil
    }
}

local function UpdateHitboxes()
    if HitboxSettings.Hitbox.Enabled then
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer then
                local Character = Player.Character
                local Adornment = HitboxSettings.Hitbox.Adornments[Player]
                if Character and HitboxSettings.Hitbox.Enabled then
                    local RootPart = Character:FindFirstChild("HumanoidRootPart")
                    if RootPart then
                        if Adornment then
                            Adornment.Size = Vector3.new(HitboxSettings.Hitbox.Size, HitboxSettings.Hitbox.Size, HitboxSettings.Hitbox.Size)
                            Adornment.Color3 = HitboxSettings.Hitbox.Color
                        else
                            local NewAdornment = Instance.new("BoxHandleAdornment")
                            NewAdornment.Adornee = RootPart
                            NewAdornment.Size = Vector3.new(HitboxSettings.Hitbox.Size, HitboxSettings.Hitbox.Size, HitboxSettings.Hitbox.Size)
                            NewAdornment.Color3 = HitboxSettings.Hitbox.Color
                            NewAdornment.Transparency = 0.4
                            NewAdornment.ZIndex = 10
                            NewAdornment.Parent = RootPart
                            HitboxSettings.Hitbox.Adornments[Player] = NewAdornment
                        end
                    end
                end
            end
        end
    else
        for Player, Adornment in pairs(HitboxSettings.Hitbox.Adornments) do
            if Adornment and Adornment.Parent then
                Adornment:Destroy()
            end
        end
        HitboxSettings.Hitbox.Adornments = {}
    end
end

RoleSection:Toggle({
    ["Title"] = "Hitboxes",
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
            for _, Adornment in pairs(HitboxSettings.Hitbox.Adornments) do
                if Adornment and Adornment.Parent then
                    Adornment:Destroy()
                end
            end
            HitboxSettings.Hitbox.Adornments = {}
        end
    end
})

RoleSection:Slider({
    ["Title"] = "Hitbox Size",
    ["step"] = 0.5,
    ["Value"] = {
        ["Min"] = 1,
        ["Max"] = 20,
        ["Default"] = 5
    },
    ["Callback"] = function(Value)
        HitboxSettings.Hitbox.Size = Value
    end
})

-- ==========================================================
-- KILL BUTTONS (Murderer Tools) - Misma lógica del script grande
-- ==========================================================

local MurderTab = Window:Tab({Title = "Murder Tools", Icon = "sword"})

local KillSection = MurderTab:Section({Title = "Kill Options (Hold Knife)"})

local function KillRole(TargetRole)
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not character or not backpack then 
        WindUI:Notify({Title = "Error", Content = "No se encontró personaje", Duration = 2})
        return 
    end

    local knife = character:FindFirstChild("Knife") or backpack:FindFirstChild("Knife")
    if not knife then
        WindUI:Notify({Title = "Kill " .. TargetRole, Content = "Necesitas el Knife", Duration = 3})
        return
    end

    local myRoot = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not (myRoot and humanoid) then return end

    -- Equip Knife
    if knife.Parent == backpack then
        humanoid:EquipTool(knife)
        task.wait(0.1)
    end

    local killed = 0

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then 
            continue 
        end

        local hasKnife = plr.Backpack:FindFirstChild("Knife") or plr.Character:FindFirstChild("Knife")
        local hasGun   = plr.Backpack:FindFirstChild("Gun") or plr.Character:FindFirstChild("Gun")

        local shouldKill = false
        if TargetRole == "All" then
            shouldKill = true
        elseif TargetRole == "Sheriff" and hasGun then
            shouldKill = true
        elseif TargetRole == "Innocents" and not hasKnife and not hasGun then
            shouldKill = true
        end

        if shouldKill then
            local enemyRoot = plr.Character.HumanoidRootPart
            enemyRoot.Anchored = true
            enemyRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -2.5)
            killed += 1
        end
    end

    -- Stab
    local stab = knife:FindFirstChild("Stab")
    if stab then stab:FireServer("Slash") end

    task.wait(0.15)

    -- Unanchor
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.Anchored = false
        end
    end

    if knife.Parent == character then knife.Parent = backpack end

    WindUI:Notify({
        Title = "Kill " .. TargetRole,
        Content = "Eliminados: " .. killed,
        Duration = 3
    })
end

-- ==================== LOS 3 BOTONES ====================

KillSection:Button({
    Title = "Kill All (hold knife)",
    Callback = function()
        KillRole("All")
    end
})

KillSection:Button({
    Title = "Kill Sheriff (hold knife)",
    Callback = function()
        KillRole("Sheriff")
    end
})

KillSection:Button({
    Title = "Kill Innocents (hold knife)",
    Callback = function()
        KillRole("Innocents")
    end
})

-- ==========================================================
-- COMBO AIMBOT + SILENT AUTO SHOOT (Solo Asesino)
-- ==========================================================

local Camera = Workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variable global para activar/desactivar el combo
_G.AimbotComboEnabled = false

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

-- PARTE 1: Seguimiento de cámara (visual)
RunService.RenderStepped:Connect(function()
    if not _G.AimbotComboEnabled then return end
    
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

-- PARTE 2: Silent Auto Shoot con Predicción
local function startSilentShootLoop()
    while _G.AimbotComboEnabled do
        local char = LocalPlayer.Character
        local gun = char and char:FindFirstChild("Gun")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if gun and gun:FindFirstChild("Shoot") and root then
            local murdererChar = getMurderer()
            
            if murdererChar and murdererChar:FindFirstChild("HumanoidRootPart") then
                local targetHRP = murdererChar.HumanoidRootPart
                local direction = (targetHRP.Position - root.Position)
                
                -- Raycast para verificar línea de visión
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char, Camera}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local result = workspace:Raycast(root.Position, direction, rayParams)
                
                if result and result.Instance:IsDescendantOf(murdererChar) then
                    -- Predicción matemática
                    local vel = targetHRP.AssemblyLinearVelocity
                    local dist = direction.Magnitude
                    local prediction = vel * (dist / 500) * 0.30
                    local targetPos = targetHRP.CFrame + prediction
                    
                    -- Disparo silencioso
                    gun.Shoot:FireServer(root.CFrame, targetPos)
                    task.wait(0.15) -- Cooldown para evitar detección
                end
            end
        end
        task.wait(0.02) -- Alta velocidad
    end
end

-- Toggle en tu pestaña Murder Tools
KillSection:Toggle({
    ["Title"] = "Aimbot + Silent Auto Shoot (Combo)",
    ["Value"] = false,
    ["Callback"] = function(state)
        _G.AimbotComboEnabled = state
        
        if state then
            coroutine.wrap(startSilentShootLoop)()
            SendNexoraNotification("Combo Aimbot", "Activado (Solo Asesino)", 3, "target")
        else
            SendNexoraNotification("Combo Aimbot", "Desactivado", 3, "x")
        end
    end
})
-- ==========================================================
-- AIMBOT SOLO PARA ASESINO (con Toggle en Murder Tools)
-- ==========================================================

local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local CamlockState = false
local Prediction = 0.1768521
local Locked = false
getgenv().Key = "q"

-- Solo busca al Asesino (misma lógica que me mandaste)
local function FindNearestMurderer()
    local ClosestDistance, ClosestPlayer = math.huge, nil
    local CenterPosition = Vector2.new(
        game:GetService("GuiService"):GetScreenResolution().X / 2,
        game:GetService("GuiService"):GetScreenResolution().Y / 2
    )

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character.Humanoid.Health > 0 then
                local hasKnife = Player.Backpack:FindFirstChild("Knife") or Character:FindFirstChild("Knife")
                if hasKnife then
                    local Position, IsVisibleOnViewport = workspace.CurrentCamera:WorldToViewportPoint(Character.HumanoidRootPart.Position)
                    if IsVisibleOnViewport then
                        local Distance = (CenterPosition - Vector2.new(Position.X, Position.Y)).Magnitude
                        if Distance < ClosestDistance then
                            ClosestPlayer = Character.HumanoidRootPart
                            ClosestDistance = Distance
                        end
                    end
                end
            end
        end
    end
    return ClosestPlayer
end

local enemy = nil

RunService.Heartbeat:Connect(function()
    if CamlockState == true and enemy then
        local camera = workspace.CurrentCamera
        camera.CFrame = CFrame.new(camera.CFrame.p, enemy.Position + enemy.Velocity * Prediction)
    end
end)

Mouse.KeyDown:Connect(function(k)
    if k == getgenv().Key then
        Locked = not Locked
        if Locked then
            enemy = FindNearestMurderer()
            CamlockState = true
        else
            enemy = nil
            CamlockState = false
        end
    end
end)

-- Toggle en la pestaña Murder Tools
KillSection:Toggle({
    ["Title"] = "Aimbot Solo Asesino (Q)",
    ["Value"] = false,
    ["Callback"] = function(State)
        CamlockState = State
        if State then
            enemy = FindNearestMurderer()
            Locked = true
            SendNexoraNotification("ACE Aimbot", "Activado (Solo Asesino)", 3, "target")
        else
            enemy = nil
            Locked = false
            SendNexoraNotification("ACE Aimbot", "Desactivado", 3, "x")
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

-- Lógica del contador
local Gameplay = game:GetService("ReplicatedStorage")
    :WaitForChild("Remotes")
    :WaitForChild("Gameplay")

local RoundStart = Gameplay:WaitForChild("RoundStart")
local RoundEndFade = Gameplay:WaitForChild("RoundEndFade")
local GameOver = Gameplay:WaitForChild("GameOver")

RoundStart.OnClientEvent:Connect(function(Time)
    if typeof(Time) ~= "number" or not TimerEnabled then return end

    isInRound = true
    RoundToken += 1
    local Token = RoundToken

    if TimerGui then
        TimerGui.Enabled = true
    end

    task.spawn(function()
        local t = Time
        local warned60 = false
        local warned30 = false

        while t >= 0 and isInRound and Token == RoundToken and TimerEnabled do
            UpdateRoundTimer(t)

            if t <= 30 and not warned30 then
                warned30 = true
                WindUI:Notify({Title = "⚠️ Tiempo", Content = "Quedan 30 segundos", Duration = 3})
            elseif t <= 60 and not warned60 then
                warned60 = true
                WindUI:Notify({Title = "⏳ Tiempo", Content = "Queda 1 minuto", Duration = 3})
            end

            task.wait(1)
            t -= 1
        end
    end)
end)

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

RoundEndFade.OnClientEvent:Connect(StopRound)
GameOver.OnClientEvent:Connect(StopRound)

-- Auto-detección por si el evento falla
task.spawn(function()
    while task.wait(3) do
        if TimerEnabled and not isInRound then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:GetAttribute("Time") and obj:GetAttribute("Time") > 10 then
                    isInRound = true
                    if TimerGui then TimerGui.Enabled = true end
                    break
                end
            end
        end
    end
end)
print("✅ 3 Botones de Kill agregados correctamente (Murder Tools)")
print("✅ Nexora Framework migrado a WindUI correctamente.")
