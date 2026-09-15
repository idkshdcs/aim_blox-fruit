local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function decode(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) >= 1 and '1' or '0') end
        return r
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local encodedData = "LS0gPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09C" ..
"-- DOEAK HUB V5 | ULTIMATE EMBED + UI SCALE\n" ..
"if not game:IsLoaded() then game.Loaded:Wait() end\n" ..
"local Players = game:GetService(\"Players\")\n" ..
"local RunService = game:GetService(\"RunService\")\n" ..
"local UserInputService = game:GetService(\"UserInputService\")\n" ..
"local Workspace = game:GetService(\"Workspace\")\n" ..
"local CoreGui = game:GetService(\"CoreGui\")\n" ..
"local TweenService = game:GetService(\"TweenService\")\n" ..
"local HttpService = game:GetService(\"HttpService\")\n" ..
"local TeleportService = game:GetService(\"TeleportService\")\n" ..
"local ReplicatedStorage = game:GetService(\"ReplicatedStorage\")\n" ..
"local Lighting = game:GetService(\"Lighting\")\n" ..
"local LocalPlayer = Players.LocalPlayer\n" ..
"local Camera = Workspace.CurrentCamera\n" ..
"if CoreGui:FindFirstChild(\"DoeakHubV5UI\") then CoreGui.DoeakHubV5UI:Destroy() end\n" ..
"local Settings = {AimEnabled = false, AimLock = false, FOV = 400, FPSBoost = false, RemoveClouds = false, AntiAFK = false, AutoHop20m = false, AutoTpLowHealth = false, HealthThreshold = 20, AttackAura = false, WeaponType = \"Melee\", AuraRange = 40, WaterWalk = false, UIScale = 1.0, FastSkill = false, FastSkillSpeed = 2.5}\n"

-- Thực thi mã nguồn
local decodedScript = decode(encodedData)
local exec, err = loadstring(decodedScript)
if exec then
    exec()
else
    warn("Lỗi giải mã:", err)
end