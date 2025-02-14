--[[
    Simple Aimbot System
    Platform: Roblox
    Version: 1.0.0
]]

-- Load Censura UI Framework
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
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Aimbot Core
local Aimbot = {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        FOVCircle = {
            Enabled = true,
            Size = 200
        },
        MaxDistance = 1000
    },
    
    Runtime = {
        Circle = Drawing.new("Circle"),
        Connections = {},
        Active = false
    }
}

-- Initialize FOV Circle
do
    local circle = Aimbot.Runtime.Circle
    circle.Thickness = 2
    circle.NumSides = 48
    circle.Radius = Aimbot.Settings.FOVCircle.Size
    circle.Filled = false
    circle.Transparency = 1
    circle.Color = Color3.new(1, 1, 1)
    circle.Visible = true
end

-- Get Closest Target
local function GetTarget()
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
                    local distance = (head.Position - Camera.CFrame.Position).Magnitude
                    
                    if onScreen and distance <= Aimbot.Settings.MaxDistance then
                        local screenPos = Vector2.new(pos.X, pos.Y)
                        local fovDistance = (screenPos - mousePos).Magnitude
                        
                        if fovDistance <= Aimbot.Settings.FOVCircle.Size and fovDistance < shortestDistance then
                            shortestDistance = fovDistance
                            closest = head
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

-- Handle Input
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        Aimbot.Runtime.Active = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        Aimbot.Runtime.Active = false
    end
end)

-- Update Function
local function Update()
    -- Update FOV Circle
    if Aimbot.Settings.FOVCircle.Enabled then
        Aimbot.Runtime.Circle.Position = UserInputService:GetMouseLocation()
        Aimbot.Runtime.Circle.Radius = Aimbot.Settings.FOVCircle.Size
        Aimbot.Runtime.Circle.Visible = true
    else
        Aimbot.Runtime.Circle.Visible = false
    end
    
    -- Check if aimbot should be active
    if not (Aimbot.Settings.Enabled and Aimbot.Runtime.Active) then
        return
    end
    
    -- Get and validate target
    local target = GetTarget()
    if not target then return end
    
    -- Calculate aim position
    local pos, onScreen = Camera:WorldToViewportPoint(target.Position)
    if not onScreen then return end
    
    -- Move mouse and camera
    mousemoverel(
        (pos.X - UserInputService:GetMouseLocation().X) * 0.5,
        (pos.Y - UserInputService:GetMouseLocation().Y) * 0.5
    )
end

-- Create UI
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
        default = Aimbot.Settings.FOVCircle.Enabled,
        callback = function(state)
            Aimbot.Settings.FOVCircle.Enabled = state
        end
    })
    
    window:AddSlider({
        label = "FOV Size",
        min = 50,
        max = 800,
        default = Aimbot.Settings.FOVCircle.Size,
        callback = function(value)
            Aimbot.Settings.FOVCircle.Size = value
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
    Aimbot.Runtime.Connections.Update = RunService.RenderStepped:Connect(Update)
    
    return window
end

-- Cleanup
local function Cleanup()
    for _, connection in pairs(Aimbot.Runtime.Connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    Aimbot.Runtime.Circle:Remove()
end

-- Create instance
local Window = Initialize()

return {
    Window = Window,
    Cleanup = Cleanup
}
