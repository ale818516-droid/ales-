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

print("✅ Nexora Framework migrado a WindUI correctamente.")
