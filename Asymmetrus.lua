--[[
    Combat Enhancement System
    Platform: Roblox
    Version: 1.1.0
]]

-- Load Censura UI Framework
local success, Censura = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()
end)

if not success or not Censura then 
    warn("Failed to load Censura UI Framework")
    return
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Locals
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ToggleKey = Enum.KeyCode.LeftAlt

-- Core System
local AimbotSystem = {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        FOV = {
            Enabled = true,
            Size = 250
        },
        MaxDistance = 1000
    },
    
    Runtime = {
        Active = false,
        FOVCircle = Drawing.new("Circle"),
        TargetHighlight = Instance.new("Highlight")
    }
}

-- Initialize Visual Elements
do
    -- FOV Circle
    AimbotSystem.Runtime.FOVCircle.Visible = true
    AimbotSystem.Runtime.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    AimbotSystem.Runtime.FOVCircle.Thickness = 1.5
    AimbotSystem.Runtime.FOVCircle.NumSides = 60
    AimbotSystem.Runtime.FOVCircle.Radius = AimbotSystem.Settings.FOV.Size
    
    -- Target Highlight
    AimbotSystem.Runtime.TargetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
    AimbotSystem.Runtime.TargetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    AimbotSystem.Runtime.TargetHighlight.FillTransparency = 0.5
    AimbotSystem.Runtime.TargetHighlight.OutlineTransparency = 0
end

-- Target Acquisition System
local function GetTarget()
    local closest = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if AimbotSystem.Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        
        if not (humanoid and humanoid.Health > 0 and head) then continue end
        
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        
        local screenPos = Vector2.new(pos.X, pos.Y)
        local distance = (head.Position - Camera.CFrame.Position).Magnitude
        
        if distance > AimbotSystem.Settings.MaxDistance then continue end
        
        local fovDistance = (screenPos - mousePos).Magnitude
        if fovDistance > AimbotSystem.Settings.FOV.Size then continue end
        
        if fovDistance < shortestDistance then
            shortestDistance = fovDistance
            closest = {
                Player = player,
                Character = character,
                Head = head,
                Distance = distance
            }
        end
    end
    
    return closest
end

-- Visibility Check System
local function IsVisible(target)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, target.Character}
    
    local origin = Camera.CFrame.Position
    local direction = target.Head.Position - origin
    
    local result = workspace:Raycast(origin, direction, rayParams)
    return not result
end

-- Core Update Function
local function Update()
    -- Update FOV Circle
    if AimbotSystem.Settings.FOV.Enabled then
        AimbotSystem.Runtime.FOVCircle.Position = UserInputService:GetMouseLocation()
        AimbotSystem.Runtime.FOVCircle.Radius = AimbotSystem.Settings.FOV.Size
        AimbotSystem.Runtime.FOVCircle.Visible = true
    else
        AimbotSystem.Runtime.FOVCircle.Visible = false
    end
    
    -- Check if system should be active
    if not (AimbotSystem.Settings.Enabled and AimbotSystem.Runtime.Active) then
        AimbotSystem.Runtime.TargetHighlight.Parent = nil
        return
    end
    
    -- Get and validate target
    local target = GetTarget()
    if not target then
        AimbotSystem.Runtime.TargetHighlight.Parent = nil
        return
    end
    
    -- Update target highlight
    local isVisible = IsVisible(target)
    AimbotSystem.Runtime.TargetHighlight.FillColor = isVisible and 
        Color3.fromRGB(255, 0, 0) or 
        Color3.fromRGB(255, 255, 255)
    AimbotSystem.Runtime.TargetHighlight.Parent = target.Character
    
    -- Update aim
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Head.Position)
    
    -- Move mouse
    local pos = Camera:WorldToViewportPoint(target.Head.Position)
    local mousePos = UserInputService:GetMouseLocation()
    mousemoverel(
        (pos.X - mousePos.X),
        (pos.Y - mousePos.Y)
    )
end

-- Input Handler
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == ToggleKey then
        AimbotSystem.Runtime.Active = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == ToggleKey then
        AimbotSystem.Runtime.Active = false
        AimbotSystem.Runtime.TargetHighlight.Parent = nil
    end
end)

-- UI System
local function CreateUI()
    local window = Censura:CreateWindow({
        title = "Combat Enhancement",
        size = UDim2.new(0, 250, 0, 200)
    })
    
    -- Main Settings
    window:AddButton({ label = "Main Settings" })
    
    window:AddToggle({
        label = "Enable System",
        default = AimbotSystem.Settings.Enabled,
        callback = function(state)
            AimbotSystem.Settings.Enabled = state
            print("System Enabled:", state) -- Debug print
        end
    })
    
    window:AddToggle({
        label = "Team Check",
        default = AimbotSystem.Settings.TeamCheck,
        callback = function(state)
            AimbotSystem.Settings.TeamCheck = state
        end
    })
    
    -- FOV Settings
    window:AddButton({ label = "FOV Settings" })
    
    window:AddToggle({
        label = "Show FOV",
        default = AimbotSystem.Settings.FOV.Enabled,
        callback = function(state)
            AimbotSystem.Settings.FOV.Enabled = state
            AimbotSystem.Runtime.FOVCircle.Visible = state
        end
    })
    
    window:AddSlider({
        label = "FOV Size",
        min = 50,
        max = 800,
        default = AimbotSystem.Settings.FOV.Size,
        callback = function(value)
            AimbotSystem.Settings.FOV.Size = value
            AimbotSystem.Runtime.FOVCircle.Radius = value
        end
    })
    
    window:AddSlider({
        label = "Max Distance",
        min = 100,
        max = 2000,
        default = AimbotSystem.Settings.MaxDistance,
        callback = function(value)
            AimbotSystem.Settings.MaxDistance = value
        end
    })
    
    return window
end

-- Initialize System
local function Initialize()
    -- Create UI
    local window = CreateUI()
    
    -- Setup update loop
    RunService.RenderStepped:Connect(Update)
    
    return window
end

-- Cleanup System
local function Cleanup()
    if AimbotSystem.Runtime.FOVCircle then
        AimbotSystem.Runtime.FOVCircle:Remove()
    end
    
    if AimbotSystem.Runtime.TargetHighlight then
        AimbotSystem.Runtime.TargetHighlight:Destroy()
    end
end

-- Create Instance
local Window = Initialize()

-- Return API
return {
    Window = Window,
    Cleanup = Cleanup
}
