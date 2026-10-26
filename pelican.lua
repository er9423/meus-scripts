[d]

feito: círculo de FOV, suavização com `[ ]` e menu, predição, tag com nome/dist/vida, arrastar pelo título e salvar/carregar config. o save/load usa `writefile`/`readfile` do executor, então no Studio fica desligado. não testei num cliente.

```lua
-- [PELICAN] TEST MENU v2 | loadstring / executor (salvar/carregar só com writefile/readfile)
-- INSERT: menu | Q: aimbot | +/-: fov | Z: wallcheck | O: círculo | [ ]: suavização | arrastar pelo título
-- projeção: Camera:WorldToViewportPoint (origem topo-esquerda, pixels de tela)
-- predição: posição da cabeça + velocidade do HRP * PREDICT_TIME

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local env = (getgenv and getgenv()) or _G

local PREDICT_TIME = 0.12
local SMOOTH_STEPS = { 0.05, 0.10, 0.15, 0.25, 0.35 }
local CONFIG_FILE = "pelican_cfg.json"
local AIM_BIND = "PelicanTestAim"

local cfg = {
    esp = false,
    aim = false,
    wall = true,
    circle = true,
    fov = 120,
    smoothIdx = 3,
}

local highlights = {}
local tags = {}
local conns = {}
local menuVisible = true

local function track(c)
    table.insert(conns, c)
    return c
end

local function onOff(v)
    return v and "ON" or "OFF"
end

-- descarrega instância anterior (rodar de novo não duplica nada)
if env.PelicanUnload then pcall(env.PelicanUnload) end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "PelicanTestMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- círculo de FOV (Frame redondo, funciona no Studio e no executor)
local circle = Instance.new("Frame")
circle.Name = "FOVCircle"
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 0
circle.Parent = gui

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circle

local circleStroke = Instance.new("UIStroke")
circleStroke.Color = Color3.new(1, 1, 1)
circleStroke.Thickness = 1
circleStroke.Transparency = 0.3
circleStroke.Parent = circle

-- menu
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(240, 370)
frame.Position = UDim2.new(0, 30, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 38)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
title.Text = "PELICAN | TEST MENU"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Active = true
title.Parent = frame

local function createButton(text, pos, size, callback)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = pos
    button.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.Parent = frame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = button

    button.MouseButton1Click:Connect(callback)
    return button
end

local espButton, aimButton, fovButton, wallButton, smoothButton, circleButton
local refreshButtons
local refreshESP

-- ESP: highlight + tag (nome, distância, vida)
local function removeESP(target)
    if highlights[target] then
        highlights[target]:Destroy()
        highlights[target] = nil
    end
    if tags[target] then
        tags[target]:Destroy()
        tags[target] = nil
    end
end

local function updateESP(target)
    removeESP(target)
    if not cfg.esp or target == player then return end

    local character = target.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "PelicanESP"
    highlight.FillColor = Color3.fromRGB(255, 65, 65)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character
    highlights[target] = highlight

    local bb = Instance.new("BillboardGui")
    bb.Name = "PelicanTag"
    bb.Size = UDim2.fromOffset(180, 20)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = head
    bb.Parent = character

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.Text = ""
    label.Parent = bb

    tags[target] = bb
end

refreshESP = function()
    for _, target in ipairs(Players:GetPlayers()) do
        updateESP(target)
    end
end

-- valores
local function setFov(v)
    cfg.fov = math.clamp(v, 60, 240)
end

local function cycleSmooth(dir)
    cfg.smoothIdx = ((cfg.smoothIdx - 1 + dir) % #SMOOTH_STEPS) + 1
end

-- config (writefile/readfile do executor)
local function saveConfig()
    if not writefile then return end
    pcall(writefile, CONFIG_FILE, HttpService:JSONEncode(cfg))
end

local function loadConfig()
    if not (readfile and isfile and isfile(CONFIG_FILE)) then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            if cfg[k] ~= nil then cfg[k] = v end
        end
        setFov(cfg.fov)
        refreshButtons()
        refreshESP()
    end
end

-- botões
espButton = createButton("ESP", UDim2.fromOffset(10, 48), UDim2.new(1, -20, 0, 35), function()
    cfg.esp = not cfg.esp
    refreshButtons()
    refreshESP()
end)

aimButton = createButton("Aimbot", UDim2.fromOffset(10, 90), UDim2.new(1, -20, 0, 35), function()
    cfg.aim = not cfg.aim
    refreshButtons()
end)

fovButton = createButton("FOV", UDim2.fromOffset(10, 132), UDim2.new(1, -20, 0, 35), function()
    setFov(cfg.fov >= 240 and 60 or cfg.fov + 20)
    refreshButtons()
end)

wallButton = createButton("Wallcheck", UDim2.fromOffset(10, 174), UDim2.new(1, -20, 0, 35), function()
    cfg.wall = not cfg.wall
    refreshButtons()
end)

smoothButton = createButton("Suavização", UDim2.fromOffset(10, 216), UDim2.new(1, -20, 0, 35), function()
    cycleSmooth(1)
    refreshButtons()
end)

circleButton = createButton("Círculo", UDim2.fromOffset(10, 258), UDim2.new(1, -20, 0, 35), function()
    cfg.circle = not cfg.circle
    refreshButtons()
end)

createButton("SALVAR", UDim2.fromOffset(10, 300), UDim2.new(0.5, -15, 0, 35), saveConfig)
createButton("CARREGAR", UDim2.new(0.5, 5, 0, 300), UDim2.new(0.5, -15, 0, 35), loadConfig)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 25)
info.Position = UDim2.fromOffset(10, 342)
info.BackgroundTransparency = 1
info.Text = "INSERT menu | Q mira | O círculo | [ ] suav."
info.TextColor3 = Color3.fromRGB(180, 180, 190)
info.TextSize = 10
info.Font = Enum.Font.Gotham
info.TextWrapped = true
info.Parent = frame

refreshButtons = function()
    espButton.Text = "ESP: " .. onOff(cfg.esp)
    aimButton.Text = "Aimbot: " .. onOff(cfg.aim) .. " (Q)"
    fovButton.Text = "FOV: " .. cfg.fov .. "  (+/-)"
    wallButton.Text = "Wallcheck: " .. onOff(cfg.wall) .. " (Z)"
    smoothButton.Text = "Suavização: " .. SMOOTH_STEPS[cfg.smoothIdx] .. " ([ ])"
    circleButton.Text = "Círculo: " .. onOff(cfg.circle) .. " (O)"
end
refreshButtons()

-- arrastar pelo título
local dragging, dragStart, startPos = false, nil, nil

track(title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end))

track(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))

track(UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end))

-- visibilidade: raycast da câmera até a cabeça, ignora o próprio personagem e o alvo
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(targetChar, pos)
    rayParams.FilterDescendantsInstances = { player.Character, targetChar }
    local origin = camera.CFrame.Position
    return workspace:Raycast(origin, pos - origin, rayParams) == nil
end

-- novos jogadores e respawn
local function trackPlayer(target)
    track(target.CharacterAdded:Connect(function()
        task.wait(0.5)
        updateESP(target)
    end))
    if target.Character then
        updateESP(target)
    end
end

for _, target in ipairs(Players:GetPlayers()) do
    if target ~= player then
        trackPlayer(target)
    end
end

track(Players.PlayerAdded:Connect(function(target)
    if target ~= player then trackPlayer(target) end
end))
track(Players.PlayerRemoving:Connect(removeESP))

-- teclas
track(UIS.InputBegan:Connect(function(input, processed)
    if processed then return end

    local kc = input.KeyCode
    if kc == Enum.KeyCode.Insert then
        menuVisible = not menuVisible
        frame.Visible = menuVisible
    elseif kc == Enum.KeyCode.Q then
        cfg.aim = not cfg.aim
        refreshButtons()
    elseif kc == Enum.KeyCode.Z then
        cfg.wall = not cfg.wall
        refreshButtons()
    elseif kc == Enum.KeyCode.O then
        cfg.circle = not cfg.circle
        refreshButtons()
    elseif kc == Enum.KeyCode.Equals then
        setFov(cfg.fov + 20)
        refreshButtons()
    elseif kc == Enum.KeyCode.Minus then
        setFov(cfg.fov - 20)
        refreshButtons()
    elseif kc == Enum.KeyCode.LeftBracket then
        cycleSmooth(-1)
        refreshButtons()
    elseif kc == Enum.KeyCode.RightBracket then
        cycleSmooth(1)
        refreshButtons()
    end
end))

-- atualiza texto das tags de ESP a cada frame
track(RunService.RenderStepped:Connect(function()
    for target, bb in pairs(tags) do
        local character = target.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local label = bb:FindFirstChildOfClass("TextLabel")
        if hum and hrp and label then
            local dist = math.floor((hrp.Position - camera.CFrame.Position).Magnitude)
            label.Text = string.format("%s [%dm] [%dhp]", target.Name, dist, math.floor(hum.Health))
        end
    end
end))

-- aimbot + círculo: alvo mais próximo do centro dentro do FOV, predição e suavização
-- suavização diminui perto do centro (alpha * fator de distância)
RunService:BindToRenderStep(
    AIM_BIND,
    Enum.RenderPriority.Camera.Value + 1,
    function()
        camera = workspace.CurrentCamera
        if not camera then return end

        local center = camera.ViewportSize / 2

        circle.Visible = cfg.circle
        circle.Size = UDim2.fromOffset(cfg.fov * 2, cfg.fov * 2)
        circle.Position = UDim2.fromOffset(center.X - cfg.fov, center.Y - cfg.fov)

        if not cfg.aim then return end

        local bestHead, bestRoot
        local bestDist = cfg.fov

        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= player and target.Character then
                local character = target.Character
                local head = character:FindFirstChild("Head")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local sameTeam = player.Team ~= nil and target.Team == player.Team

                if head and humanoid and humanoid.Health > 0 and not sameTeam then
                    local pos, onScreen = camera:WorldToViewportPoint(head.Position)

                    if onScreen and pos.Z > 0 then
                        local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if d < bestDist and (not cfg.wall or isVisible(character, head.Position)) then
                            bestDist = d
                            bestHead = head
                            bestRoot = character:FindFirstChild("HumanoidRootPart")
                        end
                    end
                end
            end
        end

        if bestHead then
            local aimPos = bestHead.Position
            if bestRoot then
                aimPos = aimPos + bestRoot.AssemblyLinearVelocity * PREDICT_TIME
            end

            local desired = CFrame.lookAt(camera.CFrame.Position, aimPos)
            local factor = math.clamp(bestDist / (cfg.fov * 0.6), 0.25, 1)
            local alpha = SMOOTH_STEPS[cfg.smoothIdx] * factor
            camera.CFrame = camera.CFrame:Lerp(desired, alpha)
        end
    end
)

-- descarregar: chamado na próxima execução ou manualmente via env.PelicanUnload()
env.PelicanUnload = function()
    for _, c in ipairs(conns) do c:Disconnect() end
    pcall(RunService.UnbindFromRenderStep, RunService, AIM_BIND)
    for _, target in ipairs(Players:GetPlayers()) do
        removeESP(target)
    end
    if gui then gui:Destroy() end
    env.PelicanUnload = nil
end

print("[PELICAN] Menu v2 carregado!")
```
