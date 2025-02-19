------------------------------------------------------------
-- Advanced Aimbot System – Revised (Persistent Target Effect)
-- Version: 1.2
-- Dependencies: LSCommons, CensuraDev (UI)
------------------------------------------------------------

-- Dependencies
local LSCommons = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/LSCommons.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
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
    CurrentEffect = nil,      -- persistent visual effect instance on the target
    
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

-- Check if an entity (player or NPC) is alive
local function IsEntityAlive(entity)
    if entity:IsA("Player") then
        return entity.Character and LSCommons.Players.isAlive(entity.Character)
    else
        local hum = entity:FindFirstChild("Humanoid")
        local head = entity:FindFirstChild("Head")
        return hum and head and hum.Health > 0
    end
end

-- Check if the entity has the target part
local function HasTargetPart(entity)
    if entity:IsA("Player") then
        return entity.Character and entity.Character:FindFirstChild(Aimbot.TargetPart)
    else
        return entity:FindFirstChild(Aimbot.TargetPart) ~= nil
    end
end

-- Unified valid target check
local function IsValidTarget(entity)
    if entity:IsA("Player") and entity == LocalPlayer then 
        return false 
    end
    return IsEntityAlive(entity) and HasTargetPart(entity)
end

-- For NPCs: Search workspace children using LSCommons isNPC
local function GetNPCs()
    local npcs = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if LSCommons.Players.isNPC(obj) and IsValidTarget(obj) then
            table.insert(npcs, obj)
        end
    end
    return npcs
end

-- Update our cache of valid targets (players & NPCs)
local function UpdateTargetCache()
    local currentTime = tick()
    if currentTime - Aimbot.LastCacheUpdate < Aimbot.CacheUpdateInterval then return end
    
    local cache = {}
    -- Valid players (exclude LocalPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsValidTarget(player) then
            table.insert(cache, player)
        end
    end
    -- Valid NPCs
    for _, npc in ipairs(GetNPCs()) do
        table.insert(cache, npc)
    end
    
    Aimbot.CachedTargets = cache
    Aimbot.LastCacheUpdate = currentTime
end

-- Returns the closest valid target based on the screen distance from the mouse.
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

-- Visibility check via raycasting
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

-- Smoothly aim the camera toward target position using Lerp.
local function AimAtTarget(targetPos)
    if not targetPos then return end
    local currentCF = Camera.CFrame
    local desiredCF = CFrame.new(currentCF.Position, targetPos)
    Camera.CFrame = currentCF:Lerp(desiredCF, Aimbot.Smoothness)
end

------------------------------------------------------------
-- Persistent Visual Feedback System
------------------------------------------------------------
local VisualSystem = {}

function VisualSystem.CreatePersistentTargetEffect(targetPart)
    local ring = Instance.new("Part")
    ring.Name = "AimbotTargetEffect"
    ring.Size = Vector3.new(2, 2, 2)
    ring.CFrame = targetPart.CFrame
    ring.Anchored = true
    ring.CanCollide = false
    ring.Transparency = 0.2
    ring.Material = Enum.Material.Neon
    ring.Color = Color3.fromRGB(126, 131, 255)
    ring.Parent = workspace
    return ring
end

function VisualSystem.UpdatePersistentTargetEffect(effect, targetPart)
    if effect and targetPart then
        effect.CFrame = targetPart.CFrame
    end
end

function VisualSystem.RemovePersistentTargetEffect(effect)
    if effect then
        effect:Destroy()
    end
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
            if Aimbot.CurrentEffect then
                VisualSystem.RemovePersistentTargetEffect(Aimbot.CurrentEffect)
                Aimbot.CurrentEffect = nil
            end
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
        
        -- If current target is still valid, remain locked on.
        if Aimbot.CurrentTarget and IsValidTarget(Aimbot.CurrentTarget) then
            local character = Aimbot.CurrentTarget:IsA("Player") and Aimbot.CurrentTarget.Character or Aimbot.CurrentTarget
            local targetPart = character and character:FindFirstChild(Aimbot.TargetPart)
            if targetPart then
                AimAtTarget(targetPart.Position)
                if Aimbot.CurrentEffect then
                    VisualSystem.UpdatePersistentTargetEffect(Aimbot.CurrentEffect, targetPart)
                else
                    -- Create persistent target effect once per target lock.
                    Aimbot.CurrentEffect = VisualSystem.CreatePersistentTargetEffect(targetPart)
                end
            end
        else
            -- Otherwise, search for a new target.
            local newTarget = GetClosestTarget()
            if newTarget then
                Aimbot.CurrentTarget = newTarget
                if Aimbot.CurrentEffect then
                    VisualSystem.RemovePersistentTargetEffect(Aimbot.CurrentEffect)
                    Aimbot.CurrentEffect = nil
                end
            else
                Aimbot.CurrentTarget = nil
                if Aimbot.CurrentEffect then
                    VisualSystem.RemovePersistentTargetEffect(Aimbot.CurrentEffect)
                    Aimbot.CurrentEffect = nil
                end
            end
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
            if Aimbot.CurrentEffect then
                VisualSystem.RemovePersistentTargetEffect(Aimbot.CurrentEffect)
                Aimbot.CurrentEffect = nil
            end
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
