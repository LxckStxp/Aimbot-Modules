------------------------------------------------------------
-- Advanced Aimbot System – Revised (No Target Effect)
-- Version: 1.3
-- Dependencies: LSCommons, CensuraDev (UI)
------------------------------------------------------------

-- Dependencies
local LSCommons = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/LSCommons.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------
-- Aimbot Configuration and Manager
------------------------------------------------------------
local Aimbot = {
    Enabled = false,          -- main toggle from UI
    Aiming = false,           -- ALT key pressed?
    TargetPart = "Head",      -- part to aim at ("Head" or "HumanoidRootPart")
    Smoothness = 0.5,         -- factor between 0 (snap) and 1 (slow)
    FOV = 400,                -- field-of-view threshold (in pixels)
    MaxDistance = 1000,       -- maximum target distance in world units
    VisibilityCheck = true,   -- require target to be visible?
    
    CurrentTarget = nil,      -- currently locked target (player or NPC)

    -- Caching system (for players and NPCs)
    CachedTargets = {},
    LastCacheUpdate = 0,
    CacheUpdateInterval = 0.1,  -- seconds
    
    LastUpdate = 0,
    UpdateInterval = 1 / 144    -- 144Hz update rate
}

------------------------------------------------------------
-- Utility Functions (using LSCommons where possible)
------------------------------------------------------------
local function IsEntityAlive(entity)
    if entity:IsA("Player") then
        return entity.Character and LSCommons.Players.isAlive(entity.Character)
    else
        local hum = entity:FindFirstChild("Humanoid")
        local head = entity:FindFirstChild("Head")
        return hum and head and hum.Health > 0
    end
end

local function HasTargetPart(entity)
    if entity:IsA("Player") then
        return entity.Character and entity.Character:FindFirstChild(Aimbot.TargetPart)
    else
        return entity:FindFirstChild(Aimbot.TargetPart) ~= nil
    end
end

local function IsValidTarget(entity)
    if entity:IsA("Player") and entity == LocalPlayer then 
        return false 
    end
    return IsEntityAlive(entity) and HasTargetPart(entity)
end

local function GetNPCs()
    local npcs = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if LSCommons.Players.isNPC(obj) and IsValidTarget(obj) then
            table.insert(npcs, obj)
        end
    end
    return npcs
end

local function UpdateTargetCache()
    local currentTime = tick()
    if currentTime - Aimbot.LastCacheUpdate < Aimbot.CacheUpdateInterval then return end
    
    local cache = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsValidTarget(player) then
            table.insert(cache, player)
        end
    end
    for _, npc in ipairs(GetNPCs()) do
        table.insert(cache, npc)
    end
    
    Aimbot.CachedTargets = cache
    Aimbot.LastCacheUpdate = currentTime
end

local function GetClosestTarget()
    local closest = nil
    local shortestDistance = Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()
    
    UpdateTargetCache()
    
    for _, entity in ipairs(Aimbot.CachedTargets) do
        local character = entity:IsA("Player") and entity.Character or entity
        if not character then continue end
        
        local targetPart = character:FindFirstChild(Aimbot.TargetPart)
        if not targetPart then continue end
        
        local worldDistance = (LocalPlayer.Character:GetPivot().Position - targetPart.Position).Magnitude
        if worldDistance > Aimbot.MaxDistance then continue end
        
        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
        if not onScreen then continue end
        
        local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if screenDistance < shortestDistance then
            if Aimbot.VisibilityCheck and (not IsVisible(entity)) then continue end
            closest = entity
            shortestDistance = screenDistance
        end
    end
    
    return closest
end

function IsVisible(entity)
    local character = entity:IsA("Player") and entity.Character or entity
    if not character then return false end
    
    local targetPart = character:FindFirstChild(Aimbot.TargetPart)
    if not targetPart then return false end
    
    local localHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not localHead then return false end
    
    local rayOrigin = localHead.Position
    local rayDir = (targetPart.Position - rayOrigin).Unit * Aimbot.MaxDistance
    local ignoreList = {LocalPlayer.Character, Camera}
    local hitPart = workspace:FindPartOnRayWithIgnoreList(Ray.new(rayOrigin, rayDir), ignoreList)
    
    return hitPart and hitPart:IsDescendantOf(character)
end

local function AimAtTarget(targetPos)
    if not targetPos then return end
    local currentCF = Camera.CFrame
    local desiredCF = CFrame.new(currentCF.Position, targetPos)
    Camera.CFrame = currentCF:Lerp(desiredCF, Aimbot.Smoothness)
end

------------------------------------------------------------
-- Input Handling
------------------------------------------------------------
local function SetupInputHandling()
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftAlt then
            Aimbot.Aiming = true
            Aimbot.LastCacheUpdate = 0  -- Force cache update on aim
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftAlt then
            Aimbot.Aiming = false
            Aimbot.CurrentTarget = nil
        end
    end)
end

------------------------------------------------------------
-- Aimbot Main Update Loop
------------------------------------------------------------
local function StartAimbotLoop()
    RunService.RenderStepped:Connect(function()
        if (not Aimbot.Enabled) or (not Aimbot.Aiming) then return end
        
        local currentTime = tick()
        if currentTime - Aimbot.LastUpdate < Aimbot.UpdateInterval then return end
        Aimbot.LastUpdate = currentTime
        
        -- If a valid target is currently locked, continue locking onto it.
        if Aimbot.CurrentTarget and IsValidTarget(Aimbot.CurrentTarget) then
            local character = Aimbot.CurrentTarget:IsA("Player") and Aimbot.CurrentTarget.Character or Aimbot.CurrentTarget
            local targetPart = character and character:FindFirstChild(Aimbot.TargetPart)
            if targetPart then
                AimAtTarget(targetPart.Position)
            end
        else
            Aimbot.CurrentTarget = GetClosestTarget()
        end
    end)
end

------------------------------------------------------------
-- UI Setup using CensuraDev
------------------------------------------------------------
local function CreateMainWindow()
    local ui = UI.new("Aimbot")
    
    ui:CreateToggle("Enable Aimbot [ALT]", false, function(enabled)
        Aimbot.Enabled = enabled
        if not enabled then
            Aimbot.CurrentTarget = nil
        end
    end)
    
    ui:CreateSlider("Smoothness", 1, 100, 50, function(value)
        Aimbot.Smoothness = value / 100
    end)
    
    ui:CreateSlider("FOV", 50, 800, 400, function(value)
        Aimbot.FOV = value
    end)
    
    ui:CreateSlider("Max Distance", 100, 2000, 1000, function(value)
        Aimbot.MaxDistance = value
    end)
    
    ui:CreateToggle("Visibility Check", true, function(enabled)
        Aimbot.VisibilityCheck = enabled
    end)
    
    ui:CreateToggle("Target Head", true, function(enabled)
        Aimbot.TargetPart = enabled and "Head" or "HumanoidRootPart"
    end)
    
    return ui
end

------------------------------------------------------------
-- Main Initialization
------------------------------------------------------------
local function Initialize()
    local mainUI = CreateMainWindow()
    SetupInputHandling()
    StartAimbotLoop()
    
    mainUI:Show()
end

------------------------------------------------------------
-- Start the Aimbot System
------------------------------------------------------------
Initialize()
