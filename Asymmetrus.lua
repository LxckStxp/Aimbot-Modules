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
    
    local sections = {
        Main = {
            { type = "toggle", label = "Enable Aimbot", bind = "Enabled" },
            { type = "toggle", label = "Team Check", bind = "TeamCheck" },
            { type = "toggle", label = "Visibility Check", bind = "VisibilityCheck" }
        },
        FOV = {
            { type = "toggle", label = "Show FOV Circle", bind = "FOV.Enabled" },
            { type = "slider", label = "FOV Size", bind = "FOV.Size", min = 10, max = 800 }
        },
        Prediction = {
            { type = "toggle", label = "Enable Prediction", bind = "Prediction.Enabled" },
            { type = "slider", label = "Prediction Amount", bind = "Prediction.Amount", min = 0, max = 1 }
        },
        Smoothing = {
            { type = "toggle", label = "Enable Smoothing", bind = "Smoothing.Enabled" },
            { type = "slider", label = "Smoothing Amount", bind = "Smoothing.Amount", min = 0, max = 1 }
        }
    }
    
    -- Create sections
    local container = window:AddContainer()
    
    for sectionName, elements in pairs(sections) do
        container:AddLabel({ text = sectionName .. " Settings" })
        
        for _, element in ipairs(elements) do
            if element.type == "toggle" then
                container:AddToggle({
                    label = element.label,
                    default = Aimbot.Settings[element.bind],
                    callback = function(state)
                        local path = element.bind:split(".")
                        local target = Aimbot.Settings
                        
                        for i = 1, #path - 1 do
                            target = target[path[i]]
                        end
                        
                        target[path[#path]] = state
                    end
                })
            elseif element.type == "slider" then
                container:AddSlider({
                    label = element.label,
                    min = element.min,
                    max = element.max,
                    default = Aimbot.Settings[element.bind],
                    callback = function(value)
                        local path = element.bind:split(".")
                        local target = Aimbot.Settings
                        
                        for i = 1, #path - 1 do
                            target = target[path[i]]
                        end
                        
                        target[path[#path]] = value
                    end
                })
            end
        end
    end
    
    return {
        Window = window,
        Container = container
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
