--[[
    Advanced Aimbot System
    Using Censura UI Framework v2.0.0
    Author: Professional Implementation
]]

-- Load Censura UI System
local Censura = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()

-- Services
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInput = game:GetService("UserInputService")
}

local Camera = workspace.CurrentCamera
local LocalPlayer = Services.Players.LocalPlayer

-- Aimbot Core
local AimbotCore = {
    Settings = {
        Enabled = false,
        AimKey = Enum.KeyCode.LeftAlt,
        TargetMode = "Head",
        Prediction = {
            Enabled = true,
            Amount = 0.165
        },
        Smoothing = {
            Enabled = true,
            Amount = 0.6
        },
        FOV = {
            Enabled = true,
            Size = 200,
            Color = Color3.fromRGB(255, 255, 255),
            Filled = false,
            Transparency = 1
        },
        MaxDistance = 1000,
        VisibilityCheck = true,
        TeamCheck = false,
        TargetPriority = "Distance"
    },
    
    Runtime = {
        CurrentCFrame = Camera.CFrame,
        FOVCircle = Drawing.new("Circle"),
        Connections = {}
    }
}

-- Initialize FOV Circle
do
    local circle = AimbotCore.Runtime.FOVCircle
    circle.Thickness = 1
    circle.NumSides = 100
    circle.Filled = AimbotCore.Settings.FOV.Filled
    circle.Transparency = AimbotCore.Settings.FOV.Transparency
    circle.Color = AimbotCore.Settings.FOV.Color
end

-- Utility Functions
local function IsVisible(part)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
    
    local result = workspace:Raycast(origin, direction, rayParams)
    return result and result.Instance:IsDescendantOf(part.Parent)
end

local function GetTargetPart(character)
    if AimbotCore.Settings.TargetMode == "Random" then
        local parts = {"Head", "UpperTorso", "LowerTorso"}
        return character:FindFirstChild(parts[math.random(1, #parts)])
    end
    return character:FindFirstChild(AimbotCore.Settings.TargetMode)
end

local function GetClosestTarget()
    local closest = nil
    local shortestDistance = math.huge
    local mousePos = Services.UserInput:GetMouseLocation()
    
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and 
           (not AimbotCore.Settings.TeamCheck or player.Team ~= LocalPlayer.Team) then
            
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                local targetPart = GetTargetPart(character)
                
                if humanoid and humanoid.Health > 0 and targetPart then
                    local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
                    
                    if onScreen and distance <= AimbotCore.Settings.MaxDistance then
                        local screenPos = Vector2.new(pos.X, pos.Y)
                        local fovDistance = (screenPos - mousePos).Magnitude
                        
                        if fovDistance <= AimbotCore.Settings.FOV.Size and
                           (not AimbotCore.Settings.VisibilityCheck or IsVisible(targetPart)) then
                            
                            if fovDistance < shortestDistance then
                                shortestDistance = fovDistance
                                closest = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

-- Main Update Function
local function UpdateAimbot()
    if not AimbotCore.Settings.Enabled or 
       not Services.UserInput:IsKeyDown(AimbotCore.Settings.AimKey) then
        AimbotCore.Runtime.CurrentCFrame = Camera.CFrame
        return
    end
    
    local target = GetClosestTarget()
    if not target then return end
    
    local targetPos = target.Position
    if AimbotCore.Settings.Prediction.Enabled then
        targetPos = targetPos + (target.AssemblyLinearVelocity * AimbotCore.Settings.Prediction.Amount)
    end
    
    local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    
    if AimbotCore.Settings.Smoothing.Enabled then
        AimbotCore.Runtime.CurrentCFrame = AimbotCore.Runtime.CurrentCFrame:Lerp(
            targetCFrame,
            AimbotCore.Settings.Smoothing.Amount
        )
    else
        AimbotCore.Runtime.CurrentCFrame = targetCFrame
    end
    
    Camera.CFrame = AimbotCore.Runtime.CurrentCFrame
end

-- Create UI
local window = Censura:CreateWindow({
    title = "Advanced Aimbot",
    theme = "Dark"
})

local container = Components.CreateContainer({
    name = "AimbotContainer",
    parent = window.Frame
})

-- Main Settings
container.AddLabel({
    text = "Main Settings"
})

container.AddToggle({
    name = "EnableAimbot",
    label = "Enable Aimbot",
    default = AimbotCore.Settings.Enabled,
    callback = function(state)
        AimbotCore.Settings.Enabled = state
    end
})

container.AddToggle({
    name = "TeamCheck",
    label = "Team Check",
    default = AimbotCore.Settings.TeamCheck,
    callback = function(state)
        AimbotCore.Settings.TeamCheck = state
    end
})

container.AddToggle({
    name = "VisibilityCheck",
    label = "Visibility Check",
    default = AimbotCore.Settings.VisibilityCheck,
    callback = function(state)
        AimbotCore.Settings.VisibilityCheck = state
    end
})

-- FOV Settings
container.AddSeparator({})
container.AddLabel({
    text = "FOV Settings"
})

container.AddToggle({
    name = "ShowFOV",
    label = "Show FOV Circle",
    default = AimbotCore.Settings.FOV.Enabled,
    callback = function(state)
        AimbotCore.Settings.FOV.Enabled = state
    end
})

container.AddSlider({
    name = "FOVSize",
    label = "FOV Size",
    min = 10,
    max = 800,
    default = AimbotCore.Settings.FOV.Size,
    callback = function(value)
        AimbotCore.Settings.FOV.Size = value
    end
})

-- Prediction Settings
container.AddSeparator({})
container.AddLabel({
    text = "Prediction Settings"
})

container.AddToggle({
    name = "Prediction",
    label = "Enable Prediction",
    default = AimbotCore.Settings.Prediction.Enabled,
    callback = function(state)
        AimbotCore.Settings.Prediction.Enabled = state
    end
})

container.AddSlider({
    name = "PredictionAmount",
    label = "Prediction Amount",
    min = 0,
    max = 1,
    default = AimbotCore.Settings.Prediction.Amount,
    callback = function(value)
        AimbotCore.Settings.Prediction.Amount = value
    end
})

-- Smoothing Settings
container.AddSeparator({})
container.AddLabel({
    text = "Smoothing Settings"
})

container.AddToggle({
    name = "Smoothing",
    label = "Enable Smoothing",
    default = AimbotCore.Settings.Smoothing.Enabled,
    callback = function(state)
        AimbotCore.Settings.Smoothing.Enabled = state
    end
})

container.AddSlider({
    name = "SmoothingAmount",
    label = "Smoothing Amount",
    min = 0,
    max = 1,
    default = AimbotCore.Settings.Smoothing.Amount,
    callback = function(value)
        AimbotCore.Settings.Smoothing.Amount = value
    end
})

-- Setup Update Loop
AimbotCore.Runtime.Connections.Update = Services.RunService.RenderStepped:Connect(function()
    if AimbotCore.Settings.FOV.Enabled then
        AimbotCore.Runtime.FOVCircle.Position = Services.UserInput:GetMouseLocation()
        AimbotCore.Runtime.FOVCircle.Radius = AimbotCore.Settings.FOV.Size
        AimbotCore.Runtime.FOVCircle.Visible = true
    else
        AimbotCore.Runtime.FOVCircle.Visible = false
    end
    
    UpdateAimbot()
end)

-- Cleanup Function
local function Cleanup()
    for _, connection in pairs(AimbotCore.Runtime.Connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    AimbotCore.Runtime.FOVCircle:Remove()
    container.Destroy()
end

return {
    Core = AimbotCore,
    Window = window,
    Container = container,
    Cleanup = Cleanup
}
