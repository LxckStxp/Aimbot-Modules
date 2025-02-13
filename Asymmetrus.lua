--[[
    Advanced Aimbot System
    Using Censura UI Framework v2.0.0
    Author: Professional Implementation
]]

-- Load Censura UI System
local success, Censura = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()
end)

if not success then error("Failed to load Censura UI Framework: \n"..Censura) end

-- Services
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInput = game:GetService("UserInputService")
}

local Camera = workspace.CurrentCamera
local LocalPlayer = Services.Players.LocalPlayer

-- Create Aimbot Module
local Aimbot = {
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
    local circle = Aimbot.Runtime.FOVCircle
    circle.Thickness = 1
    circle.NumSides = 100
    circle.Filled = Aimbot.Settings.FOV.Filled
    circle.Transparency = Aimbot.Settings.FOV.Transparency
    circle.Color = Aimbot.Settings.FOV.Color
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

-- Target Selection Logic
local TargetSystem = {
    GetPart = function(character)
        if Aimbot.Settings.TargetMode == "Random" then
            local parts = {"Head", "UpperTorso", "LowerTorso"}
            return character:FindFirstChild(parts[math.random(1, #parts)])
        end
        return character:FindFirstChild(Aimbot.Settings.TargetMode)
    end,
    
    GetClosest = function()
        local closest = nil
        local shortestDistance = math.huge
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
                               (not Aimbot.Settings.VisibilityCheck or IsVisible(targetPart)) then
                                
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

-- Aiming System
local AimSystem = {
    Update = function()
        if not Aimbot.Settings.Enabled or 
           not Services.UserInput:IsKeyDown(Aimbot.Settings.AimKey) then
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
}

-- Create UI
local function CreateUI()
    local window = Censura:CreateWindow({
        title = "Advanced Aimbot",
        theme = "Dark"
    })

    -- Use Censura's Components system
    local container = Censura.System.Components.Create.Container({
        name = "AimbotContainer",
        parent = window.Frame
    })

    -- Main Settings Section
    container:AddLabel({ text = "Main Settings" })

    container:AddToggle({
        name = "EnableAimbot",
        label = "Enable Aimbot",
        default = Aimbot.Settings.Enabled,
        callback = function(state)
            Aimbot.Settings.Enabled = state
        end
    })

    container:AddToggle({
        name = "TeamCheck",
        label = "Team Check",
        default = Aimbot.Settings.TeamCheck,
        callback = function(state)
            Aimbot.Settings.TeamCheck = state
        end
    })

    -- FOV Settings Section
    container:AddLabel({ text = "FOV Settings" })

    container:AddToggle({
        name = "ShowFOV",
        label = "Show FOV Circle",
        default = Aimbot.Settings.FOV.Enabled,
        callback = function(state)
            Aimbot.Settings.FOV.Enabled = state
        end
    })

    container:AddSlider({
        name = "FOVSize",
        label = "FOV Size",
        min = 10,
        max = 800,
        default = Aimbot.Settings.FOV.Size,
        callback = function(value)
            Aimbot.Settings.FOV.Size = value
        end
    })

    -- Prediction Settings Section
    container:AddLabel({ text = "Prediction Settings" })

    container:AddToggle({
        name = "Prediction",
        label = "Enable Prediction",
        default = Aimbot.Settings.Prediction.Enabled,
        callback = function(state)
            Aimbot.Settings.Prediction.Enabled = state
        end
    })

    container:AddSlider({
        name = "PredictionAmount",
        label = "Prediction Amount",
        min = 0,
        max = 1,
        default = Aimbot.Settings.Prediction.Amount,
        callback = function(value)
            Aimbot.Settings.Prediction.Amount = value
        end
    })

    -- Smoothing Settings Section
    container:AddLabel({ text = "Smoothing Settings" })

    container:AddToggle({
        name = "Smoothing",
        label = "Enable Smoothing",
        default = Aimbot.Settings.Smoothing.Enabled,
        callback = function(state)
            Aimbot.Settings.Smoothing.Enabled = state
        end
    })

    container:AddSlider({
        name = "SmoothingAmount",
        label = "Smoothing Amount",
        min = 0,
        max = 1,
        default = Aimbot.Settings.Smoothing.Amount,
        callback = function(value)
            Aimbot.Settings.Smoothing.Amount = value
        end
    })

    return {
        Window = window,
        Container = container
    }
end

-- Initialize
local function Initialize()
    local ui = CreateUI()
    
    -- Setup Update Loop
    Aimbot.Runtime.Connections.Update = Services.RunService.RenderStepped:Connect(function()
        -- Update FOV Circle
        if Aimbot.Settings.FOV.Enabled then
            Aimbot.Runtime.FOVCircle.Position = Services.UserInput:GetMouseLocation()
            Aimbot.Runtime.FOVCircle.Radius = Aimbot.Settings.FOV.Size
            Aimbot.Runtime.FOVCircle.Visible = true
        else
            Aimbot.Runtime.FOVCircle.Visible = false
        end
        
        -- Update Aimbot
        AimSystem.Update()
    end)
    
    return ui
end

-- Cleanup
local function Cleanup()
    for _, connection in pairs(Aimbot.Runtime.Connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    Aimbot.Runtime.FOVCircle:Remove()
end

-- Create Instance
local UI = Initialize()

return {
    Core = Aimbot,
    Window = UI.Window,
    Container = UI.Container,
    Cleanup = Cleanup
}
