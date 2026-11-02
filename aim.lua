-- CameraAim v4: camera aim and player highlights.
-- Requires standard Player.Character models. Camera alignment does not control weapon spread.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
assert(player, "Execute no cliente")
local parent = player:WaitForChild("PlayerGui", 10)
assert(parent, "PlayerGui indisponivel")
local cleanupKey, binding = "__CameraAimCleanup", "__CameraAim"
if type(_G[cleanupKey]) == "function" then pcall(_G[cleanupKey]) end
local previous = parent:FindFirstChild("CameraAimStatus")
if previous then previous:Destroy() end
local config = {Strength = 70, Radius = 220, ShowFOV = true, ESP = false, Teams = true}
local connections, highlights = {}, {}
local stopped, target = false, nil
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end
local gui = Instance.new("ScreenGui")
gui.Name = "CameraAimStatus"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(350, 340)
frame.Position = UDim2.fromOffset(20, 100)
frame.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
frame.ZIndex = 5
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local function text(class, value, y, h)
    local o = Instance.new(class)
    o.Position = UDim2.fromOffset(14, y)
    o.Size = UDim2.new(1, -28, 0, h)
    o.BackgroundTransparency = 1
    o.Text = value
    o.Font = Enum.Font.Gotham
    o.TextSize = 14
    o.TextColor3 = Color3.fromRGB(235, 239, 248)
    o.ZIndex = 6
    o.Parent = frame
    return o
end
local title = text("TextLabel", "CAMERA AIM v4  |  CABECA", 10, 30)
local hint = text("TextLabel", "Segure botao direito para mirar | End: remover", 40, 22)
hint.TextSize = 12
local function button(caption, y, callback)
    local b = text("TextButton", caption, y, 30)
    b.BackgroundTransparency = 0
    b.BackgroundColor3 = Color3.fromRGB(44, 53, 72)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    connect(b.Activated, callback)
    return b
end
local fovButton, espButton, teamButton
fovButton = button("Circulo FOV: VISIVEL", 70, function()
    config.ShowFOV = not config.ShowFOV
    fovButton.Text = "Circulo FOV: " .. (config.ShowFOV and "VISIVEL" or "OCULTO")
end)
local circle = Instance.new("Frame")
circle.Name = "FOVCircle"
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 0
circle.ZIndex = 1
circle.Active = false
circle.Parent = gui
Instance.new("UICorner", circle).CornerRadius = UDim.new(0.5, 0)
local outline = Instance.new("UIStroke")
outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
outline.Color = Color3.fromRGB(120, 195, 255)
outline.Thickness = 1.5
outline.Transparency = 0.15
outline.Parent = circle
local draggingSlider
local function slider(label, y, min, max, value, apply)
    local caption = text("TextLabel", "", y, 22)
    caption.TextXAlignment = Enum.TextXAlignment.Left
    local bar = text("TextButton", "", y + 25, 16)
    bar.BackgroundTransparency = 0
    bar.BackgroundColor3 = Color3.fromRGB(48, 56, 72)
    bar.AutoButtonColor = false
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(90, 170, 255)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.ZIndex = 7
    fill.Parent = bar
    local function set(v)
        v = math.clamp(math.floor(v + 0.5), min, max)
        caption.Text = label .. ": " .. v .. (label == "Forca" and (v == 100 and " (instantanea)" or "%") or " px")
        fill.Size = UDim2.new((v-min)/(max-min), 0, 1, 0)
        apply(v)
    end
    local function pointer(x)
        local fraction = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        set(min + fraction * (max-min))
    end
    connect(bar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = {move = pointer, input = input}
            pointer(input.Position.X)
        end
    end)
    set(value)
end
slider("Forca", 106, 1, 100, config.Strength, function(v) config.Strength = v end)
slider("Raio", 159, 40, 600, config.Radius, function(v) config.Radius = v end)
espButton = button("Wall ESP: DESLIGADO", 215, function()
    config.ESP = not config.ESP
    espButton.Text = "Wall ESP: " .. (config.ESP and "LIGADO" or "DESLIGADO")
end)
teamButton = button("Ignorar mesma equipe: SIM", 250, function()
    config.Teams = not config.Teams
    teamButton.Text = "Ignorar mesma equipe: " .. (config.Teams and "SIM" or "NAO")
    target = nil
end)
local status = text("TextLabel", "Carregado. Mira somente ao segurar botao direito.", 287, 44)
status.TextWrapped = true
status.TextSize = 12
gui.Parent = parent

connect(UIS.InputChanged, function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input == draggingSlider.input) then
        draggingSlider.move(input.Position.X)
    end
end)
connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or (draggingSlider and input == draggingSlider.input) then draggingSlider = nil end
end)
local function teammate(other)
    return config.Teams and player.Team ~= nil and not player.Neutral and not other.Neutral and player.Team == other.Team
end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = true
local function cursorPosition(camera)
    if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return camera.ViewportSize / 2
    end
    local inset = GuiService:GetGuiInset()
    return UIS:GetMouseLocation() - inset
end
local function candidate(other, camera, cursor, radius)
    if other == player or teammate(other) then return end
    local character = other.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local head = character and character:FindFirstChild("Head")
    if not humanoid or humanoid.Health <= 0 or not head or not head:IsA("BasePart") then return end
    local point, visible = camera:WorldToViewportPoint(head.Position)
    if not visible or point.Z <= 0 then return end
    local distance = (Vector2.new(point.X, point.Y) - cursor).Magnitude
    if distance > radius then return end
    local origin = camera.CFrame.Position
    local hit = workspace:Raycast(origin, head.Position - origin, params)
    if hit and not hit.Instance:IsDescendantOf(character) then return end
    return head, distance
end
local function choose(camera)
    local cursor = cursorPosition(camera)
    -- Retain the selected head while valid to avoid switching between nearby players.
    if target then
        local head = candidate(target, camera, cursor, config.Radius)
        if head then return head end
    end
    target = nil
    local best, bestDistance = nil, config.Radius
    for _, other in ipairs(Players:GetPlayers()) do
        local head, distance = candidate(other, camera, cursor, config.Radius)
        if head and distance < bestDistance then
            best, bestDistance, target = head, distance, other
        end
    end
    return best
end
local function updateESP()
    local live = {}
    for _, other in ipairs(Players:GetPlayers()) do
        local character = other.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if config.ESP and other ~= player and not teammate(other) and humanoid and humanoid.Health > 0 then
            live[other] = true
            local h = highlights[other]
            if not h then
                h = Instance.new("Highlight")
                h.Name = "CameraAimHighlight"
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.FillColor = Color3.fromRGB(255, 90, 100)
                h.OutlineColor = Color3.fromRGB(255, 245, 200)
                h.FillTransparency = 0.65
                h.OutlineTransparency = 0
                h.Parent = workspace
                highlights[other] = h
            end
            h.Adornee = character
        end
    end
    for other, h in pairs(highlights) do
        if not live[other] then h:Destroy(); highlights[other] = nil end
    end
end
local function cleanup()
    if stopped then return end
    stopped = true
    RunService:UnbindFromRenderStep(binding)
    for _, c in ipairs(connections) do c:Disconnect() end
    for _, h in pairs(highlights) do h:Destroy() end
    gui:Destroy()
    _G[cleanupKey] = nil
end
_G[cleanupKey] = cleanup
connect(UIS.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.End then cleanup() end
end)
local focused = true
connect(UIS.WindowFocusReleased, function() focused = false; target = nil end)
connect(UIS.WindowFocused, function() focused = true end)
local elapsed = 0
RunService:BindToRenderStep(binding, Enum.RenderPriority.Camera.Value + 1, function(dt)
    if stopped then return end
    local ok, err = pcall(function()
        local camera = workspace.CurrentCamera
        if not camera then return end
        params.FilterDescendantsInstances = player.Character and {player.Character} or {}
        local center = cursorPosition(camera)
        circle.Position = UDim2.fromOffset(center.X, center.Y)
        circle.Size = UDim2.fromOffset(config.Radius * 2, config.Radius * 2)
        circle.Visible = config.ShowFOV
        local active = focused and not UIS:GetFocusedTextBox() and not draggingSlider
            and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        local head
        if active then head = choose(camera) else target = nil end
        if head then
            local position = camera.CFrame.Position
            if (head.Position - position).Magnitude > 0.001 then
                local desired = CFrame.lookAt(position, head.Position)
                -- A frame-rate-independent angular response; no distance attenuation.
                local response = 2 + 178 * (config.Strength / 100)^2
                local alpha = config.Strength == 100 and 1 or 1 - math.exp(-response * dt)
                camera.CFrame = camera.CFrame:Lerp(desired, alpha)
            end
        end
        elapsed += dt
        if elapsed >= 0.15 then
            elapsed = 0
            updateESP()
            status.Text = (active and "ATIVO" or "EM ESPERA") .. " | "
                .. (target and ("Cabeca: " .. target.Name) or "Sem alvo visivel no raio")
        end
    end)
    if not ok then status.Text = "ERRO: " .. tostring(err) end
end)
print("[CameraAim v4] Painel carregado.")
