--[[
  ============================================================
   LUNAR - menu de funcoes para Roblox (executor)
  ------------------------------------------------------------
   RightShift   -> abre / fecha o menu
   E (segurar)  -> aimbot
  ------------------------------------------------------------
   Aimbot: FOV, smooth, wall check, team check, hitbox.
   ESP: caixa, nome, vida, distancia, tracer.
   Player: WalkSpeed e JumpPower.
  ------------------------------------------------------------
   Use apenas onde voce tem autorizacao.
  ============================================================
]]

local ENV = (getgenv and getgenv()) or _G
if ENV.LUNAR and ENV.LUNAR.unload then
    pcall(ENV.LUNAR.unload)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer

local Config = {
    Aimbot = {
        Enabled = false,
        Key = Enum.KeyCode.E,
        Part = "Head",
        FOV = 140,
        Smooth = 0.30,
        TeamCheck = true,
        WallCheck = true,
        ShowFOV = true,
    },
    ESP = {
        Enabled = false,
        Box = true,
        Name = true,
        Health = true,
        Distance = true,
        Tracer = true,
        TeamCheck = true,
        MaxDistance = 1000,
    },
    Player = {
        WalkSpeed = 16,
        JumpPower = 50,
        Dirty = false,
    },
}

local Parts = { "Head", "HumanoidRootPart", "UpperTorso" }

local C = {
    bg = Color3.fromRGB(17, 17, 21),
    panel = Color3.fromRGB(24, 24, 30),
    row = Color3.fromRGB(31, 31, 39),
    stroke = Color3.fromRGB(45, 45, 56),
    text = Color3.fromRGB(235, 235, 242),
    dim = Color3.fromRGB(135, 135, 150),
    accent = Color3.fromRGB(130, 95, 255),
    off = Color3.fromRGB(48, 48, 60),
    enemy = Color3.fromRGB(255, 78, 78),
}

local Drawings = {}
local Connections = {}
local ESPData = {}

local hasDrawing = pcall(function()
    local probe = Drawing.new("Square")
    if probe.Remove then
        pcall(function()
            probe:Remove()
        end)
    end
end)

local function bind(signal, fn)
    local conn = signal:Connect(fn)
    Connections[#Connections + 1] = conn
    return conn
end

local function create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    inst.Parent = parent
    return inst
end

local function corner(inst, r)
    return create("UICorner", { CornerRadius = UDim.new(0, r or 6) }, inst)
end

local function getMousePos()
    return UserInputService:GetMouseLocation()
end

-- ============================================================
--  Interface
-- ============================================================

local gui = create("ScreenGui", {
    Name = "LunarMenu",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 9999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local host = CoreGui
pcall(function()
    if gethui then
        host = gethui()
    end
end)
local parentOk = pcall(function()
    gui.Parent = host
end)
if not parentOk or not gui.Parent then
    gui.Parent = LP:WaitForChild("PlayerGui")
end

local main = create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(560, 400),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
corner(main, 10)
create("UIStroke", {
    Color = C.stroke,
    Thickness = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, main)

local title = create("Frame", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundTransparency = 1,
}, main)

create("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.fromOffset(16, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "LUNAR",
    TextSize = 14,
    TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, title)

create("TextLabel", {
    Size = UDim2.fromOffset(220, 36),
    Position = UDim2.fromOffset(96, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "rshift: menu    e: aim",
    TextSize = 11,
    TextColor3 = C.dim,
    TextXAlignment = Enum.TextXAlignment.Left,
}, title)

local closeBtn = create("TextButton", {
    Size = UDim2.fromOffset(26, 26),
    Position = UDim2.new(1, -34, 0, 5),
    BackgroundColor3 = C.row,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    Text = "x",
    TextSize = 13,
    TextColor3 = C.dim,
}, title)
corner(closeBtn, 6)
bind(closeBtn.MouseButton1Click, function()
    main.Visible = false
end)

local windowDragging = false
local dragStart = nil
local dragStartPos = nil

bind(title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        windowDragging = true
        dragStart = input.Position
        dragStartPos = main.Position
        bind(input.Changed, function()
            if input.UserInputState == Enum.UserInputState.End then
                windowDragging = false
            end
        end)
    end
end)

bind(UserInputService.InputChanged, function(input)
    if not windowDragging then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            dragStartPos.X.Scale,
            dragStartPos.X.Offset + delta.X,
            dragStartPos.Y.Scale,
            dragStartPos.Y.Offset + delta.Y
        )
    end
end)

local sidebar = create("Frame", {
    Size = UDim2.new(0, 120, 1, -36),
    Position = UDim2.fromOffset(0, 36),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, main)

local content = create("Frame", {
    Size = UDim2.new(1, -120, 1, -36),
    Position = UDim2.fromOffset(120, 36),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, main)

local pages = {}
local tabButtons = {}

local function selectTab(name)
    for key, page in pairs(pages) do
        page.Visible = (key == name)
    end
    for key, btn in pairs(tabButtons) do
        if key == name then
            btn.BackgroundColor3 = C.row
            btn.TextColor3 = C.text
        else
            btn.BackgroundColor3 = C.panel
            btn.TextColor3 = C.dim
        end
    end
end

-- ============================================================
--  Componentes
-- ============================================================

local function addToggleRow(page, y, label, tbl, key)
    local row = create("Frame", {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.fromOffset(12, y),
        BackgroundColor3 = C.row,
        BorderSizePixel = 0,
    }, page)
    corner(row, 6)

    create("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = label,
        TextSize = 12,
        TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local sw = create("Frame", {
        Size = UDim2.fromOffset(36, 18),
        Position = UDim2.new(1, -46, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = C.off,
        BorderSizePixel = 0,
    }, row)
    corner(sw, 9)

    local knob = create("Frame", {
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, sw)
    corner(knob, 6)

    local function set(state)
        tbl[key] = state
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
        }):Play()
        TweenService:Create(sw, TweenInfo.new(0.15), {
            BackgroundColor3 = state and C.accent or C.off,
        }):Play()
    end

    local hit = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 3,
    }, row)
    bind(hit.MouseButton1Click, function()
        set(not tbl[key])
    end)

    set(tbl[key])
    return y + 34
end

local function addSliderRow(page, y, label, tbl, key, min, max, decimals, suffix, onChange)
    local row = create("Frame", {
        Size = UDim2.new(1, -24, 0, 46),
        Position = UDim2.fromOffset(12, y),
        BackgroundColor3 = C.row,
        BorderSizePixel = 0,
    }, page)
    corner(row, 6)

    create("TextLabel", {
        Size = UDim2.new(1, -90, 0, 18),
        Position = UDim2.fromOffset(10, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = label,
        TextSize = 12,
        TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local value = create("TextLabel", {
        Size = UDim2.fromOffset(80, 18),
        Position = UDim2.new(1, -90, 0, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "",
        TextSize = 12,
        TextColor3 = C.accent,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)

    local track = create("Frame", {
        Size = UDim2.new(1, -20, 0, 5),
        Position = UDim2.fromOffset(10, 30),
        BackgroundColor3 = C.off,
        BorderSizePixel = 0,
    }, row)
    corner(track, 3)

    local fill = create("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    }, track)
    corner(fill, 3)

    local function format(v)
        if decimals > 0 then
            return string.format("%." .. decimals .. "f", v) .. (suffix or "")
        end
        return tostring(math.floor(v + 0.5)) .. (suffix or "")
    end

    local function apply(trigger)
        local alpha = (tbl[key] - min) / (max - min)
        alpha = math.clamp(alpha, 0, 1)
        fill.Size = UDim2.fromScale(alpha, 1)
        value.Text = format(tbl[key])
        if trigger and onChange then
            onChange(tbl[key])
        end
    end

    local hit = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.fromOffset(0, 22),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 3,
    }, row)

    local sliding = false

    local function fromInput(input)
        local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        rel = math.clamp(rel, 0, 1)
        tbl[key] = min + (max - min) * rel
        apply(true)
    end

    bind(hit.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            fromInput(input)
            bind(input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    sliding = false
                end
            end)
        end
    end)

    bind(UserInputService.InputChanged, function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end)

    apply(false)
    return y + 52
end

local function addCycleRow(page, y, label, tbl, key, options)
    local row = create("Frame", {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.fromOffset(12, y),
        BackgroundColor3 = C.row,
        BorderSizePixel = 0,
    }, page)
    corner(row, 6)

    create("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = label,
        TextSize = 12,
        TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local value = create("TextLabel", {
        Size = UDim2.fromOffset(100, 18),
        Position = UDim2.new(1, -110, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = tostring(tbl[key]),
        TextSize = 12,
        TextColor3 = C.accent,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)

    local hit = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 3,
    }, row)
    bind(hit.MouseButton1Click, function()
        local index = 1
        for i = 1, #options do
            if options[i] == tbl[key] then
                index = i
                break
            end
        end
        index = index % #options + 1
        tbl[key] = options[index]
        value.Text = tostring(tbl[key])
    end)

    return y + 34
end

local function addButtonRow(page, y, label, fn)
    local row = create("Frame", {
        Size = UDim2.new(1, -24, 0, 32),
        Position = UDim2.fromOffset(12, y),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    }, page)
    corner(row, 6)

    local btn = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        Text = label,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255),
    }, row)
    corner(btn, 6)
    bind(btn.MouseButton1Click, fn)

    return y + 40
end

local function newPage(name, order)
    local page = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.stroke,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
    }, content)
    pages[name] = page

    local btn = create("TextButton", {
        Size = UDim2.new(1, -20, 0, 32),
        Position = UDim2.fromOffset(10, 10 + order * 38),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        Text = name,
        TextSize = 13,
        TextColor3 = C.dim,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, sidebar)
    corner(btn, 6)
    create("UIPadding", { PaddingLeft = UDim.new(0, 10) }, btn)
    tabButtons[name] = btn
    bind(btn.MouseButton1Click, function()
        selectTab(name)
    end)

    return page
end

-- ============================================================
--  Player helpers
-- ============================================================

local function getHumanoid()
    local char = LP.Character
    if not char then
        return nil
    end
    return char:FindFirstChildOfClass("Humanoid")
end

local function applyPlayer()
    local hum = getHumanoid()
    if hum then
        hum.UseJumpPower = true
        hum.WalkSpeed = Config.Player.WalkSpeed
        hum.JumpPower = Config.Player.JumpPower
    end
end

bind(LP.CharacterAdded, function()
    if Config.Player.Dirty then
        task.wait(0.5)
        applyPlayer()
    end
end)

-- ============================================================
--  Paginas
-- ============================================================

local unload = nil

local pageAimbot = newPage("Aimbot", 0)
local y = 8
y = addToggleRow(pageAimbot, y, "Aimbot (segure E)", Config.Aimbot, "Enabled")
y = addToggleRow(pageAimbot, y, "Team check", Config.Aimbot, "TeamCheck")
y = addToggleRow(pageAimbot, y, "Wall check", Config.Aimbot, "WallCheck")
y = addToggleRow(pageAimbot, y, "Mostrar FOV", Config.Aimbot, "ShowFOV")
y = addSliderRow(pageAimbot, y, "FOV", Config.Aimbot, "FOV", 30, 400, 0, " px")
y = addSliderRow(pageAimbot, y, "Smooth", Config.Aimbot, "Smooth", 0.05, 1, 2, "")
y = addCycleRow(pageAimbot, y, "Hitbox", Config.Aimbot, "Part", Parts)
pageAimbot.CanvasSize = UDim2.new(0, 0, 0, y + 8)

local pageESP = newPage("ESP", 1)
local e = 8
e = addToggleRow(pageESP, e, "ESP", Config.ESP, "Enabled")
e = addToggleRow(pageESP, e, "Caixa", Config.ESP, "Box")
e = addToggleRow(pageESP, e, "Nome", Config.ESP, "Name")
e = addToggleRow(pageESP, e, "Vida", Config.ESP, "Health")
e = addToggleRow(pageESP, e, "Distancia", Config.ESP, "Distance")
e = addToggleRow(pageESP, e, "Tracer", Config.ESP, "Tracer")
e = addToggleRow(pageESP, e, "Team check", Config.ESP, "TeamCheck")
e = addSliderRow(pageESP, e, "Distancia maxima", Config.ESP, "MaxDistance", 100, 3000, 0, "m")
pageESP.CanvasSize = UDim2.new(0, 0, 0, e + 8)

local pagePlayer = newPage("Player", 2)
local p = 8
p = addSliderRow(pagePlayer, p, "WalkSpeed", Config.Player, "WalkSpeed", 8, 200, 0, "", function()
    Config.Player.Dirty = true
    applyPlayer()
end)
p = addSliderRow(pagePlayer, p, "JumpPower", Config.Player, "JumpPower", 30, 250, 0, "", function()
    Config.Player.Dirty = true
    applyPlayer()
end)
p = addButtonRow(pagePlayer, p, "Unload script", function()
    if unload then
        unload()
    end
end)
pagePlayer.CanvasSize = UDim2.new(0, 0, 0, p + 8)

selectTab("Aimbot")

-- ============================================================
--  ESP
-- ============================================================

local function newDrawing(class, props)
    local ok, obj = pcall(function()
        return Drawing.new(class)
    end)
    if not ok or not obj then
        return nil
    end
    for k, v in pairs(props) do
        obj[k] = v
    end
    Drawings[#Drawings + 1] = obj
    return obj
end

local function getESP(plr)
    if ESPData[plr] then
        return ESPData[plr]
    end
    if not hasDrawing then
        return nil
    end

    local data = {
        box = newDrawing("Square", {
            Visible = false, Thickness = 1.5, Filled = false, Color = C.enemy,
        }),
        nameTag = newDrawing("Text", {
            Visible = false, Size = 13, Center = true, Outline = true,
            Color = Color3.fromRGB(255, 255, 255),
        }),
        distTag = newDrawing("Text", {
            Visible = false, Size = 12, Center = true, Outline = true,
            Color = Color3.fromRGB(210, 210, 220),
        }),
        hpBack = newDrawing("Square", {
            Visible = false, Filled = true, Color = Color3.fromRGB(0, 0, 0), Transparency = 0.65,
        }),
        hpFill = newDrawing("Square", {
            Visible = false, Filled = true, Color = Color3.fromRGB(90, 255, 120),
        }),
        tracer = newDrawing("Line", {
            Visible = false, Thickness = 1.2, Color = C.enemy, Transparency = 0.8,
        }),
    }

    ESPData[plr] = data
    return data
end

local function hideESP(data)
    for _, obj in pairs(data) do
        if obj then
            obj.Visible = false
        end
    end
end

local function updateESP()
    if not hasDrawing then
        return
    end

    if not Config.ESP.Enabled then
        for _, data in pairs(ESPData) do
            hideESP(data)
        end
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

    local myTeam = LP.Team

    for _, plr in ipairs(Players:GetPlayers()) do
        local data = getESP(plr)
        if data then
            local char = plr.Character
            local head = char and char:FindFirstChild("Head")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            local show = plr ~= LP and head ~= nil and root ~= nil and hum ~= nil and hum.Health > 0

            if show and Config.ESP.TeamCheck and myTeam ~= nil and plr.Team == myTeam then
                show = false
            end

            local dist = 0
            if show then
                dist = (head.Position - cam.CFrame.Position).Magnitude
                if dist > Config.ESP.MaxDistance then
                    show = false
                end
            end

            local top = nil
            local bottom = nil
            if show then
                local topV, onScreen = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
                local bottomV = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 2.7, 0))
                if onScreen then
                    top = topV
                    bottom = bottomV
                else
                    show = false
                end
            end

            if not show then
                hideESP(data)
            else
                local h = math.abs(bottom.Y - top.Y)
                if h < 6 then
                    hideESP(data)
                else
                    local w = h * 0.45
                    local x = top.X - w / 2
                    local boxY = top.Y

                    if data.box then
                        data.box.Visible = Config.ESP.Box
                        data.box.Position = Vector2.new(x, boxY)
                        data.box.Size = Vector2.new(w, h)
                    end

                    if data.nameTag then
                        data.nameTag.Visible = Config.ESP.Name
                        data.nameTag.Text = plr.Name
                        data.nameTag.Position = Vector2.new(top.X, boxY - 16)
                    end

                    if data.distTag then
                        data.distTag.Visible = Config.ESP.Distance
                        data.distTag.Text = tostring(math.floor(dist)) .. "m"
                        data.distTag.Position = Vector2.new(top.X, boxY + h + 3)
                    end

                    if data.hpBack and data.hpFill then
                        local ratio = 0
                        if hum.MaxHealth > 0 then
                            ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        end
                        data.hpBack.Visible = Config.ESP.Health
                        data.hpFill.Visible = Config.ESP.Health
                        data.hpBack.Position = Vector2.new(x - 6, boxY)
                        data.hpBack.Size = Vector2.new(3, h)
                        data.hpFill.Position = Vector2.new(x - 6, boxY + h * (1 - ratio))
                        data.hpFill.Size = Vector2.new(3, h * ratio)
                        data.hpFill.Color = Color3.fromRGB(
                            math.floor(90 + 165 * (1 - ratio)),
                            math.floor(90 + 165 * ratio),
                            90
                        )
                    end

                    if data.tracer then
                        data.tracer.Visible = Config.ESP.Tracer
                        data.tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                        data.tracer.To = Vector2.new(bottom.X, bottom.Y)
                    end
                end
            end
        end
    end
end

bind(Players.PlayerRemoving, function(plr)
    local data = ESPData[plr]
    if data then
        for _, obj in pairs(data) do
            if obj then
                pcall(function()
                    obj:Remove()
                end)
            end
        end
        ESPData[plr] = nil
    end
end)

-- ============================================================
--  Aimbot
-- ============================================================

local aiming = false

local fovCircle = nil
if hasDrawing then
    local ok, obj = pcall(function()
        local circle = Drawing.new("Circle")
        circle.Thickness = 1.5
        circle.NumSides = 64
        circle.Filled = false
        circle.Transparency = 0.75
        circle.Color = C.accent
        circle.Visible = false
        return circle
    end)
    if ok and obj then
        fovCircle = obj
        Drawings[#Drawings + 1] = obj
    end
end

local function isWallBlocked(part, plr)
    local cam = Workspace.CurrentCamera
    if not cam then
        return true
    end

    local filter = {}
    if LP.Character then
        filter[#filter + 1] = LP.Character
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = filter
    params.IgnoreWater = true

    local hit = Workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
    if not hit then
        return false
    end
    return not hit.Instance:IsDescendantOf(plr.Character)
end

local function findTarget()
    local cam = Workspace.CurrentCamera
    if not cam then
        return nil
    end

    local mouse = getMousePos()
    local myTeam = LP.Team
    local best = nil
    local bestScore = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local part = char and (char:FindFirstChild(Config.Aimbot.Part) or char:FindFirstChild("HumanoidRootPart"))
            local teamOk = not (Config.Aimbot.TeamCheck and myTeam ~= nil and plr.Team == myTeam)

            if char and hum and hum.Health > 0 and part and teamOk then
                local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local score = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                    if score <= Config.Aimbot.FOV and score < bestScore then
                        if not Config.Aimbot.WallCheck or not isWallBlocked(part, plr) then
                            best = part
                            bestScore = score
                        end
                    end
                end
            end
        end
    end

    return best
end

local function updateAimbot()
    if fovCircle then
        local showFov = Config.Aimbot.Enabled and Config.Aimbot.ShowFOV
        fovCircle.Visible = showFov
        if showFov then
            fovCircle.Position = getMousePos()
            fovCircle.Radius = Config.Aimbot.FOV
        end
    end

    if not (Config.Aimbot.Enabled and aiming) then
        return
    end

    local target = findTarget()
    if not target then
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

    local origin = cam.CFrame.Position
    if (target.Position - origin).Magnitude < 0.1 then
        return
    end

    local goal = CFrame.lookAt(origin, target.Position)
    cam.CFrame = cam.CFrame:Lerp(goal, math.clamp(Config.Aimbot.Smooth, 0.01, 1))
end

bind(RunService.RenderStepped, function()
    updateESP()
    updateAimbot()
end)

-- ============================================================
--  Input
-- ============================================================

bind(UserInputService.InputBegan, function(input, processed)
    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
    if input.KeyCode == Config.Aimbot.Key and not processed then
        aiming = true
    end
end)

bind(UserInputService.InputEnded, function(input)
    if input.KeyCode == Config.Aimbot.Key then
        aiming = false
    end
end)

-- ============================================================
--  Unload
-- ============================================================

unload = function()
    for i = #Drawings, 1, -1 do
        pcall(function()
            Drawings[i]:Remove()
        end)
    end
    for i = #Connections, 1, -1 do
        pcall(function()
            Connections[i]:Disconnect()
        end)
    end
    ESPData = {}
    if gui then
        gui:Destroy()
    end
    ENV.LUNAR = nil
end

ENV.LUNAR = {
    unload = unload,
    config = Config,
}
