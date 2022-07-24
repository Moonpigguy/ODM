local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local assets = replicatedStorage:WaitForChild("Assets")
local remotes = assets:WaitForChild("Remotes")
local sounds = assets:WaitForChild("Sounds")
local debris = game:GetService("Debris")


players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        while not character:FindFirstChild("HumanoidRootPart") do task.wait() end
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local ODMGear = replicatedStorage:WaitForChild("ODMG"):Clone()
        ODMGear.Primary.Torso.Part0 = ODMGear.Primary
        ODMGear.Primary.Torso.Part1 = character.Torso
        ODMGear.Parent = character
        local ODMGAttachment = Instance.new("Attachment")
        ODMGAttachment.Name = "ODMGAttachment"
        ODMGAttachment.Parent = humanoidRootPart
        local ODMGAlign = Instance.new("Attachment")
        ODMGAlign.Name = "ODMGAlign"
        ODMGAlign.Parent = humanoidRootPart
    end)
end)


remotes.ReplicateSound.OnServerEvent:Connect(function(player, sound, bool)
    local sound = sounds:FindFirstChild(sound)
    if sound and player.Character then
        if typeof(bool) == "boolean" then
            if bool then
                local newSound = sound:Clone()
                newSound.Parent = player.Character.HumanoidRootPart
                newSound:Play()
            else
                for _, soundChild in pairs(player.Character.HumanoidRootPart:GetChildren()) do
                    if soundChild:IsA("Sound") and soundChild.Name == sound.Name then
                        soundChild:Destroy()
                    end
                end
            end
        else
            local newSound = sound:Clone()
            newSound.Parent = player.Character.HumanoidRootPart
            newSound:Play()
            debris:AddItem(newSound, 5)
        end
    end
end)

local function fireOtherClients(player, event, ...)
    for _, client in pairs(players:GetPlayers()) do
        if client ~= player then
            event:FireClient(client, ...)
        end
    end
end

local function createEffect(effect, emitAmount, bool)
    local effect = effect
    if typeof(bool) == "boolean" then
        effect.Enabled = bool
    end
    if emitAmount < 30 and emitAmount > 0 then
        effect:Emit(emitAmount)
    end
end

remotes.ReplicateRope.OnServerEvent:Connect(function(player, funcType, initial, pos, side)
    fireOtherClients(player, remotes.ReplicateRope, funcType, initial, pos, side, player)
end)

remotes.ReplicateEffect.OnServerEvent:Connect(function(player,type,emitAmount,bool)
    if player.Character and player.Character:FindFirstChild("ODMG") then
        if typeof(bool) == "boolean" then
            createEffect(player.Character:FindFirstChild("ODMG").Primary:FindFirstChild(type),emitAmount,bool)
        else
            createEffect(player.Character:FindFirstChild("ODMG").Primary:FindFirstChild(type),emitAmount)
        end
    end
end)