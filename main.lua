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
    Title = "Alexx hub",
    Theme = "Dark",
    Author = "Yisuhub",
    Folder = "Alexx",
    Acrylic = false,
    Transparent = false,
    NewElements = true,
    HideSearchBar = false,
    OpenButton = { Enabled = true, Draggable = true, Title = "YisusHub", CornerRadius = UDim.new(1), Scale = 0.8 },
    Topbar = { Height = 44, ButtonsType = "Default" }
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

-- Coins Farm (simple, sin matar ni rejoin)
local CoinsSection = FarmTab:Section({Title = "Coins Farm"})

local autoFarmCoinsRunning = false
local bag_full = false
local maxCoins = 40

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
        if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return nil end
        local HRP = char:FindFirstChild("HumanoidRootPart")
        if not HRP then return nil end
        for _, coin in ipairs(map.CoinContainer:GetChildren()) do
            local v = coin:FindFirstChild("CoinVisual")
            if v and not v:GetAttribute("Collected") then
                local d = (HRP.Position - coin.Position).Magnitude
                if d < dist then closest = coin dist = d end
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
        if not autoFarmCoinsRunning then break end

        if bag_full then
            task.wait(1)
        else
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
        end
        task.wait(0.03)
    end
end

task.spawn(function()
    local success, CoinCollected = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("CoinCollected")
    end)
    if success and CoinCollected then
        CoinCollected.OnClientEvent:Connect(function(coin_type, current, max)
            if typeof(max) == "number" then maxCoins = max end
            if current >= maxCoins then
                if not bag_full then
                    bag_full = true
                    Notify("Bolsa Llena", "Límite alcanzado. Esperando...", 3)
                end
            else
                bag_full = false
            end
        end)
    end
end)

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
        autoFarmCoinsRunning = v
        bag_full = false
        if v then
            task.spawn(AutoFarmCoinsFunc)
            Notify("Auto Farm", "Activado", 2)
        else
            Notify("Auto Farm", "Desactivado", 2)
        end
    end
})

-- ==========================================================
-- 2. PESTAÑA COMBAT
-- ==========================================================
local CombatTab = Window:Tab({Title = "Combat", Icon = "swords"})

-- SHERIFF/HERO
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

-- KNIFE AURA
local KnifeAuraSection = CombatTab:Section({Title = "KNIFE AURA"})

local function GetKnifeRemote()
    if not LocalPlayer.Character then return nil end
    local tool = LocalPlayer.Character:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
    if tool then return tool:FindFirstChild("HandleTouched", true) end
    return nil
end

task.spawn(function()
    while true do
        if Config.KnifeAura and RoleCache[LocalPlayer.Name] == "Murderer" then
            local myChar = LocalPlayer.Character
            local knife = myChar and myChar:FindFirstChild("Knife")
            if knife and knife:FindFirstChild("Handle") then
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
                                    pcall(function() remote:FireServer(eRoot) end)
                                end
                            end
                        end
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

-- HITBOX EXPANDER
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
-- 3. PESTAÑA VISUALS (ESP EXACTO que pediste)
-- ==========================================================
_G.ESP_Enabled = false
_G.LatestPlayerData = {}
_G.IsRefiningMode = false
_G.HighlightGun = false

local VisualsTab = Window:Tab({Title = "Visuals", Icon = "eye"})
local RoleSection = VisualsTab:Section({Title = "Role ESP System"})

local function cleanESP(char)
    if char:FindFirstChild("RoleHighlight") then char.RoleHighlight:Destroy() end
    if char:FindFirstChild("Head") and char.Head:FindFirstChild("RoleTag") then char.Head.RoleTag:Destroy() end
end

local function applyESP(player, role)
    local char = player.Character
    if not char then return end
    
    local color = (role == "Sheriff" and Color3.fromRGB(0, 170, 255)) or 
                  (role == "Murderer" and Color3.fromRGB(255, 85, 85)) or 
                  Color3.fromRGB(85, 255, 127)
    
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

    local head = char:FindFirstChild("Head")
    if head then
        if role == "Murderer" then
            if not head:FindFirstChild("RoleTag") then
                local bill = Instance.new("BillboardGui")
                bill.Name = "RoleTag"
                bill.Adornee = head
                bill.Size = UDim2.new(0, 150, 0, 40) 
                bill.StudsOffset = Vector3.new(0, 2.5, 0)
                bill.AlwaysOnTop = true
                bill.SizeOffset = Vector2.new(0, 0) 
                bill.Parent = head
                
                local label = Instance.new("TextLabel")
                label.Parent = bill
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = "[ASESINO]"
                label.TextColor3 = color
                label.TextStrokeTransparency = 0
                label.Font = Enum.Font.SourceSansBold
                label.TextSize = 18
                label.TextXAlignment = Enum.TextXAlignment.Center
                label.TextYAlignment = Enum.TextYAlignment.Center
            end
        else
            if head:FindFirstChild("RoleTag") then head.RoleTag:Destroy() end
        end
    end
end

pcall(function()
    game:GetService("ReplicatedStorage").Remotes.Gameplay.PlayerDataChanged.OnClientEvent:Connect(function(data)
        _G.LatestPlayerData = data
    end)
end)

task.spawn(function()
    task.wait(10)
    _G.IsRefiningMode = true
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.ESP_Enabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    local data = _G.LatestPlayerData and _G.LatestPlayerData[player.Name]
                    local role = data and data.Role or "Innocent"
                    
                    if _G.IsRefiningMode then
                        if player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") then
                            role = "Sheriff"
                        elseif player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then
                            role = "Murderer"
                        end
                    end
                    
                    applyESP(player, role)
                    
                    -- Actualizar RoleCache para el Silent Aim / Knife Aura
                    RoleCache[player.Name] = role
                end
            end
        end
    end
end)

RoleSection:Toggle({
    Title = "Role ESP",
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

local GunEspSection = VisualsTab:Section({Title = "Gun ESP"})

GunEspSection:Toggle({
    Title = "Highlight Gun Drop (Dorado)",
    Default = false,
    Callback = function(state)
        _G.HighlightGun = state
    end
})

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

print("✅ AlexHub cargado correctamente")
Notify("AlexHub", "Script cargado con éxito!", 5)