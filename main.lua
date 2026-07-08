-- Cargar la librería WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/azurelw/azurehub/refs/heads/main/main.lua"))()

-- Crear la ventana principal
local Window = Window or WindUI:CreateWindow({
    Title = "MM2 Helper",
    Icon = "rbxassetid://4483345906",
    Author = "Alexx Hub",
    Folder = "WindUI_MM2"
})

-- Crear la pestaña
local MainTab = Window:Tab({ 
    Title = "MM2 Visuals & TP", 
    Icon = "eye" 
})

-- Variables de control
local ESPEnabled = false
_G.GunTPEnabled = false
_G.AimbotComboEnabled = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local PlayerRoles = {}

local COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 0, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

-- [SISTEMA ESP ORIGINAL - COMPLETO] --
local function removeESP(player)
    if player.Character then
        local highlight = player.Character:FindFirstChild("RoleESP")
        if highlight then highlight:Destroy() end
    end
end

local function updatePlayerESP(player)
    if not ESPEnabled or player == LocalPlayer then 
        removeESP(player)
        return 
    end

    local char = player.Character
    if not char then return end

    local role = PlayerRoles[player.Name] or "Innocent"
    
    if player.Backpack:FindFirstChild("Gun") or char:FindFirstChild("Gun") then
        role = "Sheriff"
    end

    local color = COLORS[role]

    local highlight = char:FindFirstChild("RoleESP")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "RoleESP"
        highlight.Parent = char
    end

    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
end

-- Procesar evento remoto original de roles
local DataChangedEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("PlayerDataChanged")
DataChangedEvent.OnClientEvent:Connect(function(dataPacket)
    if type(dataPacket) == "table" then
        table.clear(PlayerRoles)
        
        for playerName, info in pairs(dataPacket) do
            if info and info.Role then
                PlayerRoles[playerName] = info.Role
            end
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            updatePlayerESP(player)
        end
    end
end)

-- Monitoreo clásico de mochilas original
local function setupPlayerTracking(player)
    player.Backpack.ChildAdded:Connect(function(child)
        if child.Name == "Gun" then task.wait(0.1) updatePlayerESP(player) end
    end)
    player.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(child)
            if child.Name == "Gun" then task.wait(0.1) updatePlayerESP(player) end
        end)
        task.wait(0.2)
        updatePlayerESP(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do setupPlayerTracking(player) end
Players.PlayerAdded:Connect(setupPlayerTracking)


-- [AUTO TP AUTOMÁTICO - MÉTODO COIN FARM CON AUTO-RESET] --
local function startGunDropLoop()
    local savedPosition = nil
    local teleportedToThisGun = false

    while _G.GunTPEnabled do
        local lp = Players.LocalPlayer
        local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        
        if root then
            local currentGun = nil
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == "GunDrop" and obj:IsA("BasePart") then
                    currentGun = obj
                    break
                end
            end
            
            if currentGun and not teleportedToThisGun then
                savedPosition = root.CFrame
                
                root.CFrame = currentGun.CFrame + Vector3.new(0, 1, 0)
                task.wait(0.25) 
                
                if savedPosition then
                    root.CFrame = savedPosition
                end
                
                teleportedToThisGun = true 
            end
            
            if not currentGun then
                teleportedToThisGun = false 
                savedPosition = nil
            end
        end
        
        task.wait(0.2)
    end
end


-- [COMBINACIÓN COMPLETA: SEGUIMIENTO DE CÁMARA + EL MISMO SILENT AIM MATEMÁTICO] --
local Camera = Workspace.CurrentCamera
local GunFiredRemote = ReplicatedStorage:WaitForChild("ClientServices"):WaitForChild("WeaponService"):WaitForChild("GunFired")

local function getMurderer()
    for playerName, role in pairs(PlayerRoles) do
        if role == "Murderer" then
            local p = Players:FindFirstChild(playerName)
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
                if p.Character.Humanoid.Health > 0 then
                    return p.Character
                end
            end
        end
    end
    return nil
end

-- PARTE 1: Mover la cámara físicamente para seguirlo en pantalla
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

-- PARTE 2: Silent Auto Shoot con Predicción de Alta Precisión
local function startSilentShootLoop()
    print("Bucle permanente de Silent Aim con Predicción iniciado.")
    
    while _G.AimbotComboEnabled do
        local char = LocalPlayer.Character
        local gun = char and char:FindFirstChild("Gun")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if gun and gun:FindFirstChild("Shoot") and root then
            local murdererChar = getMurderer()
            
            if murdererChar and murdererChar:FindFirstChild("HumanoidRootPart") then
                local targetHRP = murdererChar.HumanoidRootPart
                local direction = (targetHRP.Position - root.Position)
                
                -- Crear Raycast para verificar línea de visión real
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char, Workspace.CurrentCamera}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local result = Workspace:Raycast(root.Position, direction, rayParams)
                
                -- Solo dispara si es visible (evita paredes)
                if result and result.Instance:IsDescendantOf(murdererChar) then
                    -- Cálculo matemático de predicción de movimiento
                    local vel = targetHRP.AssemblyLinearVelocity
                    local dist = direction.Magnitude
                    local prediction = vel * (dist / 500) * 0.30
                    local targetPos = targetHRP.CFrame + prediction
                    
                    -- Ejecutar disparo mediante el evento remoto de tu arma
                    gun.Shoot:FireServer(root.CFrame, targetPos)
                    
                    print("¡Silent Shot con predicción ejecutado!")
                    task.wait(0.15) -- Cooldown de seguridad para evitar filtros del servidor
                end
            end
        end
        task.wait(0.02) -- Escaneo constante a alta velocidad
    end
    print("Silent Aim con Predicción detenido.")
end

-- [INTERFAZ MENÚ WINDUI] --

-- Toggle del ESP Original
MainTab:Toggle({
    Title = "Role ESP (Instantáneo)",
    Default = false,
    Callback = function(state)
        ESPEnabled = state
        for _, player in ipairs(Players:GetPlayers()) do
            if ESPEnabled then updatePlayerESP(player) else removeESP(player) end
        end
    end
})

-- Toggle del Auto Teleport Permanente
MainTab:Toggle({
    Title = "Instant TP & Return (Totalmente Automático)",
    Default = false,
    Callback = function(state)
        _G.GunTPEnabled = state
        if _G.GunTPEnabled then
            coroutine.wrap(startGunDropLoop)()
        end
    end
})

-- Toggle del Aimbot Combo (Cámara + El Silent Aim Puro Exacto)
MainTab:Toggle({
    Title = "Aimbot + Silent Auto Shoot Combo",
    Default = false,
    Callback = function(state)
        _G.AimbotComboEnabled = state
        if _G.AimbotComboEnabled then
            coroutine.wrap(startSilentShootLoop)()
        end
    end
})
