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
-- VARIABLES / CONFIG
-- ==========================================================
local RoleCache = {}
local closesthitpart = nil

local Config = {
    SilentAim = false,
    GunSilentAim = false,
    WallCheck = false,
    LeadShot = false,
    KnifeAura = false,
    KnifeAuraDist = 15,
    KnifeLegitMode = false,
    HitboxExpand = false,
    HitboxSize = 4,
    HitboxVisible = false
}

-- ==========================================================
-- 1. PESTAÑA AUTO FARM
-- ==========================================================
local FarmTab = Window:Tab({Title = "Auto Farm", Icon = "rocket"})

-- Gun Tools
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
                    if GetGunFast() then
                        Notify("¡Arma recogida!", "Recogida instantánea.", 1)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- ==================== COINS FARM ====================
local CoinsSection = FarmTab:Section({Title = "Coins Farm"})

local autoFarmCoinsRunning = false
local bag_full = false
local maxCoins = 40

local function StopFarm()
    autoFarmCoinsRunning = false
    bag_full = false
end

local function AutoFarmCoinsFunc()
    local function GetMap()
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:GetAttribute("MapID") and obj:FindFirstChild("CoinContainer") then
                return obj
            end
        end
        return nil
    end

    local function getNearest()
        local map = GetMap()
        if not map then return nil end
        
        local closest, dist = nil, math.huge
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            return nil
        end
        
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
        if not char then return end
        local HRP = char:FindFirstChild("HumanoidRootPart")
        local Humanoid = char:FindFirstChild("Humanoid")
        if not HRP or not Humanoid or Humanoid.Health <= 0 then return end
        
        Humanoid:ChangeState(11)
        local d = (HRP.Position - hp.Position).Magnitude
        local t = TweenService:Create(HRP, TweenInfo.new(d / 28, Enum.EasingStyle.Linear), {CFrame = hp.CFrame})
        t:Play()
        t.Completed:Wait()
    end

    while true do
        -- Si el toggle se apagó → salir del loop de verdad
        if not autoFarmCoinsRunning then
            break
        end

        -- Bolsa llena → eliminar de verdad (muerte limpia)
        if bag_full then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    -- Muerte limpia
                    hum.Health = 0
                    pcall(function()
                        char:BreakJoints()
                    end)
                    Notify("Bolsa Llena", "Eliminado. Esperando respawn...", 3)
                end
            end
            
            -- Esperar a que respawnee de verdad
            local newChar = LocalPlayer.CharacterAdded:Wait()
            task.wait(1.5)
            bag_full = false
        end

        if autoFarmCoinsRunning and not bag_full then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local target = getNearest()
                if target then
                    tp(target)
                    task.wait(0.12)
                else
                    task.wait(0.35)
                end
            else
                task.wait(0.4)
            end
        else
            task.wait(0.3)
        end
    end
end

-- Detectar bolsa llena
task.spawn(function()
    local success, CoinCollected = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("CoinCollected")
    end)
    
    if success and CoinCollected then
        CoinCollected.OnClientEvent:Connect(function(coin_type, current, max)
            if typeof(max) == "number" then
                maxCoins = max
            end
            
            if current >= maxCoins then
                bag_full = true
            end
        end)
    end
end)

-- Reset al empezar ronda
task.spawn(function()
    local success, RoundStart = pcall(function()
        return ReplicatedStorage.Remotes.Gameplay:WaitForChild("RoundStart")
    end)
    if success and RoundStart then
        RoundStart.OnClientEvent:Connect(function()
            bag_full = false
        end)
    end
end)

CoinsSection:Toggle({
    Title = "Auto Farm Coins",
    Default = false,
    Callback = function(v)
        if v then
            autoFarmCoinsRunning = true
            bag_full = false
            task.spawn(AutoFarmCoinsFunc)
            Notify("Auto Farm", "Activado", 2)
        else
            -- Apagar de verdad
            StopFarm()
            Notify("Auto Farm", "Desactivado", 2)
        end
    end
})

-- ==========================================================
-- 2. PESTAÑA COMBAT
-- ==========================================================
local CombatTab = Window:Tab({Title = "Combat", Icon = "swords"})

-- ==================== SHERIFF/HERO (GUN) ====================
local SheriffSection = CombatTab:Section({Title = "SHERIFF/HERO (GUN)"})

local function GetLeadShotPosition(targetRootPart)
    local currentPos = targetRootPart.Position
    if Config.LeadShot then
        local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
        currentPos = currentPos + (targetRootPart.Velocity * ping * 1.5)
    end
    return currentPos
end

local function PerformSilentAimDirectly()
    if not Config.SilentAim then return false end

    local gun = nil
    for _, i in ipairs(LocalPlayer.Character:GetChildren()) do
        if i:IsA("Tool") and (string.find(string.lower(i.Name), "gun") or i.Name == "Revolver") then
            gun = i break
        end
    end
    if not gun then
        for _, i in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if i:IsA("Tool") and (string.find(string.lower(i.Name), "gun") or i.Name == "Revolver") then
                gun = i break
            end
        end
    end
    if not gun then return false end

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
        if Workspace:Raycast(origin, direction, rayParams) then return false end
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
    if myRole ~= "Sheriff" and myRole ~= "Hero" then return nil end
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

RunService.Heartbeat:Connect(function()
    closesthitpart = getGunTarget()
end)

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

Instance.new("UICorner", ShootButton).CornerRadius = UDim.new(0, 10)

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

do
    local dragging, dragInput, dragStart, startPos
    ShootButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ShootButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
    Callback = function(v) Config.GunSilentAim = v end
})

SheriffSection:Toggle({
    Title = "Aim WallCheck",
    Default = false,
    Callback = function(v) Config.WallCheck = v end
})

SheriffSection:Toggle({
    Title = "Lead Shot (Ping Predict)",
    Default = false,
    Callback = function(v) Config.LeadShot = v end
})

-- ==================== KNIFE AURA ====================
local KnifeAuraSection = CombatTab:Section({Title = "KNIFE AURA"})

local function GetKnifeRemote()
    if not LocalPlayer.Character then return nil end
    local tool = LocalPlayer.Character:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
    if tool then
        return tool:FindFirstChild("HandleTouched", true)
    end
    return nil
end

task.spawn(function()
    while true do
        if Config.KnifeAura and RoleCache[LocalPlayer.Name] == "Murderer" then
            local myChar = LocalPlayer.Character
            local knife = myChar and myChar:FindFirstChild("Knife")
            
            if knife and knife:FindFirstChild("Handle") then
                local targetFound = false
                
                for _, enemy in ipairs(Players:GetPlayers()) do
                    if enemy ~= LocalPlayer and enemy.Character then
                        local eRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
                        local eHum = enemy.Character:FindFirstChild("Humanoid")
                        local eRole = RoleCache[enemy.Name]
                        
                        if eRoot and eHum and eHum.Health > 0 and eRole ~= "Murderer" and eRole ~= "Lobby" then
                            local dist = (eRoot.Position - myChar.HumanoidRootPart.Position).Magnitude
                            
                            if dist <= Config.KnifeAuraDist then
                                eRoot.CFrame = knife.Handle.CFrame
                                eRoot.Velocity = Vector3.new(0,0,0)
                                eRoot.RotVelocity = Vector3.new(0,0,0)
                                
                                local remote = GetKnifeRemote()
                                if remote then
                                    pcall(function()
                                        remote:FireServer(eRoot)
                                    end)
                                end
                                
                                if Config.KnifeLegitMode then
                                    targetFound = true
                                    break
                                end
                            end
                        end
                    end
                    
                    if Config.KnifeLegitMode and targetFound then
                        break
                    end
                end
            end
        end
        task.wait()
    end
end)

KnifeAuraSection:Toggle({
    Title = "Enable Knife Aura",
    Default = false,
    Callback = function(v) Config.KnifeAura = v end
})

KnifeAuraSection:Slider({
    Title = "Aura Distance",
    Value = { Min = 5, Max = 50, Default = 15 },
    Callback = function(v) Config.KnifeAuraDist = v end
})

-- ==================== HITBOX EXPANDER ====================
local HitboxSection = CombatTab:Section({Title = "HITBOX EXPANDER"})

RunService.RenderStepped:Connect(function()
    if Config.HitboxExpand then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    root.Transparency = Config.HitboxVisible and 0.5 or 1
                    root.CanCollide = false
                end
            end
        end
    end
end)

HitboxSection:Toggle({
    Title = "Enable Expand",
    Default = false,
    Callback = function(v)
        Config.HitboxExpand = v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.Size = Vector3.new(2, 2, 1)
                        root.Transparency = 0
                        root.CanCollide = true
                    end
                end
            end
        end
    end
})

HitboxSection:Slider({
    Title = "Size (Default: 4)",
    Value = { Min = 2, Max = 30, Default = 4 },
    Callback = function(v) Config.HitboxSize = v end
})

HitboxSection:Toggle({
    Title = "Visible Hitbox",
    Default = false,
    Callback = function(v) Config.HitboxVisible = v end
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
NotifySection:Toggle({ Title = "Notify Roles (Murd/Sher)", Default = false, Callback = function(v) _G.NotifyRoles = v end })
NotifySection:Toggle({ Title = "Notify Gun Drop", Default = false, Callback = function(v) _G.NotifyGunDrop = v end })
NotifySection:Toggle({ Title = "Notify Gun Pickup", Default = false, Callback = function(v) _G.NotifyGunPickup = v end })

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