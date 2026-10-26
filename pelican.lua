local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Espera a PlayerGui existir de verdade (não trava)
local pgui = player:FindFirstChildOfClass("PlayerGui")
if not pgui then
    pgui = player:WaitForChild("PlayerGui", 10)
end
if not pgui then
    warn("[PELICAN] PlayerGui nunca carregou. Script abortado.")
    return
end

-- Limpa menu antigo (se existir)
local existing = pgui:FindFirstChild("PelicanTestMenu")
if existing then existing:Destroy() end

-- Variáveis de estado
local espEnabled = false
local aimEnabled = false
local menuVisible = true
local fov = 120
local highlights = {}

-- ==================== GUI ====================
local gui = Instance.new("ScreenGui")
gui.Name = "PelicanTestMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pgui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(240, 220)
frame.Position = UDim2.new(0, 30, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
frame.BorderSizePixel = 0
frame.Visible = menuVisible
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
title.Parent = frame

local function createButton(text, y, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 35)
    button.Position = UDim2.fromOffset(10, y)
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

local espButton, aimButton, fovButton

-- ==================== ESP ====================
local function removeESP(target)
    if highlights[target] then
        highlights[target]:Destroy()
        highlights[target] = nil
    end
end

local function updateESP(target)
    removeESP(target)
    if not espEnabled or target == player then return end

    local character = target.Character
    if not character then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "PelicanESP"
    highlight.FillColor = Color3.fromRGB(255, 65, 65)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character

    highlights[target] = highlight
end

local function refreshESP()
    for _, target in ipairs(Players:GetPlayers()) do
        updateESP(target)
    end
end

espButton = createButton("ESP: OFF", 48, function()
    espEnabled = not espEnabled
    espButton.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    refreshESP()
end)

aimButton = createButton("Aimbot: OFF (Q)", 90, function()
    aimEnabled = not aimEnabled
    aimButton.Text = "Aimbot: " .. (aimEnabled and "ON" or "OFF")
end)

fovButton = createButton("FOV: 120  (+/-)", 132, function()
    fov = fov + 20
    if fov > 240 then fov = 60 end
    fovButton.Text = "FOV: " .. fov .. " (+/-)"
end)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 25)
info.Position = UDim2.fromOffset(10, 176)
info.BackgroundTransparency = 1
info.Text = "INSERT: menu | Q: mira"
info.TextColor3 = Color3.fromRGB(180, 180, 190)
info.TextSize = 11
info.Font = Enum.Font.Gotham
info.Parent = frame

-- ==================== TRACK PLAYERS ====================
local function trackPlayer(target)
    target.CharacterAdded:Connect(function()
        task.wait(0.5)
        updateESP(target)
    end)
    if target.Character then
        updateESP(target)
    end
end

for _, target in ipairs(Players:GetPlayers()) do
    if target ~= player then
        trackPlayer(target)
    end
end

Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(removeESP)

-- ==================== INPUT ====================
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        menuVisible = not menuVisible
        frame.Visible = menuVisible
    elseif input.KeyCode == Enum.KeyCode.Q then
        aimEnabled = not aimEnabled
        aimButton.Text = "Aimbot: " .. (aimEnabled and "ON" or "OFF")
    elseif input.KeyCode == Enum.KeyCode.Equals then
        fov = math.min(fov + 20, 240)
        fovButton.Text = "FOV: " .. fov .. " (+/-)"
    elseif input.KeyCode == Enum.KeyCode.Minus then
        fov = math.max(fov - 20, 60)
        fovButton.Text = "FOV: " .. fov .. " (+/-)"
    end
end)

-- ==================== AIMBOT ====================
RunService:BindToRenderStep(
    "PelicanTestAim",
    Enum.RenderPriority.Camera.Value + 1,
    function()
        if not aimEnabled then return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local center = cam.ViewportSize / 2
        local bestTarget
        local bestDistance = fov

        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= player and target.Character then
                local character = target.Character
                local head = character:FindFirstChild("Head")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local sameTeam = player.Team ~= nil and target.Team == player.Team

                if head and humanoid and humanoid.Health > 0 and not sameTeam then
                    local pos, visible = cam:WorldToViewportPoint(head.Position)
                    if visible and pos.Z > 0 then
                        local distance = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if distance < bestDistance then
                            bestDistance = distance
                            bestTarget = head
                        end
                    end
                end
            end
        end

        if bestTarget then
            local desired = CFrame.lookAt(cam.CFrame.Position, bestTarget.Position)
            cam.CFrame = cam.CFrame:Lerp(desired, 0.15)
        end
    end
)

print("[PELICAN] Menu carregado! Pressione INSERT para mostrar/ocultar.")
