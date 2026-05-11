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
local Camera = workspace.CurrentCamera

-- VARIABLES DE CONTROL
_G.EspActive = false
_G.HitboxActive = false
_G.HitboxSmartActive = false -- Nueva Variable
_G.AutoParry = false
_G.SafeMode = false
_G.AntiStaff = false
_G.AntiChatLogger = false
_G.SuperBypass = false
local TargetPlayerName = "" 

-- FUNCIÓN WALL-CHECK (NUEVA)
local function estaVisible(targetPart)
    local character = localPlayer.Character
    if not character or not targetPart then return false end
    
    local rayDirection = (targetPart.Position - Camera.CFrame.Position).Unit * (targetPart.Position - Camera.CFrame.Position).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(Camera.CFrame.Position, rayDirection, raycastParams)
    if raycastResult then
        return raycastResult.Instance:IsDescendantOf(targetPart.Parent)
    end
    return false
end

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

-- NUEVA PESTAÑA: HITBOX INTELIGENTE 🛡️
local HitboxProTab = Window:CreateTab("Hitbox Pro 🛡️", 4483362458)

HitboxProTab:CreateToggle({
   Name = "🟢 Hitbox Smart (Wall-Check)",
   CurrentValue = false,
   Callback = function(Value)
      _G.HitboxSmartActive = Value
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

-- 4. PESTAÑA BYPASS MOVIMIENTO 🔓
local MoveTab = Window:CreateTab("Bypass Movimiento 🔓", 4483362458)

MoveTab:CreateInput({
   Name = "Nombre EXACTO del Oponente",
   PlaceholderText = "Escribe el nombre completo...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      TargetPlayerName = Text
   end,
})

MoveTab:CreateButton({
   Name = "🎯 Teleport al Oponente (Preciso)",
   Callback = function()
      if TargetPlayerName == "" then 
         Rayfield:Notify({Title = "ERROR", Content = "Escribe un nombre primero", Duration = 2})
         return 
      end
      
      pcall(function()
         local found = false
         for _, v in pairs(Players:GetPlayers()) do
            if v ~= localPlayer and (v.Name:lower() == TargetPlayerName:lower() or v.DisplayName:lower() == TargetPlayerName:lower()) then
               if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                  localPlayer.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                  found = true
                  Rayfield:Notify({Title = "NOVA", Content = "Teletransportado a " .. v.Name, Duration = 2})
                  break 
               end
            end
         end
         
         if not found then
            for _, v in pairs(Players:GetPlayers()) do
               if v ~= localPlayer and v.Name:lower():find(TargetPlayerName:lower()) then
                  if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                     localPlayer.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                     found = true
                     Rayfield:Notify({Title = "NOVA (Cercano)", Content = "Llegaste a " .. v.Name, Duration = 2})
                     break
                  end
               end
            end
         end

         if not found then
            Rayfield:Notify({Title = "AVISO", Content = "Jugador no encontrado", Duration = 2})
         end
      end)
   end,
})

MoveTab:CreateToggle({
   Name = "🔥 Romper Contador (Anti-Freeze)",
   CurrentValue = false,
   Callback = function(Value)
      _G.SuperBypass = Value
      task.spawn(function()
         while _G.SuperBypass do
            pcall(function()
               local char = localPlayer.Character
               if char then
                  for _, v in pairs(char:GetDescendants()) do
                     if v:IsA("BasePart") then v.Anchored = false end
                  end
                  local hum = char:FindFirstChild("Humanoid")
                  if hum and hum.WalkSpeed < 10 then hum.WalkSpeed = 16 end
               end
            end)
            task.wait(0.1)
         end
      end)
   end,
})

-- LÓGICA DE PROCESAMIENTO
RunService.Stepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")

            if hum and hum.Health > 0 and root then
                -- Lógica combinada de Hitbox (Tradicional y Smart)
                if _G.HitboxActive or (_G.HitboxSmartActive and estaVisible(root)) then
                    root.Size = Vector3.new(7, 7, 7)
                    root.CanCollide = false
                    if _G.SafeMode then
                        root.Transparency = 1 
                    else
                        root.Transparency = 0.75
                        -- Si es Smart la pone verde, si es Normal la pone azul
                        root.Color = _G.HitboxSmartActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 255)
                    end
                else
                    root.Size = Vector3.new(2, 2, 1)
                    root.Transparency = 1
                end

                if _G.EspActive then
                    if not p.Character:FindFirstChild("NovaESP") then
                        local h = Instance.new("Highlight", p.Character)
                        h.Name = "NovaESP"
                        h.FillColor = Color3.fromRGB(255, 0, 0)
                        h.OutlineTransparency = 0
                    end
                end
                
                if _G.AutoParry then
                    local d = (root.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if d < 15 then
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

Rayfield:Notify({Title = "NOVA LOADED", Content = "Hitbox Smart con Wall-Check Activa", Duration = 5})
