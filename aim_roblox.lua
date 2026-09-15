-- ==========================================
-- DOEAK HUB V5 | ULTIMATE EMBED + UI SCALE
-- ==========================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if CoreGui:FindFirstChild("DoeakHubV5UI") then
    CoreGui.DoeakHubV5UI:Destroy()
end

-- ===== CẤU HÌNH HỆ THỐNG =====
local Settings = {
    AimEnabled = false,
    AimLock = false,
    FOV = 400,
    FPSBoost = false,
    RemoveClouds = false,
    AntiAFK = false,
    AutoHop20m = false,
    AutoTpLowHealth = false,
    HealthThreshold = 20,
    AttackAura = false,
    WeaponType = "Melee",
    AuraRange = 40,
    WaterWalk = false,
    UIScale = 1.0,
    FastSkill = false,
    FastSkillSpeed = 2.5
}

local HotAndColdCFrame = CFrame.new(-5870, 20, -5060)

local ModulesNet = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
local RegisterAttack = ModulesNet and ModulesNet:FindFirstChild("RE/RegisterAttack")
local RegisterHit = ModulesNet and ModulesNet:FindFirstChild("RE/RegisterHit")

-- ===== LOGIC BOOT TUNG CHIÊU NHANH (FAST SKILL) =====
local function applyFastSkill(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 3)
    if not hum then return end
    local animator = hum:WaitForChild("Animator", 3)
    if animator then
        animator.AnimationPlayed:Connect(function(track)
            if Settings.FastSkill then
                track:AdjustSpeed(Settings.FastSkillSpeed)
            end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(applyFastSkill)
if LocalPlayer.Character then applyFastSkill(LocalPlayer.Character) end

-- ===== FOV CIRCLE & TRACER =====
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = Settings.FOV
FOVCircle.Color = Color3.fromRGB(0, 229, 255)
FOVCircle.Thickness = 1.8
FOVCircle.Transparency = 0.8
FOVCircle.Filled = false

local TargetTracer = Drawing.new("Line")
TargetTracer.Visible = false
TargetTracer.Color = Color3.fromRGB(0, 229, 255)
TargetTracer.Thickness = 2
TargetTracer.Transparency = 0.9

local MobileGui = Instance.new("ScreenGui")
MobileGui.Name = "DoeakMobileGui"
MobileGui.ResetOnSpawn = false
MobileGui.Parent = CoreGui

local FOVKnob = Instance.new("ImageButton")
FOVKnob.Name = "FOVKnob"
FOVKnob.Size = UDim2.new(0, 28, 0, 28)
FOVKnob.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
FOVKnob.Visible = false
FOVKnob.Active = true
FOVKnob.Draggable = true
FOVKnob.Parent = MobileGui

local KnobCorner = Instance.new("UICorner")
KnobCorner.CornerRadius = UDim.new(1, 0)
KnobCorner.Parent = FOVKnob

local isKnobDragging = false

FOVKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isKnobDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isKnobDragging = false
    end
end)

FOVKnob.Changed:Connect(function(prop)
    if prop == "Position" and Settings.AimEnabled and isKnobDragging then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local knobPos = Vector2.new(FOVKnob.AbsolutePosition.X + 14, FOVKnob.AbsolutePosition.Y + 14)
        local dist = (knobPos - center).Magnitude
        Settings.FOV = math.clamp(math.floor(dist), 150, 1300)
    end
end)

-- ===== KIỂM TRA MỤC TIÊU =====
local function canAttack(player)
    if not player or player == LocalPlayer or not player.Character then return false end
    local char = player.Character
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or hum.Health <= 0 or not hrp then return false end
    if char:FindFirstChild("SafeZone") or char:FindFirstChild("NonPvP") then return false end
    if player:FindFirstChild("InSafeZone") and player.InSafeZone.Value == true then return false end
    
    local pvpData = player:FindFirstChild("Data") and player.Data:FindFirstChild("PvP") or player:FindFirstChild("PvP")
    if pvpData and pvpData.Value == false then return false end
    
    return true
end

local function getValidTarget()
    local closest = nil
    local shortestDist = Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in pairs(Players:GetPlayers()) do
        if canAttack(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- ===== RENDER LOOP =====
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = center
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Visible = Settings.AimEnabled
    FOVKnob.Visible = Settings.AimEnabled

    if Settings.AimEnabled and not isKnobDragging then
        FOVKnob.Position = UDim2.new(0, center.X + Settings.FOV - 14, 0, center.Y - 14)
    end

    if Settings.AimEnabled then
        local target = getValidTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            if Settings.AimLock then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
            
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                local myScreen = Camera:WorldToViewportPoint(myHRP.Position)
                local targetScreen = Camera:WorldToViewportPoint(head.Position)
                if myScreen.Z > 0 and targetScreen.Z > 0 then
                    TargetTracer.From = Vector2.new(myScreen.X, myScreen.Y)
                    TargetTracer.To = Vector2.new(targetScreen.X, targetScreen.Y)
                    TargetTracer.Visible = true
                else
                    TargetTracer.Visible = false
                end
            end
        else
            TargetTracer.Visible = false
        end
    else
        TargetTracer.Visible = false
    end
end)

-- ==========================================
-- GIAO DIỆN UI EMBED CAO CẤP + BO GÓC
-- ==========================================
local DoeakUI = Instance.new("ScreenGui")
DoeakUI.Name = "DoeakHubV5UI"
DoeakUI.ResetOnSpawn = false
DoeakUI.Parent = CoreGui

-- Nút Thu Nhỏ Tròn
local DragonBtn = Instance.new("ImageButton")
DragonBtn.Name = "DragonToggleBtn"
DragonBtn.Size = UDim2.new(0, 48, 0, 48)
DragonBtn.Position = UDim2.new(0, 25, 0.45, 0)
DragonBtn.BackgroundColor3 = Color3.fromRGB(13, 15, 22)
DragonBtn.Visible = false
DragonBtn.Active = true
DragonBtn.Draggable = true
DragonBtn.Parent = DoeakUI

local DragonText = Instance.new("TextLabel")
DragonText.Size = UDim2.new(1, 0, 1, 0)
DragonText.BackgroundTransparency = 1
DragonText.Text = "⚡"
DragonText.TextSize = 22
DragonText.Parent = DragonBtn

local DragonCorner = Instance.new("UICorner")
DragonCorner.CornerRadius = UDim.new(1, 0)
DragonCorner.Parent = DragonBtn

local DragonStroke = Instance.new("UIStroke")
DragonStroke.Color = Color3.fromRGB(0, 229, 255)
DragonStroke.Thickness = 2
DragonStroke.Parent = DragonBtn

-- Khung Main Embed
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 370)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -185)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = DoeakUI

-- TÍNH NĂNG UI SCALE
local MainScale = Instance.new("UIScale")
MainScale.Scale = Settings.UIScale
MainScale.Parent = MainFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(30, 34, 45)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Thanh Accent Dọc Embed
local EmbedAccent = Instance.new("Frame")
EmbedAccent.Size = UDim2.new(0, 4, 1, -20)
EmbedAccent.Position = UDim2.new(0, 10, 0, 10)
EmbedAccent.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
EmbedAccent.BorderSizePixel = 0
EmbedAccent.Parent = MainFrame

local AccentCorner = Instance.new("UICorner")
AccentCorner.CornerRadius = UDim.new(0, 4)
AccentCorner.Parent = EmbedAccent

-- TopBar Header
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -30, 0, 40)
TopBar.Position = UDim2.new(0, 22, 0, 0)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "DOEAK HUB V5 <font color=\"#00E5FF\">•</font> ULTIMATE EMBED"
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -10, 0, 6)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(0, 229, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 12
MinimizeBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    DragonBtn.Visible = true
end)

DragonBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    DragonBtn.Visible = false
end)

-- Sidebar Tabs (Bên Trái - Bo Góc Outer)
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 140, 1, -52)
TabContainer.Position = UDim2.new(0, 22, 0, 42)
TabContainer.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 8)
TabCorner.Parent = TabContainer

local UIListLayoutTabs = Instance.new("UIListLayout")
UIListLayoutTabs.Parent = TabContainer
UIListLayoutTabs.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayoutTabs.Padding = UDim.new(0, 4)

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 6)
TabPadding.PaddingLeft = UDim.new(0, 6)
TabPadding.PaddingRight = UDim.new(0, 6)
TabPadding.Parent = TabContainer

-- Content Frame (Bên Phải - Bo Góc Outer)
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -180, 1, -52)
ContentContainer.Position = UDim2.new(0, 168, 0, 42)
ContentContainer.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
ContentContainer.BorderSizePixel = 0
ContentContainer.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentContainer

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 6)
ContentPadding.PaddingBottom = UDim.new(0, 6)
ContentPadding.PaddingLeft = UDim.new(0, 6)
ContentPadding.PaddingRight = UDim.new(0, 6)
ContentPadding.Parent = ContentContainer

local Tabs = {}
local TabButtons = {}

local function CreateTab(name, id)
    local TabFrame = Instance.new("ScrollingFrame")
    TabFrame.Size = UDim2.new(1, 0, 1, 0)
    TabFrame.BackgroundTransparency = 1
    TabFrame.ScrollBarThickness = 2
    TabFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 229, 255)
    TabFrame.Visible = false
    TabFrame.Parent = ContentContainer
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Parent = TabFrame
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 6)
    
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 34)
    TabBtn.BackgroundColor3 = Color3.fromRGB(22, 25, 33)
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(130, 135, 150)
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 11
    TabBtn.TextXAlignment = Enum.TextXAlignment.Center
    TabBtn.Parent = TabContainer
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = TabBtn
    
    Tabs[id] = TabFrame
    TabButtons[id] = TabBtn
    
    TabBtn.MouseButton1Click:Connect(function()
        for tId, frame in pairs(Tabs) do
            local active = (tId == id)
            frame.Visible = active
            TweenService:Create(TabButtons[tId], TweenInfo.new(0.2), {
                BackgroundColor3 = active and Color3.fromRGB(28, 33, 46) or Color3.fromRGB(22, 25, 33),
                TextColor3 = active and Color3.fromRGB(0, 229, 255) or Color3.fromRGB(130, 135, 150)
            }):Play()
        end
    end)
    
    return TabFrame
end

-- DANH SÁCH TAB
local TabInfo = CreateTab("Thông Tin", "Info")
local TabMain = CreateTab("Aimbot & FOV", "Main")
local TabAura = CreateTab("Attack Aura", "Aura")
local TabOptimize = CreateTab("Tối Ưu Máy", "Optimize")
local TabSurvival = CreateTab("Sinh Tồn", "Survival")
local TabMisc = CreateTab("Hệ Thống", "Misc")

Tabs["Info"].Visible = true
TabButtons["Info"].BackgroundColor3 = Color3.fromRGB(28, 33, 46)
TabButtons["Info"].TextColor3 = Color3.fromRGB(0, 229, 255)

-- ==========================================
-- ĐỊNH DẠNG TÁC VỤ UI
-- ==========================================
local function AddActionButton(parent, titleText, descText, initialActive, callback)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -8, 0, 48)
    Card.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
    Card.BorderSizePixel = 0
    Card.Parent = parent

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 6)
    CardCorner.Parent = Card

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -75, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 6)
    Label.BackgroundTransparency = 1
    Label.Text = titleText
    Label.TextColor3 = Color3.fromRGB(240, 240, 245)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Card

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(1, -75, 0, 16)
    SubLabel.Position = UDim2.new(0, 10, 0, 24)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = descText
    SubLabel.TextColor3 = Color3.fromRGB(120, 125, 140)
    SubLabel.Font = Enum.Font.Gotham
    SubLabel.TextSize = 9
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.Parent = Card

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 42, 0, 22)
    Switch.Position = UDim2.new(1, -52, 0.5, -11)
    Switch.BackgroundColor3 = initialActive and Color3.fromRGB(0, 229, 255) or Color3.fromRGB(32, 36, 48)
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Switch.Parent = Card

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = initialActive and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.Parent = Switch

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local state = initialActive
    Switch.MouseButton1Click:Connect(function()
        state = not state
        local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local targetColor = state and Color3.fromRGB(0, 229, 255) or Color3.fromRGB(32, 36, 48)

        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        callback(state)
    end)
end

local function AddSlider(parent, text, min, max, default, step, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -8, 0, 50)
    Frame.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 6)
    FrameCorner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": <font color=\"#00E5FF\">" .. tostring(default) .. "</font>"
    Label.RichText = true
    Label.TextColor3 = Color3.fromRGB(240, 240, 245)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Track = Instance.new("TextButton")
    Track.Size = UDim2.new(1, -20, 0, 6)
    Track.Position = UDim2.new(0, 10, 0, 30)
    Track.BackgroundColor3 = Color3.fromRGB(30, 34, 45)
    Track.Text = ""
    Track.AutoButtonColor = false
    Track.Parent = Frame

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = Track

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local SliderHead = Instance.new("Frame")
    SliderHead.Size = UDim2.new(0, 14, 0, 14)
    SliderHead.Position = UDim2.new(1, -7, 0.5, -7)
    SliderHead.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderHead.BorderSizePixel = 0
    SliderHead.Parent = Fill

    local HeadCorner = Instance.new("UICorner")
    HeadCorner.CornerRadius = UDim.new(1, 0)
    HeadCorner.Parent = SliderHead

    local dragging = false
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = true 
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = false 
        end
    end)

    RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = UserInputService:GetMouseLocation().X
            local trackPos = Track.AbsolutePosition.X
            local trackSize = Track.AbsoluteSize.X
            local percent = math.clamp((mousePos - trackPos) / trackSize, 0, 1)
            
            local rawValue = min + (max - min) * percent
            local value
            if step and step < 1 then
                value = math.floor(rawValue / step + 0.5) * step
                value = tonumber(string.format("%.1f", value))
            else
                value = math.floor(rawValue)
            end
            
            Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            Label.Text = text .. ": <font color=\"#00E5FF\">" .. tostring(value) .. "</font>"
            callback(value)
        end
    end)
end

-- ==========================================
-- NỘI DUNG CHI TIẾT
-- ==========================================

-- TAB INFO
local InfoEmbed = Instance.new("Frame")
InfoEmbed.Size = UDim2.new(1, -8, 1, -8)
InfoEmbed.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
InfoEmbed.BorderSizePixel = 0
InfoEmbed.Parent = TabInfo

local IECorner = Instance.new("UICorner")
IECorner.CornerRadius = UDim.new(0, 8)
IECorner.Parent = InfoEmbed

local InfoText = Instance.new("TextLabel")
InfoText.Size = UDim2.new(1, -20, 1, -20)
InfoText.Position = UDim2.new(0, 10, 0, 10)
InfoText.BackgroundTransparency = 1
InfoText.TextColor3 = Color3.fromRGB(200, 205, 220)
InfoText.TextSize = 11
InfoText.Font = Enum.Font.Gotham
InfoText.TextWrapped = true
InfoText.TextYAlignment = Enum.TextYAlignment.Top
InfoText.TextXAlignment = Enum.TextXAlignment.Left
InfoText.RichText = true
InfoText.Text = [[
<b><font color="#00E5FF">DOEAK HUB V5 — ULTIMATE EMBED EDITION</font></b>

• <b>Boot Tung Chiêu Nhanh:</b> Tăng tốc Animation để thi triển kỹ năng lập tức, không bị khựng.

• <b>UI Scale (0.1 -> 3.0):</b> Tùy chỉnh kích thước giao diện hiển thị phù hợp với mọi thiết bị.

• <b>Bo Góc Mượt Mà:</b> Thiết kế Embed sắc nét với các góc outer bo tròn 8px.
]]
InfoText.Parent = InfoEmbed

-- TAB MAIN AIM & SKILL
AddActionButton(TabMain, "Boot Tung Chiêu Nhanh", "Tăng tốc Animation để ra chiêu không bị khựng", false, function(v) Settings.FastSkill = v end)
AddSlider(TabMain, "Tốc Độ Chiêu (Speed)", 1, 5, 2.5, 0.5, function(v) Settings.FastSkillSpeed = v end)
AddActionButton(TabMain, "Aimbot + Tracer", "Khóa mục tiêu và hiển thị đường kẻ ngắm", false, function(v) Settings.AimEnabled = v end)
AddActionButton(TabMain, "Aim Lock Camera", "Tự động xoay Camera hướng về phía đối thủ", false, function(v) Settings.AimLock = v end)
AddSlider(TabMain, "Kích Thước FOV", 150, 1300, 400, 1, function(v) Settings.FOV = v end)

-- TAB ATTACK AURA
AddActionButton(TabAura, "Attack Aura Remote", "Tự động gửi gói tin tấn công mục tiêu gần nhất", false, function(v) Settings.AttackAura = v end)

local WContainer = Instance.new("Frame")
WContainer.Size = UDim2.new(1, -8, 0, 105)
WContainer.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
WContainer.BorderSizePixel = 0
WContainer.Parent = TabAura

local WCorner = Instance.new("UICorner")
WCorner.CornerRadius = UDim.new(0, 6)
WCorner.Parent = WContainer

local WLabel = Instance.new("TextLabel")
WLabel.Size = UDim2.new(1, -20, 0, 22)
WLabel.Position = UDim2.new(0, 10, 0, 6)
WLabel.BackgroundTransparency = 1
WLabel.Text = "Chọn Loại Vũ Khí:"
WLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
WLabel.Font = Enum.Font.GothamBold
WLabel.TextSize = 11
WLabel.TextXAlignment = Enum.TextXAlignment.Left
WLabel.Parent = WContainer

local Weapons = {"Melee", "Sword", "Gun", "Blox Fruit"}
local WeaponBtns = {}

for i, wName in ipairs(Weapons) do
    local wBtn = Instance.new("TextButton")
    wBtn.Size = UDim2.new(0.46, 0, 0, 28)
    local posX = (i % 2 == 1) and 0.03 or 0.51
    local posY = (i > 2) and 65 or 32
    wBtn.Position = UDim2.new(posX, 0, 0, posY)
    wBtn.BackgroundColor3 = (Settings.WeaponType == wName) and Color3.fromRGB(0, 229, 255) or Color3.fromRGB(28, 32, 44)
    wBtn.Text = wName
    wBtn.TextColor3 = (Settings.WeaponType == wName) and Color3.fromRGB(10, 10, 15) or Color3.fromRGB(200, 205, 220)
    wBtn.Font = Enum.Font.GothamBold
    wBtn.TextSize = 10
    wBtn.Parent = WContainer
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 5)
    Corner.Parent = wBtn
    
    WeaponBtns[wName] = wBtn
    
    wBtn.MouseButton1Click:Connect(function()
        Settings.WeaponType = wName
        for name, btn in pairs(WeaponBtns) do
            local selected = (name == wName)
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = selected and Color3.fromRGB(0, 229, 255) or Color3.fromRGB(28, 32, 44),
                TextColor3 = selected and Color3.fromRGB(10, 10, 15) or Color3.fromRGB(200, 205, 220)
            }):Play()
        end
    end)
end

-- TAB OPTIMIZE
AddActionButton(TabOptimize, "FPS Booster", "Tối ưu hóa chất liệu bản đồ để tăng FPS", false, function(v)
    Settings.FPSBoost = v
    if v then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
                obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end
    end
end)

AddActionButton(TabOptimize, "Xóa Mây & Hiệu Ứng", "Dọn dẹp mây trời và hiệu ứng ánh sáng gây lag", false, function(v)
    Settings.RemoveClouds = v
    if v then
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            local clouds = terrain:FindFirstChildOfClass("Clouds")
            if clouds then clouds:Destroy() end
        end
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
    end
end)

-- TAB SURVIVAL
AddActionButton(TabSurvival, "Auto Teleport Cấp Cứu", "Dịch chuyển về Hot & Cold khi máu xuống thấp", false, function(v) Settings.AutoTpLowHealth = v end)
AddSlider(TabSurvival, "Ngưỡng Máu Cấp Cứu (%)", 20, 50, 20, 1, function(v) Settings.HealthThreshold = v end)
AddActionButton(TabSurvival, "Đi Trên Mặt Nước", "Tạo sàn đứng bảo vệ khi tiếp xúc với nước", false, function(v) Settings.WaterWalk = v end)

-- TAB MISC / HỆ THỐNG
AddSlider(TabMisc, "UI Scale", 0.1, 3.0, 1.0, 0.1, function(v)
    Settings.UIScale = v
    MainScale.Scale = v
end)
AddActionButton(TabMisc, "Anti-AFK (Auto Jump)", "Tự động nhảy mỗi 10 giây tránh bị ngắt kết nối", false, function(v) Settings.AntiAFK = v end)
AddActionButton(TabMisc, "Auto Hop Random (20p)", "Tự tìm và đổi Server mới sau mỗi 20 phút", false, function(v) Settings.AutoHop20m = v end)

-- ==========================================
-- LOGIC VÒNG LẶP HỆ THỐNG
-- ==========================================

-- Anti-AFK
task.spawn(function()
    while task.wait(10) do
        if Settings.AntiAFK and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                hum.Jump = true
            end
        end
    end
end)

-- Auto Hop Server
task.spawn(function()
    local timer = 0
    while task.wait(1) do
        if Settings.AutoHop20m then
            timer = timer + 1
            if timer >= 1200 then
                timer = 0
                local success, result = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
                end)
                
                if success and result and result.data then
                    local validServers = {}
                    for _, s in pairs(result.data) do
                        if type(s) == "table" and s.playing < s.maxPlayers and s.id ~= game.JobId then
                            table.insert(validServers, s.id)
                        end
                    end
                    
                    if #validServers > 0 then
                        local randomServerId = validServers[math.random(1, #validServers)]
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServerId, LocalPlayer)
                    end
                end
            end
        else
            timer = 0
        end
    end
end)

-- Equip Weapon
local function EquipWeapon(weaponCategory)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if not backpack or not char then return end
    
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == weaponCategory or tool:FindFirstChild(weaponCategory)) then
            return tool
        end
    end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == weaponCategory or tool:FindFirstChild(weaponCategory) or string.find(tool.Name:lower(), weaponCategory:lower())) then
            char.Humanoid:EquipTool(tool)
            return tool
        end
    end
    return nil
end

-- Attack Aura
task.spawn(function()
    while task.wait(0.03) do
        if Settings.AttackAura and LocalPlayer.Character then
            local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                local targetHRP = nil
                local minDistance = Settings.AuraRange
                
                local enemiesFolder = Workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    for _, mob in pairs(enemiesFolder:GetChildren()) do
                        local mHRP = mob:FindFirstChild("HumanoidRootPart")
                        local mHum = mob:FindFirstChild("Humanoid")
                        if mHRP and mHum and mHum.Health > 0 then
                            local dist = (myHRP.Position - mHRP.Position).Magnitude
                            if dist < minDistance then
                                minDistance = dist
                                targetHRP = mHRP
                            end
                        end
                    end
                end
                
                if targetHRP and RegisterAttack and RegisterHit then
                    EquipWeapon(Settings.WeaponType)
                    RegisterAttack:FireServer(targetHRP)
                    task.wait(0.01)
                    RegisterHit:FireServer(targetHRP)
                end
            end
        end
    end
end)

-- Water Walk
local WaterPlatform = Instance.new("Part")
WaterPlatform.Size = Vector3.new(150, 1, 150)
WaterPlatform.Anchored = true
WaterPlatform.Transparency = 1
WaterPlatform.Parent = Workspace

RunService.RenderStepped:Connect(function()
    if Settings.WaterWalk and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if hrp.Position.Y < 15 and hrp.Position.Y > -10 then
            WaterPlatform.Position = Vector3.new(hrp.Position.X, 1, hrp.Position.Z)
        else
            WaterPlatform.Position = Vector3.new(0, -1000, 0)
        end
    else
        WaterPlatform.Position = Vector3.new(0, -1000, 0)
    end
end)

print("DOEAK HUB V5 ULTIMATE UI SCALE LOADED!")
