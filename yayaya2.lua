-- ===== blabla UI LIBRARY =====
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ===== SERVICES =====
local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager") 
local LocalPlayer = Players.LocalPlayer
local Gojo = Rep:WaitForChild("SkillRemote"):WaitForChild("GojoRemote")
local TeleportService = game:GetService("TeleportService")

-- ===== VARIABLES =====
local AutoGojo = false
local AutoGojoRework = false 
local AutoRed = false

--  AUTO AFO VARIABLE
local AutoAFO = false

--  AUTO BINAH SEARCH
local AutoBinah = false

-- CUSTOM MOVE VARIABLES (Z & H)
local AutoZMove = false
local ZMoveFollow = false
local ZMoveTargetList = {}
local CurrentZMoveTarget = nil

--  AUTO RONIN VARIABLE (NEW)
local AutoRonin = false
local RoninFollow = false
local CurrentRoninTarget = nil
local RoninTargetList = {}

--  AUTO GILGAMESH VARIABLE
local AutoGilgamesh = false
local GilgameshFollow = false
local GilgameshTargetList = {}
local CurrentGilgameshTarget = nil

--  AUTO COMBO QZG VARIABLE
local AutoComboQZG = false
local ComboFollow = false
local ComboTargetList = {}
local CurrentComboTarget = nil

-- NEW VARIABLE: AUTO KING MON & BBQ3
local AutoKingMon = false 
local AutoBBQ3 = false 
local IsSummoningAction = false 

--  AUTO DEKU VARIABLE
local AutoDeku = false
local AutoDekuDelay = false

--  AUTO LAMANCHALAND VARIABLE
local AutoLaMancha = false
local CutsceneCount = 0
local ClashActive = false

--  AUTO ROLAND VARIABLE
local AutoRoland = false

-- Teleport State Variables
local FollowTarget = false
local RedFollow = false
local HollowFollow = false 
local CounterFollow = false 
local PurpleFollow = false

-- Mastery Variable
local AutoMastery = false
local AutoBreakthrough = false

-- Utility Variable
local AutoClear = false
local AutoBPExchange = false 

-- NO LAG V2 (TESTING)
local AutoNoLagV2 = false
local NoLagV2Connection = nil

-- Target Variables
local RedTargetList = {}
local CounterTargetList = {"Counter Dummy"} 
local PurpleTargetList = {}

local CurrentRedTarget = nil 
local CurrentCounterTarget = nil
local CurrentPurpleTarget = nil

local AutoRefreshTarget = true
local TeleportMode = "Front"
local TeleportDistance = 4

local SAFE_Y = 250 
local SAFEZONE = nil

-- Loot Variables (REWORKED)
local ItemFolder = Workspace:FindFirstChild("Item") or Workspace:WaitForChild("Item", 5)
local AutoLootRework = false 
local LootDelay = 0.5
local ItemBlacklist = {}
local AutoItemRefresh = true
local LastItemSignature = ""
local LootingActive = false 
local AutoBoxBarrel = false
local AutoSell = false
local SellList = {
    "Arrow", "Mysterious Camera", "Hamon Manual", "Rokakaka", 
    "Stop Sign", "Stone Mask", "Haunted Sword", "Spin Manual", 
    "Barrel", "Bomu Bomu Devil Fruit", "Mochi Mochi Devil Fruit", 
    "Bari Bari Devil Fruit"
}

-- ===== REMOTE FIX WRAPPERS =====
local function UseFold(duration)
    local start = os.clock()
    while os.clock() - start < duration do
        -- [UPDATE] Added Checks
        if (not AutoRed and not AutoGojoRework and not AutoZMove and not AutoGilgamesh and not AutoComboQZG) then return end
        if IsSummoningAction then return end 

        pcall(function()
            Gojo.Fold:FireServer()
        end)
        task.wait(0.5)
    end
end

local function UseHeal(duration)
    local start = os.clock()
    while os.clock() - start < duration do
        if not AutoGojoRework then return end
        if IsSummoningAction then return end
        pcall(function()
            Gojo.Heal:FireServer()
        end)
        task.wait(0.5)
    end
end

local function UseResurrect()
    if not AutoGojoRework then return end
    if IsSummoningAction then return end
    pcall(function()
        Gojo.Resurrect:FireServer()
    end)
end

-- ===== SAFEZONE / PLATFORM CREATOR =====
local function CreateSafeZone()
    if SAFEZONE and SAFEZONE.Parent == Workspace then 
        SAFEZONE.Position = Vector3.new(0, SAFE_Y, 0)
        return 
    end
    
    if SAFEZONE then SAFEZONE:Destroy() end

    SAFEZONE = Instance.new("Part")
    SAFEZONE.Name = "LootPlatform"
    SAFEZONE.Size = Vector3.new(50, 2, 50)
    SAFEZONE.Position = Vector3.new(0, SAFE_Y, 0)
    SAFEZONE.Anchored = true
    SAFEZONE.CanCollide = true
    SAFEZONE.Material = Enum.Material.Glass
    SAFEZONE.Transparency = 0.5 
    SAFEZONE.Color = Color3.fromRGB(0, 255, 128) 
    SAFEZONE.Parent = Workspace
end

-- ===== TARGET HELPERS =====
local function IsTargetAlive(target)
    if not target then return false end
    local hum = target:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function GetValidTargetFromList(nameList)
    if not nameList or type(nameList) ~= "table" or #nameList == 0 then return nil end
    
    if Workspace:FindFirstChild("Living") then
        for _, name in ipairs(nameList) do
            local targetModel = Workspace.Living:FindFirstChild(name)
            if targetModel and targetModel ~= LocalPlayer.Character and IsTargetAlive(targetModel) then
                return targetModel 
            end
        end
    end
    return nil
end

-- ===== LOOT HELPERS =====
local function getItemNameList()
    local names, seen = {}, {}
    if ItemFolder then
        for _, obj in ipairs(ItemFolder:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local part = obj.Parent
                local model = part.Parent
                local itemName = model.Name
                if itemName == "ItemDrop" and model.Parent then
                    itemName = model.Parent.Name
                end
                
                if not seen[itemName] then
                    seen[itemName] = true
                    table.insert(names, itemName)
                end
            end
        end
    end
    table.sort(names, function(a,b) return a:lower() < b:lower() end)
    return names
end

local function getItemSignature()
    return table.concat(getItemNameList(), "|")
end

local function GetItemCount(itemName)
    local count = 0
    if LocalPlayer.Backpack then
        for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
            if item.Name == itemName then
                count = count + 1
            end
        end
    end
    return count
end

-- [BARU] FUNGSI TEMBAK PROXIMITY PROMPT
local function fireItemPrompt(itemModel)
    if not itemModel then return end
    
    local prompt = itemModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    local targetPart = itemModel:FindFirstChild("ItemDrop") or itemModel:FindFirstChildWhichIsA("BasePart") or itemModel

    if prompt and targetPart then
        -- Bypass Durasi & Jarak
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 60 -- Perbesar jarak ambil
        prompt.RequiresLineOfSight = false -- Bisa ambil tembus tembok

        -- Teleport Player (Supaya server validasi jaraknya pas)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
            hrp.Velocity = Vector3.zero
        end
        
        -- Eksekusi Tembak Prompt
        task.wait(0.1) -- Delay dikit biar teleport ke-register server
        fireproximityprompt(prompt)
        return true
    end
    return false
end

-- ===== FORCE KILL ONCE (Tanpa Loop) =====
local function ForceKillByVoidOnce()
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local map = Workspace:FindFirstChild("Map")
    local voidFolder = map and map:FindFirstChild("Void")
    local voidPart = voidFolder and voidFolder:GetChildren()[6]

    if voidPart and voidPart:IsA("BasePart") then
        hrp.CFrame = CFrame.new(0, -800, 0)
    end
end

-- ===== UI WINDOW =====
local Window = Rayfield:CreateWindow({
    Name = "blabla2",
    LoadingTitle = "Well Well",
    LoadingSubtitle = "Wait A Minute",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ambatubas", 
        FileName = "Settings"
    }
})

-- TAB: COMBAT
local Tab = Window:CreateTab("Main Combat", 4483362458)

-- TAB: LOOT
local LootTab = Window:CreateTab("Loot & Items", 4483362458)

-- TAB: UTILITY
local UtilityTab = Window:CreateTab("Utility", 4483362458)

-- ===== COMBAT UI LOGIC =====
local function GetTargets()
    local t = {}
    if Workspace:FindFirstChild("Living") then
        for _,v in ipairs(Workspace.Living:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v ~= LocalPlayer.Character then
                table.insert(t, v.Name)
            end
        end
    end
    return t
end

-- PURPLE DROPDOWN
local PurpleDropdown = Tab:CreateDropdown({
    Name = "Purple Targets",
    Options = GetTargets(),
    CurrentOption = {},
    MultipleOptions = true,
    Multi = true,
    Flag = "PurpleTargets", 
    Callback = function(opts)
        PurpleTargetList = opts 
        if not CurrentPurpleTarget then
            CurrentPurpleTarget = GetValidTargetFromList(PurpleTargetList)
        end
    end
})

-- RED DROPDOWN
local RedDropdown = Tab:CreateDropdown({
    Name = "Red Targets",
    Options = GetTargets(),
    CurrentOption = {},
    MultipleOptions = true,
    Multi = true,
    Flag = "RedTargets", 
    Callback = function(opts)
        RedTargetList = opts
        if not CurrentRedTarget then
            CurrentRedTarget = GetValidTargetFromList(RedTargetList)
        end
    end
})

-- Z MOVE DROPDOWN
local ZMoveDropdown = Tab:CreateDropdown({
    Name = "Z Move Target",
    Options = GetTargets(),
    CurrentOption = {},
    MultipleOptions = true,
    Multi = true,
    Flag = "ZMoveTargets", 
    Callback = function(opts)
        ZMoveTargetList = opts
        if not CurrentZMoveTarget then
            CurrentZMoveTarget = GetValidTargetFromList(ZMoveTargetList)
        end
    end
})

-- RONIN DROPDOWN
local RoninDropdown = Tab:CreateDropdown({
    Name = "Ronin Target",
    Options = GetTargets(),
    CurrentOption = {},
    MultipleOptions = true,
    Multi = true,
    Flag = "RoninTargets", 
    Callback = function(opts)
        RoninTargetList = opts
        if not CurrentRoninTarget then
            CurrentRoninTarget = GetValidTargetFromList(RoninTargetList)
        end
    end
})

--  GILGAMESH DROPDOWN
local GilgameshDropdown = Tab:CreateDropdown({
    Name = "Gilgamesh Target",
    Options = GetTargets(),
    CurrentOption = {},
    MultipleOptions = true,
    Multi = true,
    Flag = "GilgameshTargets", 
    Callback = function(opts)
        GilgameshTargetList = opts
        if not CurrentGilgameshTarget then
            CurrentGilgameshTarget = GetValidTargetFromList(GilgameshTargetList)
        end
    end
})

--  COMBO QZG DROPDOWN
local ComboDropdown = Tab:CreateDropdown({
    Name = "Combo QZG Target",
    Options = GetTargets(),
    CurrentOption = {},
    MultipleOptions = true,
    Multi = true,
    Flag = "ComboQZGTargets", 
    Callback = function(opts)
        ComboTargetList = opts
        if not CurrentComboTarget then
            CurrentComboTarget = GetValidTargetFromList(ComboTargetList)
        end
    end
})

Tab:CreateButton({
    Name = "Refresh Target Lists",
    Callback = function()
        -- Ambil data target terbaru dari folder Living
        local newTargets = GetTargets() 
        
        -- Refresh setiap dropdown dengan data terbaru
        if RedDropdown then RedDropdown:Refresh(newTargets, true) end
        if PurpleDropdown then PurpleDropdown:Refresh(newTargets, true) end
        if ZMoveDropdown then ZMoveDropdown:Refresh(newTargets, true) end
        if GilgameshDropdown then GilgameshDropdown:Refresh(newTargets, true) end
        if ComboDropdown then ComboDropdown:Refresh(newTargets, true) end
        if RoninDropdown then RoninDropdown:Refresh(newTargets, true) end
        
        Rayfield:Notify({Title = "Target System", Content = "Target lists refreshed!", Duration = 2})
    end
})

Tab:CreateSection("Combat Toggles")

Tab:CreateToggle({
    Name = "Auto Gojo REWORK",
    CurrentValue = false,
    Flag = "AutoGojoRework", 
    Callback = function(v)
        AutoGojoRework = v
        if v then
            if AutoRed then AutoRed = false end
            if AutoZMove then AutoZMove = false end
            if AutoGilgamesh then AutoGilgamesh = false end
            if AutoComboQZG then AutoComboQZG = false end
        else
            CounterFollow = false
            PurpleFollow = false
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Red",
    CurrentValue = false,
    Flag = "AutoRed", 
    Callback = function(v)
        AutoRed = v
        if not v then
            RedFollow = false
        else
            if AutoGojoRework then AutoGojoRework = false end
            if AutoZMove then AutoZMove = false end
            if AutoGilgamesh then AutoGilgamesh = false end
            if AutoComboQZG then AutoComboQZG = false end
        end
    end
})

-- Z MOVE TOGGLE
Tab:CreateToggle({
    Name = "Auto Z Move",
    CurrentValue = false,
    Flag = "AutoZMove", 
    Callback = function(v)
        AutoZMove = v
        if not v then
            ZMoveFollow = false
        else
            if AutoGojoRework then AutoGojoRework = false end
            if AutoRed then AutoRed = false end
            if AutoGilgamesh then AutoGilgamesh = false end
            if AutoComboQZG then AutoComboQZG = false end
        end
    end
})

-- RONIN TOGGLE
Tab:CreateToggle({
    Name = "Auto Ronin (G -> Q -> T)",
    CurrentValue = false,
    Flag = "AutoRonin", 
    Callback = function(v)
        AutoRonin = v
        if not v then
            RoninFollow = false
        else
            -- Matikan auto lain agar tidak bentrok
            if AutoGojoRework then AutoGojoRework = false end
            if AutoRed then AutoRed = false end
            if AutoZMove then AutoZMove = false end
            if AutoGilgamesh then AutoGilgamesh = false end
            if AutoComboQZG then AutoComboQZG = false end
        end
    end
})

--  GILGAMESH TOGGLE
Tab:CreateToggle({
    Name = "Auto Gilgamesh",
    CurrentValue = false,
    Flag = "AutoGilgamesh", 
    Callback = function(v)
        AutoGilgamesh = v
        if not v then
            GilgameshFollow = false
        else
            if AutoGojoRework then AutoGojoRework = false end
            if AutoRed then AutoRed = false end
            if AutoZMove then AutoZMove = false end
            if AutoComboQZG then AutoComboQZG = false end
        end
    end
})

--  COMBO QZG TOGGLE
Tab:CreateToggle({
    Name = "Auto Combo QZG (Q->Z->G)",
    CurrentValue = false,
    Flag = "AutoComboQZG", 
    Callback = function(v)
        AutoComboQZG = v
        if not v then
            ComboFollow = false
        else
            if AutoGojoRework then AutoGojoRework = false end
            if AutoRed then AutoRed = false end
            if AutoZMove then AutoZMove = false end
            if AutoGilgamesh then AutoGilgamesh = false end
        end
    end
})

Tab:CreateSection("Stats & Mastery")

Tab:CreateToggle({
    Name = "Auto Mastery Up",
    CurrentValue = false,
    Flag = "AutoMastery", 
    Callback = function(v)
        AutoMastery = v
    end
})

Tab:CreateToggle({
    Name = "Auto Breakthrough",
    CurrentValue = false,
    Flag = "AutoBreakthrough", 
    Callback = function(v)
        AutoBreakthrough = v
    end
})

-- ===== UTILITY SECTION =====
UtilityTab:CreateSection("General Utility")

UtilityTab:CreateToggle({
    Name = "Auto Clear (Every 2 Minutes)",
    CurrentValue = false,
    Flag = "AutoClear", 
    Callback = function(v)
        AutoClear = v
        if v then
            Rayfield:Notify({Title = "Utility", Content = "Auto Clear Started (2m Interval)", Duration = 3})
        end
    end
})

UtilityTab:CreateToggle({
    Name = "Auto BP Exchange (BP > 1)",
    CurrentValue = false,
    Flag = "AutoBPExchange", 
    Callback = function(v)
        AutoBPExchange = v
        if v then
            Rayfield:Notify({Title = "Utility", Content = "Auto BP Exchange Started", Duration = 3})
        end
    end
})

UtilityTab:CreateToggle({
    Name = "NoLag (Testing) - Hapus Effects, VFX, Texture",
    CurrentValue = false,
    Flag = "AutoNoLagV2", 
    Callback = function(v)
        AutoNoLagV2 = v
        if v then
            NoLagV2_Enable()
            Rayfield:Notify({Title = "NoLag (Testing)", Content = "Aktif!", Duration = 3})
        else
            NoLagV2_Disable()
            Rayfield:Notify({Title = "NoLag (Testing)", Content = "Dimatikan.", Duration = 2})
        end
    end
})

UtilityTab:CreateSection("Boss Summoner")

UtilityTab:CreateToggle({
    Name = "Auto Deku (Summon & Farm)",
    CurrentValue = false,
    Flag = "AutoDeku", 
    Callback = function(v)
        AutoDeku = v
        if v then
            -- Matikan logic boss lain agar tidak bentrok
            if AutoKingMon then AutoKingMon = false end
            if AutoBBQ3 then AutoBBQ3 = false end
            Rayfield:Notify({Title = "Auto Deku", Content = "Script Started. Checking Logic...", Duration = 3})
        else
            IsSummoningAction = false -- Lepaskan kunci combat jika dimatikan
        end
    end
})

UtilityTab:CreateToggle({
    Name = "Auto Summon BBQ3 (Q3 Boss)",
    CurrentValue = false,
    Flag = "AutoBBQ3", 
    Callback = function(v)
        AutoBBQ3 = v
        if v then
            if AutoKingMon then AutoKingMon = false end 
            IsSummoningAction = false -- [FIX BUG 3] Reset state agar loop tidak nyangkut dari sisa sesi sebelumnya
            FollowTarget = false
            RedFollow = false
            HollowFollow = false
            CounterFollow = false
            PurpleFollow = false
            ZMoveFollow = false
            GilgameshFollow = false
            ComboFollow = false
            LootingActive = false 
            Rayfield:Notify({Title = "System", Content = "Auto BBQ3 ON. Checking Resources...", Duration = 3})
        else
            IsSummoningAction = false
            Rayfield:Notify({Title = "System", Content = "Auto BBQ3 Stopped.", Duration = 3})
        end
    end
})

UtilityTab:CreateToggle({
    Name = "Auto King Mon Summon",
    CurrentValue = false,
    Flag = "AutoKingMon", 
    Callback = function(v)
        AutoKingMon = v
        if v then
            if AutoBBQ3 then AutoBBQ3 = false end 
            FollowTarget = false
            RedFollow = false
            HollowFollow = false
            CounterFollow = false
            PurpleFollow = false
            ZMoveFollow = false
            GilgameshFollow = false
            ComboFollow = false
            LootingActive = false 
            Rayfield:Notify({Title = "System", Content = "Auto King Mon ON.", Duration = 3})
        else
            IsSummoningAction = false 
        end
    end
})

UtilityTab:CreateSection("Etc")

UtilityTab:CreateToggle({
    Name = "Auto Obtain OFA (Swap & Find Kuzma)",
    CurrentValue = false,
    Flag = "AutoAFO", 
    Callback = function(v)
        AutoAFO = v
        if v then
             Rayfield:Notify({Title = "Auto AFO", Content = "Script Started. Checking Stand...", Duration = 3})
        end
    end
})

UtilityTab:CreateToggle({
    Name = "Auto Roland Detect (Rejoin if Found)",
    CurrentValue = false,
    Flag = "AutoRoland", 
    Callback = function(v)
        AutoRoland = v
        if v then
            Rayfield:Notify({Title = "Roland Detect", Content = "Monitoring for Roland...", Duration = 3})
        end
    end
})

local BinahToggle
BinahToggle = UtilityTab:CreateToggle({ -- 2. Kita masukkan tombolnya ke dalam variabel
    Name = "Auto Binah Search (Rejoin Same Server)",
    CurrentValue = false,
    Flag = "AutoBinah", 
    Callback = function(v)
        AutoBinah = v
        if v then
            Rayfield:Notify({Title = "Binah Search", Content = "Checking for Arbiter...", Duration = 3})
        end
    end
})

UtilityTab:CreateSection("LaManchaland Dungeon")

UtilityTab:CreateToggle({
    Name = "Auto LaManchaland",
    CurrentValue = false,
    Flag = "AutoLaMancha", 
    Callback = function(v)
        AutoLaMancha = v
        if not v then
            -- Reset semua state jika dimatikan
            ClashActive = false
            CutsceneCount = 0
            if not AutoKingMon and not AutoBBQ3 and not AutoDeku then
                IsSummoningAction = false
            end
        end
    end
})

-- ===== LOOT UI LOGIC (REWORKED) =====
LootTab:CreateToggle({
    Name = "Auto Loot Rework",
    CurrentValue = false,
    Flag = "AutoLootRework", 
    Callback = function(v) 
        AutoLootRework = v 
    end
})

LootTab:CreateToggle({
    Name = "Auto Box & Barrel Only",
    CurrentValue = false,
    Flag = "AutoBoxBarrel", 
    Callback = function(v) 
        AutoBoxBarrel = v 
    end
})

LootTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Flag = "AutoSell", 
    Callback = function(v)
        AutoSell = v
        if v then
            Rayfield:Notify({Title = "Auto Sell", Content = "Selling items...", Duration = 3})
        end
    end
})

LootTab:CreateSlider({
    Name = "Loot Delay",
    Range = {0, 5},
    Increment = 0.1,
    CurrentValue = LootDelay,
    Flag = "LootDelay", 
    Callback = function(v)
        LootDelay = v
    end
})

local BlacklistDropdown
local function buildItemBlacklistDropdown(preserved)
    local currentItems = getItemNameList()
    if BlacklistDropdown then
        BlacklistDropdown:Refresh(currentItems, true)
    else
        BlacklistDropdown = LootTab:CreateDropdown({
            Name = "Item Blacklist (Don't Pick)",
            Options = currentItems,
            CurrentOption = preserved or {},
            MultipleOptions = true,
            Multi = true,
            Flag = "ItemBlacklist", 
            Callback = function(selected)
                table.clear(ItemBlacklist)
                for _, name in ipairs(selected) do
                    ItemBlacklist[name] = true
                end
            end
        })
    end
end
buildItemBlacklistDropdown()

LootTab:CreateButton({
    Name = "Open Shop (Auddy)",
    Callback = function()
        -- Mencari path ke prompt Auddy dengan aman
        local prompt = workspace:FindFirstChild("Map") 
            and workspace.Map:FindFirstChild("NPCs") 
            and workspace.Map.NPCs:FindFirstChild("Auddy") 
            and workspace.Map.NPCs.Auddy:FindFirstChild("ProximityPrompt")

        if prompt then
            -- Bypass jarak & durasi agar instan
            prompt.MaxActivationDistance = 50
            prompt.HoldDuration = 0
            
            -- Eksekusi prompt
            fireproximityprompt(prompt)
            Rayfield:Notify({Title = "Shop", Content = "Opening Auddy's Shop...", Duration = 2})
        else
            Rayfield:Notify({Title = "Error", Content = "Auddy NPC not found!", Duration = 2})
        end
    end
})

-- ===== TELEPORT FUNCTIONS =====
local function GetTeleportCFrame(targetHRP)
    local offset
    if TeleportMode == "Front" then
        offset = targetHRP.CFrame.LookVector * TeleportDistance
    elseif TeleportMode == "Behind" then
        offset = -targetHRP.CFrame.LookVector * TeleportDistance
    elseif TeleportMode == "Right" then
        offset = targetHRP.CFrame.RightVector * TeleportDistance
    elseif TeleportMode == "Left" then
        offset = -targetHRP.CFrame.RightVector * TeleportDistance
    elseif TeleportMode == "Up" then
        offset = Vector3.new(0, TeleportDistance, 0)
    elseif TeleportMode == "Down" then
        offset = Vector3.new(0, -TeleportDistance, 0)
    end
    return CFrame.new(targetHRP.Position + offset, targetHRP.Position)
end

-- =======================================================
-- ===== UNIFIED FOLLOW SYSTEM (LOGIC UPDATED & SPLIT) ===
-- =======================================================
RunService.Heartbeat:Connect(function()
    if IsSummoningAction then return end 
    if LootingActive then return end 

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- === 1. COUNTER FOLLOW ===
    if CounterFollow then
        local target = CurrentCounterTarget
        if target and target:FindFirstChild("HumanoidRootPart") then
            local thrp = target.HumanoidRootPart
            hrp.CFrame = CFrame.new(thrp.Position + (-thrp.CFrame.RightVector * 3), thrp.Position)
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
        end

    -- === 2. PURPLE FOLLOW ===
    elseif PurpleFollow then
        local target = CurrentPurpleTarget
        if target and target:FindFirstChild("HumanoidRootPart") then
            local thrp = target.HumanoidRootPart
            hrp.CFrame = CFrame.new(thrp.Position + Vector3.new(-20, 26, 0), thrp.Position)
        end

    -- === 3. [BARU] COMBO QZG FOLLOW ===
    elseif ComboFollow then
        local activeTarget = CurrentComboTarget
        if activeTarget and activeTarget:FindFirstChild("HumanoidRootPart") then
            local thrp = activeTarget.HumanoidRootPart
            hrp.CFrame = CFrame.new(thrp.Position + Vector3.new(0, 26, 0), thrp.Position)
            hrp.Velocity = Vector3.zero 
            hrp.AssemblyLinearVelocity = Vector3.zero
        end

    -- === 4. [TERPISAH] GILGAMESH FOLLOW ===
    elseif GilgameshFollow then
        local activeTarget = CurrentGilgameshTarget
        if activeTarget and activeTarget:FindFirstChild("HumanoidRootPart") then
            local thrp = activeTarget.HumanoidRootPart
            hrp.CFrame = CFrame.new(thrp.Position + Vector3.new(0, 26, 0), thrp.Position)
            hrp.Velocity = Vector3.zero 
            hrp.AssemblyLinearVelocity = Vector3.zero
        end

    -- === 5. [TERPISAH] RED / HOLLOW (Atas Kepala) ===
    elseif RedFollow then
        local activeTarget = nil
        if AutoRed then activeTarget = CurrentRedTarget end

        if activeTarget and activeTarget:FindFirstChild("HumanoidRootPart") then
            local thrp = activeTarget.HumanoidRootPart
            hrp.CFrame = CFrame.new(thrp.Position + Vector3.new(0, 26, 0), thrp.Position)
            hrp.Velocity = Vector3.zero 
            hrp.AssemblyLinearVelocity = Vector3.zero
        end

    -- === 6. Z MOVE FOLLOW ===
    elseif ZMoveFollow then
        local activeTarget = CurrentZMoveTarget
        if activeTarget and activeTarget:FindFirstChild("HumanoidRootPart") then
            local thrp = activeTarget.HumanoidRootPart
            hrp.CFrame = CFrame.new(thrp.Position + Vector3.new(-35, 50, 0), thrp.Position)
            hrp.Velocity = Vector3.zero 
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-- ===== AUTO MASTERY & BREAKTHROUGH =====
task.spawn(function()
    while true do
        if AutoRed or AutoGojoRework or AutoZMove or AutoGilgamesh or AutoComboQZG then
            task.wait(3) 
        else
            task.wait(1.5)
        end

        local data = LocalPlayer:FindFirstChild("Data")
        
        if data then
            local exp = data:FindFirstChild("Exp")
            local mastery = data:FindFirstChild("Mastery")
            local globalRemotes = Rep:FindFirstChild("GlobalUsedRemotes")

            if exp and mastery and globalRemotes then
                if AutoBreakthrough then
                    if mastery.Value == 15 and exp.Value >= 30725 then
                        pcall(function()
                            local breakRemote = globalRemotes:FindFirstChild("Breakthrough")
                            if breakRemote then breakRemote:FireServer() end
                        end)
                    end
                end

                if AutoMastery then
                    if exp.Value >= 30725 and mastery.Value < 15 then
                        pcall(function()
                            local upgradeRemote = globalRemotes:FindFirstChild("UpgradeMas")
                            if upgradeRemote then upgradeRemote:FireServer() end
                        end)
                    end
                end
            end
        end
    end
end)

-- ===== AUTO CLEAR LOOP =====
task.spawn(function()
    while true do
        if AutoClear then
            pcall(function()
                local args = {
                    buffer.fromstring("\018"),
                    buffer.fromstring("\254\001\000\006\005Clear")
                }
                local utilityPath = Rep:WaitForChild("ABC - First Priority"):WaitForChild("Utility")
                utilityPath:WaitForChild("Modules"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
            end)
            
            for i = 1, 120 do
                if not AutoClear then break end
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end)

-- ===== AUTO BP EXCHANGE LOOP =====
task.spawn(function()
    while true do
        task.wait(1.5) 
        if AutoBPExchange then
            local data = LocalPlayer:FindFirstChild("Data")
            local bp = data and data:FindFirstChild("BP")
            
            if bp and bp.Value >= 1 then
                local args = { "B4T" }
                pcall(function()
                    Rep:WaitForChild("GlobalUsedRemotes"):WaitForChild("TokenExchange"):FireServer(unpack(args))
                end)
            end
        end
    end
end)

-- ===== AUTO KING MON LOGIC =====
task.spawn(function()
    while true do
        task.wait(1)
        if not AutoKingMon then 
            if not AutoBBQ3 then IsSummoningAction = false end
            continue 
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then continue end

        if Workspace:FindFirstChild("Living") and Workspace.Living:FindFirstChild("King Mon") then
            if IsSummoningAction then
                IsSummoningAction = false
                Rayfield:Notify({Title = "Battle", Content = "King Mon Alive! Combat Resumed.", Duration = 3})
            end
            task.wait(2)
            continue
        end

        IsSummoningAction = true

        local soulCount = GetItemCount("Soul of Herrscher of Flamescion")
        local nailCount = GetItemCount("Holy Nail of Helena")
        local pandoraCount = GetItemCount("Pandora's Box")
        
        local QuestFolder = LocalPlayer:FindFirstChild("QuestFolder")
        local HasQuest110 = QuestFolder and QuestFolder:FindFirstChild("110")

        if nailCount > 0 then
            local map = Workspace:FindFirstChild("Map")
            local ruined = map and map:FindFirstChild("RuinedCity")
            local spawnPart = ruined and ruined:FindFirstChild("Spawn")
            
            if spawnPart then
                local prompt = spawnPart:FindFirstChild("ProximityPrompt")
                hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
                hrp.Velocity = Vector3.zero
                if prompt then
                    task.wait(0.5)
                    fireproximityprompt(prompt)
                    Rayfield:Notify({Title = "Phase 4", Content = "Summoning King Mon...", Duration = 1})
                end
            end
            task.wait(3) 
            continue 
        end

        if HasQuest110 and soulCount > 0 then
            local args = {
                buffer.fromstring("\014"),
                buffer.fromstring("\254\002\000\006\006TurnIn\006\031Soul of Herrscher of Flamescion")
            }
            pcall(function()
                Rep:WaitForChild("ABC - First Priority"):WaitForChild("Utility"):WaitForChild("Modules"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
            end)
            task.wait(0.5) 
            continue 
        end

        if HasQuest110 and soulCount == 0 and nailCount == 0 then
            local map = Workspace:FindFirstChild("Map")
            local npcs = map and map:FindFirstChild("NPCs")
            local anderson = npcs and npcs:FindFirstChild("Anderson")

            if anderson then
                local root = anderson:FindFirstChild("HumanoidRootPart") or anderson:FindFirstChild("Head")
                local prompt = anderson:FindFirstChildWhichIsA("ProximityPrompt", true)

                if root then
                    hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
                    hrp.Velocity = Vector3.zero
                    if prompt then
                        task.wait(0.5)
                        fireproximityprompt(prompt)
                        task.wait(1)
                    end
                end
            end
            continue
        end

        if not HasQuest110 then
            if soulCount < 10 then
                local foundItem = false
                if Workspace:FindFirstChild("Item") then
                    for _, drop in ipairs(Workspace.Item:GetChildren()) do
                        local itemDrop = drop:FindFirstChild("ItemDrop")
                        local nameVal = drop:FindFirstChild("ItemName") or (itemDrop and itemDrop:FindFirstChild("ItemName"))
                        local isTargetItem = (nameVal and nameVal.Value == "Soul of Herrscher of Flamescion") or (drop.Name == "Soul of Herrscher of Flamescion")

                        if isTargetItem then
                            local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt", true)
                            local targetPart = drop:FindFirstChild("ItemDrop") or drop
                            if targetPart and prompt then
                                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                                hrp.Velocity = Vector3.zero
                                task.wait(0.3) 
                                fireproximityprompt(prompt)
                                foundItem = true
                                break 
                            end
                        end
                    end
                end
                task.wait(0.5)

            else
                if pandoraCount == 0 then
                    local args = {
                        buffer.fromstring("\020"),
                        buffer.fromstring("\254\002\000\006\bPurchase\001\020")
                    }
                    pcall(function()
                        Rep:WaitForChild("ABC - First Priority"):WaitForChild("Utility"):WaitForChild("Modules"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
                    end)
                    task.wait(1)
                end
                local argsQ = {110}
                pcall(function()
                    Rep:WaitForChild("QuestRemotes"):WaitForChild("AcceptQuest"):FireServer(unpack(argsQ))
                end)
                task.wait(1) 
            end
        end
    end
end)

-- ===== AUTO BBQ3 SUMMON LOGIC =====
task.spawn(function()
    local IsSavingToken = false 

    while true do
        task.wait(0.1)
        if not AutoBBQ3 then 
            IsSavingToken = false
            if not AutoKingMon and not AutoDeku then IsSummoningAction = false end
            continue 
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then continue end

        if Workspace:FindFirstChild("Living") and Workspace.Living:FindFirstChild("Q3Boss") then
            if IsSummoningAction then
                IsSummoningAction = false
                Rayfield:Notify({Title = "Battle", Content = "Q3 Boss Spawned! Combat Resumed.", Duration = 3})
            end
            task.wait(0.1)
            continue
        end

        local meatCount = GetItemCount("Delicious Meat")
        local ultraCount = GetItemCount("Ultra Premium BBQ Meat")
        -- [FIX BUG 1] Ganti WaitForChild -> FindFirstChild agar tidak freeze loop selamanya
        local _bbqData = LocalPlayer:FindFirstChild("Data")
        local tokenData = _bbqData and _bbqData:FindFirstChild("Token")
        local tokenValue = tokenData and tokenData.Value or 0

        if ultraCount == 0 and meatCount < 5 then
            if IsSavingToken then
                if tokenValue >= 5000 then
                    IsSavingToken = false 
                    Rayfield:Notify({Title = "BBQ3", Content = "Token 5000 Terkumpul! Melanjutkan...", Duration = 3})
                else
                    IsSummoningAction = false 
                    Rayfield:Notify({Title = "Saving Token", Content = "Farming... (" .. tostring(tokenValue) .. "/5000)", Duration = 1})
                    task.wait(3)
                    continue
                end
            elseif tokenValue < 1000 then
                IsSavingToken = true
                IsSummoningAction = false 
                Rayfield:Notify({Title = "Low Token", Content = "Token < 1000. Memulai Farming sampai 5000...", Duration = 3})
                task.wait(0.1)
                continue
            end
        end

        IsSummoningAction = true

        if ultraCount > 0 then
            local map = Workspace:FindFirstChild("Map")
            local ruined = map and map:FindFirstChild("RuinedCity")
            local spawnPart = ruined and ruined:FindFirstChild("Spawn")
            if spawnPart then
                local prompt = spawnPart:FindFirstChild("ProximityPrompt")
                hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
                hrp.Velocity = Vector3.zero
                if prompt then
                    task.wait(0.5)
                    fireproximityprompt(prompt)
                    Rayfield:Notify({Title = "Phase 4", Content = "Summoning Q3BOSS...", Duration = 1})
                end
            end
            task.wait(0.1) 
            continue 
        end
            
        if ultraCount == 0 and meatCount >= 5 then
            Rayfield:Notify({Title = "BBQ3", Content = "Crafting Ultra Premium Meat... (Combat Paused)", Duration = 1})
            local args = {
                buffer.fromstring("\005"),
                buffer.fromstring("\254\003\000\006\004Rest\006\022Ultra Premium BBQ Meat\006\005Craft")
            }
            pcall(function()
                Rep:WaitForChild("ABC - First Priority"):WaitForChild("Utility"):WaitForChild("Modules"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
            end)
            task.wait(0.1)
            continue
        end

        if ultraCount == 0 and meatCount < 5 then
            local needed = 5 - meatCount
            Rayfield:Notify({Title = "BBQ3", Content = "Buying Delicious Meat... (Combat Paused)", Duration = 1})
            for i = 1, needed do
                if not AutoBBQ3 then break end
                if not tokenData or tokenData.Value < 1000 then break end -- [FIX BUG 2] Safe nil-check
                local args = {
                    buffer.fromstring("\b"),
                    buffer.fromstring("\254\001\000\006\rDeliciousMeat")
                }
                pcall(function()
                    Rep:WaitForChild("ABC - First Priority"):WaitForChild("Utility"):WaitForChild("Modules"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
                end)
                task.wait(0.1)
            end
            task.wait(0.1)
        end
    end
end)

-- ===== AUTO RED LOOP =====
task.spawn(function()
    while true do
        task.wait(2.2)
        if IsSummoningAction then continue end 

        if not AutoRed then
            RedFollow = false
            continue
        end

        CurrentRedTarget = GetValidTargetFromList(RedTargetList)

        if not CurrentRedTarget then
             RedFollow = false
             repeat
                task.wait(0.1)
                CurrentRedTarget = GetValidTargetFromList(RedTargetList)
             until not AutoRed or CurrentRedTarget or IsSummoningAction
             
             if not AutoRed or IsSummoningAction then continue end
        end

        local char = LocalPlayer.Character
        if not char then continue end

        UseFold(0.1)
        if not AutoRed then continue end
        task.wait(0.001)

        RedFollow = true
        task.wait(0.001)

        --(attack)
        pcall(function()
            Gojo.RevRed2:FireServer()
        end)

        task.wait(3)

        RedFollow = false
        if AutoRed and not IsSummoningAction then
            ForceKillByVoidOnce()
        task.wait(3)
        end
    end
end)

-- ===== AUTO Z MOVE LOOP (FIXED STAND CHECK) =====
task.spawn(function()
    while true do
        task.wait(2.2)
        if IsSummoningAction then continue end 

        if not AutoZMove then
            ZMoveFollow = false
            continue
        end

        CurrentZMoveTarget = GetValidTargetFromList(ZMoveTargetList)

        if not CurrentZMoveTarget then
             ZMoveFollow = false
             repeat
                task.wait(0.1)
                CurrentZMoveTarget = GetValidTargetFromList(ZMoveTargetList)
             until not AutoZMove or CurrentZMoveTarget or IsSummoningAction
             
             if not AutoZMove or IsSummoningAction then continue end
        end

        local char = LocalPlayer.Character
        if not char then continue end

        UseFold(0.1) -- Sekarang aman karena stand sudah pasti benar
        if not AutoZMove then continue end
        task.wait(0.001)

        ZMoveFollow = true
        task.wait(0.5)

        --(attack)
        pcall(function()
            local args = {
                buffer.fromstring("\022"),
                buffer.fromstring("\254\002\000\006\001Z\005\000")
            }
            Rep:WaitForChild("ABC - First Priority"):WaitForChild("Utility"):WaitForChild("Modules"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
        end)

        task.wait(3)

        ZMoveFollow = false
        if AutoZMove and not IsSummoningAction then
            ForceKillByVoidOnce()
            task.wait(3)
        end
    end
end)

-- ===== AUTO GILGAMESH LOOP =====
task.spawn(function()
    while true do
        task.wait(0.1)
        if IsSummoningAction then continue end 

        if not AutoGilgamesh then
            GilgameshFollow = false
            continue
        end

        CurrentGilgameshTarget = GetValidTargetFromList(GilgameshTargetList)
        -- ... (Lanjutkan logic target seperti script asli)
        if not CurrentGilgameshTarget then
             GilgameshFollow = false
             repeat
                task.wait(0.1)
                CurrentGilgameshTarget = GetValidTargetFromList(GilgameshTargetList)
             until not AutoGilgamesh or CurrentGilgameshTarget or IsSummoningAction
             
             if not AutoGilgamesh or IsSummoningAction then continue end
        end

        local char = LocalPlayer.Character
        if not char then continue end

        UseFold(0.1)
        if not AutoGilgamesh then continue end
        task.wait(0.001)

        GilgameshFollow = true
        task.wait(0.5)

        pcall(function()
            if CurrentGilgameshTarget then
                local targetName = CurrentGilgameshTarget.Name
                local targetModel = workspace:WaitForChild("Living"):FindFirstChild(targetName)
                
                --(attack)
                if targetModel then
                    local args = {
                        buffer.fromstring("\022"),
                        buffer.fromstring("\254\003\000\006\001T\255\001\004\000\000\000\000:\248\216?"),
                        { targetModel }
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("ABC - First Priority"):WaitForChild("Utility"):WaitForChild("Modules"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
                end
            end
        end)

        task.wait(1)
        GilgameshFollow = false
        if AutoGilgamesh and not IsSummoningAction then
            ForceKillByVoidOnce()
            task.wait(3)
        end
    end
end)

-- ===== AUTO LOOT LOOP (REWORKED) =====
task.spawn(function()
    while task.wait(0.5) do
        if IsSummoningAction then 
            continue 
        end

        if not AutoLootRework then 
            LootingActive = false
            continue 
        end
        
        -- [UPDATE] Added Checks
        if FollowTarget or HollowFollow or RedFollow or CounterFollow or PurpleFollow or ZMoveFollow or GilgameshFollow or ComboFollow then
            LootingActive = false
            continue
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local items = Workspace:FindFirstChild("Item") and Workspace.Item:GetChildren() or {}

        if #items > 0 then
            LootingActive = true
            for _, item in ipairs(items) do
                if not AutoLootRework then break end
                if IsSummoningAction then break end
                if FollowTarget or HollowFollow or RedFollow or CounterFollow or PurpleFollow or ZMoveFollow or GilgameshFollow or ComboFollow then break end

                local itemName = item.Name
                local nameVal = item:FindFirstChild("ItemName") or (item:FindFirstChild("ItemDrop") and item.ItemDrop:FindFirstChild("ItemName"))
                if nameVal then itemName = nameVal.Value end

                if ItemBlacklist[itemName] then 
                    continue 
                end

                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                local targetPart = item:FindFirstChild("ItemDrop") or item:FindFirstChildWhichIsA("BasePart") or item

                if prompt and targetPart and targetPart:IsA("BasePart") then
                    hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                    hrp.Velocity = Vector3.zero
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    
                    prompt.HoldDuration = 0
                    prompt.MaxActivationDistance = 50
                    
                    task.wait(0.15) 
                    fireproximityprompt(prompt) 
                    task.wait(LootDelay) 
                end
            end
            LootingActive = false
        end
    end
end)

-- ===== AUTO BOX & BARREL LOOP =====
task.spawn(function()
    while task.wait(0.5) do
        -- Cek prioritas (Summoning/Combat mematikan looting)
        if IsSummoningAction then 
            continue 
        end

        if not AutoBoxBarrel then 
            continue 
        end
        
        -- Cek jika sedang Combat/Follow (Mencegah teleport saat bertarung)
        if FollowTarget or HollowFollow or RedFollow or CounterFollow or PurpleFollow or ZMoveFollow or GilgameshFollow or ComboFollow then
            continue
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local items = Workspace:FindFirstChild("Item") and Workspace.Item:GetChildren() or {}

        if #items > 0 then
            for _, item in ipairs(items) do
                if not AutoBoxBarrel then break end
                if IsSummoningAction then break end
                -- Cek ulang combat saat looping item
                if FollowTarget or HollowFollow or RedFollow or CounterFollow or PurpleFollow or ZMoveFollow or GilgameshFollow or ComboFollow then break end

                local itemName = item.Name
                local nameVal = item:FindFirstChild("ItemName") or (item:FindFirstChild("ItemDrop") and item.ItemDrop:FindFirstChild("ItemName"))
                if nameVal then itemName = nameVal.Value end

                -- [[ MODIFIKASI: HANYA AMBIL BOX DAN BARREL ]] --
                if itemName == "Box" or itemName == "Barrel" then 
                    
                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local targetPart = item:FindFirstChild("ItemDrop") or item:FindFirstChildWhichIsA("BasePart") or item

                    if prompt and targetPart and targetPart:IsA("BasePart") then
                        -- Teleport ke item
                        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                        hrp.Velocity = Vector3.zero
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        
                        -- Bypass Prompt
                        prompt.HoldDuration = 0
                        prompt.MaxActivationDistance = 50
                        
                        task.wait(0.15) 
                        fireproximityprompt(prompt) 
                        
                        -- Menggunakan LootDelay yang sama dengan tab Loot agar kecepatannya bisa diatur
                        task.wait(LootDelay) 
                    end
                end
            end
        end
    end
end)

-- ===== AUTO ITEM REFRESH =====
task.spawn(function()
    while task.wait(1) do
        if AutoItemRefresh and BlacklistDropdown then
            local sig = getItemSignature()
            if sig ~= LastItemSignature then
                LastItemSignature = sig
                buildItemBlacklistDropdown()
            end
        end
    end
end)

-- ===== AUTO SELL LOOP =====
task.spawn(function()
    while task.wait(1) do -- Cek setiap 1 detik
        if AutoSell then
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            
            if backpack then
                -- Loop semua item di backpack
                for _, item in ipairs(backpack:GetChildren()) do
                    if not AutoSell then break end -- Stop jika dimatikan tiba-tiba

                    -- Cek apakah nama item ada di daftar SellList
                    if table.find(SellList, item.Name) then
                        pcall(function()
                            local args = { item.Name }
                            game:GetService("ReplicatedStorage"):WaitForChild("GlobalUsedRemotes"):WaitForChild("SellItem"):FireServer(unpack(args))
                        end)
                        task.wait(0.1) -- Delay kecil agar tidak spam remote berlebihan
                    end
                end
            end
        end
    end
end)

-- ===== AUTO BACKGROUND REFRESH TARGET =====
task.spawn(function()
    while task.wait(1) do
        if AutoRefreshTarget then
            if AutoRed and (not CurrentRedTarget or not IsTargetAlive(CurrentRedTarget)) then
                CurrentRedTarget = GetValidTargetFromList(RedTargetList)
            end
            if AutoZMove and (not CurrentZMoveTarget or not IsTargetAlive(CurrentZMoveTarget)) then
                CurrentZMoveTarget = GetValidTargetFromList(ZMoveTargetList)
            end
            --  GILGAMESH REFRESH
            if AutoGilgamesh and (not CurrentGilgameshTarget or not IsTargetAlive(CurrentGilgameshTarget)) then
                CurrentGilgameshTarget = GetValidTargetFromList(GilgameshTargetList)
            end
            
            -- RONIN REFRESH
            if AutoRonin and (not CurrentRoninTarget or not IsTargetAlive(CurrentRoninTarget)) then
                CurrentRoninTarget = GetValidTargetFromList(RoninTargetList)
            end
            
            --  COMBO QZG REFRESH
            if AutoComboQZG and (not CurrentComboTarget or not IsTargetAlive(CurrentComboTarget)) then
                CurrentComboTarget = GetValidTargetFromList(ComboTargetList)
            end
            if AutoGojoRework then
                 if not CurrentCounterTarget or not IsTargetAlive(CurrentCounterTarget) then
                     CurrentCounterTarget = GetValidTargetFromList(CounterTargetList)
                 end
                 if not CurrentPurpleTarget or not IsTargetAlive(CurrentPurpleTarget) then
                     CurrentPurpleTarget = GetValidTargetFromList(PurpleTargetList)
                 end
            end
        end
    end
end)

-- ==== AUTO GOJO REWORK LOOP ====
task.spawn(function()
    while true do
        task.wait(2.2)
        if IsSummoningAction then continue end

        if not AutoGojoRework then
            CounterFollow = false
            PurpleFollow = false
            continue
        end

        CurrentPurpleTarget = GetValidTargetFromList(PurpleTargetList)
        
        if not CurrentCounterTarget or not IsTargetAlive(CurrentCounterTarget) then
             CurrentCounterTarget = GetValidTargetFromList(CounterTargetList)
        end

        if not CurrentCounterTarget then
            CounterFollow = false
            PurpleFollow = false
            Rayfield:Notify({Title = "System", Content = "Waiting for Counter Dummy...", Duration = 3})
            
            repeat 
                task.wait(1)
                CurrentCounterTarget = GetValidTargetFromList(CounterTargetList)
            until not AutoGojoRework or CurrentCounterTarget or IsSummoningAction
            
            task.wait(1)
            continue
        end

        if not CurrentPurpleTarget then
             Rayfield:Notify({Title = "System", Content = "Waiting for Purple Target...", Duration = 3})             
             CounterFollow = false
             PurpleFollow = false
            
             repeat
                task.wait(1)
                CurrentPurpleTarget = GetValidTargetFromList(PurpleTargetList)
             until not AutoGojoRework or CurrentPurpleTarget or IsSummoningAction
             
             if not AutoGojoRework or IsSummoningAction then continue end
        end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then continue end

        UseFold(0.5)
        CounterFollow = true 
        task.wait(0.5)
        
        local nextPunchTime = 0
        while AutoGojoRework and not IsSummoningAction and hum.Health > 54 and IsTargetAlive(CurrentCounterTarget) do
            if os.clock() >= nextPunchTime then
                pcall(function() Gojo.Punch:FireServer() end)
                nextPunchTime = os.clock() + 0.35
            end
            RunService.Heartbeat:Wait()
        end
        
        if not AutoGojoRework or IsSummoningAction then continue end

        CounterFollow = false
        if hrp then 
            CreateSafeZone() 
            hrp.CFrame = CFrame.new(0, SAFE_Y + 5, 0)
            hrp.Velocity = Vector3.new(0,0,0) 
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
        
        UseHeal(1.85)
        task.wait(0.5)
        UseResurrect()
        task.wait(2.5)
        
        if not IsTargetAlive(CurrentCounterTarget) then
             CurrentCounterTarget = GetValidTargetFromList(CounterTargetList)
        end

        if CurrentCounterTarget then
            CounterFollow = true
            task.wait(0.1)
            local phase3Start = os.clock()
            local nextPunchStep3 = 0
            while (os.clock() - phase3Start < 12) and AutoGojoRework and not IsSummoningAction do
                if os.clock() >= nextPunchStep3 then
                    pcall(function() Gojo.Punch:FireServer() end)
                    nextPunchStep3 = os.clock() + 0.35
                end
                RunService.Heartbeat:Wait()
            end
        end

        task.wait(0.5)

        CounterFollow = false
        PurpleFollow = true 
        
        local t = os.clock()
        while os.clock() - t < 50 do
            if not AutoGojoRework or IsSummoningAction then break end
            task.wait()
        end

        --(attack)
        if AutoGojoRework and not IsSummoningAction then
            pcall(function()
                Gojo.HollowPurple:FireServer()
            end)
        end

        task.wait(23)
        PurpleFollow = false
        CounterFollow = false
        if AutoGojoRework and not IsSummoningAction then
            ForceKillByVoidOnce()
            task.wait(3)
        end
    end
end)

-- ===== AUTO COMBO QZG LOOP =====
task.spawn(function()
    while true do
        task.wait(2.5)
        if IsSummoningAction then continue end 

        -- Cek Toggle
        if not AutoComboQZG then
            ComboFollow = false
            continue
        end

        -- Cari Target
        CurrentComboTarget = GetValidTargetFromList(ComboTargetList)

        if not CurrentComboTarget then
             ComboFollow = false
             repeat
                task.wait(0.1)
                CurrentComboTarget = GetValidTargetFromList(ComboTargetList)
             until not AutoComboQZG or CurrentComboTarget or IsSummoningAction
             
             if not AutoComboQZG or IsSummoningAction then continue end
        end

        local char = LocalPlayer.Character
        if not char then continue end

        -- 1. REMOTE Q (Sebagai pengganti Fold)
        pcall(function()
            local args = {
                buffer.fromstring("\022"),
                buffer.fromstring("\254\001\000\006\001Q")
            }
            game:GetService("ReplicatedStorage"):WaitForChild("ABC - First Priority"):WaitForChild("Utility"):WaitForChild("Modules"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
        end)
        
        if not AutoComboQZG then continue end
        
        -- 2. CEK COOLDOWN Z
        -- Script akan diam di sini sampai Z_Cooldown hilang dari folder WhyIsItHere
        local whyFolder = LocalPlayer:FindFirstChild("WhyIsItHere")
        if whyFolder then
            while whyFolder:FindFirstChild("Z_Cooldown") do
                if not AutoComboQZG then break end
                -- Optional: Bisa tambahkan print("Waiting for Z Cooldown...") untuk debug
                task.wait(0.1)
            end
        end

        if not AutoComboQZG then continue end

        -- 3. REMOTE Z (Dieksekusi setelah cooldown hilang)
        pcall(function()
            local args = {
                buffer.fromstring("\022"),
                buffer.fromstring("\254\001\000\006\001Z")
            }
            game:GetService("ReplicatedStorage"):WaitForChild("ABC - First Priority"):WaitForChild("Utility"):WaitForChild("Modules"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
        end)
        
        task.wait(0.1) -- Delay kecil agar animasi server register

        -- 5. REMOTE G (Attack)
        pcall(function()
            local args = {
                buffer.fromstring("\022"),
                buffer.fromstring("\254\001\000\006\001G")
            }
            game:GetService("ReplicatedStorage"):WaitForChild("ABC - First Priority"):WaitForChild("Utility"):WaitForChild("Modules"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
        end)
        task.wait(3)
        ComboFollow = true

        task.wait(9) -- Delay sebelum reset/kill

        -- Reset State & Force Kill
        ComboFollow = false
        if AutoComboQZG and not IsSummoningAction then
            ForceKillByVoidOnce()
            task.wait(3)
        end
    end
end)

-- ===== AUTO BINAH SEARCH LOOP (MODIFIED) =====
task.spawn(function()
    -- Handler jika teleport gagal
    LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Failed then
            task.wait(1)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)

    while task.wait(2) do
        if AutoBinah then
            local SearchDuration = 95 
            local ElapsedTime = 0
            local ArbiterFound = false

            Rayfield:Notify({Title = "Binah Search", Content = "Searching for 1 Minute and 35 Seconds...", Duration = 3})

            -- Loop pencarian
            while ElapsedTime < SearchDuration do
                if not AutoBinah then break end 

                -- Cek keberadaan Arbiter
                if Workspace:FindFirstChild("Living") and Workspace.Living:FindFirstChild("Arbiter") then
                    ArbiterFound = true
                    break -- Keluar loop karena ketemu
                end

                ElapsedTime = ElapsedTime + 1
                task.wait(1)
            end

            if ArbiterFound then
                -- [[ JIKA KETEMU ARBITER ]] --
                
                -- 1. Matikan logic pencarian
                AutoBinah = false 
                
                -- 2. Matikan TOMBOL VISUAL (Centang jadi hilang)
                if BinahToggle then
                    BinahToggle:Set(false) 
                end

                -- 3. Beritahu player
                Rayfield:Notify({Title = "BINAH SEARCH", Content = "ARBITER FOUND! Stopping Search.", Duration = 10})
                
                -- 4. Bunyikan suara
                local sound = Instance.new("Sound")
                sound.SoundId = "rbxassetid://4590657391"
                sound.Parent = Workspace
                sound:Play()

            elseif AutoBinah then
                -- [[ JIKA TIDAK KETEMU (WAKTU HABIS) ]] --
                Rayfield:Notify({Title = "Binah Search", Content = "Timeout. Rejoining...", Duration = 2})
                
                -- Rejoin Logic
                if #Players:GetPlayers() <= 1 then
                    LocalPlayer:Kick("Rejoining for Arbiter...")
                    task.wait()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                else
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end
        end
    end
end)

-- ===== AUTO AFO (OBTAIN OFA) LOGIC [FIXED & IMPROVED] =====
task.spawn(function()
    while true do
        task.wait(1)
        if not AutoAFO then continue end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then continue end

        local data = LocalPlayer:FindFirstChild("Data")
        if not data then continue end

        -- Cek Stand saat ini
        local currentStand = data:FindFirstChild("Stand")
        local isStandless = false

        if currentStand then
            -- Cek value (Standless biasanya 1, tapi kita cek string juga jaga-jaga)
            if currentStand.Value == 1 or tostring(currentStand.Value) == "Standless" then
                isStandless = true
            end
        end

        if not isStandless then
            -- === LOGIKA SWAP KE SLOT KOSONG ===
            local foundSlot = nil
            for i = 1, 29 do
                if i == 4 or i == 5 or i == 6 then continue end -- Skip slot vip/khusus
                local slotName = "Slot" .. i
                local slotObj = data:FindFirstChild(slotName)
                
                if slotObj and (slotObj.Value == 1 or tostring(slotObj.Value) == "Standless") then
                    foundSlot = slotName
                    break 
                end
            end

            if foundSlot then
                Rayfield:Notify({Title = "Auto AFO", Content = "Swapping to " .. foundSlot, Duration = 2})
                pcall(function()
                    local args = { foundSlot }
                    game:GetService("ReplicatedStorage"):WaitForChild("StorageRemote"):WaitForChild("UseStorageExtra"):FireServer(unpack(args))
                end)
                task.wait(2) 
            else
                Rayfield:Notify({Title = "Auto AFO", Content = "Full Storage! Cannot swap to Standless.", Duration = 3})
                task.wait(3)
            end
            
        else
            -- === LOGIKA CARI KUZMA & TELEPORT ===
            -- Kita cari Kuzma di folder Map/NPCs ATAU di Workspace secara umum
            local map = Workspace:FindFirstChild("Map")
            local npcs = map and map:FindFirstChild("NPCs")
            
            -- Coba cari di folder NPCs dulu, kalau tidak ada cari di seluruh Workspace
            local kuzma = (npcs and npcs:FindFirstChild("Kuzma"))
            if kuzma then
                -- [PERBAIKAN UTAMA DISINI]
                -- Kita harus cari RootPart atau Head, tidak bisa langsung kuzma.CFrame
                local targetPart = kuzma:FindFirstChild("HumanoidRootPart") or kuzma:FindFirstChild("Head")

                if targetPart then
                    hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                    hrp.Velocity = Vector3.zero
                    
                    -- Debug print (bisa dihapus)
                    -- print("Teleporting to Kuzma...") 

                    task.wait(0.5)
                    
                    -- Eksekusi remote Obtain OFA
                    pcall(function()
                        game:GetService("ReplicatedStorage"):WaitForChild("GlobalUsedRemotes"):WaitForChild("ObtainOFA"):FireServer()
                    end)
                    
                    Rayfield:Notify({Title = "Auto AFO", Content = "Interacting with Kuzma...", Duration = 2})
                    task.wait(2)
                else
                    Rayfield:Notify({Title = "Error", Content = "Kuzma found but has no body parts!", Duration = 2})
                end
            else
                -- Jika Kuzma benar-benar tidak ada di map
                -- Rayfield:Notify({Title = "Auto AFO", Content = "Waiting for Kuzma Spawn...", Duration = 1})
            end
        end
    end
end)

-- ===== AUTO DEKU LOGIC ===== --
task.spawn(function()
    -- [HELPER FUNCTION] Satu fungsi pintar untuk mencari & swap Stand apapun
    local function TrySwapToStand(targetID, targetName)
        local data = LocalPlayer:FindFirstChild("Data")
        if not data then return false end

        -- 1. Cek apakah Stand yang dipakai sudah benar?
        local currentStand = data:FindFirstChild("Stand")
        if currentStand and (currentStand.Value == targetID or tostring(currentStand.Value) == targetName) then
            return true -- Sudah equip, tidak perlu swap
        end

        -- 2. Cari di Slot 1-29
        for i = 1, 29 do
            -- Skip Slot 4, 5, dan 6 sesuai request
            if i == 4 or i == 5 or i == 6 then 
                continue 
            end

            local slotName = "Slot" .. i
            local slotVal = data:FindFirstChild(slotName)
            
            -- Cek apakah isi slot cocok dengan ID atau Nama
            if slotVal and (slotVal.Value == targetID or tostring(slotVal.Value) == targetName) then
                Rayfield:Notify({Title = "Auto Swap", Content = "Found " .. targetName .. " ("..targetID..") in " .. slotName, Duration = 2})
                
                local args = { slotName }
                game:GetService("ReplicatedStorage"):WaitForChild("StorageRemote"):WaitForChild("UseStorageExtra"):FireServer(unpack(args))
                return true -- Ketemu dan sedang swap
            end
        end
        
        return false -- Tidak ketemu di loop ini
    end

    -- [MAIN LOOP]
    while true do
        task.wait(1)
        if not AutoDeku then 
            continue 
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        local data = LocalPlayer:FindFirstChild("Data")
        if not data then continue end
        
        local currentStand = data:FindFirstChild("Stand")
        if not currentStand then continue end

        -- Cek keberadaan Boss Deku
        local dekuBoss = Workspace:FindFirstChild("Living") and Workspace.Living:FindFirstChild("Deku")

        -- ==========================================
        -- KONDISI 1: BOSS TIDAK ADA (SUMMON PHASE)
        -- ==========================================
        if not dekuBoss then
            IsSummoningAction = true -- Matikan combat lain

            -- [UPDATED LOGIC] Cek OFA ID 123 ATAU 124
            local isOfaEquipped = (currentStand.Value == 123) or (currentStand.Value == 124) or (tostring(currentStand.Value) == "Ofa")

            if not isOfaEquipped then
                Rayfield:Notify({Title = "Auto Deku", Content = "Searching OFA (123 or 124)...", Duration = 1})
                
                -- Coba cari ID 123 dulu
                local found = TrySwapToStand(123, "Ofa")
                
                -- Jika 123 tidak ketemu, cari ID 124
                if not found then
                    local found2 = TrySwapToStand(124, "Ofa")
                    if not found2 then
                         Rayfield:Notify({Title = "Auto Swap", Content = "OFA Not Found (Skipped 4,5,6)", Duration = 2})
                    end
                end
                
                task.wait(3) -- Delay swap
                continue
            end

            -- 2. Ambil Item OA's Grace (Loot)
            local item2Folder = Workspace:FindFirstChild("Item2")
            local graceItem = item2Folder and item2Folder:FindFirstChild("OA's Grace")
            
            if graceItem then
                local prompt = graceItem:FindFirstChild("ProximityPrompt")
                if prompt then
                    hrp.CFrame = graceItem.CFrame + Vector3.new(0, 3, 0)
                    hrp.Velocity = Vector3.zero
                    task.wait(0.5)
                    fireproximityprompt(prompt)
                    Rayfield:Notify({Title = "Loot", Content = "Taking OA's Grace...", Duration = 1})
                    task.wait(1)
                end
            end

            -- 3. Gunakan Item OA's Grace (Use)
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack and backpack:FindFirstChild("OA's Grace") then
                Rayfield:Notify({Title = "Item", Content = "Using OA's Grace!", Duration = 2})
                pcall(function()
                    game:GetService("ReplicatedStorage"):WaitForChild("UseItem"):WaitForChild("OFA"):FireServer(unpack({}))
                end)
                task.wait(1)
            end
            
            -- 4. Summon Deku
            local map = Workspace:FindFirstChild("Map")
            local ruined = map and map:FindFirstChild("RuinedCity")
            local spawnPart = ruined and ruined:FindFirstChild("Spawn")
            
            if spawnPart then
                local prompt = spawnPart:FindFirstChild("ProximityPrompt")
                local promptB = spawnPart:FindFirstChild("ProximityPromptB")
                
                -- Teleport jika jauh
                if (hrp.Position - spawnPart.Position).Magnitude > 10 then
                    hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
                    hrp.Velocity = Vector3.zero
                end

                if prompt then
                    task.wait(0.5)
                    fireproximityprompt(prompt)
                    if promptB then fireproximityprompt(promptB) end
                    Rayfield:Notify({Title = "Phase 4", Content = "Summoning Deku...", Duration = 1})
                    task.wait(2)
                end
            end

        -- ==========================================
        -- KONDISI 2: BOSS ADA (COMBAT PHASE)
        -- ==========================================
        else
            -- Tentukan Stand ID yang dibutuhkan berdasarkan toggle combat yang aktif
            local requiredID = nil
            local requiredName = ""
            
            if AutoGojoRework or AutoRed then
                requiredID = 64; requiredName = "Gojo"
            elseif AutoZMove then
                requiredID = 249; requiredName = "H"
            elseif AutoGilgamesh then
                requiredID = 193; requiredName = "gilgamesh"
            elseif AutoComboQZG then
                requiredID = 244; requiredName = "combo"
            elseif AutoRonin then
                requiredID = 242; requiredName = "Ronin"
            end

            if not requiredID then
                Rayfield:Notify({Title = "Auto Deku", Content = "Enable a Combat Toggle!", Duration = 2})
                task.wait(2)
                continue
            end

            -- Cek apakah Stand saat ini sudah benar
            if currentStand.Value ~= requiredID and tostring(currentStand.Value) ~= requiredName then
                IsSummoningAction = true -- Tahan combat saat swap
                Rayfield:Notify({Title = "Auto Deku", Content = "Swapping to " .. requiredName, Duration = 1})
                TrySwapToStand(requiredID, requiredName)
                task.wait(3)
            else
                -- Stand Benar -> Mulai Combat (Script asli akan mengambil alih karena IsSummoningAction jadi false)
                IsSummoningAction = false 
            end
        end
    end
end)

-- ===== AUTO ROLAND DETECT LOOP =====
task.spawn(function()
    while task.wait(3) do -- Cek setiap 3 detik
        if AutoRoland then
            -- Cek apakah Roland ada di folder Living
            if Workspace:FindFirstChild("Living") and Workspace.Living:FindFirstChild("Roland") then
                
                Rayfield:Notify({Title = "ROLAND DETECTED", Content = "Roland Found! Rejoining...", Duration = 2})
                
                -- LOGIKA REJOIN (Sama persis dengan Auto Binah)
                if #Players:GetPlayers() <= 1 then
                    -- Jika sendirian, gunakan Teleport biasa untuk menghindari error
                    LocalPlayer:Kick("Rejoining for Roland...")
                    task.wait()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                else
                    -- Rejoin ke JobId yang sama (Server yang sama)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end
        end
    end
end)

-- ===== AUTO RONIN LOOP (FIXED) =====
task.spawn(function()
    while true do
        task.wait(2.2)
        if IsSummoningAction then continue end 

        -- Cek Toggle
        if not AutoRonin then
            RoninFollow = false
            continue
        end

        -- Cari Target
        CurrentRoninTarget = GetValidTargetFromList(RoninTargetList)

        -- [FIX] Mengganti ComboRoninList menjadi RoninTargetList
        if not CurrentRoninTarget then
             repeat
                task.wait(0.1)
                CurrentRoninTarget = GetValidTargetFromList(RoninTargetList)
             until not AutoRonin or CurrentRoninTarget or IsSummoningAction
             
             if not AutoRonin or IsSummoningAction then continue end
        end

        local char = LocalPlayer.Character
        if not char then continue end
        
        -- 2. CEK COOLDOWN G
        local whyFolder = LocalPlayer:FindFirstChild("WhyIsItHere")
        if whyFolder then
            while whyFolder:FindFirstChild("G_Cooldown") do
                if not AutoRonin then break end
                task.wait(0.1)
            end
        end

        if not AutoRonin then continue end

        -- 3. REMOTE G 
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("RoninRemote"):WaitForChild("G"):FireServer()
        end)
        
        task.wait(0.5) 

        -- 4. REMOTE Q (SEBELUMNYA ERROR DISINI KARENA KURANG END)
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("RoninRemote"):WaitForChild("Q"):FireServer()
        end) -- [FIX] Menambahkan penutup end)
        
        if not AutoRonin then continue end

        -- 5. REMOTE T2 (attack)
        pcall(function()
            if CurrentRoninTarget then
                local targetName = CurrentRoninTarget.Name
                local targetInstance = workspace:WaitForChild("Living"):FindFirstChild(targetName)
                
                if targetInstance then
                    local args = { targetInstance }
                    game:GetService("ReplicatedStorage"):WaitForChild("RoninRemote"):WaitForChild("T2"):FireServer(unpack(args))
                end
            end
        end)

        task.wait(4) 

        -- 6. Reset & Force Kill 
        if AutoRonin and not IsSummoningAction then
            ForceKillByVoidOnce()
            task.wait(3.5) 
        end
    end
end)

-- =======================================================
-- ===== NO LAG V2 (TESTING) =========================
-- =======================================================

local NOLAG_CLASS = {
    ParticleEmitter=true, Fire=true, Smoke=true, Sparkles=true, Trail=true,
    BloomEffect=true, BlurEffect=true, ColorCorrectionEffect=true,
    SunRaysEffect=true, DepthOfFieldEffect=true,
    Atmosphere=true, Decal=true, Texture=true,
}

local NOLAG_VFX_NAME = {
    effects=true, effect=true, vfx=true, fx=true,
}

local function NoLagV2_CleanObject(obj)
    if not obj or not obj.Parent then return end
    if NOLAG_CLASS[obj.ClassName] then
        pcall(function() obj:Destroy() end)
        return
    end
    if (obj:IsA("Folder") or obj:IsA("Model")) and NOLAG_VFX_NAME[string.lower(obj.Name)] then
        pcall(function() obj:ClearAllChildren() end)
    end
end

-- Scan sekali saat toggle ON, yield tiap 200 obj agar tidak spike
local function NoLagV2_OneTimeScan()
    local Lighting = game:GetService("Lighting")
    for _, obj in ipairs(Lighting:GetChildren()) do
        NoLagV2_CleanObject(obj)
    end
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not AutoNoLagV2 then break end
        NoLagV2_CleanObject(obj)
        count = count + 1
        if count % 200 == 0 then
            task.wait()
        end
    end
end

function NoLagV2_Enable()
    task.spawn(NoLagV2_OneTimeScan)
    if not NoLagV2Connection then
        NoLagV2Connection = Workspace.DescendantAdded:Connect(function(obj)
            if AutoNoLagV2 then
                task.delay(0.05, function()
                    NoLagV2_CleanObject(obj)
                end)
            end
        end)
    end
end

function NoLagV2_Disable()
    AutoNoLagV2 = false
    if NoLagV2Connection then
        NoLagV2Connection:Disconnect()
        NoLagV2Connection = nil
    end
end

-- ===== FORCE REFRESH (LoadCharacter) =====
local function ForceKillByVoidForLamanchaland()
    if not AutoLaMancha then return end
    pcall(function()
        LocalPlayer:LoadCharacter()
    end)
    LocalPlayer.CharacterAdded:Wait()
    task.wait(1)
end

-- =======================================================
-- ===== AUTO DUNGEON READY (UPDATED: PressedReady1) =====
-- =======================================================
task.spawn(function()
    while true do
        -- Tunggu 30 detik sesuai permintaan
        task.wait(30)
        
        -- Mengecek apakah toggle AutoLaMancha aktif (agar tidak spam jika fitur dimatikan)
        if AutoLaMancha then
            pcall(function()
                local player = game:GetService("Players").LocalPlayer
                
                -- 1. Cari Value dari PressedReady1
                local readyObj = player:FindFirstChild("PressedReady1")
                
                if readyObj then
                    local readyValue = readyObj.Value -- Ambil valuenya
                    
                    -- 2. Masukkan value ke dalam args
                    local args = {
                        readyValue
                    }
                    
                    -- 3. Fire Remote
                    game:GetService("ReplicatedStorage"):WaitForChild("ABCRemotes"):WaitForChild("DungeonReady"):FireServer(unpack(args))
                    
                    -- Optional: Notifikasi debug (bisa dihapus)
                    -- print("Dungeon Ready Fired with value:", readyValue)
                else
                    -- Jika object tidak ditemukan (mungkin belum load atau bukan di dungeon)
                    -- warn("PressedReady1 not found on LocalPlayer")
                end
            end)
        end
    end
end)

-- =======================================================
-- ===== AUTO LAMANCHALAND LOGIC & HOOKING ===============
-- =======================================================

-- 1. Hooking untuk mendeteksi Remote DungeonCutsceneDone
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    -- Dengarkan jika game menembakkan DungeonCutsceneDone
    if not checkcaller() and method == "FireServer" and tostring(self) == "DungeonCutsceneDone" then
        if AutoLaMancha then
            CutsceneCount = CutsceneCount + 1
            
            if CutsceneCount == 1 then
                -- Cutscene 1 muncul: Hentikan combat normal, mulai spam Clash
                ClashActive = true
                IsSummoningAction = true 
                Rayfield:Notify({Title = "LaManchaland", Content = "Gallop On", Duration = 3})
                
            elseif CutsceneCount >= 6 then
                -- Cutscene 6 muncul: Hentikan Clash, kembali ke combat mode
                ClashActive = false
                IsSummoningAction = false
                Rayfield:Notify({Title = "LaManchaland", Content = "its done i guess?", Duration = 3})
                
                -- [TAMBAHAN] Refresh character setelah 60 detik
                task.wait(60)
                ForceKillByVoidForLamanchaland()
            end
        end -- [KOREKSI 1]: Ini untuk menutup 'if AutoLaMancha then'
    end -- [KOREKSI 2]: Ini untuk menutup 'if not checkcaller() ... then'
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- 2. Loop Deteksi Portal & Teleport
task.spawn(function()
    while task.wait(1) do
        if not AutoLaMancha then continue end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- Cek apakah portal ada di Workspace
        local portal = Workspace:FindFirstChild("LaManchaPortal")
        
        if portal then
            -- Portal Ditemukan: Matikan combat sementara untuk masuk
            IsSummoningAction = true
            
            local prompt = portal:FindFirstChildWhichIsA("ProximityPrompt", true)
            local targetPart = portal:FindFirstChild("PortalPart") or portal:FindFirstChildWhichIsA("BasePart") or portal
            
            if prompt and targetPart then
                -- Teleport ke portal
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                hrp.Velocity = Vector3.zero
                
                task.wait(0.5)
                
                -- Tembak prompt (Bypass hold duration & distance)
                prompt.HoldDuration = 0
                prompt.MaxActivationDistance = 50
                fireproximityprompt(prompt)
                
                Rayfield:Notify({Title = "LaManchaland", Content = "Entering Portal...", Duration = 5})
                
                -- Tunggu 20 detik sesuai permintaan
                task.wait(20)
                
                -- Lepas kunci combat agar combat mode berjalan di dalam dungeon
                IsSummoningAction = false
            end
        else
            -- Jika portal tidak ada (atau kita sudah di dalam dungeon), pastikan combat jalan
            -- Cek agar tidak bertabrakan dengan logic boss lain
            if not AutoKingMon and not AutoBBQ3 and not AutoDeku and not ClashActive then
                IsSummoningAction = false
            end
        end
    end
end)

-- 3. Loop Spam SendClash
task.spawn(function()
    while task.wait() do -- Loop sangat cepat (tanpa delay angka) untuk memastikan menang clash
        if AutoLaMancha and ClashActive then
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("ABC - First Priority"):WaitForChild("Remotes"):WaitForChild("SendClash"):FireServer()
            end)
        end
    end
end)

Rayfield:LoadConfiguration()
-- [[ START: INSTANT SPAWN TELEPORT ]] --
task.spawn(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local TargetPosition = Vector3.new(-9985, 827, 9083)

    -- Fungsi untuk memaksa teleport
    local function ForceTeleport(char)
        -- Tunggu HumanoidRootPart muncul (biasanya sepersekian detik)
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if hrp then
            -- KITA PAKSA POSISI SELAMA 15 FRAME PERTAMA
            -- Ini menjamin "Tanpa Delay" dan anti-rollback dari server
            local connection
            local frameCount = 0
            
            connection = RunService.Heartbeat:Connect(function()
                if not char or not char.Parent then 
                    connection:Disconnect() 
                    return 
                end
                
                hrp.CFrame = CFrame.new(TargetPosition) -- Set Posisi
                hrp.AssemblyLinearVelocity = Vector3.zero -- Reset Momentum (biar gak mental)
                
                frameCount = frameCount + 1
                if frameCount >= 15 then -- Stop maksa setelah 15 frame (sekitar 0.2 detik)
                    connection:Disconnect()
                end
            end)
        end
    end

    -- 1. Jalankan untuk karakter yang sedang dipakai sekarang
    if LocalPlayer.Character then
        ForceTeleport(LocalPlayer.Character)
    end

    -- 2. Jalankan otomatis setiap kali respawn
    LocalPlayer.CharacterAdded:Connect(ForceTeleport)
end)
-- [[ END: INSTANT SPAWN TELEPORT ]] --

-- [[ START: AUTO DELICIOUS MEAT ON SPAWN ]] --
task.spawn(function()
    local function ClaimDeliciousMeat()
        pcall(function()
        task.wait(2.2)
            -- Menambahkan waktu tunggu maksimal (10 detik) agar tidak infinite yield
            local abcRemotes = game:GetService("ReplicatedStorage"):WaitForChild("ABCRemotes", 10)
            if abcRemotes then
                local meatRemote = abcRemotes:WaitForChild("DeliciousMeat", 10)
                if meatRemote then
                    meatRemote:FireServer()
                end
            end
        end)
    end

    -- 1. Jalankan untuk karakter yang sedang hidup saat script dieksekusi pertama kali
    if LocalPlayer.Character then
        ClaimDeliciousMeat()
    end

    -- 2. Jalankan otomatis setiap kali karakter respawn/spawn baru
    LocalPlayer.CharacterAdded:Connect(function(char)
        ClaimDeliciousMeat()
    end)
end)
-- [[ END: AUTO DELICIOUS MEAT ON SPAWN ]] --

-- [[ START: ANTI AFK / IDLE ]] --
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    -- Ketika game mendeteksi kamu AFK (sekitar 20 menit), ini akan menyimulasikan klik kanan otomatis
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
-- [[ END: ANTI AFK / IDLE ]] --

-- [[ START: REMOVE FOG (ALWAYS ON) ]] --
local _Lighting = game:GetService("Lighting")
-- Set langsung saat script load
pcall(function()
    _Lighting.FogEnd   = 100000
    _Lighting.FogStart = 0
end)
-- Listener: reset fog kalau game mengubahnya kembali (misalnya saat map load/change)
_Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
    if _Lighting.FogEnd < 100000 then
        _Lighting.FogEnd = 100000
    end
end)
_Lighting:GetPropertyChangedSignal("FogStart"):Connect(function()
    if _Lighting.FogStart > 0 then
        _Lighting.FogStart = 0
    end
end)
-- [[ END: REMOVE FOG (ALWAYS ON) ]] --

local stoploop = false
while true do            
    game:GetService("ReplicatedStorage"):WaitForChild("GlobalUsedRemotes"):WaitForChild("Play"):FireServer()
    
    if stoploop == true then
        break
    end
    task.wait(1)
end
