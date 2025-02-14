--[[
    Combat Assistance System
    Version: 1.0.0
]]

-- Load Censura UI
local success, Censura = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()
end)

if not success or not Censura then 
    error("Failed to load Censura UI Framework")
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Locals
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Main Module
local Aimbot = {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        FOV = {
            Enabled = true,
            Size = 200
        },
        MaxDistance = 1000
    },
    
    Runtime = {
        Circle = Drawing.new("Circle"),
        Highlight = Instance.new("Highlight"),
        Active = false
    }
}

-- Initialize Visual Elements
do
    -- FOV Circle Setup
    local circle = Aimbot.Runtime.Circle
    circle.Thickness = 2
    circle.NumSides = 48
    circle.Radius = Aimbot.Settings.FOV.Size
    circle.Filled = false
    circle.Transparency = 1
    circle.Color = Color3.new(1, 1, 1)
    circle.Visible = true
    
    -- Highlight Setup
    local highlight = Aimbot.Runtime.Highlight
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

-- Target Acquisition
local function GetClosestTarget()
    local closest = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and 
           (not Aimbot.Settings.TeamCheck or player.Team ~= LocalPlayer.Team) then
            
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                local head = character:FindFirstChild("Head")
                
                if humanoid and humanoid.Health > 0 and head then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if not onScreen then continue end
                    
                    local distance = (head.Position - Camera.CFrame.Position).Magnitude
                    if distance > Aimbot.Settings.MaxDistance then continue end
                    
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local fovDistance = (screenPos - mousePos).Magnitude
                    
                    if fovDistance <= Aimbot.Settings.FOV.Size and fovDistance < shortestDistance then
                        shortestDistance = fovDistance
                        closest = {
                            Instance = head,
                            Position = head.Position,
                            Character = character
                        }
                    end
                end
            end
        end
    end
    
    return closest
end

-- Visibility Check
local function IsVisible(target)
    local origin = Camera.CFrame.Position
    local direction = (target.Position - origin).Unit
    local distance = (target.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = workspace:Raycast(origin, direction * distance, raycastParams)
    return not result or result.Instance:IsDescendantOf(target.Character)
end

-- Input Handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        Aimbot.Runtime.Active = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        Aimbot.Runtime.Active = false
        Aimbot.Runtime.Highlight.Parent = nil
    end
end)

-- Update Function
local function Update()
    -- Update FOV Circle
    if Aimbot.Settings.FOV.Enabled then
        Aimbot.Runtime.Circle.Position = UserInputService:GetMouseLocation()
        Aimbot.Runtime.Circle.Radius = Aimbot.Settings.FOV.Size
        Aimbot.Runtime.Circle.Visible = true
    else
        Aimbot.Runtime.Circle.Visible = false
    end
    
    -- Check if aimbot should run
    if not (Aimbot.Settings.Enabled and Aimbot.Runtime.Active) then
        Aimbot.Runtime.Highlight.Parent = nil
        return
    end
    
    -- Get target
    local target = GetClosestTarget()
    if not target then
        Aimbot.Runtime.Highlight.Parent = nil
        return
    end
    
    -- Update highlight
    local visible = IsVisible(target)
    Aimbot.Runtime.Highlight.FillColor = visible and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
    Aimbot.Runtime.Highlight.Parent = target.Character
    
    -- Update aim
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
    
    -- Move mouse
    local pos = Camera:WorldToViewportPoint(target.Position)
    local mousePos = UserInputService:GetMouseLocation()
    mousemoverel(
        (pos.X - mousePos.X),
        (pos.Y - mousePos.Y)
    )
end

-- UI Creation
local function CreateUI()
    local window = Censura:CreateWindow({
        title = "Combat Assistance",
        size = UDim2.new(0, 250, 0, 200)
    })
    
    window:AddButton({ label = "Main Settings" })
    
    window:AddToggle({
        label = "Enable",
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
    
    window:AddButton({ label = "FOV Settings" })
    
    window:AddToggle({
        label = "Show FOV",
        default = Aimbot.Settings.FOV.Enabled,
        callback = function(state)
            Aimbot.Settings.FOV.Enabled = state
        end
    })
    
    window:AddSlider({
        label = "FOV Size",
        min = 50,
        max = 800,
        default = Aimbot.Settings.FOV.Size,
        callback = function(value)
            Aimbot.Settings.FOV.Size = value
            Aimbot.Runtime.Circle.Radius = value
        end
    })
    
    window:AddSlider({
        label = "Max Distance",
        min = 100,
        max = 2000,
        default = Aimbot.Settings.MaxDistance,
        callback = function(value)
            Aimbot.Settings.MaxDistance = value
        end
    })
    
    return window
end

-- Initialize
local function Initialize()
    local window = CreateUI()
    
    -- Setup update loop
    RunService.RenderStepped:Connect(Update)
    
    return window
end

-- Cleanup
local function Cleanup()
    Aimbot.Runtime.Circle:Remove()
    Aimbot.Runtime.Highlight:Destroy()
end

-- Create instance
local Window = Initialize()

return {
    Window = Window,
    Cleanup = Cleanup
}
