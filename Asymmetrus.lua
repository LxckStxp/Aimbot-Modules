--[[
    Advanced Aimbot System
    Using Modern CensuraDev UI Library
    Optimized for Performance and User Experience
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Load CensuraDev UI Library
local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()

-- Aimbot Configuration
local Aimbot = {
    Enabled = false,
    IsAiming = false,
    TargetPart = "Head",
    Smoothness = 0.5,
    FOV = 400,
    MaxDistance = 1000,
    TeamCheck = false,
    VisibilityCheck = true,
    
    -- Cache System
    CurrentTarget = nil,
    CurrentHighlight = nil,
    CachedPlayers = {},
    LastCacheUpdate = 0,
    CacheUpdateInterval = 0.1,
    LastUpdate = 0,
    UpdateInterval = 1/144, -- Fixed 144Hz update rate
    
    -- Player Management
    PlayerList = {},
    
    -- Visual Settings
    Colors = {
        Enabled = Color3.fromRGB(126, 131, 255),
        Disabled = Color3.fromRGB(255, 85, 85),
        Highlight = Color3.fromRGB(255, 255, 255)
    }
}

-- Utility Functions
local function IsPlayerAlive(player)
    local character = player.Character
    return character 
        and character:FindFirstChild("Humanoid") 
        and character:FindFirstChild("Head")
        and character.Humanoid.Health > 0
end

local function IsValidTarget(player)
    if player == LocalPlayer then return false end
    if not IsPlayerAlive(player) then return false end
    if Aimbot.TeamCheck and player.Team == LocalPlayer.Team then return false end
    if not Aimbot.PlayerList[player.UserId] then return false end
    
    return player.Character:FindFirstChild(Aimbot.TargetPart) ~= nil
end

local function IsVisible(player)
    if not player.Character then return false end
    local character = LocalPlayer.Character
    if not character then return false end
    
    local targetPart = player.Character:FindFirstChild(Aimbot.TargetPart)
    if not targetPart then return false end
    
    local ray = Ray.new(
        character.Head.Position,
        (targetPart.Position - character.Head.Position).Unit * Aimbot.MaxDistance
    )
    
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {character, Camera})
    return hit and hit:IsDescendantOf(player.Character)
end

-- Target System
local function UpdatePlayerCache()
    local currentTime = tick()
    if currentTime - Aimbot.LastCacheUpdate < Aimbot.CacheUpdateInterval then return end
    
    Aimbot.CachedPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            table.insert(Aimbot.CachedPlayers, player)
        end
    end
    
    Aimbot.LastCacheUpdate = currentTime
end

local function GetClosestPlayer()
    local closest = nil
    local shortestDistance = Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()
    
    UpdatePlayerCache()
    
    for _, player in ipairs(Aimbot.CachedPlayers) do
        local character = player.Character
        if not character then continue end
        
        local targetPart = character:FindFirstChild(Aimbot.TargetPart)
        if not targetPart then continue end
        
        local distance = (LocalPlayer.Character:GetPivot().Position - targetPart.Position).Magnitude
        if distance > Aimbot.MaxDistance then continue end
        
        local pos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
        if not onScreen then continue end
        
        local screenDistance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
        if screenDistance < shortestDistance then
            if Aimbot.VisibilityCheck and not IsVisible(player) then continue end
            closest = player
            shortestDistance = screenDistance
        end
    end
    
    return closest
end

-- Visual Feedback System
local VisualSystem = {
    CreateTargetEffect = function(position)
        local ring = Instance.new("Part")
        ring.Size = Vector3.new(2, 2, 2)
        ring.CFrame = CFrame.new(position)
        ring.Anchored = true
        ring.CanCollide = false
        ring.Transparency = 0.5
        ring.Material = Enum.Material.Neon
        ring.Color = Aimbot.Colors.Enabled
        ring.Parent = workspace
        
        TweenService:Create(ring,
            TweenInfo.new(0.3),
            {Size = Vector3.new(0, 0, 0), Transparency = 1}
        ):Play()
        
        Debris:AddItem(ring, 0.3)
    end,
    
    UpdateTargetHighlight = function(player)
        if player == Aimbot.CurrentTarget then return end
        
        if Aimbot.CurrentHighlight then
            Aimbot.CurrentHighlight:Destroy()
            Aimbot.CurrentHighlight = nil
        end
        
        if player then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = IsVisible(player) and 
                Aimbot.Colors.Enabled or 
                Aimbot.Colors.Highlight
            highlight.OutlineColor = Aimbot.Colors.Highlight
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = player.Character
            
            Aimbot.CurrentHighlight = highlight
        end
        
        Aimbot.CurrentTarget = player
    end
}

-- Aiming System
local function AimAtTarget(targetPos)
    if not targetPos then return end
    
    local targetCF = CFrame.new(Camera.CFrame.Position, targetPos)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, Aimbot.Smoothness)
end

-- UI Creation
local function CreateMainWindow()
    local ui = CensuraDev.new()
    
    -- Main toggle
    ui:CreateToggle("Enable Aimbot [ALT]", false, function(enabled)
        Aimbot.Enabled = enabled
        if not enabled and Aimbot.CurrentHighlight then
            Aimbot.CurrentHighlight:Destroy()
            Aimbot.CurrentHighlight = nil
            Aimbot.CurrentTarget = nil
        end
    end)
    
    -- Smoothness control
    ui:CreateSlider("Smoothness", 1, 100, 50, function(value)
        Aimbot.Smoothness = value / 100
    end)
    
    -- FOV control
    ui:CreateSlider("FOV", 50, 800, 400, function(value)
        Aimbot.FOV = value
    end)
    
    -- Distance control
    ui:CreateSlider("Max Distance", 100, 2000, 1000, function(value)
        Aimbot.MaxDistance = value
    end)
    
    -- Toggles
    ui:CreateToggle("Team Check", false, function(enabled)
        Aimbot.TeamCheck = enabled
    end)
    
    ui:CreateToggle("Visibility Check", true, function(enabled)
        Aimbot.VisibilityCheck = enabled
    end)
    
    ui:CreateToggle("Target Head", true, function(enabled)
        Aimbot.TargetPart = enabled and "Head" or "HumanoidRootPart"
    end)
    
    -- Player list button
    ui:CreateButton("Player List", function()
        CreatePlayerListWindow()
    end)
    
    return ui
end

local function CreatePlayerListWindow()
    local playerListUI = CensuraDev.new()
    
    -- Create toggles for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            playerListUI:CreateToggle(player.Name, true, function(enabled)
                Aimbot.PlayerList[player.UserId] = enabled
            end)
        end
    end
    
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            playerListUI:CreateToggle(player.Name, true, function(enabled)
                Aimbot.PlayerList[player.UserId] = enabled
            end)
        end
    end)
    
    playerListUI:Show()
end

-- Input Handling
local function SetupInputHandling()
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftAlt then
            Aimbot.IsAiming = true
            Aimbot.LastCacheUpdate = 0
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftAlt then
            Aimbot.IsAiming = false
            if Aimbot.CurrentHighlight then
                Aimbot.CurrentHighlight:Destroy()
                Aimbot.CurrentHighlight = nil
                Aimbot.CurrentTarget = nil
            end
        end
    end)
end

-- Main Loop
local function StartAimbotLoop()
    RunService.Heartbeat:Connect(function()
        if not Aimbot.Enabled or not Aimbot.IsAiming then return end
        
        local currentTime = tick()
        if currentTime - Aimbot.LastUpdate < Aimbot.UpdateInterval then return end
        Aimbot.LastUpdate = currentTime
        
        local target = GetClosestPlayer()
        VisualSystem.UpdateTargetHighlight(target)
        
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(Aimbot.TargetPart)
            if targetPart then
                AimAtTarget(targetPart.Position)
            end
        end
    end)
end

-- Initialize
local function Initialize()
    -- Initialize player list
    for _, player in ipairs(Players:GetPlayers()) do
        Aimbot.PlayerList[player.UserId] = true
    end
    
    local mainUI = CreateMainWindow()
    SetupInputHandling()
    StartAimbotLoop()
    
    -- Show UI
    mainUI:Show()
end

-- Start the aimbot
Initialize()
