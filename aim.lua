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
    rayParams.FilterDescendantsInstances = player.Character and {player.Character} or {}
    for _, other in ipairs(Players:GetPlayers()) do
        if other == player or isTeammate(other) then continue end
        local character = other.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local part = character and character:FindFirstChild(config.TargetPart)
        if not humanoid or humanoid.Health <= 0 or not part or not part:IsA("BasePart") then continue end
        local screen, visible = camera:WorldToViewportPoint(part.Position)
        if not visible or screen.Z <= 0 then continue end
        local distance = (Vector2.new(screen.X, screen.Y) - cursor).Magnitude
        if distance >= bestDistance then continue end
        if config.CheckWalls then
            local origin = camera.CFrame.Position
            local hit = Workspace:Raycast(origin, part.Position - origin, rayParams)
            if hit and not hit.Instance:IsDescendantOf(character) then continue end
        end
        bestDistance, bestPart = distance, part
    end
    return bestPart
end

local function cleanup()
    if stopped then return end
    stopped = true
    RunService:UnbindFromRenderStep(binding)
    for _, connection in ipairs(connections) do connection:Disconnect() end
    _G[key] = nil
    print("[CameraAim] Removido.")
end
_G[key] = cleanup
table.insert(connections, UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.End then cleanup() end
end))
RunService:BindToRenderStep(binding, Enum.RenderPriority.Camera.Value + 1, function(dt)
    if stopped or UIS:GetFocusedTextBox() or not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local target = findTarget(camera)
    if not target then return end
    local position = camera.CFrame.Position
    if (target.Position - position).Magnitude < 0.001 then return end
    local desired = CFrame.lookAt(position, target.Position)
    camera.CFrame = camera.CFrame:Lerp(desired, 1 - math.exp(-config.Responsiveness * dt))
end)
print("[CameraAim] Carregado. Segure o botao direito para mirar; End para remover.")
