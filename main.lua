--[[
    PROYECTO NOVA - ALEXX HUB VIP
    VERSION: ULTIMATE ELITE SECURITY (CLEAN EDITION)
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "ALEXX HUB VIP 🛡️",
   LoadingTitle = "Nova Elite Systems",
   LoadingSubtitle = "Seguridad de Grado Militar 2026",
   ConfigurationSaving = { Enabled = false },
   KeySystem = true,
   KeySettings = {
      Title = "🔑 ACCESO VIP",
      Subtitle = "Solo Usuarios Autorizados",
      Note = "Clave: ALEXX-VIP-2026",
      FileName = "NovaElite_Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"ALEXX-VIP-2026"}
   }
})

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- VARIABLES DE CONTROL
_G.EspActive = false
_G.HitboxActive = false
_G.AutoParry = false
_G.SafeMode = false
_G.AntiStaff = false
_G.AntiChatLogger = false

-- 1. PESTAÑA SEGURIDAD ÉLITE 🛡️
local SecurityTab = Window:CreateTab("Seguridad Élite 🛡️", 4483362458)

SecurityTab:CreateToggle({
   Name = "🛡️ Modo Fantasma (Anti-Staff)",
   CurrentValue = false,
   Callback = function(Value)
      _G.AntiStaff = Value
      if Value then
         task.spawn(function()
            while _G.AntiStaff do
               for _, p in pairs(Players:GetPlayers()) do
                  if p:GetRankInGroup(1) > 100 or p:IsInGroup(1200769) then 
                     _G.HitboxActive = false
                     _G.EspActive = false
                     _G.SafeMode = true
                     Rayfield:Notify({Title = "🛡️ STAFF DETECTADO", Content = "Script camuflado automáticamente.", Duration = 5})
                  end
               end
               task.wait(3)
            end
         end)
      end
   end,
})

SecurityTab:CreateToggle({
   Name = "🤐 Anti-Chat Logger (Bypass)",
   CurrentValue = false,
   Callback = function(Value)
      _G.AntiChatLogger = Value
   end,
})

SecurityTab:CreateToggle({
   Name = "🕶️ Safe Mode (Invisibilidad)",
   CurrentValue = false,
   Callback = function(Value)
      _G.SafeMode = Value
   end,
})

-- 2. PESTAÑA COMBAT PRO ⚔️
local CombatTab = Window:CreateTab("Combat Pro ⚔️", 4483362458)

CombatTab:CreateToggle({
   Name = "🎯 Hitbox 7x7x7 (Azul)",
   CurrentValue = false,
   Callback = function(Value)
      _G.HitboxActive = Value
   end,
})

CombatTab:CreateToggle({
   Name = "🛡️ Auto-Parry Inteligente",
   CurrentValue = false,
   Callback = function(Value)
      _G.AutoParry = Value
   end,
})

-- 3. PESTAÑA VISUAL 👁️
local SpyTab = Window:CreateTab("Visuals 👁️", 4483362458)
SpyTab:CreateToggle({
   Name = "Wallhack (ESP Highlight)",
   CurrentValue = false,
   Callback = function(Value)
      _G.EspActive = Value
      if not Value then
         for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("NovaESP") then
               p.Character.NovaESP:Destroy()
            end
         end
      end
   end,
})

-- LÓGICA DE PROCESAMIENTO
RunService.Stepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")

            if hum and hum.Health > 0 and root then
                -- LÓGICA HITBOX + SAFE MODE
                if _G.HitboxActive then
                    root.Size = Vector3.new(7, 7, 7)
                    root.CanCollide = false
                    if _G.SafeMode then
                        root.Transparency = 1 
                    else
                        root.Transparency = 0.75
                        root.Color = Color3.fromRGB(0, 0, 255)
                    end
                else
                    root.Size = Vector3.new(2, 2, 1)
                    root.Transparency = 1
                end

                -- ESP REFORZADO
                if _G.EspActive then
                    if not p.Character:FindFirstChild("NovaESP") then
                        local h = Instance.new("Highlight", p.Character)
                        h.Name = "NovaESP"
                        h.FillColor = Color3.fromRGB(255, 0, 0)
                        h.OutlineTransparency = 0
                    end
                end
                
                -- AUTO-PARRY
                if _G.AutoParry then
                    local dist = (root.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 15 then
                        local myTool = localPlayer.Character:FindFirstChildOfClass("Tool")
                        if myTool and myTool:FindFirstChild("Block") then
                            myTool.Block:FireServer()
                        end
                    end
                end
            end
        end
    end
end)

local Window = Rayfield:CreateWindow({
   Name = "ALEXX HUB VIP 🛡️",
   LoadingTitle = "Nova System 2026",
   LoadingSubtitle = "By ALE818516",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- PESTAÑA DE MOVIMIENTO
local MoveTab = Window:CreateTab("Movimiento 🔓", 4483362458)

_G.SuperBypass = false

MoveTab:CreateToggle({
   Name = "🔥 Forzar Movimiento (Anti-Contador)",
   CurrentValue = false,
   Callback = function(Value)
      _G.SuperBypass = Value
      task.spawn(function()
         while _G.SuperBypass do
            pcall(function()
               local char = game.Players.LocalPlayer.Character
               if char then
                  -- Desancla todo el cuerpo
                  for _, v in pairs(char:GetDescendants()) do
                     if v:IsA("BasePart") then v.Anchored = false end
                  end
                  -- Fuerza velocidad si el juego la pone en 0
                  local hum = char:FindFirstChild("Humanoid")
                  if hum and hum.WalkSpeed < 10 then
                     hum.WalkSpeed = 16
                  end
               end
            end)
            task.wait(0.1)
         end
      end)
   end,
})

MoveTab:CreateButton({
   Name = "📍 Teleport Adelante",
   Callback = function()
      local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
      if hrp then
         hrp.CFrame = hrp.CFrame + (hrp.CFrame.LookVector * 10)
      end
   end,
})

-- PESTAÑA DE COMBATE (NUEVA FUNCIÓN)
local CombatTab = Window:CreateTab("Combate 🎯", 4483362458)

_G.HitboxSize = 1
_G.HitboxEnabled = false

CombatTab:CreateSection("Asistencia Pro")

CombatTab:CreateToggle({
   Name = "🔴 Expandir Hitbox (Pegar Todo Rojo)",
   CurrentValue = false,
   Callback = function(Value)
      _G.HitboxEnabled = Value
      task.spawn(function()
         while _G.HitboxEnabled do
            for _, player in pairs(game:GetService("Players"):GetPlayers()) do
               if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                  pcall(function()
                     player.Character.Head.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                     player.Character.Head.Transparency = 0.6
                     player.Character.Head.CanCollide = false
                  end)
               end
            end
            task.wait(1)
         end
      end)
   end,
})

CombatTab:CreateSlider({
   Name = "Tamaño de Cabeza",
   Range = {1, 20},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = 1,
   Callback = function(Value)
      _G.HitboxSize = Value
   end,
})

Rayfield:Notify({Title = "CARGADO", Content = "Proyecto Nova Listo", Duration = 5})

