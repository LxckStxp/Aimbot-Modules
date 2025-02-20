--[[
    AimbotUtil Module
    Version: 1.1
    Core aimbot calculations and target selection with HumanoidHandler integration
]]

local AimbotUtil = {}

-- Dependencies
local HumanoidHandler = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/HumanoidHandler.lua"))()

-- Services
local Services = {
    Players = game:GetService("Players"),
    UserInput = game:GetService("UserInputService")
}

local Camera = workspace.CurrentCamera
local LocalPlayer = Services.Players.LocalPlayer

function AimbotUtil.isValidAimTarget(model, config)
    if not HumanoidHandler.isValidHumanoid(model) then return false end
    if model == LocalPlayer.Character then return false end
    if not model:FindFirstChild(config.TargetPart) then return false end
    
    local targetPos = AimbotUtil.getTargetPosition(model, config.TargetPart)
    if not targetPos then return false end
    
    local worldDistance = (LocalPlayer.Character:GetPivot().Position - targetPos).Magnitude
    if worldDistance > config.MaxDistance then return false end
    
    local screenPos, onScreen = Camera:WorldToScreenPoint(targetPos)
    if onScreen then
        if not AimbotUtil.isInFOV(screenPos, config.FOV) then return false end
        if config.VisibilityCheck and not AimbotUtil.isVisible(model, config) then return false end
        return true
    end
    
    return false
end

function AimbotUtil.getTargetPosition(model, targetPart)
    local part = model:FindFirstChild(targetPart)
    return part and part.Position
end

function AimbotUtil.isInFOV(screenPos, fov)
    local mousePos = Services.UserInput:GetMouseLocation()
    return (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude <= fov
end

function AimbotUtil.isVisible(model, config)
    local targetPos = AimbotUtil.getTargetPosition(model, config.TargetPart)
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
    
    return result and result.Instance:IsDescendantOf(model)
end

function AimbotUtil.getBestTarget(config)
    local closest = nil
    local minDistance = config.FOV
    local mousePos = Services.UserInput:GetMouseLocation()
    
    for _, model in ipairs(HumanoidHandler.getAllValidHumanoids()) do
        if not AimbotUtil.isValidAimTarget(model, config) then continue end
        
        local targetPos = AimbotUtil.getTargetPosition(model, config.TargetPart)
        local screenPos = Camera:WorldToScreenPoint(targetPos)
        local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if screenDistance < minDistance then
            closest = model
            minDistance = screenDistance
        end
    end
    
    return closest
end

function AimbotUtil.calculateAimCFrame(targetPos, smoothness)
    if not targetPos then return Camera.CFrame end
    
    local currentCF = Camera.CFrame
    local targetCF = CFrame.new(currentCF.Position, targetPos)
    
    return currentCF:Lerp(targetCF, smoothness)
end

return AimbotUtil
