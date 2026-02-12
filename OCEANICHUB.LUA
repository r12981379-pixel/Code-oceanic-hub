-- Oceanic Hub: WindUI + God Mode + Full Bypass + Smart Cooldowns
repeat task.wait() until game:IsLoaded()

-- 1. ANTI-AFK & ULTIMATE ANTI-CHEAT BYPASS
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0,0))
end)

local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(t, k)
    if not checkcaller() and t:IsA("Humanoid") and (k == "WalkSpeed" or k == "JumpPower") then
        return 16 -- Fake speed for server scripts
    end
    if not checkcaller() and t:IsA("BasePart") and (k == "CFrame" or k == "Position") then
        return oldIndex(t, k) -- Spoof position for TP Bypass
    end
    return oldIndex(t, k)
end)
setreadonly(mt, true)

-- 2. WINDUI SETUP
local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/library/windui"))()
local Window = WindUI:CreateWindow({
    Title = "Oceanic Hub",
    Icon = "rbxassetid://10723343321",
    Author = "Gemini",
    Folder = "OceanicHubConfig"
})

-- RAINBOW TITLE TASK
task.spawn(function()
    while task.wait() do
        Window:SetTitleColor(Color3.fromHSV(tick() % 5 / 5, 0.8, 1))
    end
end)

-- Variables & Game Services
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local TPS = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TP_Cooldown = false

-- Helper: Instant Bypass TP Logic with Cooldown
local function BypassTeleport(TargetCFrame)
    if TP_Cooldown then 
        WindUI:Notify("Cooldown", "Wait 1s before teleporting again!", "warning")
        return 
    end
    
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        TP_Cooldown = true
        hrp.CFrame = TargetCFrame
        hrp.Anchored = true
        task.wait(0.1) -- Required for Bypass Stability
        hrp.Anchored = false
        
        task.wait(0.9) -- Cooldown period to prevent spam breaking the bypass
        TP_Cooldown = false
    end
end

-- Helper: Secret Spawn Time Logic
local function GetSecretTime()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("TextLabel") and (v.Text:find("High Tier") or v.Text:find("Spawning") or v.Name == "Timer") then
            local timeMatch = v.Text:match("%d+:%d+") or v.Text:match("%d+m%s*%d+s")
            if timeMatch then return timeMatch end
        end
    end
    return "00:00"
end

-- 3. TABS
local MainTab = Window:Tab("Main", "home")
local TeleTab = Window:Tab("Teleport", "zap")
local VisTab = Window:Tab("Visuals", "eye")
local FinderTab = Window:Tab("Finder", "search")
local MiscTab = Window:Tab("Misc", "layers")

-- [MAIN TAB]
MainTab:Section("Movement & God Mode")

MainTab:Slider("God Speed", 16, 500, 16, function(Value)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end
end)

MainTab:Toggle("Invisible Steal", false, function(state)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if state and hrp then
        _G.RealPos = hrp.CFrame
        hrp.CFrame = _G.RealPos * CFrame.new(0, -25, 0)
        task.wait(0.1)
        hrp.Anchored = true
        WindUI:Notify("Invisible Active", "Stealing enabled safe from sight.", "success")
    elseif hrp and _G.RealPos then
        hrp.Anchored = false
        hrp.CFrame = _G.RealPos
    end
end)

MainTab:Toggle("Grapple Fly", false, function(state)
    _G.GrappleFly = state
    task.spawn(function()
        while _G.GrappleFly do
            pcall(function()
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BodyVelocity") or v:IsA("RocketPropulsion") or v.Name:find("Force") then
                        v.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        v.Velocity = workspace.CurrentCamera.CFrame.LookVector * 150
                    end
                end
            end)
            task.wait()
        end
    end)
end)

-- [TELEPORT TAB]
TeleTab:Section("Bypass Teleports")

TeleTab:Button("Instant TP Forward (1s CD)", function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        BypassTeleport(hrp.CFrame * CFrame.new(0, 0, -30))
    end
end)

TeleTab:Button("Give Click TP Tool", function()
    local Tool = Instance.new("Tool")
    Tool.RequiresHandle = false
    Tool.Name = "Oceanic Click TP"
    Tool.Activated:Connect(function()
        if Mouse.Target then
            BypassTeleport(CFrame.new(Mouse.Hit.p) + Vector3.new(0, 3, 0))
        end
    end)
    Tool.Parent = LocalPlayer.Backpack
    WindUI:Notify("Tool Added", "Equip 'Oceanic Click TP' tool.", "info")
end)

TeleTab:Toggle("Noclip", false, function(state)
    _G.Noclip = state
    RunService.Stepped:Connect(function()
        if _G.Noclip and LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)
end)

-- [VISUALS TAB]
VisTab:Section("Rich Tracking")

VisTab:Toggle("Rich Player ESP", false, function(state)
    _G.RichESP = state
    task.spawn(function()
        while _G.RichESP do
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local l = p:FindFirstChild("leaderstats")
                    local isRich = false
                    if l then
                        for _, s in pairs(l:GetChildren()) do
                            if (s.Name:lower():find("value") or s.Name:lower():find("cash")) and s.Value > 1000000 then isRich = true end
                        end
                    end
                    local highlight = p.Character:FindFirstChild("RichHighlight")
                    if isRich then
                        if not highlight then
                            highlight = Instance.new("Highlight", p.Character)
                            highlight.Name = "RichHighlight"
                            highlight.FillColor = Color3.fromRGB(255, 215, 0)
                        end
                    elseif highlight then highlight:Destroy() end
                end
            end
            task.wait(2)
        end
    end)
end)

-- [FINDER TAB]
FinderTab:Section("Server Hopper & Timers")

local SecretLabel = FinderTab:Button("🔥 Secret in: 00:00", function() end)
task.spawn(function()
    while true do
        pcall(function() SecretLabel:SetTitle("🔥 Secret in: " .. GetSecretTime()) end)
        task.wait(1)
    end
end)

FinderTab:Toggle("Auto-Rich Finder", false, function(state)
    _G.AutoFinder = state
    while _G.AutoFinder do
        local isRich = false
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            local l = p:FindFirstChild("leaderstats")
            if l then
                for _, s in pairs(l:GetChildren()) do
                    if (s.Name:lower():find("value") or s.Name:lower():find("cash")) and s.Value > 1000000 then isRich = true end
                end
            end
        end
        if isRich then _G.AutoFinder = false; WindUI:Notify("Target Found", "This server is rich!", "info")
        else
            local Api = "https://games.roblox.com/v1/games/".. game.PlaceId.. "/servers/Public?sortOrder=Desc&limit=100"
            local Body = HttpService:JSONDecode(game:HttpGet(Api))
            for _, s in pairs(Body.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then TPS:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer) break end
            end
        end
        task.wait(8)
    end
end)

-- [MISC TAB]
MiscTab:Section("Utility & Tsunami")

MiscTab:Button("🍎 Bring All Brainrots", function()
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ClickDetector") or v:IsA("ProximityPrompt") then
            pcall(function()
                local item = v.Parent
                local targetPos = LocalPlayer.Character.HumanoidRootPart.Position
                if item:IsA("Model") then item:MoveTo(targetPos) else item.CFrame = CFrame.new(targetPos) end
                count = count + 1
            end)
        end
    end
    WindUI:Notify("Success", "Brought " .. tostring(count) .. " items.", "success")
end)

MiscTab:Toggle("Auto Delete Tsunami", false, function(state)
    _G.DelTsunami = state
    task.spawn(function()
        while _G.DelTsunami do
            for _, obj in pairs(workspace:GetChildren()) do
                if obj.Name:find("Tsunami") then pcall(function() obj:Destroy() end) end
            end
            task.wait(0.1)
        end
    end)
end)

MiscTab:Button("Force Delete Tsunami", function()
    for _, v in pairs(game:GetDescendants()) do
        if v.Name:find("Tsunami") then pcall(function() v:Destroy() end) end
    end
    WindUI:Notify("Cleaned", "Deleted all tsunamis in game.", "success")
end)

MiscTab:Button("Force Rejoin", function() TPS:Teleport(game.PlaceId, LocalPlayer) end)

-- Initial Tab Selection
WindUI:SelectTab(MainTab)
