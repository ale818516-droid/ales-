-- Cargar la librería WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/azurelw/azurehub/refs/heads/main/main.lua"))()

local Window = Window or WindUI:CreateWindow({
    Title = "MM2 Helper",
    Icon = "rbxassetid://4483345906",
    Author = "Alexx Hub",
    Folder = "WindUI_MM2"
})

local function NotifyToggle(name, state)
    WindUI:Notify({
        Title = state and "🟢 Activado" or "🔴 Desactivado",
        Content = name,
        Icon = state and "check-circle" or "x-circle",
        Duration = 3
    })
end

-- ====================== UNA SOLA PESTAÑA ======================
local MainTab = Window:Tab({ 
    Title = "MM2 Helper", 
    Icon = "eye" 
})

-- Sección 1: Contador de Ronda
local TimerSection = MainTab:Section({Title = "⏱ Contador de Ronda"})

local RoundTimer = TimerSection:Paragraph({
    Title = "Tiempo de ronda",
    Desc = "Esperando ronda..."
})

local Gameplay = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Gameplay")
local RoundStart = Gameplay:WaitForChild("RoundStart")
local RoundEndFade = Gameplay:WaitForChild("RoundEndFade")
local GameOver = Gameplay:WaitForChild("GameOver")

local RoundToken = 0

local function FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d:%02d", minutes, secs)
end

local function SetText(text)
    if RoundTimer and RoundTimer.ParagraphFrame then
        RoundTimer.ParagraphFrame:SetDesc(text)
    end
end

local function NotifyRound(title, text, icon)
    WindUI:Notify({Title = title, Content = text, Icon = icon, Duration = 3})
end

local function StopRound()
    RoundToken += 1
    SetText("🎮 Esperando ronda...")
    NotifyRound("🏁 Ronda terminada", "Esperando la siguiente ronda...", "flag")
end

RoundStart.OnClientEvent:Connect(function(Time)
    if typeof(Time) ~= "number" then return end
    NotifyRound("🎮 Nueva ronda", "¡La ronda ha comenzado!", "play")
    RoundToken += 1
    local Token = RoundToken
    task.spawn(function()
        local t = Time
        local warned60, warned30 = false, false
        while t >= 0 do
            if Token ~= RoundToken then return end
            if t <= 30 then
                SetText("🔴 " .. FormatTime(t))
                if not warned30 then warned30 = true NotifyRound("⚠️ Tiempo", "Quedan 30 segundos", "clock") end
            elseif t <= 60 then
                SetText("🟡 " .. FormatTime(t))
                if not warned60 then warned60 = true NotifyRound("⏳ Tiempo", "Queda 1 minuto", "clock") end
            else
                SetText("🟢 " .. FormatTime(t))
            end
            task.wait(1)
            t -= 1
        end
        StopRound()
    end)
end)

RoundEndFade.OnClientEvent:Connect(StopRound)
GameOver.OnClientEvent:Connect(StopRound)

-- Sección 2: Visuals & ESP
local VisualsSection = MainTab:Section({Title = "👁 Visuals & ESP"})

local ESPEnabled = false
local PlayerRoles = {}
local COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 0, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local function removeESP(player)
    if player and player.Character then
        local highlight = player.Character:FindFirstChild("RoleESP")
        if highlight then highlight:Destroy() end
    end
end

local function getPlayerRole(player)
    local role = PlayerRoles[player.Name]
    if role then return role end
    if player.Character then
        local char = player.Character
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("gun") or name:find("revolver") or name:find("pistol") then return "Sheriff" end
                if name:find("knife") or name:find("dagger") then return "Murderer" end
            end
        end
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    local name = tool.Name:lower()
                    if name:find("gun") or name:find("revolver") or name:find("pistol") then return "Sheriff" end
                    if name:find("knife") or name:find("dagger") then return "Murderer" end
                end
            end
        end
    end
    return "Innocent"
end

local function updatePlayerESP(player)
    if not ESPEnabled or player == LocalPlayer or not player.Character then 
        removeESP(player) return 
    end
    local char = player.Character
    local role = getPlayerRole(player)
    local color = COLORS[role] or COLORS["Innocent"]
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

local DataChangedEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("PlayerDataChanged")
DataChangedEvent.OnClientEvent:Connect(function(dataPacket)
    if type(dataPacket) == "table" then
        table.clear(PlayerRoles)
        for playerName, info in pairs(dataPacket) do
            if info and info.Role then PlayerRoles[playerName] = info.Role end
        end
        for _, player in ipairs(Players:GetPlayers()) do updatePlayerESP(player) end
    end
end)

local function setupPlayerTracking(player)
    player.CharacterAdded:Connect(function() task.wait(0.2) updatePlayerESP(player) end)
    updatePlayerESP(player)
end
for _, player in ipairs(Players:GetPlayers()) do setupPlayerTracking(player) end
Players.PlayerAdded:Connect(setupPlayerTracking)
Players.PlayerRemoving:Connect(removeESP)

VisualsSection:Toggle({
    Title = "Role ESP (Instantáneo)",
    Default = false,
    Callback = function(state)
        ESPEnabled = state
        NotifyToggle("Role ESP", state)
        for _, player in ipairs(Players:GetPlayers()) do
            if ESPEnabled then updatePlayerESP(player) else removeESP(player) end
        end
    end
})

-- Sección 3: Auto Farm & TP
local FarmSection = MainTab:Section({Title = "🚀 Auto Farm & TP"})

_G.GunTPEnabled = false

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
                if savedPosition then root.CFrame = savedPosition end
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

FarmSection:Toggle({
    Title = "Instant TP & Return",
    Default = false,
    Callback = function(state)
        _G.GunTPEnabled = state
        NotifyToggle("Instant TP", state)
        if state then coroutine.wrap(startGunDropLoop)() end
    end
})

-- Sección 4: Combat (Aimbot, Kill Aura, Anti Fling, etc.)
local CombatSection = MainTab:Section({Title = "⚔ Combat"})

_G.AimbotComboEnabled = false
_G.UltraKillAura = false
_G.SheriffKillAura = false
local AntiFlingEnabled = false
_G.GunESPEnabled = false

-- Aimbot Combo
local Camera = Workspace.CurrentCamera
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
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char, Workspace.CurrentCamera}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local result = Workspace:Raycast(root.Position, direction, rayParams)
                if result and result.Instance:IsDescendantOf(murdererChar) then
                    local vel = targetHRP.AssemblyLinearVelocity
                    local dist = direction.Magnitude
                    local prediction = vel * (dist / 500) * 0.30
                    local targetPos = targetHRP.CFrame + prediction
                    gun.Shoot:FireServer(root.CFrame, targetPos)
                    task.wait(0.15)
                end
            end
        end
        task.wait(0.02)
    end
end

CombatSection:Toggle({
    Title = "Aimbot + Silent Auto Shoot Combo",
    Default = false,
    Callback = function(state)
        _G.AimbotComboEnabled = state
        NotifyToggle("Aimbot Combo", state)
        if state then coroutine.wrap(startSilentShootLoop)() end
    end
})

-- Ultra Kill Aura (todo tu código)
task.spawn(function()
    while true do
        if _G.UltraKillAura then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local humanoid = myChar and myChar:FindFirstChild("Humanoid")
            if myRoot and humanoid then
                local knife = myChar:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
                if knife then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local targetChar = player.Character
                            local targetRoot = targetChar.HumanoidRootPart
                            local targetHumanoid = targetChar:FindFirstChild("Humanoid")
                            if targetHumanoid and targetHumanoid.Health > 0 then
                                for _, part in pairs(targetChar:GetDescendants()) do
                                    if part:IsA("BasePart") then part.CanCollide = false end
                                end
                                targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -2)
                            end
                        end
                    end
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
                    knife.Parent = LocalPlayer.Backpack
                end
            end
        end
        task.wait(0.1)
    end
end)

CombatSection:Toggle({
    Title = "Ultra Kill Aura (Instant Bring)",
    Default = false,
    Callback = function(state)
        _G.UltraKillAura = state
        NotifyToggle("Ultra Kill Aura", state)
    end
})

-- Sheriff Kill Aura
_G.SheriffKillAura = false

task.spawn(function()
    while true do
        if _G.SheriffKillAura then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local knife = myChar and (myChar:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife"))
            if myRoot and knife then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and PlayerRoles[player.Name] == "Sheriff" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local targetRoot = player.Character.HumanoidRootPart
                        local targetHumanoid = player.Character:FindFirstChild("Humanoid")
                        if targetHumanoid and targetHumanoid.Health > 0 then
                            targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
                            if knife.Parent ~= myChar then
                                myChar:FindFirstChild("Humanoid"):EquipTool(knife)
                            end
                            local stabEvent = knife:FindFirstChild("Events") and knife.Events:FindFirstChild("KnifeStabbed")
                            if stabEvent then
                                stabEvent:FireServer(targetRoot)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

CombatSection:Toggle({
    Title = "Auto Kill Sheriff",
    Default = false,
    Callback = function(state)
        _G.SheriffKillAura = state
        NotifyToggle("Auto Kill Sheriff", state)
    end
})

-- Anti Fling V2
local AntiFlingEnabled = false

local function setCanCollideOfModelDescendants(model, bval)
    if not model then return end
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = bval end
    end
end

RunService.Stepped:Connect(function()
    if AntiFlingEnabled then
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= Players.LocalPlayer and v.Character then
                setCanCollideOfModelDescendants(v.Character, false)
            end
        end
    end
end)

CombatSection:Toggle({
    Title = "Anti Fling V2",
    Default = false,
    Callback = function(state)
        AntiFlingEnabled = state
        NotifyToggle("Anti Fling V2", state)
        if not AntiFlingEnabled then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= Players.LocalPlayer and v.Character then
                    setCanCollideOfModelDescendants(v.Character, true)
                end
            end
        end
    end
})

-- ESP Gun Drop
local function startGunESP()
    local highlight = Instance.new("Highlight")
    highlight.Name = "GunHighlight"
    highlight.FillColor = Color3.fromRGB(255, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0

    task.spawn(function()
        while _G.GunESPEnabled do
            local currentGun = nil
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == "GunDrop" and obj:IsA("BasePart") then
                    currentGun = obj
                    break
                end
            end
            if currentGun then
                highlight.Parent = currentGun
            else
                highlight.Parent = nil
            end
            task.wait(0.2)
        end
        highlight:Destroy()
    end)
end

CombatSection:Toggle({
    Title = "ESP Gun Drop",
    Default = false,
    Callback = function(state)
        _G.GunESPEnabled = state
        NotifyToggle("ESP Gun Drop", state)
        if state then startGunESP() end
    end
})

print("✅ MM2 Helper cargado completo - Una pestaña con secciones")