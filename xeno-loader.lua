-- Paste this entire file directly into the executor.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
assert(player, "Cliente Roblox indisponivel.")
local parent = player:WaitForChild("PlayerGui", 10)
assert(parent, "PlayerGui indisponivel.")
local gui = Instance.new("ScreenGui")
gui.Name = "CameraAimLoaderDiagnostic"
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 500, 0, 150)
label.Position = UDim2.new(0, 16, 0, 210)
label.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
label.TextColor3 = Color3.new(1, 1, 1)
label.TextSize = 16
label.TextWrapped = true
label.Font = Enum.Font.Code
label.Parent = gui
gui.Parent = parent
local function status(text)
    label.Text = "CameraAim | Carregador de diagnostico\n" .. tostring(text)
    print("[CameraAim Loader] " .. tostring(text))
end
status("Lua executado. Preparando download...")
task.wait()
local url = "https://raw.githubusercontent.com/Lp12-Irc/roblox-camera-aim/2d195391cd45d20838c39d2dd5aab369f8e23c34/aim.lua"
local ok, source = pcall(function() return game:HttpGet(url) end)
if not ok or type(source) ~= "string" or #source == 0 then
    local firstError = tostring(source)
    local requester = request or http_request or (syn and syn.request)
    if type(requester) == "function" then
        ok, source = pcall(function()
            local response = requester({Url = url, Method = "GET"})
            assert(type(response) == "table", "Resposta HTTP invalida")
            local code = response.StatusCode
            assert(not code or (code >= 200 and code < 300), "HTTP " .. tostring(code))
            assert(type(response.Body) == "string" and #response.Body > 0, "Resposta HTTP vazia")
            return response.Body
        end)
    end
    if not ok or type(source) ~= "string" or #source == 0 then
        status("FALHA NO DOWNLOAD: " .. tostring(source) .. "\nHttpGet: " .. firstError)
        return
    end
end
status("Download recebido: " .. tostring(#source) .. " bytes. Compilando...")
if type(loadstring) ~= "function" then
    status("FALHA: loadstring nao esta disponivel neste ambiente.")
    return
end
local compiled, chunk, compileError = pcall(loadstring, source, "@CameraAim")
if not compiled or type(chunk) ~= "function" then
    status("FALHA NA COMPILACAO: " .. tostring(compileError or chunk))
    return
end
status("Compilado. Executando...")
local executed, runError = pcall(chunk)
if not executed then
    status("FALHA NA EXECUCAO: " .. tostring(runError))
    return
end
status("Script iniciado. Consulte o painel CameraAim v3. F6 alterna; End remove.")
task.delay(8, function() gui:Destroy() end)
