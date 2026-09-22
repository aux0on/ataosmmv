--[[local wjskea = odh_shared_plugins
local wjjjw = wjskea.game_name

if wjjjw ~= "Murder Mystery Modded" then
    return
end
]]
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({_tasks = {}, _destroyed = false}, Maid)
end

function Maid:GiveTask(task)
    if self._destroyed then
        self:_cleanupTask(task)
        return
    end
    table.insert(self._tasks, task)
    return task
end

function Maid:GiveTasks(...)
    for i = 1, select("#", ...) do
        self:GiveTask((select(i, ...)))
    end
end

function Maid:_cleanupTask(task)
    local taskType = typeof(task)
    if taskType == "RBXScriptConnection" then
        task:Disconnect()
    elseif taskType == "Instance" then
        task:Destroy()
    elseif taskType == "function" then
        task()
    elseif taskType == "table" and type(task.Destroy) == "function" then
        task:Destroy()
    end
end

function Maid:DoCleaning()
    if self._destroyed then return end
    self._destroyed = true
    for _, task in self._tasks do
        self:_cleanupTask(task)
    end
    self._tasks = {}
end

function Maid:Destroy()
    self:DoCleaning()
end

local RootMaid = Maid.new()

local shared = odh_shared_plugins
task.spawn(function()
    shared.load_from_github_url("/aux0on/CrashHandler/refs/heads/main/Prevention.lua")
end)

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TeleportService = game:GetService("TeleportService"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    MarketplaceService = game:GetService("MarketplaceService"),
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui"),
    Stats = game:GetService("Stats")
}

local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlaceId = game.PlaceId
local JobId = game.JobId

local __PCLR = Color3.new
local __RGB = Color3.fromRGB
local __UD2 = UDim2.new
local __UD = UDim.new
local __V2 = Vector2.new

local function getfserv(s)
    local ok, svc = pcall(function() return game:GetService(s) end)
    if ok and svc then return svc end
    ok, svc = pcall(function() return game:FindService(s) end)
    if ok and svc then return svc end
    return game[s]
end

local __RS   = getfserv("RunService")
local __UIS  = getfserv("UserInputService")
local __PLRS = getfserv("Players")
local __TS   = getfserv("TweenService")

local muteButtonSounds = false

local BindableButtons = {Buttons = {}, Maids = {}, Count = 0}

local function UpdateAllButtonSounds()
    local volume = muteButtonSounds and 0 or 0.5
    for id, btn in BindableButtons.Buttons do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
end

local __SHAPES = {
    [0] = "rbxassetid://86221076925479",
    [1] = "rbxassetid://96242665417546",
    [2] = "rbxassetid://97129189935336",
    [3] = "rbxassetid://76165862027868",
    [4] = "rbxassetid://125868092127496"
}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __PCLR(0.133333, 0.827451, 0.494118)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.231373, 0.509804, 0.498039)),
    ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
})

local function bind_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BIND ERROR] " .. tostring(err)) end
end

local function Bind_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then
        parent = getfserv("CoreGui")
    end
    if not parent or typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
    end

    local sg = parent:FindFirstChild("@bindstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@bindstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local function Bind_MakeDraggable(gui, maid, ripple, sound, clickFunc)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    local rel
    local rippleTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local rippleGoal = {Size = __UD2(0, 45, 0, 45), BackgroundTransparency = 1}
    local zeroSize = __UD2(0, 0, 0, 0)

    maid:GiveTask(function()
        if rel then rel:Disconnect() rel = nil end
    end)

    maid:GiveTask(gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, gui.Position
            hasMoved = false
            sound:Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = zeroSize
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            __TS:Create(ripple, rippleTweenInfo, rippleGoal):Play()

            if rel then rel:Disconnect() rel = nil end
            rel = __UIS.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    if not hasMoved then
                        bind_safecallback(clickFunc)
                    end
                    if rel then rel:Disconnect() rel = nil end
                end
            end)
        end
    end))

    maid:GiveTask(gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    maid:GiveTask(__UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = __UD2(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

local strokeSpinners = setmetatable({}, {__mode = "k"})
local strokeSpinnerConn = nil

local function strokeSpinStep()
    local any = false
    for stroke, rot in strokeSpinners do
        any = true
        rot = (rot + 1) % 360
        strokeSpinners[stroke] = rot
        stroke.Rotation = rot
    end
    if not any and strokeSpinnerConn then
        strokeSpinnerConn:Disconnect()
        strokeSpinnerConn = nil
    end
end

local function addStrokeSpinner(stroke)
    strokeSpinners[stroke] = 0
    if not strokeSpinnerConn then
        strokeSpinnerConn = __RS.RenderStepped:Connect(strokeSpinStep)
    end
end

local function removeStrokeSpinner(stroke)
    strokeSpinners[stroke] = nil
end

RootMaid:GiveTask(function()
    if strokeSpinnerConn then
        strokeSpinnerConn:Disconnect()
        strokeSpinnerConn = nil
    end
    table.clear(strokeSpinners)
end)

function BindableButtons.AddBButton(id, text, clickFunc)
    if BindableButtons.Buttons[id] then return end

    local buttonMaid = Maid.new()
    local camera = workspace.CurrentCamera
    local screen = camera.ViewportSize
    local buttonSizeY = 0.11
    local widthScale = buttonSizeY * (screen.Y / screen.X)
    local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
    local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = id
    ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = __UD2(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = __V2(0.5, 0.5)
    ImageButton.Image = __SHAPES[0]
    ImageButton.BackgroundTransparency = 1
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    ImageButton.Parent = Bind_GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Name = "@Text"
    TextLabel.Size = __UD2(0.8, 0, 0.8, 0)
    TextLabel.Position = __UD2(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = __V2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.Jura
    TextLabel.Text = text
    TextLabel.TextColor3 = __PCLR(1, 1, 1)
    TextLabel.TextSize = 10
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3
    TextLabel.Parent = ImageButton

    local Aspect = Instance.new("UIAspectRatioConstraint")
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize
    Aspect.Parent = ImageButton

    local Stroke = Instance.new("UIGradient")
    Stroke.Name = "@Stroke"
    Stroke.Color = __NORMAL_COLOR
    Stroke.Parent = ImageButton

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton

    local rippleCorner = Instance.new("UICorner")
    rippleCorner.CornerRadius = __UD(1, 0)
    rippleCorner.Parent = ripple

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = ImageButton

    Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc)
    addStrokeSpinner(Stroke)
    buttonMaid:GiveTask(function() removeStrokeSpinner(Stroke) end)

    BindableButtons.Buttons[id] = ImageButton
    BindableButtons.Maids[id] = buttonMaid
    BindableButtons.Count = BindableButtons.Count + 1
    return ImageButton
end

function BindableButtons.DeleteBButton(id)
    if BindableButtons.Maids[id] then
        BindableButtons.Maids[id]:Destroy()
        BindableButtons.Maids[id] = nil
        BindableButtons.Buttons[id] = nil
    end
end

local function GetSafeGuiRoot()
    local success, result = pcall(function() return gethui() end)
    if success and typeof(result) == "Instance" then
        return result
    end
    return Services.CoreGui
end

local hiddenGuiParent = GetSafeGuiRoot()
local hiddenGui = hiddenGuiParent:FindFirstChild("HiddenGui")
if not hiddenGui then
    hiddenGui = Instance.new("ScreenGui")
    hiddenGui.Name = "HiddenGui"
    hiddenGui.ResetOnSpawn = false
    hiddenGui.IgnoreGuiInset = true
    hiddenGui.Parent = hiddenGuiParent
    RootMaid:GiveTask(hiddenGui)
end

local ataos = shared.CreateTab("ATAOs", "/aux0on/AllTheAdd-OnsIcon/refs/heads/main/Untitled163_20260918192358")

local aboutSection = ataos:AddSection("About")
aboutSection:AddParagraph("ATAOs MMV", "is the version you are using.")
aboutSection:AddToggle("Mute Button SFX", function(bool)
    muteButtonSounds = bool
    UpdateAllButtonSounds()
end)

local serverSection = ataos:AddSection("Server Options")
serverSection:AddLabel("Might Take a Few Tries")
serverSection:AddButton("Rejoin", function()
    Services.TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
end)
serverSection:AddButton("Server Hop", function()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PlaceId)
    local success, servers = pcall(function()
        return Services.HttpService:JSONDecode(game:HttpGet(url))
    end)
    if success and servers and servers.data and #servers.data > 0 then
        local available = {}
        for _, server in servers.data do
            if server.id ~= JobId and server.playing < server.maxPlayers then
                table.insert(available, server)
            end
        end
        if #available > 0 then
            local randomServer = available[math.random(1, #available)]
            shared.Notify("Server hopping...", 2)
            Services.TeleportService:TeleportToPlaceInstance(PlaceId, randomServer.id, LocalPlayer)
            return
        end
    end
    shared.Notify("No server found to hop to", 3)
end)
serverSection:AddButton("Join Full Server", function()
    local cursor
    local bestServer
    repeat
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
        if cursor then url = url.."&cursor="..cursor end
        local success, response = pcall(function()
            return Services.HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and response and response.data then
            for _, server in response.data do
                if server.id ~= JobId and server.playing < server.maxPlayers then
                    if not bestServer or server.playing > bestServer.playing then
                        bestServer = server
                    end
                end
            end
            cursor = response.nextPageCursor
        else
            cursor = nil
        end
    until not cursor or bestServer

    if bestServer then
        shared.Notify("Joining full server...", 2)
        Services.TeleportService:TeleportToPlaceInstance(PlaceId, bestServer.id, LocalPlayer)
    else
        shared.Notify("No suitable fuller server found", 3)
    end
end)
serverSection:AddButton("Join Dead Server", function()
    local cursor
    local lowestServer, lowestCount
    repeat
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s"):format(PlaceId, cursor and "&cursor=" .. cursor or "")
        local success, result = pcall(function()
            return Services.HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            for _, server in result.data do
                if server.id ~= JobId and server.playing > 0 then
                    if not lowestCount or server.playing < lowestCount then
                        lowestCount = server.playing
                        lowestServer = server
                    end
                end
            end
            cursor = result.nextPageCursor
            task.wait(1.5)
        else
            cursor = nil
        end
    until not cursor
    if lowestServer then
        shared.Notify("Joining dead server with " .. lowestServer.playing .. " players", 3)
        Services.TeleportService:TeleportToPlaceInstance(PlaceId, lowestServer.id, LocalPlayer)
    else
        shared.Notify("No dead server found", 3)
    end
end)

local PlaySong = Services.ReplicatedStorage.Remotes.Inventory.PlaySong
local radioSection = ataos:AddSection("Radio Abuse")
local songSaveFile = "saved_songs.json"
local savedSongs = {}
if isfile and readfile and isfile(songSaveFile) then
    local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(songSaveFile)) end)
    if ok and type(data) == "table" then savedSongs = data end
end
local function saveSongs()
    if writefile then writefile(songSaveFile, Services.HttpService:JSONEncode(savedSongs)) end
end
local function getSongNames()
    local names = table.create(#savedSongs)
    for i, song in savedSongs do names[i] = song.name or song.id end
    return names
end
local songDropdown
local lastSelectedSong = nil

local function setSongItems(items)
    local dd = songDropdown
    if not dd then return end
    if dd.ChangeItems then
        dd:ChangeItems(items)
    elseif dd.Change then
        dd.Change(items)
    end
end
songDropdown = radioSection:AddDropdown("Saved Songs", getSongNames(), function(selectedName)
    for _, song in savedSongs do
        if song.name == selectedName then
            lastSelectedSong = song
            PlaySong:FireServer("https://www.roblox.com/asset/?id=" .. song.id)
            break
        end
    end
end)
radioSection:AddButton("Replay Audio", function()
    if lastSelectedSong then
        PlaySong:FireServer("https://www.roblox.com/asset/?id=" .. lastSelectedSong.id)
        task.wait(0.1)
        PlaySong:FireServer("https://www.roblox.com/asset/?id=" .. lastSelectedSong.id)
    else
        shared.Notify("No audio selected!", 0)
    end
end)
radioSection:AddTextBox("Add Audio ID", function(text)
    local id = text:match("%d+")
    if id then
        local success, info = pcall(function() return Services.MarketplaceService:GetProductInfo(tonumber(id)) end)
        local name = (success and info and info.Name) or id
        table.insert(savedSongs, {name = name, id = id})
        saveSongs()
        setSongItems(getSongNames())
        shared.Notify("Added: " .. name, 2)
    else
        shared.Notify("Invalid audio ID!", 1)
    end
end)
radioSection:AddButton("Delete Selected Audio", function()
    if lastSelectedSong then
        for i, song in savedSongs do
            if song.name == lastSelectedSong.name then
                table.remove(savedSongs, i)
                saveSongs()
                setSongItems(getSongNames())
                shared.Notify("Removed: " .. lastSelectedSong.name, 2)
                lastSelectedSong = nil
                return
            end
        end
    end
end)

local RadioMaid = nil
local autoPlayEnabled = false
local function playSelectedSong()
    if lastSelectedSong then
        PlaySong:FireServer("https://www.roblox.com/asset/?id=" .. lastSelectedSong.id)
    end
end
radioSection:AddToggle("Auto Play Selected Audio", function(state)
    if RadioMaid then RadioMaid:DoCleaning() RadioMaid = nil end
    autoPlayEnabled = state

    if autoPlayEnabled then
        RadioMaid = Maid.new()
        RadioMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            playSelectedSong()
        end))
    end
end)
RootMaid:GiveTask(function() if RadioMaid then RadioMaid:DoCleaning() end end)

local speedGlitchSection = ataos:AddSection("Auto Speedglitch")
local asgEnabled = false
local asgHorizontal = false
local asgValue = 0
local defaultSpeed = 16
local asgChar, asgHum, asgRoot
local isInAir = false

local SpeedGlitchMaid = nil

local function asgCharSetup(c)
    asgChar, asgHum, asgRoot = c, c:WaitForChild("Humanoid"), c:WaitForChild("HumanoidRootPart")
    if SpeedGlitchMaid then
        SpeedGlitchMaid:GiveTask(asgHum.StateChanged:Connect(function(_, s)
            isInAir = (s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall)
        end))
    end
end

local function asgStep()
    if not asgEnabled or not asgChar or not asgHum or not asgRoot then return end

    local targetSpeed = defaultSpeed + asgValue
    if isInAir then
        if asgHorizontal then
            if math.abs(asgHum.MoveDirection:Dot(asgRoot.CFrame.RightVector)) > 0.5 then
                asgHum.WalkSpeed = targetSpeed
            else
                asgHum.WalkSpeed = defaultSpeed
            end
        else
            asgHum.WalkSpeed = targetSpeed
        end
    else
        asgHum.WalkSpeed = defaultSpeed
    end
end

local asgStepConn = nil
local function asgSyncStepConnection()
    local uis = Services.UserInputService
    local want = uis.TouchEnabled and not uis.KeyboardEnabled
    if want and not asgStepConn then
        asgStepConn = Services.RunService.Stepped:Connect(asgStep)
    elseif not want and asgStepConn then
        asgStepConn:Disconnect()
        asgStepConn = nil
    end
end

speedGlitchSection:AddToggle("Enable ASG", function(e)
    if SpeedGlitchMaid then SpeedGlitchMaid:DoCleaning() SpeedGlitchMaid = nil end
    asgEnabled = e
    if e then
        SpeedGlitchMaid = Maid.new()
        if LocalPlayer.Character then asgCharSetup(LocalPlayer.Character) end
        SpeedGlitchMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(asgCharSetup))

        SpeedGlitchMaid:GiveTask(function()
            if asgStepConn then asgStepConn:Disconnect() asgStepConn = nil end
        end)
        asgSyncStepConnection()
        SpeedGlitchMaid:GiveTasks(
            Services.UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(asgSyncStepConnection),
            Services.UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(asgSyncStepConnection)
        )
    end
end)
RootMaid:GiveTask(function() if SpeedGlitchMaid then SpeedGlitchMaid:DoCleaning() end end)

speedGlitchSection:AddToggle("Sideways Only", function(e) asgHorizontal = e end)
speedGlitchSection:AddSlider("Speed (0-255)", 0, 255, 0, function(v) asgValue = v end)

do
    local mapVoterSection = ataos:AddSection("Map Voter")
    local voterRespawnAmount = 12
    local savedPos, isRespawning, vmButtonEnabled
    local vmButtonSize = 0.11

    local function voteMap()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            shared.Notify("Error: Character not found", 1)
            return
        end

        savedPos = LocalPlayer.Character.HumanoidRootPart.Position
        isRespawning = true
        local count = 0

        shared.Notify("Vote Map: Starting "..voterRespawnAmount.." respawns...", 3)

        task.spawn(function()
            while count < voterRespawnAmount and isRespawning do
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.Health = 0
                    count += 1
                end
                task.wait(0.3)
            end
            isRespawning = false
            savedPos = nil
            shared.Notify("Vote Map: Completed "..count.." votes!", 3)
        end)

        local respawnCon = LocalPlayer.CharacterAdded:Connect(function(char)
            if savedPos then
                char:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(savedPos)
            else
                respawnCon:Disconnect()
            end
        end)
    end

    mapVoterSection:AddSlider("Votes Amount", 1, 20, voterRespawnAmount, function(v) voterRespawnAmount = v end)
    mapVoterSection:AddButton("Vote Map", voteMap)

    mapVoterSection:AddToggle("Enable VM Button", function(enabled)
        vmButtonEnabled = enabled

        if enabled then
            BindableButtons.AddBButton("vm_bind", "VM", voteMap)
            local btn = BindableButtons.Buttons["vm_bind"]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(vmButtonSize * (screen.Y / screen.X), 0, vmButtonSize, 0)
            end
        else
            BindableButtons.DeleteBButton("vm_bind")
        end
    end)

    mapVoterSection:AddSlider("VM Button Size", 5, 25, 11, function(value)
        vmButtonSize = value / 100
        local btn = BindableButtons.Buttons["vm_bind"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = __UD2(vmButtonSize * (screen.Y / screen.X), 0, vmButtonSize, 0)
        end
    end)
end

local whitelistSection = ataos:AddSection("Kill All")
local whitelist = {}
whitelistSection:AddLabel("Ignores Whitelisted Players")
whitelistSection:AddPlayerDropdown("Whitelist Player", function(p)
    if not table.find(whitelist, p.UserId) then
        table.insert(whitelist, p.UserId)
        shared.Notify(p.Name .. " whitelisted.", 2)
    end
end)
whitelistSection:AddButton("Clear Whitelist", function()
    whitelist = {}
    shared.Notify("Whitelist cleared.", 2)
end)

local KillAllMaid = nil
whitelistSection:AddButton("Kill All", function()
    if KillAllMaid then KillAllMaid:DoCleaning() KillAllMaid = nil end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local knife = (bp and bp:FindFirstChild("Knife"))
    if not knife then return shared.Notify("Knife not found!", 1) end

    KillAllMaid = Maid.new()
    local myChar = LocalPlayer.Character
    knife.Parent = myChar
    local root = myChar:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local offset = -2
    local offsetCF = CFrame.new(0, 0, offset)
    local targets = {}

    for _, p in Services.Players:GetPlayers() do
        if p ~= LocalPlayer and not table.find(whitelist, p.UserId) and p.Character and p.Character.PrimaryPart then
            table.insert(targets, p.Character)
        end
    end

    local function collectParts(model)
        local list = table.create(24)
        local n = 0
        for _, d in model:GetDescendants() do
            if d:IsA("BasePart") then
                n += 1
                list[n] = d
            end
        end
        return list
    end

    local myParts = collectParts(myChar)
    local targetParts = table.create(#targets)
    for i, c in targets do targetParts[i] = collectParts(c) end

    local start = tick()
    local nextScan = start + 0.25

    KillAllMaid:GiveTask(Services.RunService.RenderStepped:Connect(function()
        local now = tick()
        if now - start > 3 then
            if KillAllMaid then KillAllMaid:DoCleaning() KillAllMaid = nil end
            for _, p in myChar:GetDescendants() do if p:IsA("BasePart") and not p.CanCollide then p.CanCollide = true end end
            for _, c in targets do for _, p in c:GetDescendants() do if p:IsA("BasePart") and not p.CanCollide then p.CanCollide = true end end end
            return
        end

        if now >= nextScan then
            nextScan = now + 0.25
            myParts = collectParts(myChar)
            for i, c in targets do targetParts[i] = collectParts(c) end
        end

        for _, p in myParts do if p.CanCollide then p.CanCollide = false end end

        local rootCF = root.CFrame * offsetCF
        for i, c in targets do
            if c.PrimaryPart then
                c:SetPrimaryPartCFrame(rootCF)
                for _, p in targetParts[i] do if p.CanCollide then p.CanCollide = false end end
            end
        end
    end))
end)
RootMaid:GiveTask(function() if KillAllMaid then KillAllMaid:DoCleaning() end end)

do
    local flingSection = ataos:AddSection("Fling")
    local flingSelPlr, flingActive = nil, true
    local selectedPlayers = {}
    local whitelist = {}
    local flingButtonSize = 0.11
    local clickFlingEnabled = false
    local flingAuraEnabled = false
    local flingAuraStuds = 15
    local maids = {autoSheriff=nil, autoMurderer=nil, loopPlr=nil, loopAll=nil, clickFling=nil, flingAura=nil}
    local buttonToggles = {Sheriff=false, Murderer=false, Player=false}
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    RootMaid:GiveTask(function()
        for _, m in maids do if m then m:Destroy() end end
    end)

    local function isWhitelisted(player)
        return whitelist[player.UserId] == true
    end

    local function isPlayerSelected(player)
        for _, selected in selectedPlayers do
            if selected.UserId == player.UserId then
                return true
            end
        end
        return false
    end

    local roleRemote = nil

    local function invokeRoleRemote(remote)
        return remote:InvokeServer()
    end

    local function getRoleData()
        if not roleRemote or not roleRemote.Parent then
            local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
            roleRemote = (remote and remote:IsA("RemoteFunction")) and remote or nil
        end
        if not roleRemote then return nil end
        local success, data = pcall(invokeRoleRemote, roleRemote)
        if success then return data end
        return nil
    end

    local function findByRole(role)
        local roleData = getRoleData()
        if not roleData then return nil end
        for playerName, data in roleData do
            if data.Role == role and not data.Killed and not data.Dead then
                local p = Players:FindFirstChild(playerName)
                if p and not isWhitelisted(p) then return p end
            end
        end
        return nil
    end

    local function findSheriff()
        return findByRole("Sheriff")
    end

    local function findMurderer()
        return findByRole("Murderer")
    end

    local GUN_WORDS = {"gun", "pistol", "revolver", "shotgun", "rifle", "weapon"}

    local function isGunTool(tool)
        if not tool:IsA("Tool") then return false end
        local name = string.lower(tool.Name)
        for _, word in GUN_WORDS do
            if string.find(name, word, 1, true) then return true end
        end
        return false
    end

    local function hasGun(player)
        local character = player.Character
        if not character then return false end

        local backpack = player:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, tool in backpack:GetChildren() do
                if isGunTool(tool) then return true end
            end
        end

        for _, tool in character:GetChildren() do
            if isGunTool(tool) then return true end
        end

        return false
    end

    local function findSheriffWithFallback()
        local sheriff = findSheriff()
        if sheriff then return sheriff end

        for _, player in Players:GetPlayers() do
            if player ~= LocalPlayer and not isWhitelisted(player) and hasGun(player) then
                return player
            end
        end

        return nil
    end

    local ODHSKID_LIFT = CFrame.new(0, 0.5, 0)
    local ODHSKID_ZERO_VEC = Vector3.new()

    local function OdhSkid(TargetPlayer, duration)
        if isWhitelisted(TargetPlayer) then
            shared.Notify("Whitelist: "..TargetPlayer.Name.." is whitelisted!", 0)
            return
        end

        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart
        local TCharacter = TargetPlayer.Character

        if not (Character and Humanoid and RootPart and TCharacter) then return end

        local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
        local TRootPart = THumanoid and THumanoid.RootPart
        local THead = TCharacter:FindFirstChild("Head")
        local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
        local Handle = Accessory and Accessory:FindFirstChild("Handle")

        local genv = getgenv()
        if RootPart.Velocity.Magnitude < 50 then
            genv.OldPos = RootPart.CFrame
        end

        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif not THead and Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end

        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end

        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end

        local SFBasePart = function(BasePart)
            local TimeToWait = duration or 2
            local Time = tick()
            local Angle = 0

            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until not flingActive or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or tick() > Time + TimeToWait
        end

        local previousDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0

        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart and not THead then
            SFBasePart(TRootPart)
        elseif not TRootPart and THead then
            SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then
            SFBasePart(Handle)
        end

        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid

        repeat
            local oldPos = genv.OldPos
            if Character and Humanoid and RootPart and oldPos then
                local recovered = oldPos * ODHSKID_LIFT
                RootPart.CFrame = recovered
                Character:SetPrimaryPartCFrame(recovered)
                Humanoid:ChangeState("GettingUp")
                for _, x in Character:GetChildren() do
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = ODHSKID_ZERO_VEC, ODHSKID_ZERO_VEC
                    end
                end
            end
            task.wait()
            oldPos = genv.OldPos
        until not flingActive or (RootPart and oldPos and (RootPart.Position - oldPos.p).Magnitude < 25)

        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end

    flingSection:AddButton("Fling Sheriff", function()
        local target = findSheriffWithFallback()
        if target then OdhSkid(target, 2) else shared.Notify("Error: No Sheriff or Gun Holder Found", 1) end
    end)

    flingSection:AddButton("Fling Murderer", function()
        local murderer = findMurderer()
        if murderer then OdhSkid(murderer, 2) else shared.Notify("Error: No Murderer Found", 1) end
    end)

    flingSection:AddButton("Fling All", function()
        for _, p in Players:GetPlayers() do
            if p ~= LocalPlayer and not isWhitelisted(p) then
                OdhSkid(p, 2)
                task.wait(0.5)
            end
        end
    end)

    flingSection:AddPlayerDropdown("Fling Player", function(p)
        flingSelPlr = p
        if p ~= LocalPlayer and not isWhitelisted(p) then OdhSkid(p, 2) end
    end)

    flingSection:AddPlayerDropdown("Select Players", function(p)
        if p and p ~= LocalPlayer and not isPlayerSelected(p) then
            table.insert(selectedPlayers, p)
            shared.Notify("Selected: "..p.Name.." added to fling list", 3)
        elseif p and isPlayerSelected(p) then
            shared.Notify("Error: "..p.Name.." is already selected", 1)
        end
    end)

    flingSection:AddButton("Clear Selected Players", function()
        selectedPlayers = {}
        shared.Notify("Cleared: All selected players removed", 2)
    end)

    local function createAutoFling(name, findFunc)
        flingSection:AddToggle("Auto Fling "..name, function(enabled)
            if maids["auto"..name] then maids["auto"..name]:Destroy() end

            if enabled then
                maids["auto"..name] = Maid.new()
                local thread = task.spawn(function()
                    while true do
                        task.wait(1)
                        local target = findFunc()
                        if target then
                            OdhSkid(target, 2)
                            task.wait(3)
                        end
                    end
                end)
                maids["auto"..name]:GiveTask(function() task.cancel(thread) end)
            end
        end)
    end

    createAutoFling("Sheriff", findSheriffWithFallback)
    createAutoFling("Murderer", findMurderer)

    local buttonConfigs = {
        {name="Sheriff", text="FS", findFunc=findSheriffWithFallback, id="fling_sheriff"},
        {name="Murderer", text="FM", findFunc=findMurderer, id="fling_murderer"},
        {name="Player", text="FP", findFunc=function() return flingSelPlr end, id="fling_player"}
    }

    for _, cfg in buttonConfigs do
        flingSection:AddToggle("Enable "..cfg.text.." Button", function(enabled)
            buttonToggles[cfg.name] = enabled

            if enabled then
                BindableButtons.AddBButton(cfg.id, cfg.text, function()
                    local target = cfg.findFunc()
                    if target then
                        OdhSkid(target, 2)
                        shared.Notify("Success: Flinging "..cfg.name..": "..target.Name, 2)
                    else
                        shared.Notify("Error: No "..cfg.name.." Found", 1)
                    end
                end)
                local btn = BindableButtons.Buttons[cfg.id]
                if btn then
                    local screen = workspace.CurrentCamera.ViewportSize
                    btn.Size = __UD2(flingButtonSize * (screen.Y / screen.X), 0, flingButtonSize, 0)
                end
            else
                BindableButtons.DeleteBButton(cfg.id)
            end
        end)

        flingSection:AddSlider(cfg.name.." Button Size", 5, 25, 11, function(value)
            flingButtonSize = value / 100
            local btn = BindableButtons.Buttons[cfg.id]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(flingButtonSize * (screen.Y / screen.X), 0, flingButtonSize, 0)
            end
        end)
    end

    flingSection:AddPlayerDropdown("Add to Whitelist", function(p)
        if p and p ~= LocalPlayer then
            whitelist[p.UserId] = true
            shared.Notify("Whitelist: "..p.Name.." added to whitelist", 2)
        end
    end)

    flingSection:AddButton("Clear Whitelist", function()
        whitelist = {}
        shared.Notify("Whitelist: Whitelist cleared!", 2)
    end)

    flingSection:AddToggle("Loop Fling Player(s)", function(s)
        if maids.loopPlr then maids.loopPlr:Destroy() end

        if s then
            maids.loopPlr = Maid.new()
            local thread = task.spawn(function()
                while true do
                    if flingSelPlr and flingSelPlr.Parent and not isWhitelisted(flingSelPlr) then
                        OdhSkid(flingSelPlr, 2)
                        task.wait(3)
                    end

                    for _, player in selectedPlayers do
                        if player and player.Parent and not isWhitelisted(player) then
                            OdhSkid(player, 2)
                            task.wait(0.5)
                        end
                    end
                    task.wait(1)
                end
            end)
            maids.loopPlr:GiveTask(function() task.cancel(thread) end)
        end
    end)

    flingSection:AddToggle("Loop Fling All", function(s)
        if maids.loopAll then maids.loopAll:Destroy() end

        if s then
            maids.loopAll = Maid.new()
            local thread = task.spawn(function()
                while true do
                    for _, p in Players:GetPlayers() do
                        if p ~= LocalPlayer and p.Parent and not isWhitelisted(p) then
                            OdhSkid(p, 2)
                            task.wait(0.5)
                        end
                    end
                    task.wait(3)
                end
            end)
            maids.loopAll:GiveTask(function() task.cancel(thread) end)
        end
    end)

    flingSection:AddToggle("Click Fling", function(enabled)
        clickFlingEnabled = enabled

        if maids.clickFling then maids.clickFling:Destroy() end

        if enabled then
            maids.clickFling = Maid.new()

            local function onMouseClick(input, processed)
                if processed then return end

                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local mouse = LocalPlayer:GetMouse()
                    local target = mouse.Target

                    if target then
                        local character = target:FindFirstAncestorWhichIsA("Model")
                        if character then
                            local player = Players:GetPlayerFromCharacter(character)
                            if player and player ~= LocalPlayer and not isWhitelisted(player) then
                                OdhSkid(player, 2)
                                shared.Notify("Click Fling: Flinging "..player.Name, 2)
                            elseif player and isWhitelisted(player) then
                                shared.Notify("Click Fling: "..player.Name.." is whitelisted!", 0)
                            end
                        end
                    end
                end
            end

            if UserInputService.TouchEnabled then
                maids.clickFling:GiveTask(UserInputService.TouchTap:Connect(onMouseClick))
            end

            maids.clickFling:GiveTask(UserInputService.InputBegan:Connect(onMouseClick))
        end
    end)

    flingSection:AddToggle("Fling Aura", function(enabled)
        flingAuraEnabled = enabled

        if maids.flingAura then maids.flingAura:Destroy() end

        if enabled then
            maids.flingAura = Maid.new()
            local thread = task.spawn(function()
                while flingAuraEnabled do
                    task.wait(0.5)
                    local character = LocalPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

                    if rootPart then
                        for _, player in Players:GetPlayers() do
                            if player ~= LocalPlayer and not isWhitelisted(player) then
                                local targetChar = player.Character
                                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

                                if targetRoot and rootPart then
                                    local distance = (rootPart.Position - targetRoot.Position).Magnitude
                                    if distance <= flingAuraStuds then
                                        OdhSkid(player, 1)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            maids.flingAura:GiveTask(function() task.cancel(thread) end)
        end
    end)

    flingSection:AddSlider("Fling Aura Studs", 5, 50, 15, function(value)
        flingAuraStuds = value
    end)
end

do
    local trollSection = ataos:AddSection("Troll (FE)")
    trollSection:AddLabel("Play Troll Emotes")
    local trollButtonSize = 0.11

    local function makeEmote(eid, txt, gn)
        local playing, track, EmoteMaid

        local function stopEmote()
            if track then track:Stop() track = nil end
            playing = false
            if LocalPlayer.Character then
                local ani = LocalPlayer.Character:FindFirstChild("Animate")
                if ani then ani.Disabled = false end
            end
        end

        local function play()
            if playing then return end
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChild("Humanoid")
            if not h then return end

            local ani = c:FindFirstChild("Animate")
            if ani then ani.Disabled = true end
            for _, t in h:GetPlayingAnimationTracks() do t:Stop() end

            local a = Instance.new("Animation")
            a.AnimationId = "rbxassetid://"..eid
            track = h:LoadAnimation(a)
            track.Priority = Enum.AnimationPriority.Action
            track:Play()
            playing = true

            local tempMaid = Maid.new()
            tempMaid:GiveTasks(
                h.Running:Connect(function(s) if s > 0 then stopEmote() tempMaid:Destroy() end end),
                h.Jumping:Connect(function() stopEmote() tempMaid:Destroy() end),
                track.Stopped:Connect(function() stopEmote() tempMaid:Destroy() end)
            )
        end

        trollSection:AddToggle("Enable "..txt.." Button", function(e)
            if EmoteMaid then EmoteMaid:Destroy() EmoteMaid = nil end
            BindableButtons.DeleteBButton(gn)

            if e then
                EmoteMaid = Maid.new()
                BindableButtons.AddBButton(gn, txt, play)
                local btn = BindableButtons.Buttons[gn]
                if btn then
                    local screen = workspace.CurrentCamera.ViewportSize
                    btn.Size = __UD2(trollButtonSize * (screen.Y / screen.X), 0, trollButtonSize, 0)
                end
            end
        end)

        RootMaid:GiveTask(function() if EmoteMaid then EmoteMaid:Destroy() end end)
        trollSection:AddSlider(txt.." Button Size", 5, 25, 11, function(value)
            trollButtonSize = value / 100
            local btn = BindableButtons.Buttons[gn]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(trollButtonSize * (screen.Y / screen.X), 0, trollButtonSize, 0)
            end
        end)
        trollSection:AddButton("Play "..txt.." Emote", play)
    end

    makeEmote("84112287597268", "FD", "EmoteGUI_FakeDead")
    makeEmote("122366279755346", "KS", "EmoteGUI_KnifeSwing")
    makeEmote("103788740211648", "DS", "EmoteGUI_DualSwing")
end

do
    local rtxSection = ataos:AddSection("RTX")
    local rtx = {Sky=nil, Blur=nil, CC=nil, Bloom=nil, Sun=nil}
    local RTXMaid = nil
    RootMaid:GiveTask(function() if RTXMaid then RTXMaid:DoCleaning() end end)

    local function createRtxEffects()
        if not rtx.Sky then
            rtx.Sky = Instance.new("Sky")
            rtx.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=144933338"
            rtx.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=144931530"
            rtx.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=144933262"
            rtx.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=144933244"
            rtx.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=144933299"
            rtx.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=144931564"
            rtx.Sky.StarCount = 5000
            rtx.Sky.SunAngularSize = 5
            rtx.Sky.Parent = Services.Lighting
            if RTXMaid then RTXMaid:GiveTask(rtx.Sky) end
        end

        if not rtx.Bloom then
            rtx.Bloom = Instance.new("BloomEffect")
            rtx.Bloom.Intensity = 0.3
            rtx.Bloom.Size = 10
            rtx.Bloom.Threshold = 0.8
            rtx.Bloom.Parent = Services.Lighting
            if RTXMaid then RTXMaid:GiveTask(rtx.Bloom) end
        end

        if not rtx.Blur then
            rtx.Blur = Instance.new("BlurEffect")
            rtx.Blur.Size = 5
            rtx.Blur.Parent = Services.Lighting
            if RTXMaid then RTXMaid:GiveTask(rtx.Blur) end
        end

        if not rtx.CC then
            rtx.CC = Instance.new("ColorCorrectionEffect")
            rtx.CC.Brightness = 0
            rtx.CC.Contrast = 0.1
            rtx.CC.Saturation = 0.25
            rtx.CC.TintColor = Color3.fromRGB(255, 255, 255)
            rtx.CC.Parent = Services.Lighting
            if RTXMaid then RTXMaid:GiveTask(rtx.CC) end
        end

        if not rtx.Sun then
            rtx.Sun = Instance.new("SunRaysEffect")
            rtx.Sun.Intensity = 0.1
            rtx.Sun.Spread = 0.8
            rtx.Sun.Parent = Services.Lighting
            if RTXMaid then RTXMaid:GiveTask(rtx.Sun) end
        end
    end

    local function setRtx(enabled)
        if RTXMaid then RTXMaid:DoCleaning() RTXMaid = nil end

        if enabled then
            RTXMaid = Maid.new()
            rtx = {Sky=nil, Blur=nil, CC=nil, Bloom=nil, Sun=nil}
            createRtxEffects()

            Services.Lighting.Brightness = 2.25
            Services.Lighting.ExposureCompensation = 0.1
            Services.Lighting.ClockTime = 17.55
            RTXMaid:GiveTask(function()
                 Services.Lighting.Brightness = 2
                 Services.Lighting.ExposureCompensation = 0
            end)

            for _, v in rtx do
                if v and v:IsA("PostEffect") then v.Enabled = true end
            end
        else
            rtx = {Sky=nil, Blur=nil, CC=nil, Bloom=nil, Sun=nil}
        end
    end

    rtxSection:AddToggle("Enable RTX", setRtx)
end

do
    local lsSection = ataos:AddSection("Legit Speedglitch")
    local sideSpd = 0
    local lsHori = false
    local lsButtonSize = 0.11
    local emOn = false
    local selEmote = nil
    local emotes = {Moonwalk="79127989560307", Yungblud="15610015346", ["Bouncy Twirl"]="14353423348", ["Flex Walk"]="15506506103"}
    local lsSelectedEmoteName, lsDropdownTouched = nil, false
    local LegitSpeedMaid = nil
    local lsBindButton = nil
    local lsButtonStroke = nil
    local lsChar, lsHum, lsRoot = nil, nil, nil

    RootMaid:GiveTask(function() if LegitSpeedMaid then LegitSpeedMaid:DoCleaning() end end)

    local LS_COLOR_ON = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 200, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 0))
    })
    local LS_COLOR_OFF = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(200, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 0))
    })

    local function UpdateButtonColor()
        if not lsBindButton or not lsButtonStroke then return end
        lsButtonStroke.Color = emOn and LS_COLOR_ON or LS_COLOR_OFF
    end

    local function playE(id)
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if not h then return end

        local success = pcall(function() h:PlayEmoteAndGetAnimTrackById(id) end)
        if not success then
            local a = Instance.new("Animation")
            a.AnimationId = "rbxassetid://"..id
            h:LoadAnimation(a):Play()
        end
    end

    lsSection:AddToggle("Enable SG Bindable Button", function(e)
        if LegitSpeedMaid then LegitSpeedMaid:DoCleaning() LegitSpeedMaid = nil end
        BindableButtons.DeleteBButton("sg_bind")
        lsBindButton = nil
        lsButtonStroke = nil
        emOn = false

        if e then
            LegitSpeedMaid = Maid.new()

            BindableButtons.AddBButton("sg_bind", "SG", function()
                emOn = not emOn
                if emOn and selEmote then
                    playE(selEmote)
                elseif not emOn and LocalPlayer.Character then
                    LocalPlayer.Character.Humanoid.WalkSpeed = 16
                end
                UpdateButtonColor()
            end)
            lsBindButton = BindableButtons.Buttons["sg_bind"]
            if lsBindButton then
                local screen = workspace.CurrentCamera.ViewportSize
                lsBindButton.Size = __UD2(lsButtonSize * (screen.Y / screen.X), 0, lsButtonSize, 0)
                lsButtonStroke = lsBindButton:FindFirstChild("@Stroke")
                UpdateButtonColor()
            end

            LegitSpeedMaid:GiveTask(Services.RunService.Stepped:Connect(function()
                if not emOn then return end

                local c = LocalPlayer.Character
                if c ~= lsChar then
                    lsChar, lsHum, lsRoot = c, nil, nil
                end
                if not c then return end
                if not lsHum then lsHum = c:FindFirstChild("Humanoid") end
                if not lsRoot then lsRoot = c:FindFirstChild("HumanoidRootPart") end
                local h, r = lsHum, lsRoot
                if not h or not r then return end

                local state = h:GetState()
                local lsAir = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping

                if lsAir then
                    local spd = 16 + sideSpd
                    if lsHori then
                        h.WalkSpeed = (math.abs(h.MoveDirection:Dot(r.CFrame.RightVector)) > 0.5) and spd or 16
                    else
                        h.WalkSpeed = spd
                    end
                else
                    h.WalkSpeed = 16
                end
            end))
        end
    end)

    lsSection:AddSlider("Speed (0-255)", 0, 255, sideSpd, function(v) sideSpd = v end)
    lsSection:AddSlider("Button Size", 5, 25, 11, function(value)
        lsButtonSize = value / 100
        if lsBindButton then
            local screen = workspace.CurrentCamera.ViewportSize
            lsBindButton.Size = __UD2(lsButtonSize * (screen.Y / screen.X), 0, lsButtonSize, 0)
        end
    end)
    lsSection:AddToggle("Sideways Only", function(e) lsHori = e end)

    lsSection:AddDropdown("SG Select Emote", {"Moonwalk", "Yungblud", "Bouncy Twirl", "Flex Walk", "Custom"}, function(s)
        lsDropdownTouched = true
        lsSelectedEmoteName = s
        selEmote = (s ~= "Custom") and emotes[s] or nil
    end)

    lsSection:AddTextBox("SG Custom Emote ID", function(t)
        if lsDropdownTouched and lsSelectedEmoteName == "Custom" and t ~= "" then
            selEmote = t
        end
    end)
end

do
    local hlSection = ataos:AddSection("FE Headless")
    hlSection:AddLabel("V2 & Higher Require a Very Small Head")
    local hlId = 78837807518622
    local hlId2 = 117080641351340
    local hlId3 = 136055001302601

    local hl1 = {maid = nil}
    local hl2 = {maid = nil}
    local hl3 = {maid = nil}

    local function stopHl(st)
        if st.conn then st.conn:Disconnect() st.conn = nil end
        if st.track then
            local t = st.track
            st.track = nil
            t:Stop()
            t:Destroy()
        end
        if st.anim then st.anim:Destroy() st.anim = nil end
    end

    local function playHl(hum, id, st)
        local maid = st.maid
        if not maid or maid._destroyed then return end
        if not hum or not hum.Parent then return end
        local ani = hum:FindFirstChildOfClass("Animator")
        if not ani then return end

        stopHl(st)

        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://"..id
        local hlTrack = ani:LoadAnimation(a)
        hlTrack.Priority = Enum.AnimationPriority.Action
        hlTrack.Looped = true
        hlTrack:Play()
        st.anim, st.track = a, hlTrack

        st.conn = hlTrack.Stopped:Connect(function()
            if not st.maid or st.maid._destroyed then return end
            if hum.Parent then task.wait(0.1) playHl(hum, id, st) end
        end)
    end

    local function applyFreeze(hum, id, st)

        if st.freeze then st.freeze:Disconnect() st.freeze = nil end
        st.freeze = hum.StateChanged:Connect(function()
            local maid = st.maid
            if not maid or maid._destroyed then return end
            if hum.Parent then
                task.wait(0.05)
                if not st.maid or st.maid._destroyed then return end
                if hum.Parent then playHl(hum, id, st) end
            end
        end)
    end

    local function enableHl(id, st)
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("Humanoid")
        if not h then return end
        applyFreeze(h, id, st)
        playHl(h, id, st)
    end

    local function setHeadless(st, id, enabled)
        if st.maid then st.maid:DoCleaning() st.maid = nil end
        if st.freeze then st.freeze:Disconnect() st.freeze = nil end
        stopHl(st)
        if not enabled then return end

        st.maid = Maid.new()
        st.maid:GiveTask(function()
            if st.freeze then st.freeze:Disconnect() st.freeze = nil end
            stopHl(st)
        end)
        enableHl(id, st)
        st.maid:GiveTask(LocalPlayer.CharacterAdded:Connect(function(c)
            task.wait(0.5)
            enableHl(id, st)
        end))
    end

    RootMaid:GiveTask(function()
        setHeadless(hl1, hlId, false)
        setHeadless(hl2, hlId2, false)
        setHeadless(hl3, hlId3, false)
    end)

    hlSection:AddToggle("Enable Headless", function(s)
        setHeadless(hl1, hlId, s)
    end)

    hlSection:AddToggle("Enable Headless V2", function(s)
        setHeadless(hl2, hlId2, s)
    end)

    hlSection:AddToggle("Enable Headless V3", function(s)
        setHeadless(hl3, hlId3, s)
    end)
end

do
    local perkSection = ataos:AddSection("Perks")
    local hasteOn, blatantMode, hasteSpd = false, false, 18
    local PerkMaid

    RootMaid:GiveTask(function() if PerkMaid then PerkMaid:Destroy() end end)

    local function updSpd()
        if not hasteOn then return end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("Humanoid")
        if not h then return end
        local knifeInChar = c:FindFirstChild("Knife")
        h.WalkSpeed = (knifeInChar or (LocalPlayer.Backpack:FindFirstChild("Knife") and knifeInChar))
            and hasteSpd or 16
    end

    perkSection:AddToggle("Enable Auto Haste", function(s)
        hasteOn = s
        if PerkMaid then PerkMaid:Destroy() end

        if s then
            PerkMaid = Maid.new()
            PerkMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function(c)
                local h = c:WaitForChild("Humanoid")
                PerkMaid:GiveTasks(c.ChildAdded:Connect(updSpd), c.ChildRemoved:Connect(updSpd))
                task.wait(0.5)
                updSpd()
            end))

            if LocalPlayer.Character then
                PerkMaid:GiveTasks(
                    LocalPlayer.Character.ChildAdded:Connect(updSpd),
                    LocalPlayer.Character.ChildRemoved:Connect(updSpd)
                )
                updSpd()
            end
        elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end)

    perkSection:AddToggle("Enable Blatant Mode", function(s)
        blatantMode = s
        hasteSpd = blatantMode and 19 or 18
        updSpd()
    end)
    perkSection:AddLabel("Stacks With Other Perks")
end

do
    local wallhopSection = ataos:AddSection("Wallhop")

    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer

    local wallhopToggle = false
    local flickEnabled = false
    local InfiniteJumpEnabled = true
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local WallhopMaid = nil
    RootMaid:GiveTask(function() if WallhopMaid then WallhopMaid:DoCleaning() end end)

    local function getWallRaycastResult()
        local character = player.Character
        if not character then return nil end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return nil end

        raycastParams.FilterDescendantsInstances = {character}
        local detectionDistance = 2
        local closestHit = nil
        local minDistance = detectionDistance + 1
        local hrpCF = humanoidRootPart.CFrame

        for i = 0, 7 do
            local angle = math.rad(i * 45)
            local direction = (hrpCF * CFrame.Angles(0, angle, 0)).LookVector
            local ray = Workspace:Raycast(humanoidRootPart.Position, direction * detectionDistance, raycastParams)
            if ray and ray.Instance and ray.Distance < minDistance then
                minDistance = ray.Distance
                closestHit = ray
            end
        end

        local blockCastSize = Vector3.new(1.5, 1, 0.5)
        local blockCastOffset = CFrame.new(0, -1, -0.5)
        local blockCastOriginCF = hrpCF * blockCastOffset
        local blockCastDirection = hrpCF.LookVector
        local blockCastDistance = 1.5
        local blockResult = Workspace:Blockcast(blockCastOriginCF, blockCastSize, blockCastDirection * blockCastDistance, raycastParams)

        if blockResult and blockResult.Instance and blockResult.Distance < minDistance then
            minDistance = blockResult.Distance
            closestHit = blockResult
        end

        return closestHit
    end

    local function executeWallJump(wallRayResult)
        if not InfiniteJumpEnabled then return end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local camera = Workspace.CurrentCamera

        if not (humanoid and rootPart and camera and humanoid:GetState() ~= Enum.HumanoidStateType.Dead and wallRayResult) then
            return
        end

        InfiniteJumpEnabled = false

        if flickEnabled then
            local maxInfluenceAngleRight = math.rad(20)
            local maxInfluenceAngleLeft  = math.rad(-100)

            local wallNormal = wallRayResult.Normal
            local baseDirectionAwayFromWall = Vector3.new(wallNormal.X, 0, wallNormal.Z).Unit
            if baseDirectionAwayFromWall.Magnitude < 0.1 then
                local dirToHit = (wallRayResult.Position - rootPart.Position) * Vector3.new(1,0,0)
                baseDirectionAwayFromWall = -dirToHit.Unit
                if baseDirectionAwayFromWall.Magnitude < 0.1 then
                    baseDirectionAwayFromWall = -rootPart.CFrame.LookVector * Vector3.new(1, 0, 0)
                    if baseDirectionAwayFromWall.Magnitude > 0.1 then baseDirectionAwayFromWall = baseDirectionAwayFromWall.Unit end
                    if baseDirectionAwayFromWall.Magnitude < 0.1 then baseDirectionAwayFromWall = Vector3.new(0,0,1) end
                end
            end
            baseDirectionAwayFromWall = Vector3.new(baseDirectionAwayFromWall.X, 0, baseDirectionAwayFromWall.Z).Unit
            if baseDirectionAwayFromWall.Magnitude < 0.1 then baseDirectionAwayFromWall = Vector3.new(0,0,1) end

            local cameraLook = camera.CFrame.LookVector
            local horizontalCameraLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
            if horizontalCameraLook.Magnitude < 0.1 then horizontalCameraLook = baseDirectionAwayFromWall end

            local dot = math.clamp(baseDirectionAwayFromWall:Dot(horizontalCameraLook), -1, 1)
            local angleBetween = math.acos(dot)
            local cross = baseDirectionAwayFromWall:Cross(horizontalCameraLook)
            local rotationSign = -math.sign(cross.Y)
            if rotationSign == 0 then angleBetween = 0 end

            local actualInfluenceAngle
            if rotationSign == 1 then
                actualInfluenceAngle = math.min(angleBetween, maxInfluenceAngleRight)
            elseif rotationSign == -1 then
                actualInfluenceAngle = math.min(angleBetween, maxInfluenceAngleLeft)
            else
                actualInfluenceAngle = 0
            end

            local adjustmentRotation = CFrame.Angles(0, actualInfluenceAngle * rotationSign, 0)
            local initialTargetLookDirection = adjustmentRotation * baseDirectionAwayFromWall

            rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + initialTargetLookDirection)
            RunService.Heartbeat:Wait()

            if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

                rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, -1, 0)
                task.wait(0.15)
                rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, 1, 0)
            end

            local directionTowardsWall = -baseDirectionAwayFromWall
            task.wait(0.05)
            rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + directionTowardsWall)
        else
            if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end

        task.wait(0.1)
        InfiniteJumpEnabled = true
    end

    wallhopSection:AddToggle("Enable Wallhop", function(enabled)
        if WallhopMaid then WallhopMaid:DoCleaning() WallhopMaid = nil end
        wallhopToggle = enabled

        if enabled then
            WallhopMaid = Maid.new()
            WallhopMaid:GiveTask(UserInputService.JumpRequest:Connect(function()
                if not wallhopToggle then return end

                local wallRayResult = getWallRaycastResult()
                if wallRayResult then
                    executeWallJump(wallRayResult)
                end
            end))
        end
    end)

    wallhopSection:AddToggle("Enable Wallhop Flick", function(enabled)
        flickEnabled = enabled
    end)
end

do
    local ssSection = ataos:AddSection("Sign Spam")
    local spamming = false
    local ssButtonEnabled = false
    local ssButtonSize = 0.11
    local autoGetGG = false
    local SignSpamMaid = nil
    local SignSpamAutoMaid = nil

    RootMaid:GiveTask(function()
        if SignSpamMaid then SignSpamMaid:DoCleaning() end
        if SignSpamAutoMaid then SignSpamAutoMaid:DoCleaning() end
    end)

    local function getSign()
        pcall(function()
            Services.ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("GGSign")
        end)
    end

    local function isSignTool(tool)
        return tool:IsA("Tool") and string.find(string.lower(tool.Name), "sign", 1, true) ~= nil
    end

    local function findInBackpack()
        local backpack = LocalPlayer:WaitForChild("Backpack")
        for _, tool in backpack:GetChildren() do
            if isSignTool(tool) then
                return true
            end
        end
        return false
    end

    local function findSign(backpack)
        backpack = backpack or LocalPlayer:WaitForChild("Backpack")
        local character = LocalPlayer.Character

        for _, tool in backpack:GetChildren() do
            if isSignTool(tool) then
                return tool, backpack
            end
        end

        if character then
            for _, tool in character:GetChildren() do
                if isSignTool(tool) then
                    return tool, character
                end
            end
        end

        return nil, nil
    end

    local function startSpam()
        spamming = true
        if SignSpamMaid then SignSpamMaid:DoCleaning() SignSpamMaid = nil end
        SignSpamMaid = Maid.new()

        local thread = task.spawn(function()

            local backpack = LocalPlayer:WaitForChild("Backpack")
            while spamming do
                local character = LocalPlayer.Character
                if not character then task.wait(0.1) continue end

                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid then task.wait(0.1) continue end

                if not backpack or backpack.Parent ~= LocalPlayer then
                    backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                    if not backpack then task.wait(0.1) continue end
                end

                local tool, location = findSign(backpack)

                if tool then
                    if location == backpack then
                        humanoid:EquipTool(tool)
                    end
                    task.wait(0.05)
                    humanoid:UnequipTools()
                    task.wait(0.05)
                else
                    task.wait(0.5)
                end
            end
        end)
        SignSpamMaid:GiveTask(function() task.cancel(thread) end)
    end

    local function stopSpam()
        spamming = false
        if SignSpamMaid then SignSpamMaid:DoCleaning() SignSpamMaid = nil end
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:UnequipTools() end
        end
    end

    ssSection:AddToggle("Enable Auto-Get GG", function(state)
        if SignSpamAutoMaid then SignSpamAutoMaid:DoCleaning() SignSpamAutoMaid = nil end
        autoGetGG = state
        if state then
            SignSpamAutoMaid = Maid.new()
            if not findInBackpack() then
                getSign()
            end
            SignSpamAutoMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1)
                if autoGetGG then getSign() end
            end))
        end
    end)

    ssSection:AddToggle("Enable Sign Spam", function(state)
        if state then startSpam() else stopSpam() end
    end)

    ssSection:AddToggle("Enable SS Button", function(enabled)
        ssButtonEnabled = enabled

        if enabled then
            BindableButtons.AddBButton("ss_bind", "SS", function()
                if spamming then stopSpam() else startSpam() end
            end)
            local btn = BindableButtons.Buttons["ss_bind"]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(ssButtonSize * (screen.Y / screen.X), 0, ssButtonSize, 0)
            end
        else
            BindableButtons.DeleteBButton("ss_bind")
        end
    end)

    ssSection:AddSlider("SS Button Size", 5, 25, 11, function(value)
        ssButtonSize = value / 100
        local btn = BindableButtons.Buttons["ss_bind"]
        if btn then
            local screen = workspace.CurrentCamera.ViewportSize
            btn.Size = __UD2(ssButtonSize * (screen.Y / screen.X), 0, ssButtonSize, 0)
        end
    end)
end

local autoGGSection = ataos:AddSection("Auto Grab Gun")
local autoGGEnabled = false

local autoGGMaid = nil
RootMaid:GiveTask(function() if autoGGMaid then autoGGMaid:DoCleaning() end end)

local function touch(a, b)
    firetouchinterest(a, b, 0)
    firetouchinterest(a, b, 1)
end

local function findGunDrop()
    local hit = workspace:FindFirstChild("GunDrop", true)
    if not hit then return nil end
    if hit:IsA("BasePart") then return hit end
    for _, obj in workspace:GetDescendants() do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") then
            return obj
        end
    end
    return nil
end

local function bringGun(gunDrop)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    gunDrop = gunDrop or findGunDrop()
    if rootPart and gunDrop then
        touch(rootPart, gunDrop)
    end
end

local function hasGunInInventory()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    if char then
        for _, tool in char:GetChildren() do
            if tool:IsA("Tool") and tool.Name == "Gun" then
                return true
            end
        end
    end
    if backpack then
        for _, tool in backpack:GetChildren() do
            if tool:IsA("Tool") and tool.Name == "Gun" then
                return true
            end
        end
    end
    return false
end

local function grabGun(gunDrop)
    gunDrop = gunDrop or findGunDrop()
    if not gunDrop then return false end
    if hasGunInInventory() then return true end
    bringGun(gunDrop)
    task.wait(0.5)
    return hasGunInInventory()
end

autoGGSection:AddToggle("Enable Auto GG", function(enabled)
    autoGGEnabled = enabled
    if autoGGMaid then autoGGMaid:DoCleaning() autoGGMaid = nil end
    if enabled then
        autoGGMaid = Maid.new()
        local thread = task.spawn(function()
            while autoGGEnabled do
                if LocalPlayer.Character then

                    local gunDrop = findGunDrop()
                    if gunDrop and not hasGunInInventory() then
                        grabGun(gunDrop)
                    end
                end
                task.wait(0.5)
            end
        end)

        autoGGMaid:GiveTask(function()
            autoGGEnabled = false
            pcall(task.cancel, thread)
        end)
    end
end)

local statColorsEnabled = false
local uiPosition = "Top Right"

local positionPresets = {
    ["Top Right"]    = UDim2.new(0.80, 0, 0, 15),
    ["Top Left"]     = UDim2.new(0.02, 0, 0, 15),
    ["Top Center"]   = UDim2.new(0.44, 0, 0, 15),
    ["Bottom Right"] = UDim2.new(0.80, 0, 0.85, 0),
    ["Bottom Left"]  = UDim2.new(0.02, 0, 0.85, 0),
}

local STAT_GOOD  = Color3.fromRGB(0, 255, 0)
local STAT_OKAY  = Color3.fromRGB(255, 200, 0)
local STAT_BAD   = Color3.fromRGB(255, 0, 0)
local STAT_PLAIN = Color3.fromRGB(255, 255, 255)

local function getFpsCap()
    local cap = workspace:GetAttribute("FPSCap") or 60
    return cap
end

local function getFpsColor(fps, cap)
    if fps >= cap * 0.85 then
        return STAT_GOOD
    elseif fps >= cap * 0.5 then
        return STAT_OKAY
    else
        return STAT_BAD
    end
end

local function getPingColor(ping)
    if ping <= 80 then
        return STAT_GOOD
    elseif ping <= 150 then
        return STAT_OKAY
    else
        return STAT_BAD
    end
end

local function applyPosition(Fps, Ping, preset)
    local base = positionPresets[preset] or positionPresets["Top Right"]
    Fps.Position = base
    Ping.Position = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset + 28)
end

local function createFpsPingGui()
    if _G.FpsPingGui then
        _G.FpsPingGui:Destroy()
    end

    repeat task.wait() until game:IsLoaded()
    task.wait(0.25)

    local ScreenGui = Instance.new("ScreenGui")
    local Fps = Instance.new("TextLabel")
    local Ping = Instance.new("TextLabel")

    ScreenGui.Name = "FpsPingMonitor"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    Fps.BackgroundTransparency = 1
    Fps.Size = UDim2.new(0, 120, 0, 25)
    Fps.Font = Enum.Font.SourceSans
    Fps.TextColor3 = STAT_PLAIN
    Fps.TextScaled = true
    Fps.Text = "0"
    Fps.Parent = ScreenGui

    Ping.BackgroundTransparency = 1
    Ping.Size = UDim2.new(0, 120, 0, 25)
    Ping.Font = Enum.Font.SourceSans
    Ping.TextColor3 = STAT_PLAIN
    Ping.TextScaled = true
    Ping.Text = "0"
    Ping.Parent = ScreenGui

    applyPosition(Fps, Ping, uiPosition)

    ScreenGui.Parent = Services.CoreGui
    _G.FpsPingGui = ScreenGui
    _G.FpsLabel = Fps
    _G.PingLabel = Ping

    local Stats = Services.Stats
    local lastFPS = -1
    local lastPing = -1
    local lastFpsColor = nil
    local lastPingColor = nil
    local lastPingUpdate = 0
    local pingInterval = 0.5

    local fpsCap = getFpsCap()
    local connection

    connection = Services.RunService.RenderStepped:Connect(function(frame)
        if not ScreenGui.Parent then
            if connection then connection:Disconnect() connection = nil end
            return
        end

        local fps = math.floor(1 / frame + 0.5)
        if fps ~= lastFPS then
            lastFPS = fps
            Fps.Text = tostring(fps)
        end
        local fpsColor = statColorsEnabled and getFpsColor(fps, fpsCap) or STAT_PLAIN
        if fpsColor ~= lastFpsColor then
            lastFpsColor = fpsColor
            Fps.TextColor3 = fpsColor
        end

        local now = os.clock()
        if now - lastPingUpdate >= pingInterval then
            lastPingUpdate = now
            fpsCap = getFpsCap()
            local pingValue = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
            local rawPing = tonumber(pingValue:match("%-?%d+")) or 0
            if rawPing ~= lastPing then
                lastPing = rawPing
                Ping.Text = tostring(rawPing)
            end
            local pingColor = statColorsEnabled and getPingColor(rawPing) or STAT_PLAIN
            if pingColor ~= lastPingColor then
                lastPingColor = pingColor
                Ping.TextColor3 = pingColor
            end
        end
    end)
end

local fps_ping_section = ataos:AddSection("FPS & PING MONITOR")

fps_ping_section:AddToggle("Enable Monitor UI", function(bool)
    if bool then
        createFpsPingGui()
    else
        if _G.FpsPingGui then
            _G.FpsPingGui:Destroy()
            _G.FpsPingGui = nil
            _G.FpsLabel = nil
            _G.PingLabel = nil
        end
    end
end)

RootMaid:GiveTask(function()
    if _G.FpsPingGui then
        _G.FpsPingGui:Destroy()
        _G.FpsPingGui = nil
        _G.FpsLabel = nil
        _G.PingLabel = nil
    end
end)

fps_ping_section:AddToggle("Enable Statistic Colors", function(bool)
    statColorsEnabled = bool
end)

fps_ping_section:AddDropdown("UI Position", {
    "Top Right", "Top Left", "Top Center",
    "Bottom Right", "Bottom Left"
}, function(s)
    uiPosition = s
    if _G.FpsLabel and _G.PingLabel then
        applyPosition(_G.FpsLabel, _G.PingLabel, s)
    end
end)

local fpsBoostEnabled = false
local fpsBoostActive = false
local FpsBoostMaid = nil

local fpsBoostState = setmetatable({}, {__mode = "ks"})
local fpsBoostScalars = nil

local function fpsBoostSet(obj, prop, value)
    obj[prop] = value
end

local function fpsBoostGet(obj, prop)
    return obj[prop]
end

local function fpsRemember(obj, prop)
    local st = fpsBoostState[obj]
    if not st then
        st = {}
        fpsBoostState[obj] = st
    end
    if st[prop] == nil then

        local ok, current = pcall(fpsBoostGet, obj, prop)
        if ok then st[prop] = current end
    end
end

local function fpsSetTracked(obj, prop, value)
    fpsRemember(obj, prop)
    pcall(fpsBoostSet, obj, prop, value)
end

local function isLightingEffect(obj)
    return obj:IsA("PostEffect") or obj:IsA("Sky") or obj:IsA("Atmosphere")
end

local function dgMeshPart(obj)
    fpsSetTracked(obj, "CastShadow", false)
    fpsSetTracked(obj, "RenderFidelity", Enum.RenderFidelity.Disabled)
    fpsSetTracked(obj, "LODFactor", 0)
end

local function dgBasePart(obj)
    fpsSetTracked(obj, "CastShadow", false)
end

local function dgSpecialMesh(obj)
    fpsSetTracked(obj, "LOD", Enum.MeshPartDetailLevel.Disabled)
end

local function dgParticleEmitter(obj)
    fpsSetTracked(obj, "Enabled", false)
    fpsSetTracked(obj, "Rate", 0)
end

local function dgEnabledOff(obj)
    fpsSetTracked(obj, "Enabled", false)
end

local function dgExplosion(obj)
    fpsSetTracked(obj, "BlastPressure", 0)
end

local function dgSelectionBox(obj)
    fpsSetTracked(obj, "Visible", false)
end

local function dgTransparent(obj)
    fpsSetTracked(obj, "Transparency", 1)
end

local function dgSkyDetach(obj)
    fpsSetTracked(obj, "Parent", nil)
end

local degradeByClass = {}

local function resolveDegrade(obj)
    if obj:IsA("MeshPart") then return dgMeshPart
    elseif obj:IsA("BasePart") then return dgBasePart
    elseif obj:IsA("SpecialMesh") then return dgSpecialMesh
    elseif obj:IsA("ParticleEmitter") then return dgParticleEmitter
    elseif obj:IsA("Trail") then return dgEnabledOff
    elseif obj:IsA("Smoke") then return dgEnabledOff
    elseif obj:IsA("Fire") then return dgEnabledOff
    elseif obj:IsA("Sparkles") then return dgEnabledOff
    elseif obj:IsA("Explosion") then return dgExplosion
    elseif obj:IsA("SelectionBox") then return dgSelectionBox
    elseif obj:IsA("BillboardGui") then return dgEnabledOff
    elseif obj:IsA("SurfaceGui") then return dgEnabledOff
    elseif obj:IsA("Decal") then return dgTransparent
    elseif obj:IsA("Texture") then return dgTransparent
    elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then return dgEnabledOff
    elseif obj:IsA("Sky") then return dgSkyDetach
    end
    return false
end

local function degradePart(obj)
    local cn = obj.ClassName
    local h = degradeByClass[cn]
    if h == nil then
        h = resolveDegrade(obj)
        degradeByClass[cn] = h
    end
    if h then h(obj) end
end
local function degradePartDeferred(obj)
    if not fpsBoostActive then return end
    degradePart(obj)
end

local function applyFpsBoost()
    if fpsBoostActive then return end
    if FpsBoostMaid then FpsBoostMaid:DoCleaning() FpsBoostMaid = nil end
    FpsBoostMaid = Maid.new()
    fpsBoostActive = true

    local Lighting = Services.Lighting
    local localPlayer = LocalPlayer
    local Terrain = workspace.Terrain
    local renderSettings = settings().Rendering

    fpsBoostScalars = {
        Lighting = Lighting,
        Terrain = Terrain,
        Rendering = renderSettings,
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        QualityLevel = renderSettings.QualityLevel,
        MeshPartDetailLevel = renderSettings.MeshPartDetailLevel,
        WaterWaveSize = Terrain.WaterWaveSize,
        WaterWaveSpeed = Terrain.WaterWaveSpeed,
        Decoration = Terrain.Decoration,
        WaterReflectance = Terrain.WaterReflectance,
        WaterTransparency = Terrain.WaterTransparency
    }

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    Lighting.FogStart = 100000
    Lighting.Brightness = 1
    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    Lighting.ClockTime = 14

    for _, effect in Lighting:GetChildren() do
        if isLightingEffect(effect) then
            fpsSetTracked(effect, "Enabled", false)
        end
    end

    renderSettings.QualityLevel = Enum.QualityLevel.Level01
    renderSettings.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Disabled

    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.Decoration = false
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0

    if localPlayer and localPlayer.Character then
        for _, obj in localPlayer.Character:GetDescendants() do
            if obj:IsA("Accessory") or obj:IsA("Hat") then
                for _, part in obj:GetDescendants() do
                    if part:IsA("BasePart") then
                        fpsSetTracked(part, "CastShadow", false)
                    end
                end
            end
        end
    end

    FpsBoostMaid:GiveTask(workspace.DescendantAdded:Connect(function(obj)
        task.defer(degradePartDeferred, obj)
    end))

    FpsBoostMaid:GiveTask(Lighting.DescendantAdded:Connect(function(obj)
        if fpsBoostActive and isLightingEffect(obj) then
            fpsSetTracked(obj, "Enabled", false)
        end
    end))

    if localPlayer then
        FpsBoostMaid:GiveTask(localPlayer.CharacterAdded:Connect(function(char)
            if not fpsBoostActive then return end
            for _, obj in char:GetDescendants() do
                degradePart(obj)
            end

            FpsBoostMaid:GiveTask(char.DescendantAdded:Connect(function(obj)
                task.defer(degradePartDeferred, obj)
            end))
        end))
    end

    local all = workspace:GetDescendants()
    local total = #all
    local i = 1
    while i <= total do
        if not fpsBoostActive then return end
        local stop = math.min(i + 499, total)
        for j = i, stop do
            degradePart(all[j])
        end
        i = stop + 1
        task.wait()
    end
end

local function removeFpsBoost()
    if FpsBoostMaid then FpsBoostMaid:DoCleaning() FpsBoostMaid = nil end
    if not fpsBoostActive then return end
    fpsBoostActive = false

    local scalars = fpsBoostScalars
    if scalars then
        local Lighting = scalars.Lighting
        Lighting.GlobalShadows = scalars.GlobalShadows
        Lighting.FogEnd = scalars.FogEnd
        Lighting.FogStart = scalars.FogStart
        Lighting.Brightness = scalars.Brightness
        Lighting.Ambient = scalars.Ambient
        Lighting.OutdoorAmbient = scalars.OutdoorAmbient
        Lighting.ClockTime = scalars.ClockTime

        local renderSettings = scalars.Rendering
        renderSettings.QualityLevel = scalars.QualityLevel
        renderSettings.MeshPartDetailLevel = scalars.MeshPartDetailLevel

        local Terrain = scalars.Terrain
        Terrain.WaterWaveSize = scalars.WaterWaveSize
        Terrain.WaterWaveSpeed = scalars.WaterWaveSpeed
        Terrain.Decoration = scalars.Decoration
        Terrain.WaterReflectance = scalars.WaterReflectance
        Terrain.WaterTransparency = scalars.WaterTransparency
        fpsBoostScalars = nil
    end

    for obj, st in fpsBoostState do
        for prop, value in st do
            pcall(fpsBoostSet, obj, prop, value)
        end
    end
    table.clear(fpsBoostState)
end

RootMaid:GiveTask(function()
    if fpsBoostActive then removeFpsBoost() end
end)

local ultra_fps_section = ataos:AddSection("Light FPS Boost")

ultra_fps_section:AddToggle("Enable Frame Enhancement", function(bool)
    fpsBoostEnabled = bool
    if bool then
        applyFpsBoost()
    else
        removeFpsBoost()
    end
end)

do
    local cameraSection = ataos:AddSection("Camera Stretch")
    cameraSection:AddLabel("Default values for horizontal and vertical are 0.80")

    local stretchHorizontal = 0.80
    local stretchVertical = 0.80
    local cameraStretchConnection = nil
    local cameraStretchEnabled = false

    local stretchCF = CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)

    local function cameraStretchStep()
        local Camera = workspace.CurrentCamera
        if Camera then
            Camera.CFrame = Camera.CFrame * stretchCF
        end
    end

    local function applyCameraStretch()
        if cameraStretchConnection then
            cameraStretchConnection:Disconnect()
            cameraStretchConnection = nil
        end

        if not cameraStretchEnabled then return end

        stretchCF = CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
        cameraStretchConnection = Services.RunService.RenderStepped:Connect(cameraStretchStep)
    end

    local function stopCameraStretch()
        if cameraStretchConnection then
            cameraStretchConnection:Disconnect()
            cameraStretchConnection = nil
        end
    end

    cameraSection:AddToggle("Enable Camera Stretch", function(state)
        cameraStretchEnabled = state
        if state then
            applyCameraStretch()
        else
            stopCameraStretch()
        end
    end)

    cameraSection:AddTextBox("Horizontal Stretch", function(text)
        local num = tonumber(text)
        if num then
            stretchHorizontal = num
            if cameraStretchEnabled then
                applyCameraStretch()
            end
        end
    end, "0.80")

    cameraSection:AddTextBox("Vertical Stretch", function(text)
        local num = tonumber(text)
        if num then
            stretchVertical = num
            if cameraStretchEnabled then
                applyCameraStretch()
            end
        end
    end, "0.80")

    RootMaid:GiveTasks(
        LocalPlayer.CharacterRemoving:Connect(function()
            stopCameraStretch()
        end),
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            if cameraStretchEnabled then
                applyCameraStretch()
            end
        end),
        function() stopCameraStretch() end
    )
end

local VirtualUser = getfserv("VirtualUser")
local trueAntiFlingEnabled = false
local trueAntiAfkEnabled = false
local trueAntiFlingConnection = nil
local trueAntiAfkConnection = nil

local afParts = setmetatable({}, {__mode = "ks"})
local afCharMaids = setmetatable({}, {__mode = "ks"})
local afMaid = nil

local function afUntrack(char)
    if not char then return end
    local m = afCharMaids[char]
    if m then m:Destroy() end
    afCharMaids[char] = nil
    afParts[char] = nil
end

local function afTrack(char)
    if not char or afParts[char] then return end
    if not afMaid or afMaid._destroyed then return end

    local list = table.create(24)
    local n = 0
    for _, v in char:GetDescendants() do
        if v:IsA("BasePart") then
            n += 1
            list[n] = v
        end
    end
    afParts[char] = list

    local charMaid = Maid.new()
    afCharMaids[char] = charMaid
    charMaid:GiveTasks(
        char.DescendantAdded:Connect(function(v)
            if v:IsA("BasePart") then
                local l = afParts[char]
                if l then l[#l + 1] = v end
            end
        end),
        char.DescendantRemoving:Connect(function(v)
            local l = afParts[char]
            if l then
                local i = table.find(l, v)
                if i then table.remove(l, i) end
            end
        end)
    )
end

local function afWatchPlayer(p)
    if p == LocalPlayer then return end
    if not afMaid or afMaid._destroyed then return end
    afTrack(p.Character)
    afMaid:GiveTasks(
        p.CharacterAdded:Connect(afTrack),
        p.CharacterRemoving:Connect(afUntrack)
    )
end

local function enableTrueAntiFling()
    if trueAntiFlingConnection then
        trueAntiFlingConnection:Disconnect()
        trueAntiFlingConnection = nil
    end
    if afMaid then afMaid:DoCleaning() end

    afMaid = Maid.new()
    local thisMaid = afMaid
    afMaid:GiveTask(function()
        for c in afCharMaids do afUntrack(c) end
        table.clear(afParts)
        table.clear(afCharMaids)
    end)

    for _, player in Services.Players:GetPlayers() do
        afWatchPlayer(player)
    end
    afMaid:GiveTask(Services.Players.PlayerAdded:Connect(afWatchPlayer))
    afMaid:GiveTask(Services.Players.PlayerRemoving:Connect(function(p)
        afUntrack(p.Character)
    end))

    trueAntiFlingConnection = Services.RunService.Stepped:Connect(function()
        if thisMaid._destroyed then return end
        for _, list in afParts do
            for _, v in list do
                if v.CanCollide then v.CanCollide = false end
            end
        end
    end)
end

local function disableTrueAntiFling()
    if trueAntiFlingConnection then
        trueAntiFlingConnection:Disconnect()
        trueAntiFlingConnection = nil
    end
    if afMaid then afMaid:DoCleaning() afMaid = nil end
end

local AFK_CLICK_POS = Vector2.new()

local function enableTrueAntiAfk()
    if trueAntiAfkConnection then
        trueAntiAfkConnection:Disconnect()
        trueAntiAfkConnection = nil
    end
    trueAntiAfkConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(AFK_CLICK_POS)
    end)
end

local function disableTrueAntiAfk()
    if trueAntiAfkConnection then
        trueAntiAfkConnection:Disconnect()
        trueAntiAfkConnection = nil
    end
end

local true_antis_section = ataos:AddSection("True Anti's")
true_antis_section:AddToggle("Enable IY Anti Fling", function(bool)
    trueAntiFlingEnabled = bool
    if bool then
        enableTrueAntiFling()
    else
        disableTrueAntiFling()
    end
end)
true_antis_section:AddToggle("Enable True Anti AFK", function(bool)
    trueAntiAfkEnabled = bool
    if bool then
        enableTrueAntiAfk()
    else
        disableTrueAntiAfk()
    end
end)

local creditsSection = ataos:AddSection("Credits")
creditsSection:AddParagraph("@lzzzx", "Made this plugin, if you have requests feel free to ask.")

shared.Notify("ATAOs Successfully Loaded!", 2)

RootMaid:GiveTask(function()
    disableTrueAntiFling()
    disableTrueAntiAfk()
end)
