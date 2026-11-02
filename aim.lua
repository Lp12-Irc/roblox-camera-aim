-- Camera aim: hold right mouse button; End removes the script.
-- Requires standard Roblox player characters. Not validated in Urban Reload.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
assert(player, "Execute no cliente.")
local config = { Radius = 140, Responsiveness = 18, CheckTeams = true, CheckWalls = true, TargetPart = "Head" }
local key = "__CameraAimCleanup"
if type(_G[key]) == "function" then _G[key]() end
local connections = {}
local binding = "__CameraAim"
local stopped = false
local locked = false
local playerGui = player:WaitForChild("PlayerGui", 10)
assert(playerGui, "PlayerGui nao encontrado.")
local oldGui = playerGui:FindFirstChild("CameraAimStatus")
if oldGui then oldGui:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "CameraAimStatus"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
local panel = Instance.new("TextLabel")
panel.Size = UDim2.fromOffset(440, 120)
panel.Position = UDim2.fromOffset(16, 80)
panel.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
panel.BackgroundTransparency = 0.1
panel.TextColor3 = Color3.fromRGB(240, 240, 240)
panel.TextSize = 16
panel.Font = Enum.Font.Code
panel.TextWrapped = true
panel.Text = "CameraAim v2 carregado — iniciando..."
panel.Parent = gui
gui.Parent = playerGui
local function status(message)
    panel.Text = "CameraAim v2 | " .. message
        .. "\nSegure botao direito ou F6 para alternar. End remove."
end
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isTeammate(other)
    return config.CheckTeams and not player.Neutral and not other.Neutral
        and player.Team ~= nil and other.Team == player.Team
end

local function findTarget(camera)
    local inset = GuiService:GetGuiInset()
    local cursor = UIS:GetMouseLocation() - inset
    local bestPart, bestDistance = nil, config.Radius
    local stats = {others = 0, teams = 0, alive = 0, onScreen = 0, inRadius = 0, walls = 0}
    rayParams.FilterDescendantsInstances = player.Character and {player.Character} or {}
    for _, other in ipairs(Players:GetPlayers()) do
        if other == player then continue end
        stats.others += 1
        if isTeammate(other) then stats.teams += 1; continue end
        local character = other.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local part = character and character:FindFirstChild(config.TargetPart)
        if not humanoid or humanoid.Health <= 0 or not part or not part:IsA("BasePart") then continue end
        stats.alive += 1
        local screen, visible = camera:WorldToViewportPoint(part.Position)
        if not visible or screen.Z <= 0 then continue end
        stats.onScreen += 1
        local distance = (Vector2.new(screen.X, screen.Y) - cursor).Magnitude
        if distance < config.Radius then stats.inRadius += 1 end
        if distance >= bestDistance then continue end
        if config.CheckWalls then
            local origin = camera.CFrame.Position
            local hit = Workspace:Raycast(origin, part.Position - origin, rayParams)
            if hit and not hit.Instance:IsDescendantOf(character) then stats.walls += 1; continue end
        end
        bestDistance, bestPart = distance, part
    end
    return bestPart, stats
end

local function cleanup()
    if stopped then return end
    stopped = true
    RunService:UnbindFromRenderStep(binding)
    for _, connection in ipairs(connections) do connection:Disconnect() end
    gui:Destroy()
    _G[key] = nil
    print("[CameraAim] Removido.")
end
_G[key] = cleanup
table.insert(connections, UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.End then cleanup()
    elseif input.KeyCode == Enum.KeyCode.F6 then locked = not locked end
end))
local lastError = nil
local elapsed = 0
RunService:BindToRenderStep(binding, Enum.RenderPriority.Camera.Value + 1, function(dt)
    if stopped or lastError then return end
    local ok, err = pcall(function()
        local camera = Workspace.CurrentCamera
        if not camera then status("Aguardando camera"); return end
        local target, stats = findTarget(camera)
        local active = not UIS:GetFocusedTextBox()
            and (locked or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
        elapsed += dt
        if elapsed >= 0.2 then
            elapsed = 0
            local state = active and "ATIVO" or "EM ESPERA"
            local detail = target and ("Alvo: " .. target.Parent.Name) or "Nenhum alvo elegivel"
            status(state .. " | " .. detail
                .. string.format("\nOutros:%d Equipe:%d Vivos:%d Tela:%d Raio:%d Paredes:%d",
                    stats.others, stats.teams, stats.alive, stats.onScreen, stats.inRadius, stats.walls))
        end
        if not active or not target then return end
        local position = camera.CFrame.Position
        if (target.Position - position).Magnitude < 0.001 then return end
        local desired = CFrame.lookAt(position, target.Position)
        camera.CFrame = camera.CFrame:Lerp(desired, 1 - math.exp(-config.Responsiveness * dt))
    end)
    if not ok then
        lastError = tostring(err)
        status("ERRO: " .. lastError)
        warn("[CameraAim] " .. lastError)
    end
end)
print("[CameraAim v2] Carregado. Botao direito ou F6; End remove.")
