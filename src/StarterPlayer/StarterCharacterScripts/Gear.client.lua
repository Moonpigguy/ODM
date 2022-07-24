local Debris = game:GetService("Debris")
local player = game:GetService("Players").LocalPlayer
local character = player.Character
local mouse = player:GetMouse()
local ODMGear = character:WaitForChild("ODMG")
local replicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local alignmentAttachment = humanoidRootPart:WaitForChild("ODMGAlign")
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local assets = replicatedStorage:WaitForChild("Assets")
local remotes = assets:WaitForChild("Remotes")
local sounds = assets:WaitForChild("Sounds")
local modules = assets:WaitForChild("Modules")
local animations = assets:WaitForChild("Animations")
local settings = require(modules:WaitForChild("ODMGSettings"))["ODMG"]
local turnSpeed = 0
local ropes = {}
local initialRopes = {}
local currentVelocities = {}
local currentAlignments = {}
local sliding = false
local slideVelocity = nil


local highJumpAnim = character.Humanoid:LoadAnimation(animations:WaitForChild("HighJump"))
local grappleAnim = character.Humanoid:LoadAnimation(animations:WaitForChild("Grapple"))
grappleAnim.Looped = true
local slideAnim = character.Humanoid:LoadAnimation(animations:WaitForChild("Slide"))
slideAnim.Looped = true
character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.FallingDown, false);


local function createVelocity(root)
    local bodyVelocity = Instance.new("LinearVelocity")
    bodyVelocity.Name = "ODMGVelocity"
    bodyVelocity.VectorVelocity = Vector3.new(0,0,0)
    bodyVelocity.MaxForce = 0
    bodyVelocity.Attachment0 = root:WaitForChild("ODMGAttachment")
    bodyVelocity.Parent = root
    return bodyVelocity
end

--[[local function createAlignment(root)
    local bodyAlignment = Instance.new("AlignOrientation")
    bodyAlignment.Parent = root
    bodyAlignment.Name = "ODMGAlignment"
    bodyAlignment.MaxTorque = 2000
    bodyAlignment.Mode = Enum.OrientationAlignmentMode.OneAttachment
    bodyAlignment.Attachment0 = root:WaitForChild("ODMGAlign")
    return bodyAlignment
end]]

local function createAlignment(root)
    local bodyAlignment = Instance.new("BodyGyro")
    bodyAlignment.Name = "ODMGGyro"
    bodyAlignment.MaxTorque = Vector3.new(0,0,0)
    bodyAlignment.Parent = root
    bodyAlignment.P = 10000
    bodyAlignment.D = 100
    bodyAlignment.Parent = root
    return bodyAlignment
end


local currentBodyVelocity = createVelocity(humanoidRootPart)
local currentAlignment = createAlignment(humanoidRootPart)

local alignment = CFrame.new()

local function addVelocity(velocity,string)
    table.insert(currentVelocities, {string,velocity})
end

local function updateAlignment(cframe)
    currentAlignment.CFrame = cframe
end

local function addAlignment(cframe)
    table.insert(currentAlignments, cframe)
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

local function lerpAndUpdateVelocity(velocity,target,origin,alpha)
    local newVelocity = velocity:Lerp(target,alpha/10)
    updateVelocity(newVelocity,origin)
    task.wait(0.02)
end

addAlignment(humanoidRootPart.CFrame)

local function findAndDestroyInitialRopes(side)
    for i,v in pairs(initialRopes) do
        if v[1] == side then
            print("Destroying rope",v[2])
            v[2]:Destroy()
            table.remove(initialRopes,table.find(initialRopes,v))
            return true
        end
    end
    return false
end
local function findAndDestroyRopes(side)
    for i,v in pairs(ropes) do
        if v[1] == side then
            print("Destroying rope",v[2])
            v[2]:Destroy()
            table.remove(ropes,table.find(ropes,v))
            return true
        end
    end
    return false
end

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


local function endMovement(origin)
    for i,v in pairs(currentVelocities) do
        if v[1] == origin then
            table.remove(currentVelocities,i)
        end
    end
    for i,v in pairs(ropes) do
        if v[1] == origin then
            v[2]:Destroy()
            remotes.ReplicateSound:FireServer("GrappleEnd")
            remotes.ReplicateRope:FireServer("Destroy",nil,nil,origin)
            grappleAnim:Stop()
            table.remove(ropes,i)
        end
    end
    for i,v in pairs(initialRopes) do
        if v[1] == origin then
            v[2]:Destroy()
            table.remove(initialRopes,i)
        end
    end
    if #currentVelocities == 0 then
        character.Humanoid.AutoRotate = true
        currentAlignment.MaxTorque = Vector3.new(0,0,0)
        currentBodyVelocity.MaxForce = 0
    end
end

local function doMovement(origin,dest,ropeTable)
    sliding = false
    local connection = nil
    local hookPos = humanoidRootPart.Position
    local targetVelocity = Vector3.new(0,0,0)
    grappleAnim:Play()
    if turnSpeed ~= 0 then
        targetVelocity = (CFrame.new(hookPos, dest) * CFrame.fromEulerAnglesXYZ(0, math.pi/turnSpeed, 0)).LookVector * speed -- velocity
    else
        targetVelocity = CFrame.new(hookPos, dest).LookVector * speed -- velocity
    end
    addVelocity(targetVelocity,origin)
    connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if origin == "Left" then
            if not UIS:IsKeyDown(Enum.KeyCode.Q) then 
                endMovement(origin)
                connection:Disconnect()
                return 
            end
        elseif origin == "Right" then
            if not UIS:IsKeyDown(Enum.KeyCode.E) then 
                endMovement(origin)
                connection:Disconnect()
                return 
            end
        end
        if not table.find(ropes, ropeTable) then connection:Disconnect() return end
        if turnSpeed ~= 0 then
            targetVelocity = (CFrame.new(humanoidRootPart.Position, dest) * CFrame.fromEulerAnglesXYZ(0, math.pi/turnSpeed, 0)).LookVector * speed -- velocity
        else
            targetVelocity = CFrame.new(humanoidRootPart.Position, dest).LookVector * speed -- velocity
        end
        if ropes[1] and ropes[1][1] ~= ropeTable[1] then
            updateAlignment(CFrame.new(humanoidRootPart.Position, dest / 2 + ropes[1][2].Target.Position / 2))
        elseif ropes[2] and ropes[2][1] ~= ropeTable[1] then
            updateAlignment(CFrame.new(humanoidRootPart.Position, dest / 2 + ropes[2][2].Target.Position / 2))
        else
            updateAlignment(CFrame.new(humanoidRootPart.Position, dest))
        end
        updateVelocity(targetVelocity,origin)
    end)
end

local function shootRope(origin,dest,side)
    if findAndDestroyInitialRopes(side) then return end
    if findAndDestroyRopes(side) then return end
    remotes.ReplicateSound:FireServer("Grapple1")
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
    remotes.ReplicateRope:FireServer("Create",origin,dest,side)
    ropeConnection = RunService.RenderStepped:Connect(function()
        local grappleRay = Ray.new(ropeDest.Position, (dest - origin.Position).unit * settings.GrappleSpeed)
        local grapplePart, grapplePoint = workspace:FindPartOnRayWithIgnoreList(grappleRay, {origin, ropeDest, workspace.Ignore, character})
        if (origin.Position - grapplePoint).magnitude > settings.RopeMaxLength then
            print("Grapple too long")
            initialRope:Destroy()
            table.remove(initialRopes,table.find(initialRopes,initialRopeTable))
            ropeConnection:Disconnect()
            return
        end
        if grapplePoint then
            ropeDest.Position = grapplePoint
        end
        if grapplePart then
            print(grapplePart)
            if findAndDestroyRopes(side) then return end
            currentBodyVelocity.MaxForce = 5000
            character.Humanoid.AutoRotate = false
            currentAlignment.MaxTorque = Vector3.new(2000,2000,2000)
            ropeConnection:Disconnect()
            initialRope:Destroy()
            local ropeTable = createRope(origin, grapplePoint, side)
            doMovement(side,grapplePoint,ropeTable)
        end
    end)
end

local function createMovement(origin, dest)
    local hook = nil
    if origin == "Left" then
        if not UIS:IsKeyDown(Enum.KeyCode.Q) then return end
        hook = ODMGear.LeftHook
    elseif origin == "Right" then
        if not UIS:IsKeyDown(Enum.KeyCode.E) then return end
        hook = ODMGear.RightHook
    end
    if hook then
        findAndDestroyInitialRopes(origin)
        shootRope(hook, dest, origin)
    end
end

local function stopSlide()
    slideAnim:Stop()
    sliding = false
    if slideVelocity then
        slideVelocity:Destroy()
        slideVelocity = nil
    end
    character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
end


UIS.InputBegan:Connect(function(input,processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.E then
        createMovement("Right", mouse.Hit.Position)
    elseif input.KeyCode == Enum.KeyCode.Q then
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


local function slide(velocity)
    print(velocity)
    character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    sliding = true
    slideVelocity = Instance.new("BodyVelocity")
    slideVelocity.Name = "SlideVelocity"
    slideVelocity.Velocity = Vector3.new(velocity.X, 0, velocity.Z)
    slideVelocity.MaxForce = Vector3.new(math.huge,0,math.huge)
    slideVelocity.Parent = character.HumanoidRootPart
    slideAnim:Play()
    local connection = nil
    connection = RunService.RenderStepped:Connect(function()
        local slideRay = Ray.new(character.HumanoidRootPart.Position, Vector3.new(velocity.X, 0, velocity.Z))
        local slidePart, slidePoint = workspace:FindPartOnRayWithIgnoreList(slideRay, {character.HumanoidRootPart, workspace.Ignore, character})
        if slidePart then
            stopSlide()
            connection:Disconnect()
            return
        end
        if character.HumanoidRootPart:FindFirstChild("SlideVelocity").Velocity.Magnitude < 10 or sliding == false or not UIS:IsKeyDown(Enum.KeyCode.W) then
            stopSlide()
            connection:Disconnect()
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            stopSlide()
            connection:Disconnect()
            local highJumpForce = Instance.new("VectorForce")
            highJumpForce.Name = "HighJumpForce"
            highJumpForce.Force = Vector3.new(0, settings.HighJumpForce, 0)
            highJumpForce.Attachment0 = character.HumanoidRootPart:WaitForChild("ODMGAttachment")
            highJumpForce.Parent = character.HumanoidRootPart
            Debris:AddItem(highJumpForce, 0.1)
            --character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
    end)
end

character.Humanoid.StateChanged:Connect(function(old,new)
    if new == Enum.HumanoidStateType.Landed then
        print("Landed")
        if Vector3.new(humanoidRootPart.Velocity.X,0,humanoidRootPart.Velocity.Z).Magnitude > 100 then
            slide(humanoidRootPart.Velocity)
        end
    end
end)

while true do
    camera.FieldOfView = 70 + character.HumanoidRootPart.Velocity.Magnitude / 10
    local mainVelocity = Vector3.new(0,0,0)
    local mainAlignment = CFrame.new()
    for _, velocity in pairs(currentVelocities) do
        mainVelocity = mainVelocity + velocity[2]
    end
    for _, alignment in pairs(currentAlignments) do
        mainAlignment = alignment
    end
    mainAlignment = mainAlignment  * CFrame.new(0, 0, -0.25)
    currentBodyVelocity.VectorVelocity = mainVelocity
    currentAlignment.CFrame = mainAlignment
    alignmentAttachment.CFrame = alignment
    task.wait()
end