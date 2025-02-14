local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer



local Censura = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()



local Aimbot = {
    Enabled = false,
    IsAiming = false,
    TargetPart = "Head",
    AimMethod = "Camera",
    Smoothness = 1,
    FOV = 400,
    MaxDistance = 1000,
    TeamCheck = false,
    VisibilityCheck = true,
    CurrentTarget = nil,
    CurrentHighlight = nil,
    PredictionAmount = 0.0,
    TriggerBot = {
        Enabled = false,
        Delay = {
            Min = 0.08,
            Max = 0.15
        },
        LastShot = 0,
        BurstConfig = {
            Enabled = true,
            MinShots = 2,
            MaxShots = 4,
            ShotsLeft = 0
        },
        HumanizationConfig = {
            Enabled = true,
            MissChance = 0.1,
            ReactionDelay = {
                Min = 0.05,
                Max = 0.15
            }
        }
    },
    TargetFilters = {
        IgnoreDead = true,
        IgnorePlayers = false,
        IgnoreNPCs = false,
        MinHealth = 0
    }
}



local function IsHumanoidAlive(humanoid)
    return humanoid and humanoid.Health > Aimbot.TargetFilters.MinHealth
end



local function IsValidTarget(model)
    if not model:IsA("Model") then return false end
    local humanoid = model:FindFirstChild("Humanoid")
    if not humanoid then return false end
    if Aimbot.TargetFilters.IgnoreDead and not IsHumanoidAlive(humanoid) then return false end
    if not model:FindFirstChild(Aimbot.TargetPart) then return false end
    local player = Players:GetPlayerFromCharacter(model)
    if player then
        if Aimbot.TargetFilters.IgnorePlayers then return false end
        if player == LocalPlayer then return false end
        if Aimbot.TeamCheck and player.Team == LocalPlayer.Team then return false end
    else
        if Aimbot.TargetFilters.IgnoreNPCs then return false end
    end
    return true
end



local function GetAllValidTargets()
    local targets = {}
    for _, model in pairs(workspace:GetDescendants()) do
        if IsValidTarget(model) then
            table.insert(targets, model)
        end
    end
    return targets
end



local function IsVisible(part)
    local character = LocalPlayer.Character
    if not character then return false end
    local origin = character:FindFirstChild("Head") and character.Head.Position or character:GetPivot().Position
    local direction = (part.Position - origin).Unit
    local ray = Ray.new(origin, direction * Aimbot.MaxDistance)
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {character})
    return hit and hit:IsDescendantOf(part.Parent)
end



local function GetClosestTarget()
    local closest = nil
    local shortestDistance = Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()
    for _, model in pairs(GetAllValidTargets()) do
        local targetPart = model:FindFirstChild(Aimbot.TargetPart)
        if not targetPart then continue end
        local distance = (LocalPlayer.Character:GetPivot().Position - targetPart.Position).Magnitude
        if distance > Aimbot.MaxDistance then continue end
        local pos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
        if not onScreen then continue end
        local screenDistance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
        if screenDistance < shortestDistance then
            if Aimbot.VisibilityCheck and not IsVisible(targetPart) then continue end
            closest = model
            shortestDistance = screenDistance
        end
    end
    return closest
end



local Window = Censura:CreateWindow({
    title = "Universal Aimbot",
    size = UDim2.new(0, 300, 0, 400)
})



local ToggleAimbot = Window:AddToggle({
    label = "Enable Aimbot (Hold Alt)",
    callback = function(value)
        Aimbot.Enabled = value
        if not value and Aimbot.CurrentHighlight then
            Aimbot.CurrentHighlight:Destroy()
            Aimbot.CurrentHighlight = nil
        end
    end
})



local TriggerToggle = Window:AddToggle({
    label = "Enable TriggerBot",
    callback = function(value)
        Aimbot.TriggerBot.Enabled = value
    end
})



local SmoothnessSlider = Window:AddSlider({
    label = "Smoothness",
    min = 0.1,
    max = 1,
    default = 0.5,
    callback = function(value)
        Aimbot.Smoothness = value
    end
})



local FOVSlider = Window:AddSlider({
    label = "FOV",
    min = 50,
    max = 800,
    default = 400,
    callback = function(value)
        Aimbot.FOV = value
    end
})



local function UpdateTargetHighlight(target)
    if Aimbot.CurrentHighlight then
        Aimbot.CurrentHighlight:Destroy()
        Aimbot.CurrentHighlight = nil
    end
    if target then
        local visible = IsVisible(target[Aimbot.TargetPart])
        Aimbot.CurrentHighlight = Instance.new("Highlight")
        Aimbot.CurrentHighlight.FillColor = visible and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
        Aimbot.CurrentHighlight.OutlineColor = Color3.new(1, 1, 1)
        Aimbot.CurrentHighlight.FillTransparency = 0.5
        Aimbot.CurrentHighlight.OutlineTransparency = 0
        Aimbot.CurrentHighlight.Parent = target
    end
end



local function AimAtTarget(targetPos)
    if not targetPos then return end
    local character = LocalPlayer.Character
    if not character then return end
    local targetCF = CFrame.new(Camera.CFrame.Position, targetPos)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, Aimbot.Smoothness)
end



local function GetWeaponRemotes(tool)
    local remotes = {}
    for _, obj in pairs(tool:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if obj.Name:lower():match("fire") or obj.Name:lower():match("shoot") or obj.Name:lower():match("activate") or obj.Name:lower():match("mouse") then
                table.insert(remotes, obj)
            end
        end
    end
    return remotes
end



local function SimulateWeaponFire(tool)
    local remotes = GetWeaponRemotes(tool)
    local method = math.random(1, 3)
    
    if method == 1 and #remotes > 0 then
        local remote = remotes[math.random(1, #remotes)]
        if remote:IsA("RemoteEvent") then
            remote:FireServer()
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer()
        end
    elseif method == 2 then
        if tool:FindFirstChild("Enabled") then
            tool.Enabled = false
            task.wait(math.random(1, 3) * 0.01)
            tool.Enabled = true
        end
        if tool:FindFirstChild("Active") then
            tool.Active = true
            task.wait(math.random(1, 2) * 0.01)
            tool.Active = false
        end
    else
        local fireFunction = tool:FindFirstChild("Fire") or tool:FindFirstChild("Shoot") or tool:FindFirstChild("Activate")
        if fireFunction and typeof(fireFunction) == "function" then
            fireFunction:Invoke()
        end
    end
end



local function GetRandomDelay()
    return Aimbot.TriggerBot.Delay.Min + (math.random() * (Aimbot.TriggerBot.Delay.Max - Aimbot.TriggerBot.Delay.Min))
end



local function ShouldTakeShot()
    if not Aimbot.TriggerBot.HumanizationConfig.Enabled then return true end
    return math.random() > Aimbot.TriggerBot.HumanizationConfig.MissChance
end



local function HandleTriggerBot(target)
    if not target then return end
    local currentTime = tick()
    local timeSinceLastShot = currentTime - Aimbot.TriggerBot.LastShot
    
    if Aimbot.TriggerBot.BurstConfig.Enabled then
        if Aimbot.TriggerBot.BurstConfig.ShotsLeft <= 0 then
            Aimbot.TriggerBot.BurstConfig.ShotsLeft = math.random(
                Aimbot.TriggerBot.BurstConfig.MinShots,
                Aimbot.TriggerBot.BurstConfig.MaxShots
            )
            task.wait(math.random() * 0.2 + 0.1)
        end
    end
    
    if timeSinceLastShot >= GetRandomDelay() then
        if ShouldTakeShot() then
            local character = LocalPlayer.Character
            if character then
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    if Aimbot.TriggerBot.HumanizationConfig.Enabled then
                        local reactionDelay = Aimbot.TriggerBot.HumanizationConfig.ReactionDelay
                        task.wait(reactionDelay.Min + math.random() * (reactionDelay.Max - reactionDelay.Min))
                    end
                    SimulateWeaponFire(tool)
                    if Aimbot.TriggerBot.BurstConfig.Enabled then
                        Aimbot.TriggerBot.BurstConfig.ShotsLeft -= 1
                    end
                end
            end
        end
        Aimbot.TriggerBot.LastShot = currentTime
    end
end



UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        Aimbot.IsAiming = true
    end
end)



UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        Aimbot.IsAiming = false
        if Aimbot.CurrentHighlight then
            Aimbot.CurrentHighlight:Destroy()
            Aimbot.CurrentHighlight = nil
        end
    end
end)



RunService.RenderStepped:Connect(function()
    if not Aimbot.Enabled or not Aimbot.IsAiming then return end
    local target = GetClosestTarget()
    if target ~= Aimbot.CurrentTarget then
        Aimbot.CurrentTarget = target
        UpdateTargetHighlight(target)
    end
    if target then
        local targetPart = target:FindFirstChild(Aimbot.TargetPart)
        if targetPart then
            AimAtTarget(targetPart.Position)
            if Aimbot.TriggerBot.Enabled then
                HandleTriggerBot(target)
            end
        end
    end
end)
