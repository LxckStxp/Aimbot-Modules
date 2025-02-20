--[[
    CensuraAimbot Module
    Version: 1.5
    Main aimbot implementation using AimbotUtil
]]

-- Dependencies
local LSCommons = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/LSCommons.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
local AimbotUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Aimbot-Modules/main/AimbotUtil.lua"))()

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
    UpdateRate = 144,
    CacheInterval = 0.1,
    
    -- Internal state
    CurrentTarget = nil,
    CachedTargets = {},
    LastCache = 0,
    LastUpdate = 0
}

-- Target Cache Management
local function updateTargetCache()
    local currentTime = tick()
    if currentTime - AimbotConfig.LastCache < AimbotConfig.CacheInterval then return end
    
    local cache = {}
    
    -- Cache players
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if AimbotUtil.isValidTarget(player, AimbotConfig) then
            table.insert(cache, player)
        end
    end
    
    -- Cache NPCs
    for _, obj in ipairs(workspace:GetChildren()) do
        if LSCommons.Players.isNPC(obj) and AimbotUtil.isValidTarget(obj, AimbotConfig) then
            table.insert(cache, obj)
        end
    end
    
    AimbotConfig.CachedTargets = cache
    AimbotConfig.LastCache = currentTime
end

-- Input Handling
local function setupInputHandling()
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
local function startAimbotLoop()
    Services.RunService.RenderStepped:Connect(function()
        if not (AimbotConfig.Enabled and AimbotConfig.Aiming) then return end
        
        local currentTime = tick()
        if currentTime - AimbotConfig.LastUpdate < (1 / AimbotConfig.UpdateRate) then return end
        AimbotConfig.LastUpdate = currentTime
        
        updateTargetCache()
        
        if AimbotConfig.CurrentTarget and AimbotUtil.isValidTarget(AimbotConfig.CurrentTarget, AimbotConfig) then
            local targetPos = AimbotUtil.getTargetPosition(AimbotConfig.CurrentTarget, AimbotConfig.TargetPart)
            if targetPos then
                Camera.CFrame = AimbotUtil.calculateAimCFrame(targetPos, AimbotConfig.Smoothness)
                return
            end
        end
        
        AimbotConfig.CurrentTarget = AimbotUtil.getBestTarget(AimbotConfig.CachedTargets, AimbotConfig)
    end)
end

-- UI Setup
local function createUI()
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
    local mainWindow = createUI()
    setupInputHandling()
    startAimbotLoop()
    mainWindow:Show()
end

Initialize()
