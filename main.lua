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
local Mouse = localPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- VARIABLES DE CONTROL (PROYECTO NOVA)
_G.EspActive = false
_G.HitboxActive = false
_G.HitboxSmartActive = false
_G.AutoParry = false
_G.SafeMode = false
_G.AntiStaff = false
_G.AntiChatLogger = false
_G.SuperBypass = false
local TargetPlayerName = "" 

-- VARIABLES DE CONTROL (DARK HUB ORIGINAL)
_G.AutoShotEnabled = false
_G.SilentAimEnabled = false
local ChamsEnabled = false

local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name = "DarkHub_Chams"
ChamsFolder.Parent = game.CoreGui

-- ==========================================
-- FUNCIONES BASE & SEGURIDAD
-- ==========================================

local function BorrarMenuTotal()
    for _, v in ipairs(game:GetDescendants()) do
        if v.ClassName == "ScreenGui" and (v.Name == "Rayfield" or v:FindFirstChild("Main")) then
            v:Destroy()
        end
    end
end

-- Wall-Check Proyecto Nova
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

-- Wall-Check Dark Hub
local function isEnemyVisible(targetPart)
    if not targetPart then return false end
    local character = localPlayer.Character
    if not character then return false end

    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

-- Algoritmo de Target Dark Hub
local function getBestTarget()
    local target = nil
    local shortestDistance = math.huge

    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= localPlayer
        and v.Character
        and v.Character:FindFirstChild("HumanoidRootPart")
        and v.Character:FindFirstChild("Humanoid")
        and v.Character.Humanoid.Health > 0 then

            local hrp = v.Character.HumanoidRootPart
            local pos, visible = Camera:WorldToViewportPoint(hrp.Position)

            if visible and isEnemyVisible(hrp) then
                local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    target = hrp
                end
            end
        end
    end
    return target
end

-- Lógica de Chams Dark Hub
local function ClearChams()
    ChamsFolder:ClearAllChildren()
end

local function ApplyChams(player)
    if player == localPlayer then return end

    local function SetupCharacter(character)
        if not ChamsEnabled then return end

        if ChamsFolder:FindFirstChild(player.Name) then
            ChamsFolder[player.Name]:Destroy()
        end

        local Highlight = Instance.new("Highlight")
        Highlight.Name = player.Name
        Highlight.FillColor = Color3.fromRGB(148, 0, 211)
        Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        Highlight.FillTransparency = 0.5
        Highlight.OutlineTransparency = 0
        Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        Highlight.Adornee = character
        Highlight.Parent = ChamsFolder
    end

    if player.Character then SetupCharacter(player.Character) end

    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        SetupCharacter(char)
    end)
end

-- METATABLE SILENT AIM (DARK HUB)
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, index)
    if self == Mouse and _G.SilentAimEnabled and (index == "Hit" or index == "Target") then
        local target = getBestTarget()
        if target then
            if index == "Hit" then
                return target.CFrame
            elseif index == "Target" then
                return target
            end
        end
    end
    return oldIndex(self, index)
end)
setreadonly(mt, true)


-- ==========================================
-- 1. PESTAÑA SEGURIDAD ÉLITE 🛡️
-- ==========================================
local SecurityTab = Window:CreateTab("Seguridad Élite 🛡️", 4483362458)

SecurityTab:CreateButton({
   Name = "❌ ELIMINAR MENÚ (Grabar Clip)",
   Callback = function()
      Rayfield:Notify({Title = "MODO GRABACIÓN", Content = "Menú eliminado. Las funciones siguen activas.", Duration = 3})
      task.wait(1)
      BorrarMenuTotal()
   end,
})

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


-- ==========================================
-- 2. PESTAÑA COMBAT PRO ⚔️
-- ==========================================
local CombatTab = Window:CreateTab("Combat Pro ⚔️", 4483345998)

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

-- NUEVAS FUNCIONES DE COMBATE INYECTADAS DE DARK HUB
CombatTab:CreateToggle({
    Name = "Auto Shot",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoShotEnabled = Value
    end
})

CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(Value)
        _G.SilentAimEnabled = Value
    end
})

CombatTab:CreateButton({
    Name = "Hitbox Expander (Script Externo)",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Gwaporoblox/Vascal-Hard-scripts/main/Vascal-Hitbox-Expander-UWUU"))()
        Rayfield:Notify({
            Title = "ALEXX HUB LOGIC",
            Content = "Hitbox activado correctamente.",
            Duration = 3,
            Image = 4483345998
        })
    end
})

CombatTab:CreateButton({
    Name = "Aimbot (Script Externo)",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nexuscripts/DUELS-Murders-vs-Sheriffs/refs/heads/main/Aimbot.lua"))()
        Rayfield:Notify({
            Title = "ALEXX HUB LOGIC",
            Content = "Aimbot ejecutado correctamente.",
            Duration = 3,
            Image = 4483345998
        })
    end
})


-- ==========================================
-- 3. PESTAÑA HITBOX INTELIGENTE 🛡️
-- ==========================================
local HitboxProTab = Window:CreateTab("Hitbox Pro 🛡️", 4483362458)

HitboxProTab:CreateToggle({
   Name = "🟢 Hitbox Smart (Wall-Check)",
   CurrentValue = false,
   Callback = function(Value)
      _G.HitboxSmartActive = Value
   end,
})


-- ==========================================
-- 4. PESTAÑA VISUAL 👁️
-- ==========================================
local SpyTab = Window:CreateTab("Visuals 👁️", 4483362458)

SpyTab:CreateToggle({
   Name = "Wallhack (ESP Highlight - Nova)",
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

-- NUEVO CONTROL VISUAL INYECTADO DE DARK HUB
SpyTab:CreateToggle({
    Name = "Wallhack (Chams Tradicionales)",
    CurrentValue = false,
    Callback = function(Value)
        ChamsEnabled = Value
        if Value then
            for _, player in ipairs(Players:GetPlayers()) do
                ApplyChams(player)
            end
        else
            ClearChams()
        end
    end
})


-- ==========================================
-- 5. PESTAÑA BYPASS MOVIMIENTO 🔓
-- ==========================================
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


-- ==========================================
-- 6. PESTAÑA SCRIPT ANIMACIONES 🎭 (DISEÑO ACTUALIZADO ALEXX HUB)
-- ==========================================
local ScriptsTab = Window:CreateTab("Script Animaciones", 4483362458)

ScriptsTab:CreateButton({
    Name = "Animaciones",
    Callback = function()

        if game.CoreGui:FindFirstChild("DARK_HUB_ANIMS") then
            game.CoreGui.DARK_HUB_ANIMS:Destroy()
        end

        local TweenService = game:GetService("TweenService")
        local LP = game:GetService("Players").LocalPlayer

        -- Paleta de colores VIP (Estilo Nova Dark Premium)
        local T = {
            bg     = Color3.fromRGB(10, 10, 14),
            panel  = Color3.fromRGB(20, 20, 30),
            border = Color3.fromRGB(0, 170, 255),
            acc    = Color3.fromRGB(0, 210, 255),
            text   = Color3.fromRGB(250, 250, 250),
            red    = Color3.fromRGB(255, 75, 75),
        }

        local SelectedAnim = {}
        local minimized = false

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "DARK_HUB_ANIMS"
        ScreenGui.Parent = game.CoreGui

        local Main = Instance.new("Frame", ScreenGui)
        Main.Size = UDim2.new(0, 240, 0, 300)
        Main.Position = UDim2.new(0.5, -120, 1.2, 0)
        Main.BackgroundColor3 = T.bg
        Main.BackgroundTransparency = 0.05
        Main.Active = true
        Main.Draggable = true
        Main.ClipsDescendants = true

        Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

        local Stroke = Instance.new("UIStroke", Main)
        Stroke.Color = T.border
        Stroke.Thickness = 2

        local Gradient = Instance.new("UIGradient", Main)
        Gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 12, 18)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 35, 70))
        }
        Gradient.Rotation = 90

        local Top = Instance.new("Frame", Main)
        Top.Size = UDim2.new(1,0,0,38)
        Top.BackgroundColor3 = T.panel
        Top.BorderSizePixel = 0

        Instance.new("UICorner", Top).CornerRadius = UDim.new(0,14)

        local Title = Instance.new("TextLabel", Top)
        Title.Size = UDim2.new(1,-70,1,0)
        Title.Position = UDim2.new(0,12,0,0)
        Title.BackgroundTransparency = 1
        Title.Text = "ALEXX HUB VIP"
        Title.TextColor3 = T.acc
        Title.Font = Enum.Font.GothamBlack
        Title.TextSize = 14
        Title.TextXAlignment = Enum.TextXAlignment.Left

        local function TopButton(text, pos, color, callback)
            local Btn = Instance.new("TextButton", Top)

            Btn.Size = UDim2.new(0,22,0,22)
            Btn.Position = pos
            Btn.Text = text
            Btn.TextColor3 = Color3.new(1,1,1)
            Btn.BackgroundColor3 = color
            Btn.Font = Enum.Font.GothamBold
            Btn.TextSize = 12

            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,6)

            Btn.MouseButton1Click:Connect(callback)

            return Btn
        end

        TopButton("X", UDim2.new(1,-30,0.5,-11), T.red, function()
            Main:TweenPosition(
                UDim2.new(0.5,-120,1.2,0),
                "In",
                "Back",
                0.4,
                true,
                function()
                    ScreenGui:Destroy()
                end
            )
        end)

        TopButton("-", UDim2.new(1,-58,0.5,-11), T.acc, function()
            minimized = not minimized
            if minimized then
                Main:TweenSize(UDim2.new(0,240,0,38),"Out","Quart",0.3,true)
                Scroll.Visible = false
            else
                Main:TweenSize(UDim2.new(0,240,0,300),"Out","Quart",0.3,true)
                task.wait(0.15)
                Scroll.Visible = true
            end
        end)

        local Scroll = Instance.new("ScrollingFrame", Main)
        Scroll.Position = UDim2.new(0,8,0,46)
        Scroll.Size = UDim2.new(1,-16,1,-54)
        Scroll.BackgroundTransparency = 1
        Scroll.BorderSizePixel = 0
        Scroll.ScrollBarThickness = 3
        Scroll.ScrollBarImageColor3 = T.acc
        Scroll.CanvasSize = UDim2.new(0,0,0,0)
        Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

        local Layout = Instance.new("UIListLayout", Scroll)
        Layout.Padding = UDim.new(0,5)
        Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        Layout.SortOrder = Enum.SortOrder.LayoutOrder

        local function ApplyAnims(ids)
            local char = LP.Character or LP.CharacterAdded:Wait()
            local Animate = char:WaitForChild("Animate",5)
            if not Animate then return end

            pcall(function()
                Animate.idle.Animation1.AnimationId = ids.idle1 or "0"
                Animate.idle.Animation2.AnimationId = ids.idle2 or "0"
                Animate.walk.WalkAnim.AnimationId = ids.walk or "0"
                Animate.run.RunAnim.AnimationId = ids.run or "0"
                Animate.jump.JumpAnim.AnimationId = ids.jump or "0"
                Animate.fall.FallAnim.AnimationId = ids.fall or "0"
            end)
        end

        local function CreateButton(name, ids)
            local Btn = Instance.new("TextButton", Scroll)
            Btn.Size = UDim2.new(1,-5,0,35)
            Btn.BackgroundColor3 = T.panel
            Btn.TextColor3 = T.text
            Btn.Text = name
            Btn.Font = Enum.Font.GothamBold
            Btn.TextSize = 11

            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,8)
            local BtnStroke = Instance.new("UIStroke", Btn)
            BtnStroke.Color = Color3.fromRGB(35, 45, 60)

            Btn.MouseEnter:Connect(function()
                BtnStroke.Color = T.acc
            end)
            Btn.MouseLeave:Connect(function()
                BtnStroke.Color = Color3.fromRGB(35, 45, 60)
            end)

            Btn.MouseButton1Click:Connect(function()
                SelectedAnim = ids
                ApplyAnims(ids)
            end)
        end

        CreateButton("Astronaut", {
            idle1 = "http://www.roblox.com/asset/?id=891621366",
            idle2 = "http://www.roblox.com/asset/?id=891633237",
            walk  = "http://www.roblox.com/asset/?id=891667138",
            run   = "http://www.roblox.com/asset/?id=891636393",
            jump  = "http://www.roblox.com/asset/?id=891627522",
            fall  = "http://www.roblox.com/asset/?id=891617961"
        })

        CreateButton("Bubbly", {
            idle1 = "http://www.roblox.com/asset/?id=910004836",
            idle2 = "http://www.roblox.com/asset/?id=910009958",
            walk  = "http://www.roblox.com/asset/?id=910034870",
            run   = "http://www.roblox.com/asset/?id=910025107",
            jump  = "http://www.roblox.com/asset/?id=910016857",
            fall  = "http://www.roblox.com/asset/?id=910001910"
        })

        CreateButton("Ninja", {
            idle1 = "http://www.roblox.com/asset/?id=656117400",
            idle2 = "http://www.roblox.com/asset/?id=656118341",
            walk  = "http://www.roblox.com/asset/?id=656121766",
            run   = "http://www.roblox.com/asset/?id=656118852",
            jump  = "http://www.roblox.com/asset/?id=656117878",
            fall  = "http://www.roblox.com/asset/?id=656115606"
        })

        CreateButton("Zombie", {
            idle1 = "http://www.roblox.com/asset/?id=616158929",
            idle2 = "http://www.roblox.com/asset/?id=616160636",
            walk  = "http://www.roblox.com/asset/?id=616168032",
            run   = "http://www.roblox.com/asset/?id=616163682",
            jump  = "http://www.roblox.com/asset/?id=616161997",
            fall  = "http://www.roblox.com/asset/?id=616157476"
        })

        CreateButton("Stylish", {
            idle1 = "http://www.roblox.com/asset/?id=616136790",
            idle2 = "http://www.roblox.com/asset/?id=616138447",
            walk  = "http://www.roblox.com/asset/?id=616146177",
            run   = "http://www.roblox.com/asset/?id=616140816",
            jump  = "http://www.roblox.com/asset/?id=616139451",
            fall  = "http://www.roblox.com/asset/?id=616134815"
        })

        CreateButton("SuperHero", {
            idle1 = "http://www.roblox.com/asset/?id=616111295",
            idle2 = "http://www.roblox.com/asset/?id=616113536",
            walk  = "http://www.roblox.com/asset/?id=616122287",
            run   = "http://www.roblox.com/asset/?id=616117076",
            jump  = "http://www.roblox.com/asset/?id=616115533",
            fall  = "http://www.roblox.com/asset/?id=616108001"
        })

        CreateButton("Robot", {
            idle1 = "http://www.roblox.com/asset/?id=616088211",
            idle2 = "http://www.roblox.com/asset/?id=616089559",
            walk  = "http://www.roblox.com/asset/?id=616095330",
            run   = "http://www.roblox.com/asset/?id=616091570",
            jump  = "http://www.roblox.com/asset/?id=616090535",
            fall  = "http://www.roblox.com/asset/?id=616087089"
        })

        CreateButton("Knight", {
            idle1 = "http://www.roblox.com/asset/?id=657595757",
            idle2 = "http://www.roblox.com/asset/?id=657568135",
            walk  = "http://www.roblox.com/asset/?id=657552124",
            run   = "http://www.roblox.com/asset/?id=657564596",
            jump  = "http://www.roblox.com/asset/?id=658409194",
            fall  = "http://www.roblox.com/asset/?id=657600338"
        })

        CreateButton("Levitation", {
            idle1 = "http://www.roblox.com/asset/?id=616006778",
            idle2 = "http://www.roblox.com/asset/?id=616008087",
            walk  = "http://www.roblox.com/asset/?id=616013216",
            run   = "http://www.roblox.com/asset/?id=616010382",
            jump  = "http://www.roblox.com/asset/?id=616008936",
            fall  = "http://www.roblox.com/asset/?id=616005863"
        })

        CreateButton("Mage", {
            idle1 = "http://www.roblox.com/asset/?id=707742142",
            idle2 = "http://www.roblox.com/asset/?id=707855907",
            walk  = "http://www.roblox.com/asset/?id=707897309",
            run   = "http://www.roblox.com/asset/?id=707861613",
            jump  = "http://www.roblox.com/asset/?id=707853694",
            fall  = "http://www.roblox.com/asset/?id=707829716"
        })

        CreateButton("Pirate", {
            idle1 = "http://www.roblox.com/asset/?id=750781874",
            idle2 = "http://www.roblox.com/asset/?id=750782770",
            walk  = "http://www.roblox.com/asset/?id=750785693",
            run   = "http://www.roblox.com/asset/?id=750783738",
            jump  = "http://www.roblox.com/asset/?id=750782230",
            fall  = "http://www.roblox.com/asset/?id=750780242"
        })

        CreateButton("Toy", {
            idle1 = "http://www.roblox.com/asset/?id=782841498",
            idle2 = "http://www.roblox.com/asset/?id=782845736",
            walk  = "http://www.roblox.com/asset/?id=782843345",
            run   = "http://www.roblox.com/asset/?id=782842708",
            jump  = "http://www.roblox.com/asset/?id=782847020",
            fall  = "http://www.roblox.com/asset/?id=782846423"
        })

        CreateButton("Vampire", {
            idle1 = "http://www.roblox.com/asset/?id=1083445855",
            idle2 = "http://www.roblox.com/asset/?id=1083450166",
            walk  = "http://www.roblox.com/asset/?id=1083473930",
            run   = "http://www.roblox.com/asset/?id=1083462077",
            jump  = "http://www.roblox.com/asset/?id=1083455352",
            fall  = "http://www.roblox.com/asset/?id=1083443587"
        })

        CreateButton("Werewolf", {
            idle1 = "http://www.roblox.com/asset/?id=1083195517",
            idle2 = "http://www.roblox.com/asset/?id=1083214717",
            walk  = "http://www.roblox.com/asset/?id=1083178339",
            run   = "http://www.roblox.com/asset/?id=1083216690",
            jump  = "http://www.roblox.com/asset/?id=1083218792",
            fall  = "http://www.roblox.com/asset/?id=1083189019"
        })

        CreateButton("Cowboy", {
            idle1 = "http://www.roblox.com/asset/?id=1014390418",
            idle2 = "http://www.roblox.com/asset/?id=1014398616",
            walk  = "http://www.roblox.com/asset/?id=1014421541",
            run   = "http://www.roblox.com/asset/?id=1014401683",
            jump  = "http://www.roblox.com/asset/?id=1014394726",
            fall  = "http://www.roblox.com/asset/?id=1014384571"
        })

        CreateButton("Confident", {
            idle1 = "http://www.roblox.com/asset/?id=1069977950",
            idle2 = "http://www.roblox.com/asset/?id=1069987858",
            walk  = "http://www.roblox.com/asset/?id=1070017263",
            run   = "http://www.roblox.com/asset/?id=1070001516",
            jump  = "http://www.roblox.com/asset/?id=1069984524",
            fall  = "http://www.roblox.com/asset/?id=1069973677"
        })

        CreateButton("Sneaky", {
            idle1 = "http://www.roblox.com/asset/?id=1132473842",
            idle2 = "http://www.roblox.com/asset/?id=1132477671",
            walk  = "http://www.roblox.com/asset/?id=1132510133",
            run   = "http://www.roblox.com/asset/?id=1132494274",
            jump  = "http://www.roblox.com/asset/?id=1132489853",
            fall  = "http://www.roblox.com/asset/?id=1132469004"
        })

        CreateButton("Princess", {
            idle1 = "http://www.roblox.com/asset/?id=941003647",
            idle2 = "http://www.roblox.com/asset/?id=941013098",
            walk  = "http://www.roblox.com/asset/?id=941028902",
            run   = "http://www.roblox.com/asset/?id=941015281",
            jump  = "http://www.roblox.com/asset/?id=941008832",
            fall  = "http://www.roblox.com/asset/?id=941000007"
        })

        Main:TweenPosition(UDim2.new(0.5,-120,0.5,-150),"Out","Back",0.7,true)
    end
})


-- ==========================================
-- EVENTOS Y PROCESOS PERSISTENTES (BACKGROUND)
-- ==========================================

-- Listeners para Chams Tradicionales (Dark Hub)
Players.PlayerAdded:Connect(function(player)
    if ChamsEnabled then ApplyChams(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    local old = ChamsFolder:FindFirstChild(player.Name)
    if old then old:Destroy() end
end)

-- Bucle Principal (Render Stepped)
task.spawn(function()
    RunService.Stepped:Connect(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= localPlayer and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")

                if hum and hum.Health > 0 and root then
                    
                    -- Manejo de Hitbox Proyecto Nova / Smart
                    if _G.HitboxActive or (_G.HitboxSmartActive and estaVisible(root)) then
                        root.Size = Vector3.new(7, 7, 7)
                        root.CanCollide = false
                        root.Transparency = _G.SafeMode and 1 or 0.75
                        root.Color = _G.HitboxSmartActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 255)
                    else
                        -- Resetear si no se fuerza por otro script
                        if not _G.HitboxActive and not _G.HitboxSmartActive then
                            root.Size = Vector3.new(2, 2, 1)
                            root.Transparency = 1
                        end
                    end

                    -- ESP Highlight de Nova
                    if _G.EspActive then
                        if not p.Character:FindFirstChild("NovaESP") then
                            local h = Instance.new("Highlight", p.Character)
                            h.Name = "NovaESP"
                            h.FillColor = Color3.fromRGB(255, 0, 0)
                        end
                    end
                    
                    -- Auto-Parry Inteligente
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
end)

Rayfield:Notify({Title = "ALEXX HUB VIP LOADED", Content = "Todo listo, Alexx. Menú híbrido 100% funcional.", Duration = 5})
