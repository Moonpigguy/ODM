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


local function createRope(origin, dest, side)
    local rope = replicatedStorage.RopeModel:Clone()
    local ropeOrigin = rope.Origin
    local ropeDest = rope.Target
    ropeOrigin.OriginWeld.Part1 = origin
    ropeOrigin.Position = origin.Position
    ropeDest.Position = dest
    ropeDest.Anchored = true
    rope.Parent = workspace.Ignore
    local ropeTable = {side,rope}
    table.insert(ropes,ropeTable)
    return ropeTable
end

local function shootRope(origin,dest,side,player)
    local initialRope = replicatedStorage.InitialRopeModel:Clone()
    local ropeOrigin = initialRope.Origin
    local ropeDest = initialRope.Target
    ropeDest.Anchored = true
    ropeOrigin.OriginWeld.Part1 = origin
    ropeOrigin.Position = origin.Position
    ropeDest.Position = origin.Position
    initialRope.Parent = workspace.Ignore
    local initialRopeTable = {side,initialRope}
    table.insert(initialRopes,initialRopeTable)
    local ropeConnection = nil
    ropeConnection = RunService.RenderStepped:Connect(function()
        local grappleRay = Ray.new(ropeDest.Position, (dest - origin.Position).unit * settings.GrappleSpeed)
        local grapplePart, grapplePoint = workspace:FindPartOnRayWithIgnoreList(grappleRay, {origin, ropeDest, workspace.Ignore, player.Character})
        if (origin.Position - grapplePoint).magnitude > settings.RopeMaxLength then
            initialRope:Destroy()
            table.remove(initialRopes,table.find(initialRopes,initialRopeTable))
            ropeConnection:Disconnect()
            return
        end
        if grapplePoint then
            ropeDest.Position = grapplePoint
        end
        if grapplePart then
            ropeConnection:Disconnect()
            initialRope:Destroy()
            createRope(origin, grapplePoint, side)
        end
    end)
end

remotes.ReplicateRope.OnClientEvent:Connect(function(funcType, initial, pos, side, player)
    print("client received rope")
    if funcType == "Create" then
        shootRope(initial,pos,side, player)
    elseif funcType == "Destroy" then
        for i,v in pairs(ropes) do
            if v[1] == side then
                v[2]:Destroy()
                table.remove(ropes,i)
            end
        end
        for i,v in pairs(initialRopes) do
            if v[1] == side then
                v[2]:Destroy()
                table.remove(initialRopes,i)
            end
        end
    end
end)