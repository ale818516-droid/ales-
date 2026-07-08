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

_G.GunTPEnabled = false
_G.AimbotComboEnabled = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
-- [SISTEMA ESP DE ROLES COMPLETO - CON CANDADO POR ROLES] --

-- Variables de control (Asegúrate de tenerlas declaradas)
local ESPEnabled = ESPEnabled or false
local PlayerRoles = PlayerRoles or {}
local LocalPlayer = game:GetService("Players").LocalPlayer

local COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 0, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

-- Función limpia para remover el Highlight visual
local function removeESP(player)
    if player.Character then
        local highlight = player.Character:FindFirstChild("RoleESP")
        if highlight then highlight:Destroy() end
    end
end

-- Función auxiliar para verificar si la partida está activa según tus datos
local function isRoundActive()
    -- Candado inteligente: Si tú tienes un rol asignado, la partida está corriendo
    local myRole = PlayerRoles[LocalPlayer.Name]
    if myRole and myRole ~= "" and myRole ~= "Lobby" then
        return true
    end
    return false
end

-- Función principal que pinta a los jugadores
local function updatePlayerESP(player)
    -- Si el botón está apagado, eres tú mismo, o no ha iniciado la ronda, se borra
    if not ESPEnabled or player == LocalPlayer or not isRoundActive() then 
        removeESP(player)
        return 
    end

    local char = player.Character
    if not char then return end

    -- Obtener rol de la tabla o dejarlo como Inocente por defecto
    local role = PlayerRoles[player.Name] or "Innocent"
    
    -- Verificación en tiempo real por si saca o agarra la pistola física
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

-- Procesar evento remoto original PlayerDataChanged sin pérdida de datos
local DataChangedEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("PlayerDataChanged")
DataChangedEvent.OnClientEvent:Connect(function(dataPacket)
    if type(dataPacket) == "table" then
        -- Guardar los roles nuevos en la tabla posición por posición
        for playerName, info in pairs(dataPacket) do
            if info and info.Role then
                PlayerRoles[playerName] = info.Role
            end
        end
        
        -- Si la ronda está activa, actualiza los colores; si no, limpia todo
        if isRoundActive() then
            for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                updatePlayerESP(player)
            end
        else
            table.clear(PlayerRoles)
            for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                removeESP(player)
            end
        end
    end
end)

-- Monitoreo clásico de mochilas en tiempo real
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

-- Inicializar escuchadores en los jugadores
for _, player in ipairs(game:GetService("Players"):GetPlayers()) do setupPlayerTracking(player) end
game:GetService("Players").PlayerAdded:Connect(setupPlayerTracking)

-- LIMPIADOR DE SEGURIDAD ABSOLUTO (Cuando se destruye el mapa/limpieza de ronda)
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "Normal" or child.Name == "Infection" or child.Name == "Assassin" then
        table.clear(PlayerRoles)
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            removeESP(player)
        end
    end
end)

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

-- [SISTEMA ESP DE LA PISTOLA TIRADA - MÉTODO REAL DE MM2] --

_G.GunESPEnabled = _G.GunESPEnabled or false

-- Función para buscar el objeto físico de la pistola en el mapa
local function findDroppedGun()
    -- En MM2 la pistola tirada se genera como un objeto llamado "GunDrop" directamente en el Workspace
    local gun = workspace:FindFirstChild("GunDrop")
    if gun and gun:IsA("BasePart") then
        return gun
    end
    
    -- Respaldo: Buscar por si se metió dentro de la carpeta del mapa actual
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") then
            return obj
        end
    end
    return nil
end

local function applyGunEffects(obj)
    if not obj or not obj:IsA("BasePart") then return end
    if obj:FindFirstChild("GunVisualESP") then return end
    
    -- Caja visual (Box) sobre el arma tirada
    local box = Instance.new("BoxHandleAdorner")
    box.Name = "GunVisualESP"
    box.Size = Vector3.new(1.5, 1.5, 1.5) -- Tamaño perfecto para que se note en el suelo
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Color3 = Color3.fromRGB(0, 150, 255) -- Azul brillante
    box.Transparency = 0.4
    box.Adornee = obj
    box.Parent = obj
    
    -- Línea trazadora (Tracer)
    local tracer = Drawing.new("Line")
    tracer.Visible = true
    tracer.Color = Color3.fromRGB(0, 150, 255)
    tracer.Thickness = 2.5
    tracer.Transparency = 0.8
    
    -- Actualización en tiempo real del Tracer hacia la posición de la pistola
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        local isPlaying = workspace:FindFirstChild("Normal") or workspace:FindFirstChild("Infection") or workspace:FindFirstChild("Assassin")
        
        -- Si se borra la pistola, apagas el botón, o vas al lobby, se elimina el tracer
        if not obj or not obj.Parent or not _G.GunESPEnabled or not isPlaying then 
            tracer:Remove()
            if connection then connection:Disconnect() end
            return
        end
        
        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(obj.Position)
        if onScreen then
            tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
            tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            tracer.Visible = true
        else
            tracer.Visible = false
        end
    end)
end

-- BUCLE DE ESCANEO ACTIVO CONSTANTE
task.spawn(function()
    while true do
        local isPlaying = workspace:FindFirstChild("Normal") or workspace:FindFirstChild("Infection") or workspace:FindFirstChild("Assassin")
        
        if _G.GunESPEnabled and isPlaying then
            local gunInstance = findDroppedGun()
            if gunInstance then
                applyGunEffects(gunInstance)
            end
        else
            -- Limpieza automática de cajas si el switch está apagado o estás en el lobby
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "GunDrop" and obj:IsA("BasePart") then
                    local box = obj:FindFirstChild("GunVisualESP")
                    if box then box:Destroy() end
                end
            end
        end
        task.wait(0.2) -- Escaneo continuo cada 200 milisegundos
    end
end)

-- Asegurar borrado total cuando el mapa se remueve
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "Normal" or child.Name == "Infection" or child.Name == "Assassin" then
        for _, obj in ipairs(workspace:GetDescendants()) do
            local box = obj:FindFirstChild("GunVisualESP")
            if box then box:Destroy() end
        end
    end
end)

-- Toggle para Activar/Desactivar el ESP de la Pistola Tirada (Rastreo de MM2)
MainTab:Toggle({
    Title = "Gun Drop ESP (Rastreo Físico)",
    Default = false,
    Callback = function(state)
        _G.GunESPEnabled = state
        
        -- Si se desactiva manualmente, limpia las cajas del mapa al instante
        if not _G.GunESPEnabled then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "GunDrop" and obj:IsA("BasePart") then
                    local box = obj:FindFirstChild("GunVisualESP")
                    if box then box:Destroy() end
                end
            end
        end
    end
})
