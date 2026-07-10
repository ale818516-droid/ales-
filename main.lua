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
-- ESTRUCTURA FARM (Lógica e Interfaz Original)
-- ==========================================================
local FarmSection = FarmTab:Section({ Title = "Configuración de Farm" })

-- Variables de estado (Basadas en el original)
_G.autofarmEnabled = false
local currentSpeed = 20
local farmCoinType = "Egg"
local farming = true
local bag_full = false
_G.AntiMurderer = false
local MurdererTarget = nil

-- Servicios necesarios
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- ==========================================================
-- ESTRUCTURA FARM (CONFIGURACIÓN CORREGIDA PARA AZUREHUB)
-- ==========================================================

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
    Values = {
        "Egg",
        "Coin"
    },
    Value = "Egg",
    Callback = function(v)
        print("Seleccionaste:", v)
        farmCoinType = v
    end
})


-- Lógica de recolección (IDÉNTICA al archivo original)
task.spawn(function()
    local CoinCollected = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("CoinCollected")
    local RoundStart = ReplicatedStorage.Remotes.Gameplay:WaitForChild("RoundStart")
    local RoundEnd = ReplicatedStorage.Remotes.Gameplay:WaitForChild("RoundEndFade")

    -- Detección de moneda cercana
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

    -- Evento de bolsa llena (Reinicia personaje como en el original)
    CoinCollected.OnClientEvent:Connect(function(coin_type, current, max)
        if coin_type == farmCoinType and current == max then
            bag_full = true
            task.spawn(function()
                if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                    LP.Character:BreakJoints()
                end
            end)
            repeat task.wait() until not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart")
            bag_full = false
        end
    end)

    RoundStart.OnClientEvent:Connect(function() farming = true end)
    RoundEnd.OnClientEvent:Connect(function() farming = false end)

    -- Bucle principal de Farm
    while task.wait() do
        if _G.autofarmEnabled and farming and not bag_full then
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local coin, dist = get_nearest_coin(hrp)
                if coin then
                    if dist > 150 then
                        hrp.CFrame = coin.CFrame
                    else
                        local tw = TweenService:Create(hrp, TweenInfo.new(dist / math.max(1, currentSpeed), Enum.EasingStyle.Linear), {CFrame = coin.CFrame})
                        tw:Play()
                        repeat task.wait() until not coin:FindFirstChild("TouchInterest") or not _G.autofarmEnabled or not farming
                        tw:Cancel()
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
        print("Anti-Murderer activado: " .. tostring(state))
    end
})

-- Lógica Anti-Murderer
task.spawn(function()
    while task.wait(0.2) do
        if _G.AntiMurderer then
            local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if myHrp then
                -- Escanear jugadores
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        -- Aquí se asume que el juego actualiza el rol en un Attribute o similar, 
                        -- si tu script de Cobalt lo maneja distinto, ajusta esta línea:
                        local role = player:GetAttribute("Role") -- Ajusta según como detecte el rol tu juego
                        
                        if role == "Murderer" then
                            local mHrp = player.Character.HumanoidRootPart
                            local dist = (myHrp.Position - mHrp.Position).Magnitude
                            
                            if dist < 30 then -- Distancia de seguridad
                                local direction = (myHrp.Position - mHrp.Position).Unit
                                myHrp.CFrame = myHrp.CFrame + (direction * 15)
                            end
                        end
                    end
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

print("✅ 3 Botones de Kill agregados correctamente (Murder Tools)")
print("✅ Nexora Framework migrado a WindUI correctamente.")
