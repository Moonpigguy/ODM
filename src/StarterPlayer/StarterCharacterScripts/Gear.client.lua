local player = game:GetService("Players").LocalPlayer
local character = player.Character
local ODMGear = character:WaitForChild("ODMG")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local function createRope(origin, dest)
    local rope = ReplicatedStorage.RopeModel:Clone()
    local ropeOrigin = rope.Origin
    local ropeDest = rope.Target
    ropeOrigin.Position = origin
    rope.Parent = character
end


UIS.InputBegan:Connect(function(input,processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.E then
        
        createRope(orign, dest)

    elseif input.KeyCode == Enum.KeyCode.Q then
        


    end
end)
