-- Cargar la librería WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/azurelw/azurehub/refs/heads/main/main.lua"))()

-- Crear la ventana principal
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

-- =============================================
--                  FARMING
-- =============================================

local AutoFarmToggle = false
local AutoFarmAvoidToggle = false
local AutoFarmMethod = "Closest"

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local function noclip()
    if not LocalPlayer.Character then return end
    for _, v in ipairs(LocalPlayer.Character:GetChildren()) do
        if v:IsA("BasePart") and v.CanCollide then
            v.CanCollide = false
        end
    end
end

local function clip()
    -- No hace falta desconectar si usamos método simple
end

local function autofarm()
    task.spawn(function()
        while AutoFarmToggle do
            local myChar = LocalPlayer.Character
            local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not root then task.wait(1) continue end

            local isMurderer = myChar and (myChar:FindFirstChild("Footsteps") or myChar:FindFirstChild("Sleight") or myChar:FindFirstChild("Decoy") or myChar:FindFirstChild("Ghost") or myChar:FindFirstChild("Fake Gun") or myChar:FindFirstChild("Xray") or myChar:FindFirstChild("Haste") or myChar:FindFirstChild("Trap") or myChar:FindFirstChild("Sprint") or myChar:FindFirstChild("Ninja"))
            
            local CoinContainer = workspace:FindFirstChild("CoinContainer", true)
            
            if CoinContainer then
                local currentMurderer = nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local char = p.Character
                        if char:FindFirstChild("Footsteps") or char:FindFirstChild("Decoy") or char:FindFirstChild("Sleight") or char:FindFirstChild("Ghost") or char:FindFirstChild("Ninja") or char:FindFirstChild("Fake Gun") or char:FindFirstChild("Xray") or char:FindFirstChild("Haste") or char:FindFirstChild("Trap") or char:FindFirstChild("Sprint") then
                            currentMurderer = char:FindFirstChild("HumanoidRootPart")
                            break
                        end
                    end
                end

                local allCoins = {}
                for _, c in ipairs(CoinContainer:GetChildren()) do
                    if c:IsA("BasePart") and string.find(c.Name, "Coin_Server") then
                        local isDangerous = false
                        if AutoFarmAvoidToggle and currentMurderer then
                            if (c.Position - currentMurderer.Position).Magnitude < 15 then
                                isDangerous = true
                            end
                        end
                        if not isDangerous then table.insert(allCoins, c) end
                    end
                end

                local targetCoin = nil
                local tweenTime = 1
                local waitTime = 1.1

                if #allCoins > 0 then
                    if AutoFarmMethod == "Closest" then
                        local closestDist = math.huge
                        for _, coin in ipairs(allCoins) do
                            local dist = (root.Position - coin.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                targetCoin = coin
                            end
                        end
                    elseif AutoFarmMethod == "Randomized" then
                        targetCoin = allCoins[math.random(1, #allCoins)]
                        tweenTime = 3
                        waitTime = 3.1
                    end
                end

                if targetCoin then
                    local distance = (root.Position - targetCoin.Position).Magnitude
                    if distance > 10 then
                        tweenTime += 0.5
                        waitTime += 0.6
                    elseif distance < 5 then
                        tweenTime = 0.3
                        waitTime = 0.4
                    end

                    local tween = TweenService:Create(root, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetCoin.Position)})
                    tween:Play()

                    local start = tick()
                    local cancelled = false
                    while tick() - start < waitTime do
                        if not AutoFarmToggle then tween:Cancel(); break end
                        if AutoFarmAvoidToggle and currentMurderer and not isMurderer then
                            if (root.Position - currentMurderer.Position).Magnitude < 7 then
                                tween:Cancel()
                                cancelled = true
                                break
                            end
                        end
                        task.wait(0.1)
                    end

                    if not cancelled and targetCoin and targetCoin.Parent then
                        targetCoin:Destroy()
                    end
                else
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        end
    end)
end

-- =============================================
--                  TABS
-- =============================================

local MainTab = Window:Tab({ 
    Title = "MM2 Visuals & TP", 
    Icon = "eye" 
})

-- Nueva pestaña de Farming
local FarmingTab = Window:Tab({ 
    Title = "Farming", 
    Icon = "tractor" 
})

-- =============================================
--             FARMING SECTION (Nueva Pestaña)
-- =============================================

local FarmSection = FarmingTab:Section({ 
    Title = "Auto Farm Coins", 
    Opened = true 
})

FarmSection:Toggle({
    Title = "Auto Farm Coins",
    Default = false,
    Callback = function(state)
        AutoFarmToggle = state
        NotifyToggle("Auto Farm Coins", state)
        if state then
            autofarm()
            -- Activar noclip automáticamente
            RunService.Stepped:Connect(function()
                if AutoFarmToggle then noclip() end
            end)
        end
    end
})

FarmSection:Toggle({
    Title = "Avoid Murderer",
    Default = false,
    Callback = function(state)
        AutoFarmAvoidToggle = state
        NotifyToggle("Avoid Murderer (Farm)", state)
    end
})

FarmSection:Dropdown({
    Title = "Farm Method",
    Values = {"Closest", "Randomized"},
    Default = "Closest",
    Callback = function(option)
        AutoFarmMethod = option
    end
})

-- =============================================
--          RESTO DE TU CÓDIGO ORIGINAL
-- =============================================

-- Variables de control
local ESPEnabled = false
_G.GunTPEnabled = false
_G.AimbotComboEnabled = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

