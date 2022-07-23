local player = game:GetService("Players").LocalPlayer
local character = player.Character
local ODMGear = character:WaitForChild("ODMG")
local replicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local mouse = player:GetMouse()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local ropes = {}
local currentVelocities = {}
local alignmentAttachment = humanoidRootPart:WaitForChild("ODMGAlign")
local turnSpeed = 0

character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.FallingDown, false);

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

local function createVelocity(root)
    local bodyVelocity = Instance.new("LinearVelocity")
    bodyVelocity.Name = "ODMGVelocity"
    bodyVelocity.VectorVelocity = Vector3.new(0,0,0)
    bodyVelocity.MaxForce = 0
    bodyVelocity.Attachment0 = root:WaitForChild("ODMGAttachment")
    bodyVelocity.Parent = root
    return bodyVelocity
end

local function createAlignment(root)
    local bodyAlignment = Instance.new("AlignOrientation")
    bodyAlignment.Parent = root
    bodyAlignment.Name = "ODMGAlignment"
    bodyAlignment.MaxTorque = 2000
    bodyAlignment.Mode = Enum.OrientationAlignmentMode.OneAttachment
    bodyAlignment.Attachment0 = root:WaitForChild("ODMGAlign")
    return bodyAlignment
end

local currentBodyVelocity = createVelocity(humanoidRootPart)
local currentAlignment = createAlignment(humanoidRootPart)

local alignment = CFrame.new()

local function addVelocity(velocity,string)
    table.insert(currentVelocities, {string,velocity})
end

local function updateAlignment(alignValue)
    alignment = alignValue
end

local function updateVelocity(velocity,string)
    for i,v in pairs(currentVelocities) do
        if v[1] == string then
            v[2] = velocity
            return
        end
    end
end

local speed = 200

--[[local function lerpAndUpdateVelocity(velocity,target,origin,alpha)
    local newVelocity = velocity:Lerp(target,alpha/10)
    updateVelocity(newVelocity,origin)
    task.wait(0.02)
end]]

local function createMovement(origin, dest)
    currentBodyVelocity.MaxForce = 5000
    local connection = nil
    local hook = nil
    if origin == "Left" then
        hook = ODMGear.LeftHook
    elseif origin == "Right" then
        hook = ODMGear.RightHook
    end
    if hook then
        local ropeTable = createRope(hook, dest, origin)
        local hookPos = humanoidRootPart.Position
        local velocity = humanoidRootPart.Velocity
        local targetVelocity = nil
        if turnSpeed ~= 0 then
            targetVelocity = (CFrame.new(hookPos, dest) * CFrame.fromEulerAnglesXYZ(0, math.pi/turnSpeed, 0)).LookVector * speed -- velocity
        else
            targetVelocity = CFrame.new(hookPos, dest).LookVector * speed -- velocity
        end
        addVelocity(velocity,origin)
        updateVelocity(targetVelocity,origin)
        updateAlignment(CFrame.new(hookPos, dest))
        connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
            if not table.find(ropes, ropeTable) then print("Disconnected") connection:Disconnect() return end
            local targetVelocity = nil
            if turnSpeed ~= 0 then
                targetVelocity = (CFrame.new(humanoidRootPart.Position, dest) * CFrame.fromEulerAnglesXYZ(0, math.pi/turnSpeed, 0)).LookVector * speed -- velocity
            else
                targetVelocity = CFrame.new(humanoidRootPart.Position, dest).LookVector * speed -- velocity
            end
            updateAlignment(CFrame.new(humanoidRootPart.Position, dest))
            updateVelocity(targetVelocity,origin)
        end)
    end
end

local function endMovement(origin)
    for i,v in pairs(currentVelocities) do
        if v[1] == origin then
            table.remove(currentVelocities,i)
        end
    end
    for i,v in pairs(ropes) do
        if v[1] == origin then
            v[2]:Destroy()
            table.remove(ropes,i)
        end
    end
    if #currentVelocities == 0 then
        currentBodyVelocity.MaxForce = 0
    end
end

UIS.InputBegan:Connect(function(input,processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.E then
        if (humanoidRootPart.Position - mouse.Hit.Position).Magnitude > 400 then return end
        createMovement("Right", mouse.Hit.Position)
    elseif input.KeyCode == Enum.KeyCode.Q then
        if (humanoidRootPart.Position - mouse.Hit.Position).Magnitude > 400 then return end
        createMovement("Left", mouse.Hit.Position)
    elseif input.KeyCode == Enum.KeyCode.A then
        turnSpeed = 3.14
    elseif input.KeyCode == Enum.KeyCode.D then
        turnSpeed = -3.14
    end
end)

UIS.InputEnded:Connect(function(input,processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.E then
        endMovement("Right")
    elseif input.KeyCode == Enum.KeyCode.Q then
        endMovement("Left")
    elseif input.KeyCode == Enum.KeyCode.A then
        turnSpeed = 0
    elseif input.KeyCode == Enum.KeyCode.D then
        turnSpeed = 0
    end
end)


while true do
    local mainVelocity = Vector3.new(0,0,0)
    for _, velocity in pairs(currentVelocities) do
        mainVelocity = mainVelocity + velocity[2]
    end
    currentBodyVelocity.VectorVelocity = mainVelocity
    alignmentAttachment.CFrame = alignment
    task.wait()
end