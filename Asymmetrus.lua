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
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    VirtualUser = game:GetService("VirtualUser"),
    GuiService = game:GetService("GuiService")
}

-- Locals
local Camera = workspace.CurrentCamera
local LocalPlayer = Services.Players.LocalPlayer

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
        Connections = {}
    }
}

-- Initialize FOV Circle
do
    local circle = Aimbot.Runtime.Circle
    circle.Thickness = 1
    circle.NumSides = 36
    circle.Radius = Aimbot.Settings.FOVCircle.Size
    circle.Filled = false
    circle.Transparency = 1
    circle.Color = Color3.new(1, 1, 1)
    circle.Visible = Aimbot.Settings.FOVCircle.Enabled
end

-- Target Acquisition
local function GetTarget()
    local closest = nil
    local shortestDistance = math.huge
    local mousePos = Services.UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Services.Players:GetPlayers()) do
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

-- Aiming System
local function UpdateAim()
    -- Validate aimbot state
    if not (Aimbot.Settings.Enabled and Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)) then
        return
    end
    
    -- Get target
    local target = GetTarget()
    if not target then return end
    
    -- Calculate aim position
    local pos, onScreen = Camera:WorldToViewportPoint(target.Position)
    if not onScreen then return end
    
    -- Update mouse and camera
    local targetPos = Vector2.new(pos.X, pos.Y)
    
    -- Move mouse to target
    mousemoveabs(targetPos.X, targetPos.Y)
    
    -- Update camera
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
end

-- User Interface
local function CreateUI()
    local window = Censura:CreateWindow({
        title = "Combat Assistance",
        size = UDim2.new(0, 250, 0, 200)
    })
    
    -- Main Settings
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
    
    -- FOV Settings
    window:AddButton({ label = "FOV Settings" })
    
    window:AddToggle({
        label = "Show FOV",
        default = Aimbot.Settings.FOVCircle.Enabled,
        callback = function(state)
            Aimbot.Settings.FOVCircle.Enabled = state
            Aimbot.Runtime.Circle.Visible = state
        end
    })
    
    window:AddSlider({
        label = "FOV Size",
        min = 50,
        max = 800,
        default = Aimbot.Settings.FOVCircle.Size,
        callback = function(value)
            Aimbot.Settings.FOVCircle.Size = value
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

-- System Initialization
local function Initialize()
    local window = CreateUI()
    
    -- Setup update loop
    Aimbot.Runtime.Connections.Update = Services.RunService.RenderStepped:Connect(function()
        -- Update FOV Circle
        if Aimbot.Settings.FOVCircle.Enabled then
            Aimbot.Runtime.Circle.Position = Services.UserInputService:GetMouseLocation()
            Aimbot.Runtime.Circle.Visible = true
        else
            Aimbot.Runtime.Circle.Visible = false
        end
        
        -- Update Aimbot
        UpdateAim()
    end)
    
    return window
end

-- Cleanup System
local function Cleanup()
    for _, connection in pairs(Aimbot.Runtime.Connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    
    if Aimbot.Runtime.Circle then
        Aimbot.Runtime.Circle:Remove()
    end
end

-- Create Instance
local Window = Initialize()

-- Return API
return {
    Window = Window,
    Cleanup = Cleanup
}
