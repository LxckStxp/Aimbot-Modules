--[[
    AimbotUtil Module
    Version: 1.0
    Core utility functions for aimbot targeting and calculations
]]

local AimbotUtil = {}

-- Services
local Services = {
    Players = game:GetService("Players"),
    UserInput = game:GetService("UserInputService")
}

local Camera = workspace.CurrentCamera
local LocalPlayer = Services.Players.LocalPlayer

-- Target Validation
function AimbotUtil.isValidTarget(entity, config)
    if not entity then return false end
    
    -- Check if target is local player
    if entity == LocalPlayer then return false end
    
    -- Get character
    local character = entity:IsA("Player") and entity.Character or entity
    if not character then return false end
    
    -- Check for required parts
    local humanoid = character:FindFirstChild("Humanoid")
    local targetPart = character:FindFirstChild(config.TargetPart)
    
    return humanoid 
        and humanoid.Health > 0 
        and targetPart 
        and character:FindFirstChild("Head")
end

-- Position Utilities
function AimbotUtil.getTargetPosition(entity, targetPart)
    local character = entity:IsA("Player") and entity.Character or entity
    if not character then return nil end
    
    local part = character:FindFirstChild(targetPart)
    return part and part.Position
end

-- FOV Calculations
function AimbotUtil.isInFOV(screenPos, fov)
    local mousePos = Services.UserInput:GetMouseLocation()
    return (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude <= fov
end

-- Visibility Check
function AimbotUtil.isVisible(entity, config)
    local targetPos = AimbotUtil.getTargetPosition(entity, config.TargetPart)
    if not targetPos then return false end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local head = character:FindFirstChild("Head")
    if not head then return false end
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character, Camera}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local direction = (targetPos - head.Position).Unit * config.MaxDistance
    local result = workspace:Raycast(head.Position, direction, params)
    
    if result then
        local hit = result.Instance
        return hit:IsDescendantOf(entity:IsA("Player") and entity.Character or entity)
    end
    
    return false
end

-- Target Selection
function AimbotUtil.getBestTarget(cachedTargets, config)
    local closest = nil
    local minDistance = config.FOV
    local mousePos = Services.UserInput:GetMouseLocation()
    
    for _, target in ipairs(cachedTargets) do
        local targetPos = AimbotUtil.getTargetPosition(target, config.TargetPart)
        if not targetPos then continue end
        
        -- Check distance
        local worldDistance = (LocalPlayer.Character:GetPivot().Position - targetPos).Magnitude
        if worldDistance > config.MaxDistance then continue end
        
        -- Check FOV
        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPos)
        if not onScreen then continue end
        
        local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if screenDistance < minDistance then
            if config.VisibilityCheck and not AimbotUtil.isVisible(target, config) then continue end
            
            closest = target
            minDistance = screenDistance
        end
    end
    
    return closest
end

-- Aiming Calculations
function AimbotUtil.calculateAimCFrame(targetPos, smoothness)
    if not targetPos then return nil end
    
    local currentCF = Camera.CFrame
    local targetCF = CFrame.new(currentCF.Position, targetPos)
    
    return currentCF:Lerp(targetCF, smoothness)
end

return AimbotUtil
