--[[
  [Alexamorzinho] Ultimate v6.2 [BULLETPROOF] - CORRIGIDO
  Fixes: FPS counter, Idled, JumpRequest, hum:Move deprec,
         noclip perf, fly CFrame, auto-clicker delay,
         loadConfig completo, smooth UI, cleanup, raycast pooling
]]

local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not WindUI then
    warn("[Alexamorzinho] Falha ao carregar a WindUI. Verifique sua conexao.")
    return
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local BASE_WALKSPEED = 16
local CONFIG_FILE = "alexamorzinho_config.json"

local SMOOTH_STEPS = { 0.05, 0.10, 0.15, 0.25, 0.35 }
local PREDICT_TIME = 0.12
local targetPlayerName = "None"
local uiVisible = true

-- ============================ ESTADO GLOBAL ============================
local cfg = {
    esp = false, aim = false, wall = true, circle = true,
    fov = 120, smoothIdx = 3, camFov = 70,
    triggerBot = false, wallshotType = "Head",
    predict = false, predictOffset = 50, instantAim = false,
    speed = false, speedValue = 16, autoJump = false, jumpPower = 50,
    bunnyHop = false, jumpMult = 1.2, strafeAim = false, strafeSpeed = 16,
    fly = false, flyValue = 50, flyMethod = "BodyVelocity",
    espColor = Color3.fromRGB(130, 100, 255),
    circleColor = Color3.fromRGB(130, 100, 255),
    chams = false, chamsColor = Color3.fromRGB(255, 50, 50),
    tracers = false, itemEsp = false, itemColor = Color3.fromRGB(255, 200, 0),
    headDot = true, weaponEsp = true,
    fullbright = false, noclip = false, infJump = false,
    aimPart = "Head", autoClicker = false, clickDelay = 0.1,
    hitbox = false, hitboxSize = 5, antiFling = false,
    teamEsp = false, teamColor = Color3.fromRGB(0, 200, 100),
    perfMode = false, perfFps = 60,
    clickTp = false, antiAfk = true,
}

local uiRefs = {}
local chamsObjs = {}
local itemEspObjs = {}
local espObjs = {}
local trackedItems = {}
local currentFps = 60
local antiFlingConn = nil
local noclipPartsCache = {}
local autoClickerTask = nil

local flyConn, flyBV, flyBG = nil, nil, nil
local lastHumanoid, speedWasApplied = nil, false

-- R15 e R6 corrigidos: cada par tem exatamente 2 elementos
local SKEL_R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local SKEL_R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

-- Pool de filtros de raycast (evita alocar tabela a cada frame)
local raycastFilterPool = {}
local raycastFilterIndex = 0
local function getRayFilter()
    raycastFilterIndex = raycastFilterIndex % #raycastFilterPool + 1
    local slot = raycastFilterPool[raycastFilterIndex]
    if not slot then
        slot = {}
        raycastFilterPool[raycastFilterIndex] = slot
    end
    for i = 1, #slot do slot[i] = nil end
    return slot
end

-- ============================ WINDUI CONFIG ============================
local Window = WindUI:CreateWindow({
    Title = "Alexamorzinho",
    Icon = "gamepad-2",
    Author = "Ultimate v6.2 [BULLETPROOF]",
    Folder = "AlexamorzinhoHub",
    Size = UDim2.fromOffset(640, 520),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    HideSearchBar = true,
    User = { Enabled = true, Anonymous = false },
})

local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local CombatTab = Window:Tab({ Title = "Combat", Icon = "target" })
local MovementTab = Window:Tab({ Title = "Movement", Icon = "run" })
local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })
local UtilTab = Window:Tab({ Title = "Utility", Icon = "tool" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ============================ MAIN TAB ============================
local CombatSec = MainTab:Section({ Title = "Combat" })
uiRefs.aim = CombatSec:Toggle({ Title = "Aimbot", Desc = "Mira automatica", Value = cfg.aim, Callback = function(s) cfg.aim = s end })
uiRefs.wall = CombatSec:Toggle({ Title = "Wallcheck", Desc = "Ignora alvos atras de paredes", Value = cfg.wall, Callback = function(s) cfg.wall = s end })
CombatSec:Dropdown({ Title = "Aim Target", Values = { "Head", "Torso", "HumanoidRootPart" }, Default = "Head", Callback = function(o) cfg.aimPart = o end })
uiRefs.triggerBot = CombatSec:Toggle({ Title = "Trigger Bot", Desc = "Atira automaticamente ao mirar no alvo", Value = cfg.triggerBot, Callback = function(s) cfg.triggerBot = s end })
CombatSec:Toggle({ Title = "Velocity Predict", Desc = "Prevê movimento do alvo", Value = cfg.predict, Callback = function(s) cfg.predict = s end })
CombatSec:Slider({ Title = "Predict Offset", Value = { Min = 0, Max = 200, Default = 50 }, Callback = function(v) cfg.predictOffset = v end })
CombatSec:Toggle({ Title = "Instant Aim", Desc = "Mira instantanea (sem suavizacao)", Value = cfg.instantAim, Callback = function(s) cfg.instantAim = s end })
-- Smooth dropdown (adicionado - faltava na versao original)
uiRefs.smooth = CombatSec:Dropdown({
    Title = "Smooth Level",
    Values = { "0.05 (Lento)", "0.10", "0.15", "0.25", "0.35 (Rápido)" },
    Default = "0.35 (Rápido)",
    Callback = function(o)
        for i, label in ipairs({ "0.05", "0.10", "0.15", "0.25", "0.35" }) do
            if string.find(o, label, 1, true) then
                cfg.smoothIdx = i
                break
            end
        end
    end
})

local MovementSec = MainTab:Section({ Title = "Movement" })
uiRefs.speed = MovementSec:Toggle({ Title = "SpeedHack", Desc = "Corre mais rapido", Value = cfg.speed, Callback = function(s) cfg.speed = s end })
MovementSec:Slider({ Title = "WalkSpeed", Value = { Min = 16, Max = 500, Default = 16 }, Callback = function(v) cfg.speedValue = v end })
MovementSec:Slider({ Title = "Jump Power", Value = { Min = 50, Max = 300, Default = 50 }, Callback = function(v) cfg.jumpPower = v end })
uiRefs.autoJump = MovementSec:Toggle({ Title = "Auto-Jump", Desc = "Bunny Hop automatico", Value = cfg.autoJump, Callback = function(s) cfg.autoJump = s end })
MovementSec:Toggle({ Title = "Bunny Hop Assist", Desc = "Assiste pulos proximos ao chao", Value = cfg.bunnyHop, Callback = function(s) cfg.bunnyHop = s end })
MovementSec:Slider({ Title = "Jump Multiplier", Value = { Min = 1.0, Max = 3.0, Default = 1.2 }, Callback = function(v) cfg.jumpMult = v end })
MovementSec:Toggle({ Title = "Strafe Aim", Desc = "Strafe quando aimbot ativo", Value = cfg.strafeAim, Callback = function(s) cfg.strafeAim = s end })
MovementSec:Slider({ Title = "Strafe Speed", Value = { Min = 10, Max = 50, Default = 16 }, Callback = function(v) cfg.strafeSpeed = v end })

-- ============================ COMBAT TAB ============================
local CombatCombatSec = CombatTab:Section({ Title = "Advanced Combat" })
uiRefs.autoClicker = CombatCombatSec:Toggle({ Title = "Auto Clicker", Desc = "Clica automaticamente", Value = cfg.autoClicker, Callback = function(s) cfg.autoClicker = s end })
CombatCombatSec:Slider({ Title = "Click Delay", Value = { Min = 0.01, Max = 1, Default = 0.1 }, Callback = function(v) cfg.clickDelay = v end })

-- ============================ MOVEMENT TAB ============================
local MovementMovementSec = MovementTab:Section({ Title = "Fly & Flight" })
uiRefs.fly = MovementMovementSec:Toggle({ Title = "Fly", Desc = "Voo (WASD)", Value = cfg.fly, Callback = function(s) cfg.fly = s end })
MovementMovementSec:Dropdown({ Title = "Fly Method", Values = { "BodyVelocity", "CFrame" }, Default = "BodyVelocity", Callback = function(o) cfg.flyMethod = o end })
MovementMovementSec:Slider({ Title = "Fly Speed", Value = { Min = 10, Max = 300, Default = 50 }, Callback = function(v) cfg.flyValue = v end })
uiRefs.noclip = MovementMovementSec:Toggle({ Title = "Noclip", Desc = "Atravessa paredes", Value = cfg.noclip, Callback = function(s)
    cfg.noclip = s
    if s and player.Character then setupNoclipCache(player.Character) end
end)
uiRefs.infJump = MovementMovementSec:Toggle({ Title = "Inf Jump", Desc = "Pula no ar", Value = cfg.infJump, Callback = function(s) cfg.infJump = s end })
MovementMovementSec:Toggle({ Title = "Anti-Fling", Desc = "Impede knockback", Value = cfg.antiFling, Callback = function(s)
    cfg.antiFling = s
    if s then
        antiFlingConn = RunService.Heartbeat:Connect(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Velocity.Magnitude > 100 then
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)
            end
        end)
    else
        if antiFlingConn then antiFlingConn:Disconnect(); antiFlingConn = nil end
    end
end)

-- ============================ VISUAL TAB ============================
local VisualVisualSec = VisualTab:Section({ Title = "Player ESP" })
uiRefs.esp = VisualVisualSec:Toggle({ Title = "ESP / Skeleton", Desc = "Caixas e ossos", Value = cfg.esp, Callback = function(s) cfg.esp = s end })
uiRefs.circle = VisualVisualSec:Toggle({ Title = "FOV Circle", Desc = "Circulo de mira", Value = cfg.circle, Callback = function(s) cfg.circle = s end })
uiRefs.headDot = VisualVisualSec:Toggle({ Title = "Head Dot", Desc = "Bolinha na cabeca", Value = cfg.headDot, Callback = function(s) cfg.headDot = s end })
uiRefs.weaponEsp = VisualVisualSec:Toggle({ Title = "Weapon ESP", Desc = "Mostra arma do inimigo", Value = cfg.weaponEsp, Callback = function(s) cfg.weaponEsp = s end })
VisualVisualSec:Toggle({ Title = "Team ESP", Desc = "Mostrar aliados com cor diferente", Value = cfg.teamEsp, Callback = function(s) cfg.teamEsp = s end })
VisualVisualSec:Colorpicker({ Title = "ESP Color", Default = cfg.espColor, Callback = function(c)
    cfg.espColor = c
    for _, o in pairs(espObjs) do
        o.box.Color = c; o.name.Color = c; o.headDot.Color = c; o.tracer.Color = c
        for _, l in ipairs(o.lines) do l.Color = c end
    end
end })
VisualVisualSec:Colorpicker({ Title = "Team ESP Color", Default = cfg.teamColor, Callback = function(c) cfg.teamColor = c end })

local WorldSec = VisualTab:Section({ Title = "World & Items" })
uiRefs.itemEsp = WorldSec:Toggle({ Title = "Item ESP", Desc = "Destaca itens no chao", Value = cfg.itemEsp, Callback = function(s) cfg.itemEsp = s end })
WorldSec:Colorpicker({ Title = "Item Color", Default = cfg.itemColor, Callback = function(c) cfg.itemColor = c end })
uiRefs.tracers = WorldSec:Toggle({ Title = "Tracers", Desc = "Linhas ate o alvo", Value = cfg.tracers, Callback = function(s) cfg.tracers = s end })
uiRefs.chams = WorldSec:Toggle({ Title = "Chams", Desc = "Destaque 3D", Value = cfg.chams, Callback = function(s) cfg.chams = s end })
WorldSec:Colorpicker({ Title = "Chams Color", Default = cfg.chamsColor, Callback = function(c) cfg.chamsColor = c end })
uiRefs.fullbright = WorldSec:Toggle({ Title = "Fullbright", Desc = "Remove sombras", Value = cfg.fullbright, Callback = function(s)
    cfg.fullbright = s
    if s then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1; Lighting.GlobalShadows = true
    end
end

local CameraSec = VisualTab:Section({ Title = "Camera" })
CameraSec:Slider({ Title = "Camera FOV", Value = { Min = 40, Max = 120, Default = 70 }, Callback = function(v) cfg.camFov = v end })
CameraSec:Slider({ Title = "ESP FOV Size", Value = { Min = 60, Max = 240, Default = 120 }, Callback = function(v) cfg.fov = v end })

-- ============================ UTILITY TAB ============================
local TPSec = UtilTab:Section({ Title = "Teleportation" })
uiRefs.clickTp = TPSec:Toggle({ Title = "Click TP", Desc = "Aperte T para ir ao mouse", Value = cfg.clickTp, Callback = function(s) cfg.clickTp = s end })
local tpDropdown = TPSec:Dropdown({
    Title = "Select Player",
    Values = {"None"},
    Default = "None",
    Callback = function(selectedName) targetPlayerName = selectedName end
})
TPSec:Button({ Title = "Refresh Player List", Callback = function()
    local playerNames = {"None"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(playerNames, p.Name) end
    end
    if tpDropdown.SetValues then tpDropdown:SetValues(playerNames)
    elseif tpDropdown.Refresh then tpDropdown:Refresh(playerNames) end
end })
TPSec:Button({ Title = "Teleport to Selected", Callback = function()
    if targetPlayerName and targetPlayerName ~= "None" then
        local target = Players:FindFirstChild(targetPlayerName)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local char = player.Character
            if char then char:PivotTo(target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)) end
        end
    end
end })

local MiscSec = UtilTab:Section({ Title = "Miscellaneous" })
uiRefs.antiAfk = MiscSec:Toggle({ Title = "Anti-AFK", Desc = "Evita kick por inatividade", Value = true, Callback = function(s) cfg.antiAfk = s end })
MiscSec:Button({ Title = "Rejoin Server", Callback = function() TeleportService:Teleport(game.PlaceId, player) end })

-- ============================ SETTINGS TAB ============================
local BindSec = SettingsTab:Section({ Title = "Keybinds" })
BindSec:Keybind({ Title = "Toggle UI", Value = "RightShift", Callback = function()
    uiVisible = not uiVisible
    if uiVisible then Window:Open() else Window:Close() end
end })
BindSec:Keybind({ Title = "Aimbot", Value = "Q", Callback = function()
    cfg.aim = not cfg.aim
    if uiRefs.aim then uiRefs.aim:Set(cfg.aim) end
end })
BindSec:Keybind({ Title = "ESP", Value = "H", Callback = function()
    cfg.esp = not cfg.esp
    if uiRefs.esp then uiRefs.esp:Set(cfg.esp) end
end })
BindSec:Keybind({ Title = "Noclip", Value = "N", Callback = function()
    cfg.noclip = not cfg.noclip
    if uiRefs.noclip then uiRefs.noclip:Set(cfg.noclip) end
end })
BindSec:Keybind({ Title = "Fly", Value = "F", Callback = function()
    cfg.fly = not cfg.fly
    if uiRefs.fly then uiRefs.fly:Set(cfg.fly) end
end })

local ConfigSec = SettingsTab:Section({ Title = "Configuration" })
ConfigSec:Button({ Title = "Save Config", Callback = function()
    if writefile then
        local ok, encoded = pcall(function() return HttpService:JSONEncode(cfg) end)
        if ok then
            writefile(CONFIG_FILE, encoded)
            WindUI:Notify({ Title = "Config", Content = "Salvo com sucesso!", Duration = 3 })
        end
    else
        WindUI:Notify({ Title = "Erro", Content = "Executor nao suporta writefile.", Duration = 3 })
    end
end })
ConfigSec:Button({ Title = "Load Config", Callback = function()
    if readfile and isfile and isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and data then
            for k, v in pairs(data) do
                if cfg[k] ~= nil then cfg[k] = v end
            end
            -- Atualiza todos os elementos da UI
            local updates = {
                aim = cfg.aim, esp = cfg.esp, noclip = cfg.noclip,
                fly = cfg.fly, wall = cfg.wall, headDot = cfg.headDot,
                chams = cfg.chams, triggerBot = cfg.triggerBot,
                autoClicker = cfg.autoClicker, clickTp = cfg.clickTp,
                antiAfk = cfg.antiAfk, autoJump = cfg.autoJump,
                speed = cfg.speed, circle = cfg.circle,
                tracers = cfg.tracers, weaponEsp = cfg.weaponEsp,
                infJump = cfg.infJump, fullbright = cfg.fullbright,
            }
            for key, val in pairs(updates) do
                if uiRefs[key] and uiRefs[key].Set then
                    pcall(function() uiRefs[key]:Set(val) end)
                end
            end
            WindUI:Notify({ Title = "Config", Content = "Carregado com sucesso!", Duration = 3 })
        end
    end
end })

-- ============================ LOGICA VISUAL ============================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.NumSides = 60
fovCircle.Radius = cfg.fov
fovCircle.Filled = false
fovCircle.Visible = false
fovCircle.Color = cfg.circleColor

local function newEspObj()
    local o = {
        box = Drawing.new("Square"), name = Drawing.new("Text"),
        hp = Drawing.new("Line"), tracer = Drawing.new("Line"),
        headDot = Drawing.new("Circle"), weapon = Drawing.new("Text"), lines = {},
    }
    o.box.Thickness = 1; o.box.Filled = false; o.box.Color = cfg.espColor; o.box.Visible = false
    o.name.Size = 13; o.name.Center = true; o.name.Outline = true; o.name.Color = cfg.espColor; o.name.Visible = false
    o.hp.Thickness = 2; o.hp.Visible = false
    o.tracer.Thickness = 1; o.tracer.Color = cfg.espColor; o.tracer.Visible = false
    o.headDot.Radius = 5; o.headDot.Filled = true; o.headDot.Color = cfg.espColor; o.headDot.Visible = false
    o.weapon.Size = 12; o.weapon.Center = true; o.weapon.Outline = true
    o.weapon.Color = Color3.fromRGB(255, 255, 255); o.weapon.Visible = false
    local maxLines = #SKEL_R15
    for i = 1, maxLines do
        local l = Drawing.new("Line")
        l.Thickness = 1; l.Color = cfg.espColor; l.Visible = false
        o.lines[i] = l
    end
    return o
end

local function hideEsp(o)
    o.box.Visible = false; o.name.Visible = false; o.hp.Visible = false
    o.tracer.Visible = false; o.headDot.Visible = false; o.weapon.Visible = false
    for _, l in ipairs(o.lines) do l.Visible = false end
end

local function destroyEsp(target)
    local o = espObjs[target]
    if not o then return end
    pcall(function()
        o.box:Remove(); o.name:Remove(); o.hp:Remove(); o.tracer:Remove()
        o.headDot:Remove(); o.weapon:Remove()
        for _, l in ipairs(o.lines) do l:Remove() end
    end)
    espObjs[target] = nil
    if chamsObjs[target] then chamsObjs[target]:Destroy() chamsObjs[target] = nil end
    if itemEspObjs[target] then itemEspObjs[target]:Remove() itemEspObjs[target] = nil end
end

local function isEnemy(t)
    -- nil == nil (ambos sem time) conta como mesmo lado
    return not (player.Team ~= nil and t.Team == player.Team)
end

local function getTargetColor(targetPlayer)
    if player.Team and targetPlayer.Team == player.Team then
        return cfg.teamEsp and cfg.teamColor or cfg.espColor
    end
    return cfg.espColor
end

local function toScreen(cam, pos)
    local p, on = cam:WorldToViewportPoint(pos)
    return Vector2.new(p.X, p.Y), on and p.Z > 0
end

local function addPlayer(t)
    if t == player or not Drawing then return end
    if not espObjs[t] then espObjs[t] = newEspObj() end
end

for _, t in ipairs(Players:GetPlayers()) do addPlayer(t) end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(plr)
    destroyEsp(plr)
    noclipPartsCache[player.Character] = nil
end)

-- OTIMIZACAO DO ITEM ESP (com cleanup correto)
local function trackItem(inst)
    if (inst:IsA("Tool") or inst:IsA("Model"))
        and inst:FindFirstChild("Handle")
        and not inst:FindFirstChildOfClass("Humanoid") then
        table.insert(trackedItems, inst)
    end
end
for _, v in ipairs(workspace:GetDescendants()) do trackItem(v) end
workspace.DescendantAdded:Connect(trackItem)
workspace.DescendantRemoving:Connect(function(inst)
    for i, v in ipairs(trackedItems) do
        if v == inst then
            table.remove(trackedItems, i)
            if itemEspObjs[inst] then itemEspObjs[inst]:Remove() itemEspObjs[inst] = nil end
            break
        end
    end
end)

-- ============================ NOCLIP (CACHE - OTIMIZADO) ============================
local function setupNoclipCache(char)
    if not char then return end
    local parts = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            table.insert(parts, part)
        end
    end
    noclipPartsCache[char] = parts
end

player.CharacterAdded:Connect(setupNoclipCache)
if player.Character then setupNoclipCache(player.Character) end

RunService.Stepped:Connect(function()
    if cfg.noclip then
        local char = player.Character
        local parts = noclipPartsCache[char]
        if parts then
            for _, part in ipairs(parts) do
                if part.CanCollide then part.CanCollide = false end
            end
        end
    end
end)

-- ============================ LOGICA DE MOVIMENTO ============================

-- Inf Jump corrigido (UserInputService.JumpRequest existe, mas eh mais seguro)
UIS.JumpRequest:Connect(function()
    if cfg.infJump then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        uiVisible = not uiVisible
        if uiVisible then Window:Open() else Window:Close() end
    end
    if input.KeyCode == Enum.KeyCode.T and cfg.clickTp then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local mouse = player:GetMouse()
            if mouse.Hit then char:PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))) end
        end
    end
end)

-- Anti-AFK corrigido (player.Idled NAO EXISTE - usa VirtualUser periodico)
task.spawn(function()
    while true do
        task.wait(25)
        if cfg.antiAfk then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end
end)

local function applyMovement()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if hum ~= lastHumanoid then
        speedWasApplied = false
        lastHumanoid = hum
    end
    if cfg.speed then
        hum.WalkSpeed = math.floor(cfg.speedValue + 0.5)
        speedWasApplied = true
    elseif speedWasApplied then
        hum.WalkSpeed = BASE_WALKSPEED
        speedWasApplied = false
    end

    hum.UseJumpPower = true
    hum.JumpPower = math.floor(cfg.jumpPower * cfg.jumpMult + 0.5)

    if cfg.autoJump and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function startFly()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if cfg.flyMethod == "BodyVelocity" then
        hum.PlatformStand = true
        local bv = Instance.new("BodyVelocity")
        bv.Name = "AlexamorzinhoFlyBV"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        local bg = Instance.new("BodyGyro")
        bg.Name = "AlexamorzinhoFlyBG"
        bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bg.P = 3000; bg.D = 100
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
        flyBV, flyBG = bv, bg
    end

    flyConn = RunService.RenderStepped:Connect(function(dt)
        if not cfg.fly or not (hrp and hrp.Parent) then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local look = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += look end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= look end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += right end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= right end
        if dir.Magnitude > 0 then dir = dir.Unit end

        if cfg.flyMethod == "BodyVelocity" and flyBV and flyBG then
            flyBV.Velocity = dir * cfg.flyValue
            flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + look)
        elseif cfg.flyMethod == "CFrame" then
            local speed = cfg.flyValue * dt
            local newPos = hrp.Position + dir * speed
            hrp.CFrame = CFrame.new(newPos, newPos + look)
        end
    end)
end

-- ============================ WATERMARK E FPS ============================
local wmGui = Instance.new("ScreenGui")
wmGui.Name = "AlexamorzinhoWM"
wmGui.ResetOnSpawn = false
wmGui.IgnoreGuiInset = true
local wmHost = CoreGui
pcall(function() if gethui then wmHost = gethui() end end)
wmGui.Parent = wmHost

local wmLabel = Instance.new("TextLabel")
wmLabel.Size = UDim2.fromOffset(280, 35)
wmLabel.Position = UDim2.new(0, 10, 0, 10)
wmLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
wmLabel.BackgroundTransparency = 0.4
wmLabel.TextColor3 = Color3.fromRGB(130, 100, 255)
wmLabel.TextSize = 14
wmLabel.Font = Enum.Font.GothamBold
wmLabel.TextXAlignment = Enum.TextXAlignment.Left
wmLabel.Parent = wmGui
local wmCorner = Instance.new("UICorner")
wmCorner.CornerRadius = UDim.new(0, 8)
wmCorner.Parent = wmLabel

-- FPS counter CORRIGIDO: usa delta time de Stepped em vez de task.wait
task.spawn(function()
    local frames = 0
    local timeAccum = 0
    RunService.Stepped:Connect(function(dt)
        frames += 1
        timeAccum += dt
        if timeAccum >= 1 then
            currentFps = frames / timeAccum
            frames = 0
            timeAccum = 0
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            local activeCount = 0
            if cfg.esp then activeCount += 1 end
            if cfg.aim then activeCount += 1 end
            if cfg.noclip then activeCount += 1 end
            if cfg.fly then activeCount += 1 end
            if cfg.instantAim then activeCount += 1 end
            if cfg.triggerBot then activeCount += 1 end
            wmLabel.Text = string.format("Alexamorzinho v6.2  |  FPS: %d  |  Ping: %dms  |  Active: %d",
                math.floor(currentFps), ping, activeCount)
        end
    end)
end)

-- ============================ AUTO CLICKER (CORRIGIDO) ============================
local function toggleAutoClicker()
    if cfg.autoClicker and not autoClickerTask then
        autoClickerTask = task.spawn(function()
            while autoClickerTask do
                task.wait(cfg.clickDelay) -- relê delay a cada iteracao
                if cfg.autoClicker then
                    local m = player:GetMouse()
                    if m.Target then
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new(m.X, m.Y), camera.CFrame)
                        end)
                    end
                end
            end
            autoClickerTask = nil
        end)
    elseif not cfg.autoClicker and autoClickerTask then
        autoClickerTask = nil
    end
end

-- Monitora mudanca do autoClicker via callback (fallback com tick)
local lastAutoClicker = cfg.autoClicker
task.spawn(function()
    while true do
        task.wait(0.1)
        if cfg.autoClicker ~= lastAutoClicker then
            lastAutoClicker = cfg.autoClicker
            toggleAutoClicker()
        end
    end
end)

-- ============================ RENDER & AIMBOT ============================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(targetChar, pos)
    if not camera then return false end
    local filter = getRayFilter()
    if player.Character then table.insert(filter, player.Character) end
    if targetChar then table.insert(filter, targetChar) end
    rayParams.FilterDescendantsInstances = filter
    rayParams.IgnoreWater = true
    local hit = workspace:Raycast(camera.CFrame.Position, pos - camera.CFrame.Position, rayParams)
    return hit == nil
end

RunService.RenderStepped:Connect(function()
    camera = workspace.CurrentCamera
    if not camera then return end

    if camera.FieldOfView ~= cfg.camFov then
        camera.FieldOfView = cfg.camFov
    end

    -- FOV circle
    if cfg.circle then
        fovCircle.Position = camera.ViewportSize / 2
        fovCircle.Radius = cfg.fov
        fovCircle.Color = cfg.circleColor
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end

    applyMovement()
    if cfg.fly and not flyConn then startFly()
    elseif not cfg.fly and flyConn then stopFly() end

    local myTracerPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)

    for target, o in pairs(espObjs) do
        local char = target.Character
        local head = char and char:FindFirstChild("Head")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        local isAlly = (player.Team ~= nil and target.Team == player.Team)
        local valid = head and hrp and hum and hum.Health > 0
        if isAlly and not cfg.teamEsp then valid = false end

        if valid then
            if cfg.hitbox and not isAlly then
                local hb = char:FindFirstChild("AlexamorzinhoHitbox")
                if not hb then
                    hb = Instance.new("Part")
                    hb.Name = "AlexamorzinhoHitbox"
                    hb.Transparency = 1; hb.CanCollide = false; hb.Massless = true
                    hb.Size = Vector3.new(cfg.hitboxSize, cfg.hitboxSize, cfg.hitboxSize)
                    hb.Anchored = true
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = head; weld.Part1 = hb; weld.Parent = hb
                    hb.Parent = char
                else
                    hb.Size = Vector3.new(cfg.hitboxSize, cfg.hitboxSize, cfg.hitboxSize)
                end
            else
                local hb = char:FindFirstChild("AlexamorzinhoHitbox")
                if hb then hb:Destroy() end
            end
        end

        -- Chams
        if cfg.chams and valid then
            if not chamsObjs[target] then
                local hl = Instance.new("Highlight")
                hl.Parent = char; hl.FillColor = cfg.chamsColor
                hl.OutlineColor = Color3.new(1, 1, 1); hl.FillTransparency = 0.5
                chamsObjs[target] = hl
            else chamsObjs[target].FillColor = cfg.chamsColor end
        elseif chamsObjs[target] then
            chamsObjs[target]:Destroy(); chamsObjs[target] = nil
        end

        if not (cfg.esp or cfg.tracers or cfg.headDot or cfg.weaponEsp) or not valid then
            hideEsp(o)
        else
            local top, onTop = toScreen(camera, head.Position + Vector3.new(0, 0.7, 0))
            local bot, onBot = toScreen(camera, hrp.Position - Vector3.new(0, 3, 0))
            local hPos, onHead = toScreen(camera, head.Position)

            if onTop and onBot and onHead then
                local h = math.abs(bot.Y - top.Y)
                local w = h / 2
                local left = top.X - w / 2
                local targetColor = getTargetColor(target)

                if cfg.esp then
                    o.box.Size = Vector2.new(w, h)
                    o.box.Position = Vector2.new(left, top.Y)
                    o.box.Color = targetColor; o.box.Visible = true

                    local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    local hx = left - 4
                    o.hp.From = Vector2.new(hx, bot.Y)
                    o.hp.To = Vector2.new(hx, bot.Y - h * frac)
                    o.hp.Color = Color3.fromRGB(
                        math.floor(255 * (1 - frac)),
                        math.floor(255 * frac), 0)
                    o.hp.Visible = true

                    o.name.Text = string.format("%s [%dm] [%dhp]",
                        target.Name,
                        math.floor((hrp.Position - camera.CFrame.Position).Magnitude),
                        math.floor(hum.Health))
                    o.name.Position = Vector2.new(top.X, top.Y - 14)
                    o.name.Color = targetColor; o.name.Visible = true

                    local bones = char:FindFirstChild("UpperTorso") and SKEL_R15 or SKEL_R6
                    for i, pair in ipairs(bones) do
                        local a = char:FindFirstChild(pair[1])
                        local b = char:FindFirstChild(pair[2])
                        local l = o.lines[i]
                        if a and b and l then
                            local pa, oa = toScreen(camera, a.Position)
                            local pb, ob = toScreen(camera, b.Position)
                            if oa and ob then
                                l.From = pa; l.To = pb; l.Color = targetColor; l.Visible = true
                            else
                                l.Visible = false
                            end
                        elseif l then l.Visible = false end
                    end
                else
                    o.box.Visible = false; o.name.Visible = false; o.hp.Visible = false
                    for _, l in ipairs(o.lines) do l.Visible = false end
                end

                if cfg.tracers then
                    o.tracer.From = myTracerPos
                    o.tracer.To = Vector2.new(top.X, top.Y)
                    o.tracer.Color = targetColor; o.tracer.Visible = true
                else o.tracer.Visible = false end

                if cfg.headDot then
                    o.headDot.Position = hPos
                    o.headDot.Color = targetColor; o.headDot.Visible = true
                else o.headDot.Visible = false end

                if cfg.weaponEsp then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        o.weapon.Text = "[" .. tool.Name .. "]"
                        o.weapon.Position = Vector2.new(top.X, top.Y + h + 5)
                        o.weapon.Color = targetColor; o.weapon.Visible = true
                    else o.weapon.Visible = false end
                else o.weapon.Visible = false end
            else hideEsp(o) end
        end
    end

    -- Item ESP
    if cfg.itemEsp then
        for _, item in ipairs(trackedItems) do
            if item.Parent then
                local handle = item:FindFirstChild("Handle")
                if handle then
                    local pos, onScreen = toScreen(camera, handle.Position)
                    if onScreen then
                        if not itemEspObjs[item] then
                            local txt = Drawing.new("Text")
                            txt.Size = 14; txt.Center = true; txt.Outline = true
                            txt.Color = cfg.itemColor
                            itemEspObjs[item] = txt
                        end
                        local txt = itemEspObjs[item]
                        txt.Text = string.format("%s [%dm]", item.Name,
                            math.floor((handle.Position - camera.CFrame.Position).Magnitude))
                        txt.Position = Vector2.new(pos.X, pos.Y)
                        txt.Visible = true; txt.Color = cfg.itemColor
                    elseif itemEspObjs[item] then
                        itemEspObjs[item].Visible = false
                    end
                end
            end
        end
    else
        for _, txt in pairs(itemEspObjs) do
            if txt then pcall(function() txt.Visible = false end) end
        end
    end

    -- AIMBOT
    if cfg.aim then
        local center = camera.ViewportSize / 2
        local bestPart, bestRoot = nil, nil
        local bestScore = math.huge

        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= player and target.Character then
                local char = target.Character
                local part = char:FindFirstChild("AlexamorzinhoHitbox")
                    or char:FindFirstChild(cfg.aimPart)
                    or char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 and isEnemy(target) then
                    local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z > 0 then
                        local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if d <= cfg.fov and (not cfg.wall or isVisible(char, part.Position)) then
                            -- Score: prioriza vida baixa (corrigido)
                            local score = d + (hum.Health / math.max(hum.MaxHealth, 1)) * 100
                            if score < bestScore then
                                bestScore = score
                                bestPart = part
                                bestRoot = char:FindFirstChild("HumanoidRootPart")
                            end
                        end
                    end
                end
            end
        end

        if bestPart then
            local aimPos = bestPart.Position
            if bestRoot then
                if cfg.predict then
                    aimPos += bestRoot.AssemblyLinearVelocity * (cfg.predictOffset / 1000)
                end
                aimPos += bestRoot.AssemblyLinearVelocity * PREDICT_TIME
            end
            local desired = CFrame.lookAt(camera.CFrame.Position, aimPos)
            if cfg.instantAim then
                camera.CFrame = desired
            else
                local smoothVal = SMOOTH_STEPS[math.clamp(cfg.smoothIdx, 1, #SMOOTH_STEPS)]
                local alpha = smoothVal * math.clamp(bestDist / (cfg.fov * 0.6), 0.25, 1)
                camera.CFrame = camera.CFrame:Lerp(desired, math.clamp(alpha, 0, 1))
            end
        end
    end
end)

-- TRIGGER BOT E STRAFE AIM (CORRIGIDO - usa SetMoveVector no lugar de Move deprecado)
RunService:BindToRenderStep("AlexamorzinhoAim", Enum.RenderPriority.Camera.Value + 1, function()
    camera = workspace.CurrentCamera
    if not camera then return end

    if cfg.triggerBot then
        local center = camera.ViewportSize / 2
        local clicked = false
        for _, target in ipairs(Players:GetPlayers()) do
            if clicked then break end
            if target ~= player and target.Character then
                local char = target.Character
                local part = char:FindFirstChild(cfg.aimPart) or char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 and isEnemy(target) then
                    local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z > 0 then
                        local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if d <= 30 and isVisible(char, part.Position) then
                            pcall(function()
                                VirtualUser:CaptureController()
                                VirtualUser:ClickButton1(center, camera.CFrame)
                            end)
                            clicked = true
                        end
                    end
                end
            end
        end
    end

    if cfg.strafeAim and cfg.aim then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local right = camera.CFrame.RightVector
            local strafeDir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.A) then strafeDir -= right end
            if UIS:IsKeyDown(Enum.KeyCode.D) then strafeDir += right end
            if strafeDir.Magnitude > 0 then
                hum:SetMoveVector(strafeDir.Unit) -- SetMoveVector no lugar de Move (deprecado)
                hum.WalkSpeed = cfg.strafeSpeed
            else
                hum:SetMoveVector(Vector3.zero)
                if not cfg.speed then hum.WalkSpeed = BASE_WALKSPEED end
            end
        end
    end
end)

-- BUNNY HOP (Heartbeat)
RunService.Heartbeat:Connect(function()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and cfg.bunnyHop then
        if hum.FloorMaterial ~= Enum.Material.Air
            and hum:GetState() ~= Enum.HumanoidStateType.Jumping
            and hum:GetState() ~= Enum.HumanoidStateType.Falling then
            hum.Jump = true
        end
    end
end)

-- ============================ CLEANUP / UNLOAD ============================
local function unload()
    stopFly()
    if autoClickerTask then autoClickerTask = nil end
    if antiFlingConn then antiFlingConn:Disconnect(); antiFlingConn = nil end
    pcall(function()
        for _, o in pairs(espObjs) do
            hideEsp(o)
        end
    end)
    for plr, data in pairs(espObjs) do destroyEsp(plr) end
    for _, txt in pairs(itemEspObjs) do if txt then pcall(function() txt:Remove() end) end end
    itemEspObjs = {}
    chamsObjs = {}
    trackedItems = {}
    espObjs = {}
    noclipPartsCache = {}
    raycastFilterPool = {}
    pcall(function() wmGui:Destroy() end)
    pcall(function()
        local allConns = RunService.RenderStepped:GetConnections()
        for _, c in ipairs(allConns) do
            if c and c.Connected and c.ConnectorName == "AlexamorzinhoAim" then
                c:Disconnect()
            end
        end
    end)
    Lighting.Brightness = 1; Lighting.GlobalShadows = true
    pcall(function() WindUI:Destroy() end)
end

-- ============================ CARREGAR CONFIG INICIAL ============================
if readfile and isfile and isfile(CONFIG_FILE) then
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok and data then
        for k, v in pairs(data) do
            if cfg[k] ~= nil then cfg[k] = v end
        end
    end
end
