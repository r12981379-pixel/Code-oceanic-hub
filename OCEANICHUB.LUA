-- Oceanic Hub: WindUI + Environment Protection + Full Feature Set
repeat task.wait() until game:IsLoaded()

-- 1. ENVIRONMENT PROTECTION & SENTINEL BYPASS
local ProtectedUI = nil
if gethui then
    ProtectedUI = gethui()
elseif game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
    ProtectedUI = game:GetService("CoreGui").RobloxGui
else
    ProtectedUI = game:GetService("CoreGui")
end

-- METATABLE HOOKING (ANTI-BAN / ANTI-DETECTION)
local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__index = newcclosure(function(t, k)
    if not checkcaller() and t:IsA("Humanoid") then
        if k == "WalkSpeed" then return 16 end
        if k == "JumpPower" then return 50 end
    end
    return oldIndex(t, k)
end)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    -- Block game from seeing external logs or injection traces
    if not checkcaller() and method == "GetLogHistory" then
        return {}
    end
    
    -- Block Anti-Cheat Remote Events (Ban/Kick/Detection)
    if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
        local remoteName = tostring(self)
        if remoteName:lower():find("ban") or remoteName:lower():find("kick") or remoteName:lower():find("cheat") or remoteName:lower():find("detect") then
            return nil
        end
    end
    
    -- Block Local Kick Commands
    if not checkcaller() and (method == "Kick" or method == "kick") then
        return nil
    end
    
    return oldNamecall(self, unpack(args))
end)
setreadonly(mt, true)

-- 2. WINDUI SETUP
local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/library/windui"))()
local Window = WindUI:CreateWindow({
    Title = "Oceanic Hub",
    Icon = "rbxassetid://10723343321",
    Author = "Gemini",
    Folder = "OceanicSentinelConfig"
})

-- Parent the UI to the protected container to hide from game scripts
if Window.Instance then
    Window.Instance.Parent = ProtectedUI
end

-- Rainbow Title Effect
task.spawn(function()
    while task.wait() do
        Window:SetTitleColor(Color3.fromHSV(tick() % 5 / 5, 0.8, 1))
    end
end)

-- Variables & Services
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local TPS = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TP_Cooldown = false

-- Helper: Instant Bypass TP Logic
local function SecureTeleport(TargetCFrame)
    if TP_Cooldown then 
        WindUI:Notify("Cooldown", "Wait 1s for safety!", "warning")
        return 
    end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        TP_Cooldown = true
        hrp.Anchored = true
        hrp.CFrame = TargetCFrame
        task.wait(0.1) -- Required for bypass stability
        hrp.Anchored = false
        task.wait(0.9) -- CD to prevent spam-breaking the bypass
        TP_Cooldown = false
    end
end

-- Helper: Secret Time Logic
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
local MainTab = Window:Tab("Main", "shield")
local TeleTab = Window:Tab("Teleport", "zap")
local VisTab = Window:Tab("Visuals", "eye")
local FinderTab = Window:Tab("Finder", "search")
local MiscTab = Window:Tab("Misc", "layers")

-- [MAIN TAB]
MainTab:Section("Security Movement")

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
        WindUI:Notify("Stealth Active", "You are hidden from server logs.", "success")
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
                    if v:IsA("BodyVelocity") or v.Name:find("Force") then
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
TeleTab:Section("Anti-Cheat Bypasses")

TeleTab:Button("Instant TP Forward (No Kill)", function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then SecureTeleport(hrp.CFrame * CFrame.new(0, 0, -35)) end
end)

TeleTab:Button("Give Click TP Tool", function()
    local Tool = Instance.new("Tool")
    Tool.RequiresHandle, Tool.Name = false, "Oceanic Click TP"
    Tool.Activated:Connect(function() 
        if Mouse.Target then SecureTeleport(CFrame.new(Mouse.Hit.p) + Vector3.new(0, 3, 0)) end 
    end)
    Tool.Parent = LocalPlayer.Backpack
    WindUI:Notify("Tool Added", "Equip to teleport instantly.", "info")
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
VisTab:Section("Tracking ESP")

VisTab:Toggle("Rich Player ESP", false, function(state)
    _G.RichESP = state
    task.spawn(function()
        while _G.RichESP do
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local isRich = false
                    local l = p:FindFirstChild("leaderstats")
                    if l then
                        for _, s in pairs(l:GetChildren()) do
                            if (s.Name:lower():find("cash") or s.Name:lower():find("value")) and s.Value > 1000000 then isRich = true end
                        end
                    end
                    local h = p.Character:FindFirstChild("RichHighlight")
                    if isRich then
                        if not h then
                            h = Instance.new("Highlight", p.Character)
                            h.Name = "RichHighlight"; h.FillColor = Color3.fromRGB(255, 215, 0)
                        end
                    elseif h then h:Destroy() end
                end
            end
            task.wait(2)
        end
    end)
end)

-- [FINDER TAB]
FinderTab:Section("Secret & Server Sniper")

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
        for _, p in pairs(game.Players:GetPlayers()) do
            local l = p:FindFirstChild("leaderstats")
            if l and (l:FindFirstChild("Cash") or l:FindFirstChild("Value")) then
                local val = l:FindFirstChild("Cash") or l:FindFirstChild("Value")
                if val.Value > 1000000 then isRich = true end
            end
        end
        if isRich then 
            _G.AutoFinder = false
            WindUI:Notify("Rich Server Found", "Join and loot now!", "success")
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
MiscTab:Section("Original Utility")

MiscTab:Button("🍎 Bring All Brainrots", function()
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ClickDetector") or v:IsA("ProximityPrompt") then
            pcall(function() 
                v.Parent.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame 
                count = count + 1
            end)
        end
    end
    WindUI:Notify("Loot Brought", "Moved " .. tostring(count) .. " items to you.", "success")
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

MiscTab:Button("Force Rejoin", function() TPS:Teleport(game.PlaceId, LocalPlayer) end)

WindUI:SelectTab(MainTab)
