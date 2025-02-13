--[[
    Advanced Aimbot System
    Using Censura UI Framework v2.0.0
    Author: Professional Implementation
]]

-- Load Censura
local success, Censura = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()
end)

if not success or not Censura then 
    error("Failed to load Censura UI Framework")
end

-- Services & Locals
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInput = game:GetService("UserInputService")
}

local Camera = workspace.CurrentCamera
local LocalPlayer = Services.Players.LocalPlayer

-- Aimbot Core
local Aimbot = {
    Settings = {
        Enabled = false,
        AimKey = Enum.KeyCode.LeftAlt,
        TargetPart = "Head",
        Prediction = { Enabled = true, Amount = 0.165 },
        Smoothing = { Enabled = true, Amount = 0.6 },
        FOV = {
            Enabled = true,
            Size = 200,
            Color = Color3.fromRGB(255, 255, 255),
            Filled = false,
            Transparency = 1
        },
        MaxDistance = 1000,
        VisibilityCheck = true,
        TeamCheck = false
    },
    
    Runtime = {
        FOVCircle = Drawing.new("Circle"),
        CurrentCFrame = Camera.CFrame,
        Connections = {}
    }
}

-- Initialize FOV Circle
do
    local circle = Aimbot.Runtime.FOVCircle
    for prop, value in pairs(Aimbot.Settings.FOV) do
        if circle[prop] ~= nil then
            circle[prop] = value
        end
    end
    circle.Thickness = 1
    circle.NumSides = 100
end

-- Target System
local TargetSystem = {
    GetPart = function(character)
        return character:FindFirstChild(Aimbot.Settings.TargetPart)
    end,
    
    IsVisible = function(part)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        
        local origin = Camera.CFrame.Position
        local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
        
        local result = workspace:Raycast(origin, direction, params)
        return result and result.Instance:IsDescendantOf(part.Parent)
    end,
    
    GetClosest = function()
        local closest, shortestDistance = nil, math.huge
        local mousePos = Services.UserInput:GetMouseLocation()
        
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player ~= LocalPlayer and 
               (not Aimbot.Settings.TeamCheck or player.Team ~= LocalPlayer.Team) then
                
                local character = player.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    local targetPart = TargetSystem.GetPart(character)
                    
                    if humanoid and humanoid.Health > 0 and targetPart then
                        local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
                        
                        if onScreen and distance <= Aimbot.Settings.MaxDistance then
                            local screenPos = Vector2.new(pos.X, pos.Y)
                            local fovDistance = (screenPos - mousePos).Magnitude
                            
                            if fovDistance <= Aimbot.Settings.FOV.Size and
                               (not Aimbot.Settings.VisibilityCheck or TargetSystem.IsVisible(targetPart)) then
                                
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
}

-- Aim System
local function UpdateAim()
    if not (Aimbot.Settings.Enabled and Services.UserInput:IsKeyDown(Aimbot.Settings.AimKey)) then
        Aimbot.Runtime.CurrentCFrame = Camera.CFrame
        return
    end
    
    local target = TargetSystem.GetClosest()
    if not target then return end
    
    local targetPos = target.Position
    if Aimbot.Settings.Prediction.Enabled then
        targetPos = targetPos + (target.AssemblyLinearVelocity * Aimbot.Settings.Prediction.Amount)
    end
    
    local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    
    if Aimbot.Settings.Smoothing.Enabled then
        Aimbot.Runtime.CurrentCFrame = Aimbot.Runtime.CurrentCFrame:Lerp(
            targetCFrame,
            Aimbot.Settings.Smoothing.Amount
        )
    else
        Aimbot.Runtime.CurrentCFrame = targetCFrame
    end
    
    Camera.CFrame = Aimbot.Runtime.CurrentCFrame
end

-- Create UI
local function CreateUI()
    local window = Censura:CreateWindow({
        title = "Advanced Aimbot",
        size = UDim2.new(0, 300, 0, 400)
    })

    -- Main Settings
    window:AddButton({ label = "Main Settings" })
    
    window:AddToggle({
        label = "Enable Aimbot",
        default = Aimbot.Settings.Enabled,
        callback = function(state)
            Aimbot.Settings.Enabled = state
        end
    })
    
    window:AddToggle({
        label = "Team Check",
        default = Aimbot.Settings.TeamCheck,
        callback = function(state)
            Aimbot.Settings.TeamCheck = state
        end
    })
    
    window:AddToggle({
        label = "Visibility Check",
        default = Aimbot.Settings.VisibilityCheck,
        callback = function(state)
            Aimbot.Settings.VisibilityCheck = state
        end
    })

    -- FOV Settings
    window:AddButton({ label = "FOV Settings" })
    
    window:AddToggle({
        label = "Show FOV Circle",
        default = Aimbot.Settings.FOV.Enabled,
        callback = function(state)
            Aimbot.Settings.FOV.Enabled = state
        end
    })
    
    window:AddSlider({
        label = "FOV Size",
        min = 10,
        max = 800,
        default = Aimbot.Settings.FOV.Size,
        callback = function(value)
            Aimbot.Settings.FOV.Size = value
        end
    })

    -- Prediction Settings
    window:AddButton({ label = "Prediction Settings" })
    
    window:AddToggle({
        label = "Enable Prediction",
        default = Aimbot.Settings.Prediction.Enabled,
        callback = function(state)
            Aimbot.Settings.Prediction.Enabled = state
        end
    })
    
    window:AddSlider({
        label = "Prediction Amount",
        min = 0,
        max = 1,
        default = Aimbot.Settings.Prediction.Amount,
        callback = function(value)
            Aimbot.Settings.Prediction.Amount = value
        end
    })

    -- Smoothing Settings
    window:AddButton({ label = "Smoothing Settings" })
    
    window:AddToggle({
        label = "Enable Smoothing",
        default = Aimbot.Settings.Smoothing.Enabled,
        callback = function(state)
            Aimbot.Settings.Smoothing.Enabled = state
        end
    })
    
    window:AddSlider({
        label = "Smoothing Amount",
        min = 0,
        max = 1,
        default = Aimbot.Settings.Smoothing.Amount,
        callback = function(value)
            Aimbot.Settings.Smoothing.Amount = value
        end
    })

    return {
        Window = window
    }
end

-- Initialize
local function Initialize()
    local ui = CreateUI()
    
    -- Setup update loop
    Aimbot.Runtime.Connections.Update = Services.RunService.RenderStepped:Connect(function()
        -- Update FOV Circle
        Aimbot.Runtime.FOVCircle.Position = Services.UserInput:GetMouseLocation()
        Aimbot.Runtime.FOVCircle.Radius = Aimbot.Settings.FOV.Size
        Aimbot.Runtime.FOVCircle.Visible = Aimbot.Settings.FOV.Enabled
        
        -- Update Aimbot
        UpdateAim()
    end)
    
    return ui
end

-- Cleanup
local function Cleanup()
    for _, connection in pairs(Aimbot.Runtime.Connections) do
        connection:Disconnect()
    end
    Aimbot.Runtime.FOVCircle:Remove()
end

-- Create instance
local UI = Initialize()

return {
    Core = Aimbot,
    Window = UI.Window,
    Container = UI.Container,
    Cleanup = Cleanup
}
