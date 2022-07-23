local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        while not character:FindFirstChild("HumanoidRootPart") do task.wait() end
        local ODMGear = replicatedStorage:WaitForChild("ODMG"):Clone()
        ODMGear.Primary.HumanoidRootPart.Part0 = ODMGear.Primary
        ODMGear.Primary.HumanoidRootPart.Part1 = character.HumanoidRootPart
        ODMGear.LeftHook["Left Arm"].Part0 = ODMGear.LeftHook
        ODMGear.LeftHook["Left Arm"].Part1 = character["Left Arm"]
        ODMGear.RightHook["Right Arm"].Part0 = ODMGear.RightHook
        ODMGear.RightHook["Right Arm"].Part1 = character["Right Arm"]
        ODMGear.Parent = character
        local ODMGAttachment = Instance.new("Attachment")
        ODMGAttachment.Name = "ODMGAttachment"
        ODMGAttachment.Parent = character.HumanoidRootPart
        local ODMGAlign = Instance.new("Attachment")
        ODMGAlign.Name = "ODMGAlign"
        ODMGAlign.Parent = character.HumanoidRootPart
    end)
end)