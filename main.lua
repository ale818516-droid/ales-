-- ==================== SETUP INICIAL ====================
repeat task.wait() until game:IsLoaded()

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = Workspace.CurrentCamera

-- ==================== CONFIGURACIÓN DE UI ====================
local Window = WindUI:CreateWindow({
    Title = "ALexHub",
    Icon = "rbxassetid://4483345906",
    Author = "Alexx Hub",
    Folder = "MM2_New_Project"
})

WindUI:AddTheme({
    ["Name"] = "Dark",
    ["Accent"] = "#18181b",
    ["Background"] = "#0e0e10"
})

local function Notify(title, content, duration)
    pcall(function()
        WindUI:Notify({
            Title = title or "AlexHub",
            Content = content or "",
            Duration = duration or 3
        })
    end)
end

-- ==========================================================
-- VARIABLES GLOBALES (necesarias para Silent Aim)
-- ==========================================================
local RoleCache = {}
local closesthitpart = nil

local Config = {
    SilentAim = false,
    GunSilentAim = false,
    WallCheck = false,
    LeadShot = false
}

-- ==========================================================
-- 1. PESTAÑA AUTO FARM
-- ==========================================================
local FarmTab = Window:Tab({Title = "Auto Farm", Icon = "rocket"})

local SecGun = FarmTab:Section({Title = "Gun Tools"})

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
                        Notify("¡Arma recogida!", "Recogida instantánea.", 1)
                    end
                    task.wait(0.1) 
                end
            end)
        end
    end
})

-- Coins Farm
local CoinsSection = FarmTab:Section({Title = "Coins Farm"})

local coinOrig = {}
local coinReachConn = nil
local autoFarmCoinsRunning = false
local autoFarmCoinsThread = nil

CoinsSection:Toggle({
    Title = "Coins Reach (4x Size)",
    Default = false,
    Callback = function(v)
        if v then
            coinOrig = {}
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
                    if not coinOrig[obj] then
                        coinOrig[obj] = obj.Size
                    end
                    obj.Size = coinOrig[obj] * 4
                end
            end
            
            coinReachConn = Workspace.DescendantAdded:Connect(function(obj)
                if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
                    if not coinOrig[obj] then
                        coinOrig[obj] = obj.Size
                    end
                    obj.Size = coinOrig[obj] * 4
                end
            end)
        else
            for obj, originalSize in pairs(coinOrig) do
                if obj and obj.Parent then
                    obj.Size = originalSize
                end
            end
            if coinReachConn then
                coinReachConn:Disconnect()
                coinReachConn = nil
            end
            coinOrig = {}
        end
    end
})

local function AutoFarmCoinsFunc()
    local function GetMap()
        while true do
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:GetAttribute("MapID") and obj:FindFirstChild("CoinContainer") then
                    return obj
                end
            end
            task.wait(0.1)
        end
    end

    local function getNearest()
        local map = GetMap()
        local closest, dist = nil, math.huge
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return nil end
        local HRP = char:FindFirstChild("HumanoidRootPart")
        if not HRP then return nil end
        
        for _, coin in ipairs(map.CoinContainer:GetChildren()) do
            local v = coin:FindFirstChild("CoinVisual")
            if v and not v:GetAttribute("Collected") then
                local d = (HRP.Position - coin.Position).Magnitude
                if d < dist then
                    closest = coin
                    dist = d
                end
            end
        end
        return closest
    end

    local function tp(hp)
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") then return end
        local HRP = char:FindFirstChild("HumanoidRootPart")
        local Humanoid = char:FindFirstChild("Humanoid")
        if not HRP or not Humanoid or Humanoid.Health <= 0 then
            autoFarmCoinsRunning = false
            return
        end
        Humanoid:ChangeState(11)
        local d = (HRP.Position - hp.Position).Magnitude
        local t = TweenService:Create(HRP, TweenInfo.new(d / 25, Enum.EasingStyle.Linear), {CFrame = hp.CFrame})
        t:Play()
        t.Completed:Wait()
    end

    while autoFarmCoinsRunning and task.wait(0.1) do
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            autoFarmCoinsRunning = false
            break
        end
        local target = getNearest()
        if target then
            tp(target)
            local v = target:FindFirstChild("CoinVisual")
            while v and not v:GetAttribute("Collected") and v.Parent do
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
                    autoFarmCoinsRunning = false
                    break
                end
                local n = getNearest()
                if n and n ~= target then break end
                task.wait(0.1)
            end
        else
            task.wait(0.5)
        end
    end
end

CoinsSection:Toggle({
    Title = "Auto Farm Coins",
    Default = false,
    Callback = function(v)
        if v then
            autoFarmCoinsRunning = true
            autoFarmCoinsThread = task.spawn(AutoFarmCoinsFunc)
        else
            autoFarmCoinsRunning = false
            if autoFarmCoinsThread then
                task.cancel(autoFarmCoinsThread)
                autoFarmCoinsThread = nil
            end
        end
    end
})

CoinsSection:Button({
    Title = "FORCE STOP FARM (if dead)",
    Callback = function()
        autoFarmCoinsRunning = false
        if autoFarmCoinsThread then
            task.cancel(autoFarmCoinsThread)
            autoFarmCoinsThread = nil
        end
        Notify("Farm", "Auto Farm detenido!", 2)
    end
})

-- ==========================================================
-- 2. PESTAÑA COMBAT (SHERIFF/HERO - EXACTO DE NEXUS)
-- ==========================================================
local CombatTab = Window:Tab({Title = "Combat", Icon = "swords"})

local SheriffSection = CombatTab:Section({Title = "SHERIFF/HERO (GUN)"})

-- ========== LÓGICA EXACTA DE NEXUS ==========

local function GetLeadShotPosition(targetRootPart)
    local currentPos = targetRootPart.Position
    if Config.LeadShot then 
        local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
        currentPos = currentPos + (targetRootPart.Velocity * ping * 1.5) 
    end
    return currentPos
end

local function PerformSilentAimDirectly()
    if not Config.SilentAim then
        return false
    end
    
    local gun = nil
    
    for _, i in ipairs(LocalPlayer.Character:GetChildren()) do
        if i:IsA("Tool") and (string.find(string.lower(i.Name), "gun") or i.Name == "Revolver") then
            gun = i
            break
        end
    end
    
    if not gun then
        for _, i in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if i:IsA("Tool") and (string.find(string.lower(i.Name), "gun") or i.Name == "Revolver") then
                gun = i
                break
            end
        end
    end
    
    if not gun then
        return false
    end
    
    local targetPlr = nil
    for plrName, role in pairs(RoleCache) do
        if role == "Murderer" then
            targetPlr = Players:FindFirstChild(plrName)
            if targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") then
                break
            else
                targetPlr = nil
            end
        end
    end
    
    if not targetPlr or not targetPlr.Character or not targetPlr.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    if Config.WallCheck then
        local origin = Camera.CFrame.Position
        local targetPosRaw = targetPlr.Character.HumanoidRootPart.Position
        local direction = (targetPosRaw - origin).Unit * (targetPosRaw - origin).Magnitude
        
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPlr.Character, Workspace:FindFirstChild("GunDrop")}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        
        if Workspace:Raycast(origin, direction, rayParams) then
            return false
        end
    end
    
    local wasInBackpack = (gun.Parent == LocalPlayer.Backpack)
    if wasInBackpack then
        LocalPlayer.Character.Humanoid:EquipTool(gun)
        task.wait(0.1)
    end
    
    local targetRoot = targetPlr.Character.HumanoidRootPart
    local targetPos = GetLeadShotPosition(targetRoot)
    
    local args = {CFrame.new(Camera.CFrame.Position, targetPos), CFrame.new(targetPos)}
    
    if gun:FindFirstChild("Shoot") then
        gun.Shoot:FireServer(unpack(args))
        
        if wasInBackpack and gun.Parent == LocalPlayer.Character then
            gun.Parent = LocalPlayer.Backpack
        end
        return true
    end
    
    return false
end

local function getGunTarget()
    if not Config.GunSilentAim then return nil end
    
    local myRole = RoleCache[LocalPlayer.Name]
    if myRole ~= "Sheriff" and myRole ~= "Hero" then
        return nil
    end
    
    for plrName, role in pairs(RoleCache) do
        if role == "Murderer" then
            local plr = Players:FindFirstChild(plrName)
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local humanoidrootpart = plr.Character.HumanoidRootPart
                local humanoid = plr.Character:FindFirstChild("Humanoid")
                
                if humanoidrootpart and humanoid and humanoid.Health > 0 then
                    return humanoidrootpart
                end
            end
        end
    end
    
    return nil
end

local function getdirection(origin, position)
    return (position - origin).Unit
end

-- Hook de Raycast (Gun Silent Aim) - EXACTO de Nexus
local oldnamecall
oldnamecall = hookmetamethod(game, "__namecall", function(...)
    local method = getnamecallmethod()
    local arguments = {...}
    local self = arguments[1]

    if self == Workspace and not checkcaller() and method == "Raycast" and Config.GunSilentAim then
        local hitpart = closesthitpart
        
        if hitpart then
            local origin = arguments[2]
            local direction = getdirection(origin, hitpart.Position) * 1000
            arguments[3] = direction
            return oldnamecall(unpack(arguments))
        end
    end

    return oldnamecall(...)
end)

-- Actualizar target continuamente
RunService.Heartbeat:Connect(function()
    closesthitpart = getGunTarget()
end)

-- Botón flotante NEXUS AIM (exacto)
local ShootGui = Instance.new("ScreenGui")
ShootGui.Name = "ShootGui_Overlay_V19"
ShootGui.Parent = CoreGui
ShootGui.Enabled = false
ShootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ShootButton = Instance.new("TextButton")
ShootButton.Parent = ShootGui
ShootButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ShootButton.BackgroundTransparency = 0.5
ShootButton.Position = UDim2.new(0.65, 0, 0.6, 0)
ShootButton.Size = UDim2.new(0, 220, 0, 80)
ShootButton.Font = Enum.Font.GothamBold
ShootButton.Text = "NEXUS AIM"
ShootButton.TextColor3 = Color3.fromRGB(0, 170, 255)
ShootButton.TextSize = 24
ShootButton.AutoButtonColor = false
ShootButton.TextStrokeTransparency = 0.8

local ShootCorner = Instance.new("UICorner")
ShootCorner.CornerRadius = UDim.new(0, 10)
ShootCorner.Parent = ShootButton

local ShootStroke = Instance.new("UIStroke")
ShootStroke.Parent = ShootButton
ShootStroke.Color = Color3.fromRGB(0, 170, 255)
ShootStroke.Thickness = 2
ShootStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local ShootGradient = Instance.new("UIGradient")
ShootGradient.Parent = ShootStroke
ShootGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 170, 255)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 170, 255))
}
ShootGradient.Rotation = 45

task.spawn(function()
    while ShootGui do
        if ShootGui.Enabled then
            ShootGradient.Rotation = (ShootGradient.Rotation + 2) % 360
        end
        task.wait(0.03)
    end
end)

-- Hacer draggable el botón
do
    local dragging, dragInput, dragStart, startPos
    ShootButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ShootButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    ShootButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            ShootButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function PerformSilentAimMouse()
    if not Config.SilentAim then return end
    
    local success = PerformSilentAimDirectly()
    
    if success then
        ShootButton.Text = "FIRED"
        ShootStroke.Color = Color3.fromRGB(255, 50, 50)
        task.delay(0.2, function()
            ShootButton.Text = "NEXUS AIM"
            ShootStroke.Color = Color3.fromRGB(0, 170, 255)
        end)
    else
        ShootButton.Text = "NO TARGET"
        ShootStroke.Color = Color3.fromRGB(255, 50, 50)
        task.delay(0.5, function()
            ShootButton.Text = "NEXUS AIM"
            ShootStroke.Color = Color3.fromRGB(0, 170, 255)
        end)
    end
end

ShootButton.MouseButton1Click:Connect(PerformSilentAimMouse)

-- Toggles exactos
SheriffSection:Toggle({
    Title = "Silent Aim (Button)",
    Default = false,
    Callback = function(v)
        Config.SilentAim = v
        ShootGui.Enabled = v
    end
})

SheriffSection:Toggle({
    Title = "Gun Silent Aim",
    Default = false,
    Callback = function(v)
        Config.GunSilentAim = v
    end
})

SheriffSection:Toggle({
    Title = "Aim WallCheck",
    Default = false,
    Callback = function(v)
        Config.WallCheck = v
    end
})

SheriffSection:Toggle({
    Title = "Lead Shot (Ping Predict)",
    Default = false,
    Callback = function(v)
        Config.LeadShot = v
    end
})

-- ==========================================================
-- 3. PESTAÑA VISUALS
-- ==========================================================
local VisualsTab = Window:Tab({Title = "Visuals", Icon = "eye"})

local RoleColors = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff  = Color3.fromRGB(0, 100, 255),
    Hero     = Color3.fromRGB(255, 255, 0),
    Innocent = Color3.fromRGB(0, 255, 100),
    Lobby    = Color3.fromRGB(150, 150, 150),
    Gun      = Color3.fromRGB(255, 215, 0)
}

_G.ESP_Enabled = false
_G.GunESP_Enabled = false
_G.NotifyRoles = false
_G.NotifyGunDrop = false
_G.NotifyGunPickup = false

local rolesNotified = false
local wasGunDropped = false

local NotifySection = VisualsTab:Section({Title = "Notifications"})

NotifySection:Toggle({
    Title = "Notify Roles (Murd/Sher)",
    Default = false,
    Callback = function(Value) _G.NotifyRoles = Value end
})

NotifySection:Toggle({
    Title = "Notify Gun Drop",
    Default = false,
    Callback = function(Value) _G.NotifyGunDrop = Value end
})

NotifySection:Toggle({
    Title = "Notify Gun Pickup",
    Default = false,
    Callback = function(Value) _G.NotifyGunPickup = Value end
})

local RoleSection = VisualsTab:Section({Title = "Role ESP"})

local function cleanESP(char)
    local holder = char:FindFirstChild("AlexESP_Holder")
    if holder then holder:Destroy() end
end

local function applyRoleHighlight(player, role)
    local char = player.Character
    if not char then return end
    local color = RoleColors[role] or RoleColors.Innocent
    local holder = char:FindFirstChild("AlexESP_Holder")
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = "AlexESP_Holder"
        holder.Parent = char
    end
    local hl = holder:FindFirstChild("Highlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "Highlight"
        hl.Adornee = char
        hl.Parent = holder
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
end

local function getRoles()
    local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
    if remote then
        local success, data = pcall(function() return remote:InvokeServer() end)
        if success and data then
            local newRoles = {}
            for plr, plrData in pairs(data) do
                if plrData.Dead or not plrData.Role or plrData.Role == "" then
                    newRoles[plr] = "Lobby"
                else
                    newRoles[plr] = plrData.Role
                end
            end
            return newRoles
        end
    end
    return nil
end

task.spawn(function()
    while true do
        local roles = getRoles()
        if roles then
            RoleCache = roles
            if _G.NotifyRoles and not rolesNotified then
                local murderer, sheriff = "None", "None"
                for name, role in pairs(RoleCache) do
                    if role == "Murderer" then murderer = name end
                    if role == "Sheriff" then sheriff = name end
                end
                if murderer ~= "None" then
                    Notify("Roles Revelados", "Murderer: " .. murderer .. "\nSheriff: " .. sheriff, 5)
                    rolesNotified = true
                end
            end
            local hasMurder = false
            for _, r in pairs(RoleCache) do
                if r == "Murderer" then hasMurder = true break end
            end
            if not hasMurder then rolesNotified = false end
        end
        task.wait(0.4)
    end
end)

task.spawn(function()
    while task.wait(0.4) do
        if _G.ESP_Enabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local role = RoleCache[player.Name] or "Innocent"
                    if player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then
                        role = "Murderer"
                    elseif player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") then
                        role = "Sheriff"
                    end
                    applyRoleHighlight(player, role)
                end
            end
        else
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character then cleanESP(player.Character) end
            end
        end
    end
end)

RoleSection:Toggle({
    Title = "Role ESP (Highlight)",
    Default = false,
    Callback = function(Value)
        _G.ESP_Enabled = Value
        if not Value then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then cleanESP(p.Character) end
            end
        end
    end
})

local GunSection = VisualsTab:Section({Title = "Gun ESP"})

GunSection:Toggle({
    Title = "Highlight Gun Drop",
    Default = false,
    Callback = function(state) _G.GunESP_Enabled = state end
})

task.spawn(function()
    while true do
        local gunDrop = Workspace:FindFirstChild("GunDrop", true)

        if _G.GunESP_Enabled and gunDrop then
            local holder = gunDrop:FindFirstChild("AlexGunESP")
            if not holder then
                holder = Instance.new("Folder")
                holder.Name = "AlexGunESP"
                holder.Parent = gunDrop
                local hl = Instance.new("Highlight")
                hl.Name = "Highlight"
                hl.Adornee = gunDrop
                hl.FillColor = RoleColors.Gun
                hl.OutlineColor = Color3.fromRGB(255, 165, 0)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.Parent = holder
            end
        else
            if gunDrop then
                local holder = gunDrop:FindFirstChild("AlexGunESP")
                if holder then holder:Destroy() end
            end
        end

        if gunDrop and not wasGunDropped and _G.NotifyGunDrop then
            Notify("Gun Dropped", "¡El arma ha sido soltada en el mapa!", 4)
        end

        if wasGunDropped and not gunDrop and _G.NotifyGunPickup then
            task.wait(0.4)
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and (p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun")) then
                    Notify("Gun Picked", p.Name .. " recogió el arma!", 4)
                    break
                end
            end
        end

        wasGunDropped = (gunDrop ~= nil)
        task.wait(0.5)
    end
end)

print("✅ AlexHub cargado correctamente")
Notify("AlexHub", "Script cargado con éxito!", 4)