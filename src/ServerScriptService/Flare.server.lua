local replicatedStorage = game:GetService("ReplicatedStorage")
local assets = replicatedStorage:WaitForChild("Assets")
local remotes = assets:WaitForChild("Remotes")
local sounds = assets:WaitForChild("Sounds")
local modules = assets:WaitForChild("Modules")
local parts = assets:WaitForChild("Parts")
local animations = assets:WaitForChild("Animations")
local tweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local function createFlare(flareGun)
    local flare = parts.BlackFlare:Clone()
    flare.Parent = workspace.Ignore
    flare.CFrame = flareGun.PrimaryPart.CFrame
    local desiredPosition = flare.Position + Vector3.new(0,1200,0)
    local flareTween = tweenService:Create(flare, tweenInfo, {Position = desiredPosition})
    flareTween:Play()
    flareTween.Completed:Connect(function()
        flare.Flaresmoke.Enabled = false
    end)
end

local function giveFlareGun(player)
    local flareGun = parts:WaitForChild("Flare gun"):Clone()
    flareGun.PrimaryWeld.Part0 = player.Character["Right Arm"]
    flareGun.PrimaryWeld.Part1 = flareGun.PrimaryPart
    flareGun.Parent = player.Character
    return flareGun
end

local function removeFlareGun(flare)
    flare:Destroy()
end

remotes.Flare.OnServerEvent:Connect(function(player)
    local flareAnim = player.Character.Humanoid:LoadAnimation(animations:WaitForChild("Flare"))
    flareAnim:Play()
    task.wait(0.3)
    local flareGun = giveFlareGun(player)
    task.wait(0.83)
    createFlare(flareGun)
    task.wait(0.3)
    removeFlareGun(flareGun)
end)