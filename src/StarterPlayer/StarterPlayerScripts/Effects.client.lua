local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local assets = replicatedStorage:WaitForChild("Assets")
local remotes = assets:WaitForChild("Remotes")
local sounds = assets:WaitForChild("Sounds")
local modules = assets:WaitForChild("Modules")
local loadedEffects = {}
local initialRopes = {}
local ropes = {}
local RunService = game:GetService("RunService")
local settings = require(modules:WaitForChild("ODMGSettings"))["ODMG"]

local function createRope(origin, dest, side, player)
    print("Creating rope")
    local rope = replicatedStorage.RopeModel:Clone()
    local ropeOrigin = rope.Origin
    local ropeDest = rope.Target
    ropeOrigin.OriginWeld.Part1 = origin
    ropeOrigin.Position = origin.Position
    ropeDest.Position = dest
    ropeDest.Anchored = true
    rope.Parent = workspace.Ignore
    local ropeTable = {side,rope,player}
    table.insert(ropes,ropeTable)
    return ropeTable
end

local function findAndDestroyInitialRopes(side,player)
    print("destroying initial ropes")
    for i,v in pairs(initialRopes) do
        if v[1] == side and v[3] == player then
            print("Destroying rope",v[2])
            v[2]:Destroy()
            table.remove(initialRopes,table.find(initialRopes,v))
            return true
        end
    end
    return false
end
local function findAndDestroyRopes(side,player)
    for i,v in pairs(ropes) do
        if v[1] == side and v[3] == player then
            print("Destroying rope",v[2])
            v[2]:Destroy()
            table.remove(ropes,table.find(ropes,v))
            return true
        end
    end
    return false
end
local function shootRope(origin,dest,side,player)
    if findAndDestroyRopes(side,player) or findAndDestroyInitialRopes(side,player) then -- in place to ensure that the player has only one rope per side at a time
        return
    end
    local initialRope = replicatedStorage.InitialRopeModel:Clone()
    local ropeOrigin = initialRope.Origin
    local ropeDest = initialRope.Target
    ropeDest.Anchored = true
    ropeOrigin.OriginWeld.Part1 = origin
    ropeOrigin.Position = origin.Position
    ropeDest.Position = origin.Position
    initialRope.Parent = workspace.Ignore
    local initialRopeTable = {side,initialRope,player}
    table.insert(initialRopes,initialRopeTable)
    local ropeConnection = nil
    ropeConnection = RunService.RenderStepped:Connect(function() 
        local grappleRay = Ray.new(ropeDest.Position, (dest - origin.Position).unit * settings.GrappleSpeed) -- raycast to the destination a distance of grappleSpeed
        local grapplePart, grapplePoint = workspace:FindPartOnRayWithIgnoreList(grappleRay, {origin, ropeDest, workspace.Ignore, player.Character}) -- ignore the player's character and the rope itself
        if (origin.Position - grapplePoint).magnitude > settings.RopeMaxLength then
            initialRope:Destroy()
            table.remove(initialRopes,table.find(initialRopes,initialRopeTable))
            ropeConnection:Disconnect()
            return
        end
        if grapplePoint then
            ropeDest.Position = grapplePoint
        end
        if grapplePart and not findAndDestroyRopes(side,player) then
            ropeConnection:Disconnect()
            findAndDestroyInitialRopes(side,player)
            createRope(origin, grapplePoint, side, player)
        end
    end)
end



remotes.ReplicateRope.OnClientEvent:Connect(function(funcType, initial, pos, side, player)
    if funcType == "Create" then
        shootRope(initial,pos,side, player)
    elseif funcType == "Destroy" then
        findAndDestroyRopes(side,player)
        findAndDestroyInitialRopes(side,player)
    end
end)
