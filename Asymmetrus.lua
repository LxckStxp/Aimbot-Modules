--[[
    Advanced Combat Assistance System
    Features:
    - Smooth mouse and camera movement
    - Visual target highlighting
    - FOV circle
    - Line of sight checking
    - Team check system
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

-- Highlight System
local function CreateHighlight()
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.new(1, 0, 0) -- Red for visible
    highlight.OutlineColor = Color3.new(1, 1, 1) -- White outline
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    return highlight
end

-- Aimbot Core
local Aimbot = {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        FOVCircle = {
            Enabled = true,
            Size = 200
        },
        MaxDistance = 1000,
        SmoothFactor = 0.5, -- Lower = smoother
        VisibilityCheck = true
    },
    
    Runtime = {
        Circle = Drawing.new("Circle"),
        Highlight = CreateHighlight(),
        CurrentTarget = nil,
        Active = false,
        Connections = {}
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

-- Utility Functions
local function IsVisible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local distance = (part.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = workspace:Raycast(origin, direction * distance, raycastParams)
    
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function UpdateHighlight(character, isVisible)
    if not character then
        Aimbot.Runtime.Highlight.Parent = nil
        return
    end
    
    Aimbot.Runtime.Highlight.FillColor = isVisible and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
    Aimbot.Runtime.Highlight.Parent = character
end

-- Target Acquisition
local function GetTarget()
    local closest = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local isVisible = false
    
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
                        
                        if fovDistance <= Aimbot.Settings.FOVCircle.Size then
                            local targetVisible = IsVisible(head)
                            
                            if fovDistance < shortestDistance and 
                               (not Aimbot.Settings.VisibilityCheck or targetVisible) then
                                shortestDistance = fovDistance
                                closest = head
                                isVisible = targetVisible
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closest, isVisible
end

-- Input Handling
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        Aimbot.Runtime.Active = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        Aimbot.Runtime.Active = false
        UpdateHighlight(nil)
    end
end)

-- Aim System
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
        UpdateHighlight(nil)
        return
    end
    
    -- Get and validate target
    local target, isVisible = GetTarget()
    if not target then
        UpdateHighlight(nil)
        return
    end
    
    -- Update highlight
    UpdateHighlight(target.Parent, isVisible)
    
    -- Calculate aim position
    local pos, onScreen = Camera:WorldToViewportPoint(target.Position)
    if not onScreen then return end
    
    -- Smooth mouse movement
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(pos.X, pos.Y)
    local delta = (targetPos - mousePos) * Aimbot.Settings.SmoothFactor
    
    mousemoverel(delta.X, delta.Y)
    
    -- Update camera
    local targetCF = CFrame.lookAt(Camera.CFrame.Position, target.Position)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, Aimbot.Settings.SmoothFactor)
end

-- UI Creation
local function CreateUI()
    local window = Censura:CreateWindow({
        title = "Combat Assistance",
        size = UDim2.new(0, 250, 0, 250)
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
    
    window:AddToggle({
        label = "Visibility Check",
        default = Aimbot.Settings.VisibilityCheck,
        callback = function(state)
            Aimbot.Settings.VisibilityCheck = state
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
    
    window:AddButton({ label = "Aim Settings" })
    
    window:AddSlider({
        label = "Smooth Factor",
        min = 1,
        max = 100,
        default = Aimbot.Settings.SmoothFactor * 100,
        callback = function(value)
            Aimbot.Settings.SmoothFactor = value / 100
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
    Aimbot.Runtime.Highlight:Destroy()
end

-- Create instance
local Window = Initialize()

return {
    Window = Window,
    Cleanup = Cleanup
}
