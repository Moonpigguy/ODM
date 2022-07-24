local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local assets = replicatedStorage:WaitForChild("Assets")
local remotes = assets:WaitForChild("Remotes")
local sounds = assets:WaitForChild("Sounds")


players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        while not character:FindFirstChild("HumanoidRootPart") do task.wait() end
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local ODMGear = replicatedStorage:WaitForChild("ODMG"):Clone()
        ODMGear.Primary.HumanoidRootPart.Part0 = ODMGear.Primary
        ODMGear.Primary.HumanoidRootPart.Part1 = humanoidRootPart
        ODMGear.LeftHook["Left Arm"].Part0 = ODMGear.LeftHook
        ODMGear.LeftHook["Left Arm"].Part1 = character["Left Arm"]
        ODMGear.RightHook["Right Arm"].Part0 = ODMGear.RightHook
        ODMGear.RightHook["Right Arm"].Part1 = character["Right Arm"]
        ODMGear.Parent = character
        local ODMGAttachment = Instance.new("Attachment")
        ODMGAttachment.Name = "ODMGAttachment"
        ODMGAttachment.Parent = humanoidRootPart
        local ODMGAlign = Instance.new("Attachment")
        ODMGAlign.Name = "ODMGAlign"
        ODMGAlign.Parent = humanoidRootPart
    end)
end)

remotes.ReplicateSound.OnServerEvent:Connect(function(player, sound)
    local sound = sounds:FindFirstChild(sound)
    if sound and player.Character then
        local newSound = sound:Clone()
        newSound.Parent = player.Character.HumanoidRootPart
        newSound:Play()
    end
end)

local function fireOtherClients(player, event, ...)
    for _, client in pairs(players:GetPlayers()) do
        if client ~= player then
            event:FireClient(client, ...)
        end
    end
end

remotes.ReplicateRope.OnServerEvent:Connect(function(player, funcType, initial, pos, side)
    fireOtherClients(player, remotes.ReplicateRope, funcType, initial, pos, side, player)
end)