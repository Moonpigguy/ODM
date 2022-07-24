local player = game:GetService("Players").LocalPlayer
local character = player.Character
local mouse = player:GetMouse()
local ODMGear = character:WaitForChild("ODMG")
local replicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local UIS = game:GetService("UserInputService")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local alignmentAttachment = humanoidRootPart:WaitForChild("ODMGAlign") -- This is the attachment that the gear will be aligned to when I eventually use AlignOrientation
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local assets = replicatedStorage:WaitForChild("Assets")
local remotes = assets:WaitForChild("Remotes")
local sounds = assets:WaitForChild("Sounds")
local modules = assets:WaitForChild("Modules")
local animations = assets:WaitForChild("Animations")
local ODMGSettings = require(modules:WaitForChild("ODMGSettings"))["ODMG"]
local settingsFolder = assets:WaitForChild("ODMGSettings") -- mainly for optimising the movement of the gear during testing (not used)
local turnSpeed = 0 -- higher this value is the slower the turn
local speed = 0 -- base speed definition of the gear
local ropes = {}
local initialRopes = {} 
local currentVelocities = {} -- this is used to store velocities so that all values in the table can be added to calculate the desired velocity
local currentAlignments = {}
local sliding = false
local slideVelocity = nil
local boosting = false

--local highJumpAnim = character.Humanoid:LoadAnimation(animations:WaitForChild("HighJump")) -- this isnt needed currently because the animation isnt used
local grappleStart = character.Humanoid:LoadAnimation(animations:WaitForChild("GrappleStart"))
local leftGrappleIdle = character.Humanoid:LoadAnimation(animations:WaitForChild("LeftGrappleIdle"))
local rightGrappleIdle = character.Humanoid:LoadAnimation(animations:WaitForChild("RightGrappleIdle"))
--local flareAnim = character.Humanoid:LoadAnimation(animations:WaitForChild("Flare")) -- this isnt needed currently because the animation isnt used on the client
local slideAnim = character.Humanoid:LoadAnimation(animations:WaitForChild("Slide"))
rightGrappleIdle.Looped = true
leftGrappleIdle.Looped = true
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

--[[local function createAlignment(root) -- not used because alignOrientation uses attachments (might update to this in the future)
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

local function updateVelocity(velocity,string)
    for i,v in pairs(currentVelocities) do
        if v[1] == string then
            v[2] = velocity
            return
        end
    end
end


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
            if origin == "Left" then
                leftGrappleIdle:Stop()
            elseif origin == "Right" then
                rightGrappleIdle:Stop()
            end
            table.remove(ropes,i)
        end
    end
    for i,v in pairs(initialRopes) do
        if v[1] == origin then
            v[2]:Destroy()
            remotes.ReplicateRope:FireServer("Destroy",nil,nil,origin)
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
    speed = ODMGSettings.BaseSpeed
    local connection = nil -- vsCode complains if i dont do this i dont know why
    local targetVelocity = Vector3.new(0,0,0)
    addVelocity(targetVelocity,origin)
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        if origin == "Left" then
            if not UIS:IsKeyDown(Enum.KeyCode.Q) then -- if the key isnt pressed, delete the rope and end the movement
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
        if not table.find(ropes, ropeTable) then connection:Disconnect() return end -- if the rope has been removed, end the movement
        if turnSpeed ~= 0 then -- so i dont divide by 0
            targetVelocity = (CFrame.new(humanoidRootPart.Position, dest) * CFrame.fromEulerAnglesXYZ(0, math.pi/turnSpeed, 0)).LookVector * speed -- the target velocity for that specific hook with the added velocity for rotation
        else
            targetVelocity = CFrame.new(humanoidRootPart.Position, dest).LookVector * speed -- velocity
        end
        if boosting then
            targetVelocity = targetVelocity + humanoidRootPart.CFrame.LookVector * ODMGSettings.BoostSpeed -- add the boost speed to the target velocity
        end
        if ropes[1] and ropes[1][1] ~= ropeTable[1] then -- if statement to find the opposite rope (sort of a hacky way i dont really like)
            updateAlignment(CFrame.new(humanoidRootPart.Position, dest / 2 + ropes[1][2].Target.Position / 2)) -- get the average position two hooks, get the lookvector from the character towards the average and update the alignment to that lookvector
        elseif ropes[2] and ropes[2][1] ~= ropeTable[1] then
            updateAlignment(CFrame.new(humanoidRootPart.Position, dest / 2 + ropes[2][2].Target.Position / 2)) -- same as above
        else
            updateAlignment(CFrame.new(humanoidRootPart.Position, dest)) -- face the character towards the hook
        end
        updateVelocity(targetVelocity,origin) -- update the velocity for specific hook side
    end)
end

local function shootRope(origin,dest,side)
    if findAndDestroyInitialRopes(side) or findAndDestroyRopes(side) then return end -- if we already have a rope, don't make another one
    remotes.ReplicateSound:FireServer("Grapple1") -- play grapple sound
    local initialRope = replicatedStorage.InitialRopeModel:Clone() -- create initial rope
    local ropeOrigin = initialRope.Origin
    local ropeDest = initialRope.Target
    ropeDest.Anchored = true
    ropeOrigin.OriginWeld.Part1 = origin
    ropeOrigin.Position = origin.Position
    ropeDest.Position = origin.Position
    initialRope.Parent = workspace.Ignore
    local initialRopeTable = {side,initialRope}
    table.insert(initialRopes,initialRopeTable) -- add initial rope table to initial ropes table
    local ropeConnection = nil
    remotes.ReplicateRope:FireServer("Create",origin,dest,side) -- send rope data to server to be replicated via fireclient
    ropeConnection = RunService.RenderStepped:Connect(function()
        local grappleRay = Ray.new(ropeDest.Position, (dest - origin.Position).unit * ODMGSettings.GrappleSpeed) -- create a ray towards the hook from the character's position (origin in this case)
        local grapplePart, grapplePoint = workspace:FindPartOnRayWithIgnoreList(grappleRay, {origin, ropeDest, workspace.Ignore, character})
        if (humanoidRootPart.Position - grapplePoint).magnitude > ODMGSettings.RopeMaxLength then -- if statement to check if the hook is too far away
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
            if findAndDestroyRopes(side) then return end -- if a rope already exists, destroy it and return
            initialRope:Destroy()
            findAndDestroyInitialRopes(side) -- destroy all other initial rope (is this even needed?)
            currentBodyVelocity.MaxForce = 5000 -- set the max force for the character's body to 5000 to prepare for the movement
            character.Humanoid.AutoRotate = false
            currentAlignment.MaxTorque = Vector3.new(2000,2000,2000) -- set the max torque for the character's alignment to 2000 to prepare for the movement
            ropeConnection:Disconnect()
            local ropeTable = createRope(origin, grapplePoint, side) -- create a rope and receive a table with the side and rope
            task.spawn(function()
                task.wait(0.2)
                if side == "Left" then
                    leftGrappleIdle:Play()
                elseif side == "Right" then
                    rightGrappleIdle:Play()
                end
            end)
            doMovement(side,grapplePoint,ropeTable) -- begin the movement
        end
    end)
end

local function createMovement(origin, dest)
    local hook = nil
    if origin == "Left" then -- if the origin is left, select the left hook instance
        if not UIS:IsKeyDown(Enum.KeyCode.Q) then return end
        hook = ODMGear.LeftHook
    elseif origin == "Right" then -- if the origin is right, select the right hook instance
        if not UIS:IsKeyDown(Enum.KeyCode.E) then return end
        hook = ODMGear.RightHook
    end
    if hook then -- if the hook exists, shoot the rope
        --grappleStart:Play()
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
        createMovement("Right", mouse.Hit.Position) -- create a movement with the right hook
    elseif input.KeyCode == Enum.KeyCode.Q then
        createMovement("Left", mouse.Hit.Position) -- create a movement with the left hook
    elseif input.KeyCode == Enum.KeyCode.A then
        if boosting then -- if the player is boosting, set the turn speed to the boost turn speed
            turnSpeed = ODMGSettings.BoostRotationSpeed
        else
            turnSpeed = ODMGSettings.BaseRotationSpeed
        end
    elseif input.KeyCode == Enum.KeyCode.D then
        if boosting then -- if the player is boosting, set the turn speed to the boost turn speed
            turnSpeed = -ODMGSettings.BoostRotationSpeed
        else
            turnSpeed = -ODMGSettings.BaseRotationSpeed
        end
    elseif input.KeyCode == Enum.KeyCode.Space then
        remotes.ReplicateEffect:FireServer("Boost",0,true)
        remotes.ReplicateSound:FireServer("Boost",true)
        boosting = true
        if UIS:IsKeyDown(Enum.KeyCode.A) then -- if player presses space after pressing a, set the turn speed to the boost turn speed
            turnSpeed = ODMGSettings.BoostRotationSpeed
        elseif UIS:IsKeyDown(Enum.KeyCode.D) then
            turnSpeed = -ODMGSettings.BoostRotationSpeed
        end
    elseif input.KeyCode == Enum.KeyCode.V then
        --flareAnim:Play() -- this is no longer done on the client, but it is still done on the server
        if not player.PlayerGui.MainGui.FlarePicker.Visible then
            player.PlayerGui.MainGui.FlarePicker.Visible = true
        else
            player.PlayerGui.MainGui.FlarePicker.Visible = false
        end
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
    elseif input.KeyCode == Enum.KeyCode.Space then
        remotes.ReplicateEffect:FireServer("Boost",0,false)
        remotes.ReplicateSound:FireServer("Boost",false)
        boosting = false
    end
end)


local function slide(velocity)
    if sliding then return end
    print(velocity)
    local timeElapsed = 0
    character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    sliding = true
    slideVelocity = Instance.new("BodyVelocity")
    slideVelocity.Name = "SlideVelocity"
    slideVelocity.Velocity = Vector3.new(velocity.X, 0, velocity.Z)
    slideVelocity.MaxForce = Vector3.new(math.huge,0,math.huge)
    slideVelocity.Parent = character.HumanoidRootPart
    slideAnim:Play()
    local connection = nil
    connection = RunService.RenderStepped:Connect(function(dt)
        local slideRay = Ray.new(character.HumanoidRootPart.Position, CFrame.new(character.HumanoidRootPart.Position,velocity).LookVector * 4 + Vector3.new(0,2,0))
        local slidePart, slidePoint = workspace:FindPartOnRayWithIgnoreList(slideRay, {workspace.Ignore, character})
        if slidePart then
            print("Slide hit " .. tostring(slidePoint),slidePart)
            stopSlide()
            connection:Disconnect()
            return
        end
        if Vector3.new(humanoidRootPart.Velocity.X,0,humanoidRootPart.Velocity.Z).Magnitude < 10 or sliding == false or not UIS:IsKeyDown(Enum.KeyCode.C) then
            print("slide stopped")
            stopSlide()
            connection:Disconnect()
            return
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            stopSlide()
            connection:Disconnect()
            local highJumpForce = Instance.new("VectorForce")
            highJumpForce.Name = "HighJumpForce"
            highJumpForce.Force = Vector3.new(0, ODMGSettings.HighJumpForce, 0)
            highJumpForce.Attachment0 = character.HumanoidRootPart:WaitForChild("ODMGAttachment")
            highJumpForce.Parent = character.HumanoidRootPart
            Debris:AddItem(highJumpForce, 0.1)
        end
    end)
    task.wait(0.5)
    for i = 1,100 do
        if slideVelocity then
            slideVelocity.Velocity = slideVelocity.Velocity:Lerp(Vector3.new(0,0,0),i/100)
            task.wait(0.1)
        else 
            stopSlide()
            connection:Disconnect()
            return
        end
    end
end

character.Humanoid.StateChanged:Connect(function(old,new)
    if new == Enum.HumanoidStateType.Landed then
        if UIS:IsKeyDown(Enum.KeyCode.C) then
            if Vector3.new(humanoidRootPart.Velocity.X,0,humanoidRootPart.Velocity.Z).Magnitude > 50 then
                slide(humanoidRootPart.Velocity)
            end
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
    currentBodyVelocity.VectorVelocity = mainVelocity
    alignmentAttachment.CFrame = alignment
    task.wait()
end