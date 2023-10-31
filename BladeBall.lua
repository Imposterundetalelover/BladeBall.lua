--// System 

local Library = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local SystemWindow = Library:CreateWindow({
    Name = "TroXer Hub | Who Exsist",
    LoadingTitle = "TroXer Hub is Loading..",
    LoadingSubtitle = "By ArteeSo",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = nil, -- Create a custom folder for your hub/game
       FileName = ""
    },
    Discord = {
       Enabled = true,
       Invite = "GajSbcfHxh", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ABCD would be ABCD
       RememberJoins = false -- Set this to false to make them join the discord every time they load it up
    },
    KeySystem = true, -- Set this to true to use our key system
    KeySettings = {
       Title = "TroXer Protection",
       Subtitle = "Key System",
       Note = "Join to discord {https://discord.gg/GajSbcfHxh}",
       FileName = "TroXerKey", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
       SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
       GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
       Key = {"Its A Key"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
    }
})

--// Variables

local FocusedBall, DisplayBall = nil, nil
local Balls = game.Workspace:WaitForChild("Balls")
local Base, Fast, Slow = 0.2, 0.050, 0.1
local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character
local SliderValue = 20
local DistanceVisualizer = nil
local NotifyParried = false
local UseRage = false
local AbilityButtonPress = game.ReplicatedStorage.Remotes.ParryButtonPress
local IsRunning = false

--// Values

_G.InfiniteToogle = true

--// Functions

function Infinite()
    while wait(1.5) do
        if _G.InfiniteToogle == true then
            game:GetService("UserInputService").JumpRequest:Connect(function()
                game:GetService"Players".LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")     
            end)        
        elseif _G.InfiniteToogle == false then
            print("False")
        end
    end
end

function Notify(Title, Content, Duration)
    Library:Notify({
        Title = Title,
        Content = Content,
        Duration = Duration or 0.7,
        Image = 10010348543
    })
end

function ChooseFocusedBall()
    local Balls = Balls:GetChildren()
    for _, Ball in pairs(Balls) do
        if Ball:GetAttribute("realBall") ~= nil and Ball:GetAttribute("realBall") == true then
            FocusedBall = Ball
            print(FocusedBall.Name)
            break
        elseif Ball:GetAttribute("target") ~= nil then
            FocusedBall = Ball
            print(FocusedBall.Name)
            break
        end
    end

    if FocusedBall == nil then
        print("Debug: Could'nt find the real ball!")
        wait(1.5)
        ChooseFocusedBall()
    end
    return FocusedBall
end

function GetDynamic(BallVelocity)
    if BallVelocity > 60 then
        return math.max(0.20, Base - (BallVelocity * Fast))
    else
        return math.max(0.01, Base - (BallVelocity * Slow))
    end
end

function Impact(BallVelocity, DistanceToPlayer, PlayerVelocity)
    if not Character then
        return
    end

    local Direction = (Character.HumanoidRootPart.Position - FocusedBall.Position).Unit
    local Velocity = BallVelocity:Dot(Direction) - PlayerVelocity:Dot(Direction)

    if Velocity <= 0 then
        return math.huge
    end

    return (DistanceToPlayer - SliderValue)/Velocity
end

function UpdateDistnace()
    local CharPos = Character and Character.PrimaryPart and Character.PrimaryPart.Position
    if CharPos and FocusedBall then
        if DistanceVisualizer then
            DistanceVisualizer:Destroy()
        end

        local TimeToImpact = Impact(FocusedBall.Velocity, (FocusedBall.Position - CharPos).Magnitude, Character.PrimaryPart.Velocity)
        local FuturePosition = FocusedBall.Position + FocusedBall.Velocity * Impact

        DistanceVisualizer = Instance.new("Part", workspace)
        DistanceVisualizer.Size = Vector3.new(1, 1, 1)
        DistanceVisualizer.Anchored = true
        DistanceVisualizer.CanCollide = false
        DistanceVisualizer.Position = FuturePosition
    end
end

function CheckIfTarget()
    for _, V in pairs(Balls:GetChildren()) do
        if V:IsA("Part") and V.BrickColor == BrickColor.new("Really red") then
            print("Target unlock")
            return true
        end
    end
    return false
end

function CooldownInEffect(UIGradient)
    return UIGradient.Offset.Y < 0.5
end

function CheckBallDistance()
    if not Character or not CheckIfTarget() then 
        return 
    end

    local charPos = Character.PrimaryPart.Position
    local charVel = Character.PrimaryPart.Velocity

    if FocusedBall and not FocusedBall.Parent then
        print("Focused ball lost parent. Choosing a new focused ball.")
        ChooseFocusedBall()
    end
    if not FocusedBall then 
        print("No focused ball.")
        ChooseFocusedBall()
    end

    local ball = FocusedBall
    local distanceToPlayer = (ball.Position - charPos).Magnitude
    local ballVelocityTowardsPlayer = ball.Velocity:Dot((charPos - ball.Position).Unit)
    
    if distanceToPlayer < 15 then
        AbilityButtonPress:Fire()
        task.wait()
    end

    if Impact(ball.Velocity, distanceToPlayer, charVel) < GetDynamic(ballVelocityTowardsPlayer) then
        if (Character.Abilities["Raging Deflection"].Enabled or Character.Abilities["Rapture"].Enabled) and UseRage == true then
            if not CooldownInEffect(UIGradient) then
                AbilityButtonPress:Fire()
            end

            if CooldownInEffect(UIGradient) and not CooldownInEffect(UIGradient) then
                AbilityButtonPress:Fire()
                if NotifyParried == true then
                    Notify("Auto Parry", "Manually Parried Ball (Ability on CD)", 0.3)
                end
            end

        elseif not CooldownInEffect(UIGradient) then
            print(CooldownInEffect(UIGradient))
            AbilityButtonPress:Fire()
            if NotifyParried == true then
                Notify("Auto Parry", "Automatically Parried Ball", 0.3)
            end
            task.wait(0.3)
        end
    end
end

function AutoParryCoroutine()
    while isRunning do
        CheckBallDistance()
        UpdateDistnace()
        task.wait()
    end
end

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    ChooseFocusedBall()
    UpdateDistnace()
end)

LocalPlayer.CharacterRemoving:Connect(function()
    if DistanceVisualizer then
        DistanceVisualizer:Destroy()
        DistanceVisualizer = nil
    end
end)



function StartParry()   
    ChooseFocusedBall()
    
    IsRunning = true
    local co = coroutine.create(AutoParryCoroutine)
    coroutine.resume(co)
end

function StopParry()
    IsRunning = false
end

--// Update

function Update()
    local Player = game.Players.LocalPlayer
  
    if Player.UserId == 4548471055 then
        Notify("Nofity", "Thanks for you support!", 1)
    
        local PlayerTab = SystemWindow:CreateTab("Player", 4483362458)

        PlayerTab:CreateToggle({
            Name = "Infinite Jump Toogle",
            CurrentValue = false,
            Flag = "Toogle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
            Callback = function(Value)
                _G.InfiniteToogle = Value
                Infinite()
            end,
        })

        local CombatTab = SystemWindow:CreateTab("Player", 4483362458)

        local AutoParryToggle = CombatTab:CreateToggle({
            Name = "Auto Parry",
            CurrentValue = false,
            Flag = "Toogle",
            Callback = function(Value)
                if Value then
                    StartParry()
                    Notify("Auto Parry", "Auto Parry has been started", 1)
                else
                    StopParry()
                    Notify("Auto Parry", "Auto Parry has been disabled", 1)
                end
            end,
        })

        CombatTab:CreateToggle({
            Name = "Auto Parry (Rage Deflect, Equip PROPER ABILITY!)",
            CurrentValue = false,
            Flag = "Toogle",
            Callback = function(Value)
                if Value then
                    StartParry()
                    UseRage = Value
                    Notify("Auto Parry", "Auto Parry has been started", 1)
                else
                    StopParry()
                    UseRage = Value
                    Notify("Auto Parry", "Auto Parry has been disabled", 1)
                end
            end,
        })

        CombatTab:CreateKeybind({
            Name = "Spam Parry (Hold)",
            CurrentKeybind = "C",
            HoldToInteract = true,
            Flag = "Keybind", 
            Callback = function(Keybind)
                ParryButtonPress:Fire()
            end,
        })

        CombatTab:CreateSection("Configuration")

        local DistanceSlider = CombatTab:CreateSlider({
            Name = "Distance Configuration",
            Range = {0, 100},
            Increment = 1,
            Suffix = "Distance",
            CurrentValue = 20,
            Flag = "DistanceSlider",
            Callback = function(Value)
                SliderValue = Value
            end,
         })
        
        ToggleParryOn = CombatTab:CreateKeybind({
           Name = "Toggle Parry On (Bind)",
           CurrentKeybind = "One",
           HoldToInteract = false,
           Flag = "ToggleParryOn", 
           Callback = function(Keybind)
            AutoParryToggle:Set(true)
           end
        })

        CombatTab:CreateKeybind({
           Name = "Toggle Parry Off (Bind)",
           CurrentKeybind = "Two",
           HoldToInteract = false,
           Flag = "Keybind2",
           Callback = function(Keybind)
            AutoParryToggle:Set(false)
           end,
        })
        
        CombatTab:CreateKeybind({
            Name = "+ 10 Range",
            CurrentKeybind = "X",
            HoldToInteract = false,
            Flag = "Keybind3",
            Callback = function()
                 if SliderValue < 200 then
                     SliderValue = SliderValue + 10
                     DistanceSlider:Set(SliderValue)
                     Notify("Range Increased", "New Range: " .. SliderValue)
                 end
            end,
         })
         
        CombatTab:CreateKeybind({
            Name = "- 10 Range",
            CurrentKeybind = "Z",
            HoldToInteract = false,
            Flag = "Keybind4",
            Callback = function()
                 if SliderValue > 0 then
                     SliderValue = SliderValue - 10
                     DistanceSlider:Set(SliderValue)
                     Notify("Range Decreased", "New Range: " .. SliderValue)
                 end
            end,
        })

        local MiscTab = SystemWindow:CreateTab("Player", 4483362458)

        MiscTab:CreateButton({
            Name = "Bypass Anti-Cheat",
            Callback = function()
                game:GetService("ReplicatedStorage").Security.RemoteEvent:Destroy()
                game:GetService("ReplicatedStorage").Security[""]:Destroy()
                game:GetService("ReplicatedStorage").Security:Destroy()
                game:GetService("Players").LocalPlayer.PlayerScripts.Client.DeviceChecker:Destroy()
            end,
         })
    elseif Player.UserId == "" then
        print("Blacklist Player UserId - ".. Player.UserId)
        game.Players.LocalPlayer:Kick("Blacklisted, Please try to appeal in our discord!")
    else
        Notify("Nofity", "Thanks for enjoying our script", 1)

        local PlayerTab = SystemWindow:CreateTab("Player", 4483362458)

        PlayerTab:CreateToggle({
            Name = "Infinite Jump Toogle",
            CurrentValue = false,
            Flag = "Toogle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
            Callback = function(Value)
                _G.InfiniteToogle = Value
                Infinite()
            end,
        })

        local CombatTab = SystemWindow:CreateTab("Player", 4483362458)

        local AutoParryToggle = CombatTab:CreateToggle({
            Name = "Auto Parry",
            CurrentValue = false,
            Flag = "Toogle",
            Callback = function(Value)
                if Value then
                    StartParry()
                    Notify("Auto Parry", "Auto Parry has been started", 1)
                else
                    StopParry()
                    Notify("Auto Parry", "Auto Parry has been disabled", 1)
                end
            end,
        })

        CombatTab:CreateToggle({
            Name = "Auto Parry (Rage Deflect, Equip PROPER ABILITY!)",
            CurrentValue = false,
            Flag = "Toogle",
            Callback = function(Value)
                if Value then
                    StartParry()
                    UseRage = Value
                    Notify("Auto Parry", "Auto Parry has been started", 1)
                else
                    StopParry()
                    UseRage = Value
                    Notify("Auto Parry", "Auto Parry has been disabled", 1)
                end
            end,
        })

        CombatTab:CreateKeybind({
            Name = "Spam Parry (Hold)",
            CurrentKeybind = "C",
            HoldToInteract = true,
            Flag = "Keybind", 
            Callback = function(Keybind)
                ParryButtonPress:Fire()
            end,
        })

        CombatTab:CreateSection("Configuration")

        local DistanceSlider = CombatTab:CreateSlider({
            Name = "Distance Configuration",
            Range = {0, 100},
            Increment = 1,
            Suffix = "Distance",
            CurrentValue = 20,
            Flag = "DistanceSlider",
            Callback = function(Value)
                SliderValue = Value
            end,
         })
        
        ToggleParryOn = CombatTab:CreateKeybind({
           Name = "Toggle Parry On (Bind)",
           CurrentKeybind = "One",
           HoldToInteract = false,
           Flag = "ToggleParryOn", 
           Callback = function(Keybind)
            AutoParryToggle:Set(true)
           end
        })

        CombatTab:CreateKeybind({
           Name = "Toggle Parry Off (Bind)",
           CurrentKeybind = "Two",
           HoldToInteract = false,
           Flag = "Keybind2",
           Callback = function(Keybind)
            AutoParryToggle:Set(false)
           end,
        })
        
        CombatTab:CreateKeybind({
            Name = "+ 10 Range",
            CurrentKeybind = "X",
            HoldToInteract = false,
            Flag = "Keybind3",
            Callback = function()
                 if SliderValue < 200 then
                     SliderValue = SliderValue + 10
                     DistanceSlider:Set(SliderValue)
                     Notify("Range Increased", "New Range: " .. SliderValue)
                 end
            end,
         })
         
        CombatTab:CreateKeybind({
            Name = "- 10 Range",
            CurrentKeybind = "Z",
            HoldToInteract = false,
            Flag = "Keybind4",
            Callback = function()
                 if SliderValue > 0 then
                     SliderValue = SliderValue - 10
                     DistanceSlider:Set(SliderValue)
                     Notify("Range Decreased", "New Range: " .. SliderValue)
                 end
            end,
         })

        local MiscTab = SystemWindow:CreateTab("Player", 4483362458)

        MiscTab:CreateButton({
            Name = "Bypass Anti-Cheat",
            Callback = function()
                game:GetService("ReplicatedStorage").Security.RemoteEvent:Destroy()
                game:GetService("ReplicatedStorage").Security[""]:Destroy()
                game:GetService("ReplicatedStorage").Security:Destroy()
                game:GetService("Players").LocalPlayer.PlayerScripts.Client.DeviceChecker:Destroy()
            end,
         })
    end
end

if game:IsLoaded() then
    Update()
end
