local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local ODMGear = replicatedStorage:WaitForChild("ODMG")
        ODMGear.Primary.HumanoidRootPart.Part0 = ODMGear.Primary
        ODMGear.Primary.HumanoidRootPart.Part1 = character.HumanoidRootPart
        ODMGear.Parent = character
    end)
end)