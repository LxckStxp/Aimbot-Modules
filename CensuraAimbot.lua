--[[
    Advanced Aimbot System
    Version: 1.4
    Dependencies: LSCommons, CensuraDev
]]

-- Dependencies
local LSCommons = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/LSCommons.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()

-- Services
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInput = game:GetService("UserInputService")
}

local Camera = workspace.CurrentCamera
local LocalPlayer = Services.Players.LocalPlayer

-- Configuration
local AimbotConfig = {
    Enabled = false,
    Aiming = false,
    TargetPart = "Head",
    Smoothness = 0.5,
    FOV = 400,
    MaxDistance = 1000,
    VisibilityCheck = true,
    
    -- Performance settings
    UpdateRate = 144, -- Hz
    CacheInterval = 0.1, -- seconds
    
    -- Internal state
    CurrentTarget = nil,
    CachedTargets = {},
    LastCache = 0,
    LastUpdate = 0
}

-- Utility Functions
local function IsValidTarget(entity)
    if not entity then return false end
    
    -- Check if target is local player
    if entity == LocalPlayer then return false end
    
    -- Get character
    local character = entity:IsA("Player") and entity.Character or entity
    if not character then return false end
    
    -- Check for required parts
    local humanoid = character:FindFirstChild("Humanoid")
    local targetPart = character:FindFirstChild(AimbotConfig.TargetPart)
    
    return humanoid 
        and humanoid.Health > 0 
        and targetPart 
        and character:FindFirstChild("Head")
end

local function GetTargetPosition(entity)
    local character = entity:IsA("Player") and entity.Character or entity
    if not character then return nil end
    
    local targetPart = character:FindFirstChild(AimbotConfig.TargetPart)
    return targetPart and targetPart.Position
end

local function IsInFOV(screenPos)
    local mousePos = Services.UserInput:GetMouseLocation()
    return (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude <= AimbotConfig.FOV
end

local function IsVisible(entity)
    local targetPos = GetTargetPosition(entity)
    if not targetPos then return false end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local head = character:FindFirstChild("Head")
    if not head then return false end
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character, Camera}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local direction = (targetPos - head.Position).Unit * AimbotConfig.MaxDistance
    local result = workspace:Raycast(head.Position, direction, params)
    
    if result then
        local hit = result.Instance
        return hit:IsDescendantOf(entity:IsA("Player") and entity.Character or entity)
    end
    
    return false
end

-- Target Management
local function UpdateTargetCache()
    local currentTime = tick()
    if currentTime - AimbotConfig.LastCache < AimbotConfig.CacheInterval then return end
    
    local cache = {}
    
    -- Cache players
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if IsValidTarget(player) then
            table.insert(cache, player)
        end
    end
    
    -- Cache NPCs
    for _, obj in ipairs(workspace:GetChildren()) do
        if LSCommons.Players.isNPC(obj) and IsValidTarget(obj) then
            table.insert(cache, obj)
        end
    end
    
    AimbotConfig.CachedTargets = cache
    AimbotConfig.LastCache = currentTime
end

local function GetBestTarget()
    UpdateTargetCache()
    
    local closest = nil
    local minDistance = AimbotConfig.FOV
    local mousePos = Services.UserInput:GetMouseLocation()
    
    for _, target in ipairs(AimbotConfig.CachedTargets) do
        local targetPos = GetTargetPosition(target)
        if not targetPos then continue end
        
        -- Check distance
        local worldDistance = (LocalPlayer.Character:GetPivot().Position - targetPos).Magnitude
        if worldDistance > AimbotConfig.MaxDistance then continue end
        
        -- Check FOV
        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPos)
        if not onScreen then continue end
        
        local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if screenDistance < minDistance then
            if AimbotConfig.VisibilityCheck and not IsVisible(target) then continue end
            
            closest = target
            minDistance = screenDistance
        end
    end
    
    return closest
end

-- Aiming Logic
local function AimAtTarget(targetPos)
    if not targetPos then return end
    
    local currentCF = Camera.CFrame
    local targetCF = CFrame.new(currentCF.Position, targetPos)
    
    Camera.CFrame = currentCF:Lerp(targetCF, AimbotConfig.Smoothness)
end

-- Input Handling
local function SetupInputHandling()
    Services.UserInput.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftAlt then
            AimbotConfig.Aiming = true
            AimbotConfig.LastCache = 0
        end
    end)
    
    Services.UserInput.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftAlt then
            AimbotConfig.Aiming = false
            AimbotConfig.CurrentTarget = nil
        end
    end)
end

-- Main Loop
local function StartAimbotLoop()
    Services.RunService.RenderStepped:Connect(function()
        if not (AimbotConfig.Enabled and AimbotConfig.Aiming) then return end
        
        local currentTime = tick()
        if currentTime - AimbotConfig.LastUpdate < (1 / AimbotConfig.UpdateRate) then return end
        AimbotConfig.LastUpdate = currentTime
        
        if AimbotConfig.CurrentTarget and IsValidTarget(AimbotConfig.CurrentTarget) then
            local targetPos = GetTargetPosition(AimbotConfig.CurrentTarget)
            if targetPos then
                AimAtTarget(targetPos)
                return
            end
        end
        
        AimbotConfig.CurrentTarget = GetBestTarget()
    end)
end

-- UI Setup
local function CreateUI()
    local window = UI.new("Aimbot")
    
    window:CreateToggle("Enable Aimbot [ALT]", false, function(value)
        AimbotConfig.Enabled = value
        if not value then
            AimbotConfig.CurrentTarget = nil
        end
    end)
    
    window:CreateSlider("Smoothness", 1, 100, 50, function(value)
        AimbotConfig.Smoothness = value / 100
    end)
    
    window:CreateSlider("FOV", 50, 800, 400, function(value)
        AimbotConfig.FOV = value
    end)
    
    window:CreateSlider("Max Distance", 100, 2000, 1000, function(value)
        AimbotConfig.MaxDistance = value
    end)
    
    window:CreateToggle("Visibility Check", true, function(value)
        AimbotConfig.VisibilityCheck = value
    end)
    
    window:CreateToggle("Target Head", true, function(value)
        AimbotConfig.TargetPart = value and "Head" or "HumanoidRootPart"
    end)
    
    return window
end

-- Initialization
local function Initialize()
    local mainWindow = CreateUI()
    SetupInputHandling()
    StartAimbotLoop()
    mainWindow:Show()
end

-- Start the system
Initialize()
