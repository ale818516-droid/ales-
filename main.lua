local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "ALEXX HUB VIP 🛡️",
   LoadingTitle = "Nova Elite Systems",
   LoadingSubtitle = "Seguridad 2026",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false -- Desactivé la llave temporalmente para que pruebes si abre
})

local CombatTab = Window:CreateTab("Principal ⚔️", 4483362458)
CombatTab:CreateToggle({
   Name = "🎯 Hitbox Activa",
   CurrentValue = false,
   Callback = function(Value)
      _G.HitboxActive = Value
   end,
})

Rayfield:Notify({Title = "SISTEMA", Content = "Script Cargado con Éxito", Duration = 5})
