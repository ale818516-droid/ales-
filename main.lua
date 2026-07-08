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
_G.AutoShootEnabled = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerRoles = {}

local COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 0, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

-- [SISTEMA ESP ORIGINAL - TOTALMENTE RESTAURADO] --
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

-- [PROCESAR EVENTO REMOTO ORIGINAL] --
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

-- Monitoreo de mochilas original
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


-- [SISTEMA AUTO SHOOT (DISPARO AUTOMÁTICO AL ASESINO)] --
local GunFiredRemote = ReplicatedStorage:WaitForChild("ClientServices"):WaitForChild("WeaponService"):WaitForChild("GunFired")

local function getMurderer()
    for playerName, role in pairs(PlayerRoles) do
        if role == "Murderer" then
            local p = Players:FindFirstChild(playerName)
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
                return p.Character
            end
        end
    end
    return nil
end

local function startAutoShootLoop()
    while _G.AutoShootEnabled do
        local char = LocalPlayer.Character
        local gun = char and char:FindFirstChild("Gun")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if gun and root then
            local murdererChar = getMurderer()
            if murdererChar then
                local muderRoot = murdererChar.HumanoidRootPart
                
                local rayOrigin = root.Position
                local rayDirection = (muderRoot.Position - rayOrigin).Unit * 200
                
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {char, Workspace:FindFirstChild("CoinContainer")}
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                
                if raycastResult and raycastResult.Instance:IsDescendantOf(murdererChar) then
                    local gunHandle = gun:FindFirstChild("Handle") or root
                    local startPos = gunHandle.Position
                    local targetPos = muderRoot.Position
                    
                    -- Disparar usando la estructura capturada de Cobalt
                    GunFiredRemote:FireServer(
                        gunHandle,
                        startPos,
                        targetPos,
                        raycastResult.Instance
                    )
                    
                    task.wait(1) -- Cooldown para evitar bugs de recarga
                end
            end
        end
        task.wait(0.05)
    end
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

-- Toggle del Auto Shoot Inteligente
MainTab:Toggle({
    Title = "Silent Auto Shoot (Al Mirar Asesino)",
    Default = false,
    Callback = function(state)
        _G.AutoShootEnabled = state
        if _G.AutoShootEnabled then
            coroutine.wrap(startAutoShootLoop)()
        end
    end
})
