local Settings = ...

if type(Settings) ~= "table" then
  return nil
end

local _ENV = (getgenv or getrenv or getfenv)()

local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Validator2 = Remotes:WaitForChild("Validator2")
local Validator = Remotes:WaitForChild("Validator")
local CommF = Remotes:WaitForChild("CommF_")
local CommE = Remotes:WaitForChild("CommE")

local ChestModels = workspace:WaitForChild("ChestModels")
local WorldOrigin = workspace:WaitForChild("_WorldOrigin")
local Characters = workspace:WaitForChild("Characters")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Enemies = workspace:WaitForChild("Enemies")
local Map = workspace:WaitForChild("Map")

local EnemySpawns = WorldOrigin:WaitForChild("EnemySpawns")
local Locations = WorldOrigin:WaitForChild("Locations")

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped
local Player = Players.LocalPlayer

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")

local executor = if identifyexecutor then identifyexecutor() else "Null"
local is_blacklisted_executor = table.find({ "Null", "Xeno" }, executor)

local hookmetamethod = (not is_blacklisted_executor and hookmetamethod) or (function(...) return ... end)
local sethiddenproperty = sethiddenproperty or (function(...) return ... end)
local setupvalue = setupvalue or (debug and debug.setupvalue)
local getupvalue = getupvalue or (debug and debug.getupvalue)

local BRING_TAG = _ENV._Bring_Tag or `{math.random(80, 140)}_Bring`
local KILLAURA_TAG = _ENV._KillAura_Tag or `{math.random(120, 200)}_Kill`

_ENV._Bring_Tag = BRING_TAG
_ENV._KillAura_Tag = KILLAURA_TAG

local function GetEnemyName(string)
  return (string:find("Lv. ") and string:gsub(" %pLv. %d+%p", "") or string):gsub(" %pBoss%p", "")
end

local function GetCharacterHumanoid(Character)
  if Character:GetAttribute("IsBoat") or Character.Parent == SeaBeasts then
    local HealthValue = Character:FindFirstChild("Health")
    
    if HealthValue then
      return HealthValue
    else
      return Character:FindFirstChild("Humanoid"), true
    end
  else
    return Character:FindFirstChildOfClass("Humanoid")
  end
end

local function WaitChilds(Instance, ...)
  for _, ChildName in ipairs({...}) do
    Instance = Instance:WaitForChild(ChildName)
  end
  return Instance
end

local Module = {} do
  local CachedBaseParts = {}
  local CachedEnemies = {}
  local CachedBring = {}
  local CachedChars = {}
  local CachedTools = {}
  local Items = {}
  
  local placeId = game.PlaceId
  local HitBoxSize = Vector3.new(50, 50, 50)
  local SeaList = {"TravelMain", "TravelDressrosa", "TravelZou"}
  
  Module.Sea = (placeId == 2753915549 and 1) or (placeId == 4442272183 and 2) or (placeId == 7449423635 and 3) or 0
  
  Module.AttackCooldown = 0
  Module.MaxLevel = 2600
  Module.Webhooks = true
  
  Module.allMobs = { __RaidBoss = {}, __Bones = {}, __Elite = {}, __CakePrince = {} }
  Module.Progress = {}
  Module.SpawnedFruits = {}
  Module.BossesName = {}
  Module.EnemyLocations = {}
  Module.SpawnLocations = {}
  
  Module.FruitsId = {
    ["rbxassetid://15060012861"] = "Rocket-Rocket",
    ["rbxassetid://15057683975"] = "Spin-Spin",
    ["rbxassetid://15104782377"] = "Chop-Chop",
    ["rbxassetid://15105281957"] = "Spring-Spring",
    ["rbxassetid://15116740364"] = "Bomb-Bomb",
    ["rbxassetid://15116696973"] = "Smoke-Smoke",
    ["rbxassetid://15107005807"] = "Spike-Spike",
    ["rbxassetid://15111584216"] = "Flame-Flame",
    ["rbxassetid://15112469964"] = "Falcon-Falcon",
    ["rbxassetid://15100433167"] = "Ice-Ice",
    ["rbxassetid://15111517529"] = "Sand-Sand",
    ["rbxassetid://15111553409"] = "Dark-Dark",
    ["rbxassetid://15112600534"] = "Diamond-Diamond",
    ["rbxassetid://15100283484"] = "Light-Light",
    ["rbxassetid://15104817760"] = "Rubber-Rubber",
    ["rbxassetid://15100485671"] = "Barrier-Barrier",
    ["rbxassetid://15112333093"] = "Ghost-Ghost",
    ["rbxassetid://15105350415"] = "Magma-Magma",
    ["rbxassetid://15057718441"] = "Quake-Quake",
    ["rbxassetid://15100313696"] = "Buddha-Buddha",
    ["rbxassetid://15116730102"] = "Love-Love",
    ["rbxassetid://15116967784"] = "Spider-Spider",
    ["rbxassetid://14661873358"] = "Sound-Sound",
    ["rbxassetid://15100246632"] = "Phoenix-Phoenix",
    ["rbxassetid://15112215862"] = "Portal-Portal",
    ["rbxassetid://15116747420"] = "Rumble-Rumble",
    ["rbxassetid://15116721173"] = "Pain-Pain",
    ["rbxassetid://15100384816"] = "Blizzard-Blizzard",
    ["rbxassetid://15100299740"] = "Gravity-Gravity",
    ["rbxassetid://14661837634"] = "Mammoth-Mammoth",
    ["rbxassetid://15708895165"] = "T-Rex-T-Rex",
    ["rbxassetid://15100273645"] = "Dough-Dough",
    ["rbxassetid://15112263502"] = "Shadow-Shadow",
    ["rbxassetid://15100184583"] = "Control-Control",
    ["rbxassetid://15106768588"] = "Leopard-Leopard",
    ["rbxassetid://15482881956"] = "Kitsune-Kitsune",
    ["https://assetdelivery.roblox.com/v1/asset/?id=10395893751"] = "Venom-Venom",
    ["https://assetdelivery.roblox.com/v1/asset/?id=10537896371"] = "Dragon-Dragon"
  }
  Module.Bosses = {
    -- Bosses Sea 1
    ["Saber Expert"] = {
      NoQuest = true,
      Position = CFrame.new(-1461, 30, -51)
    },
    ["The Saw"] = {
      RaidBoss = true,
      Position = CFrame.new(-690, 15, 1583)
    },
    ["Greybeard"] = {
      RaidBoss = true,
      Position = CFrame.new(-4807, 21, 4360)
    },
    ["The Gorilla King"] = {
      IsBoss = true,
      Level = 20,
      Position = CFrame.new(-1128, 6, -451),
      Quest = {"JungleQuest", CFrame.new(-1598, 37, 153)}
    },
    ["Bobby"] = {
      IsBoss = true,
      Level = 55,
      Position = CFrame.new(-1131, 14, 4080),
      Quest = {"BuggyQuest1", CFrame.new(-1140, 4, 3829)}
    },
    ["Yeti"] = {
      IsBoss = true,
      Level = 105,
      Position = CFrame.new(1185, 106, -1518),
      Quest = {"SnowQuest", CFrame.new(1385, 87, -1298)}
    },
    ["Vice Admiral"] = {
      IsBoss = true,
      Level = 130,
      Position = CFrame.new(-4807, 21, 4360),
      Quest = {"MarineQuest2", CFrame.new(-5035, 29, 4326), 2}
    },
    ["Swan"] = {
      IsBoss = true,
      Level = 240,
      Position = CFrame.new(5230, 4, 749),
      Quest = {"ImpelQuest", CFrame.new(5191, 4, 692)}
    },
    ["Chief Warden"] = {
      IsBoss = true,
      Level = 230,
      Position = CFrame.new(5230, 4, 749),
      Quest = {"ImpelQuest", CFrame.new(5191, 4, 692), 2}
    },
    ["Warden"] = {
      IsBoss = true,
      Level = 220,
      Position = CFrame.new(5230, 4, 749),
      Quest = {"ImpelQuest", CFrame.new(5191, 4, 692), 1}
    },
    ["Magma Admiral"] = {
      IsBoss = true,
      Level = 350,
      Position = CFrame.new(-5694, 18, 8735),
      Quest = {"MagmaQuest", CFrame.new(-5319, 12, 8515)}
    },
    ["Fishman Lord"] = {
      IsBoss = true,
      Level = 425,
      Position = CFrame.new(61350, 31, 1095),
      Quest = {"FishmanQuest", CFrame.new(61122, 18, 1567)}
    },
    ["Wysper"] = {
      IsBoss = true,
      Level = 500,
      Position = CFrame.new(-7927, 5551, -637),
      Quest = {"SkyExp1Quest", CFrame.new(-7861, 5545, -381)}
    },
    ["Thunder God"] = {
      IsBoss = true,
      Level = 575,
      Position = CFrame.new(-7751, 5607, -2315),
      Quest = {"SkyExp2Quest", CFrame.new(-7903, 5636, -1412)}
    },
    ["Cyborg"] = {
      IsBoss = true,
      Level = 675,
      Position = CFrame.new(6138, 10, 3939),
      Quest = {"FountainQuest", CFrame.new(5258, 39, 4052)}
    },
    
    -- Bosses Sea 2
    ["Don Swan"] = {
      RaidBoss = true,
      Position = CFrame.new(2289, 15, 808)
    },
    ["Cursed Captain"] = {
      RaidBoss = true,
      Position = CFrame.new(912, 186, 33591)
    },
    ["Darkbeard"] = {
      RaidBoss = true,
      Position = CFrame.new(3695, 13, -3599)
    },
    ["Diamond"] = {
      IsBoss = true,
      Level = 750,
      Position = CFrame.new(-1569, 199, -31),
      Quest = {"Area1Quest", CFrame.new(-427, 73, 1835)}
    },
    ["Jeremy"] = {
      IsBoss = true,
      Level = 850,
      Position = CFrame.new(2316, 449, 787),
      Quest = {"Area2Quest", CFrame.new(635, 73, 919)}
    },
    ["Fajita"] = {
      IsBoss = true,
      Level = 925,
      Position = CFrame.new(-2086, 73, -4208),
      Quest = {"MarineQuest3", CFrame.new(-2441, 73, -3219)}
    },
    ["Smoke Admiral"] = {
      IsBoss = true,
      Level = 1150,
      Position = CFrame.new(-5078, 24, -5352),
      Quest = {"IceSideQuest", CFrame.new(-6061, 16, -4904)}
    },
    ["Awakened Ice Admiral"] = {
      IsBoss = true,
      Level = 1400,
      Position = CFrame.new(6473, 297, -6944),
      Quest = {"FrostQuest", CFrame.new(5668, 28, -6484)}
    },
    ["Tide Keeper"] = {
      IsBoss = true,
      Level = 1475,
      Position = CFrame.new(-3711, 77, -11469),
      Quest = {"ForgottenQuest", CFrame.new(-3056, 240, -10145)}
    },
    
    -- Bosses Sea 3
    ["Cake Prince"] = {
      RaidBoss = true,
      Position = CFrame.new(-2103, 70, -12165)
    },
    ["Dough King"] = {
      RaidBoss = true,
      Position = CFrame.new(-2103, 70, -12165)
    },
    ["rip_indra True Form"] = {
      RaidBoss = true,
      Position = CFrame.new(-5333, 424, -2673)
    },
    ["Stone"] = {
      IsBoss = true,
      Level = 1550,
      Position = CFrame.new(-1049, 40, 6791),
      Quest = {"PiratePortQuest", CFrame.new(-449, 109, 5950)}
    },
    ["Hydra Leader"] = {
      IsBoss = true,
      Level = 1675,
      Position = CFrame.new(5730, 602, 199),
      Quest = {"VenomCrewQuest", CFrame.new(5448, 602, 748)}
    },
    ["Kilo Admiral"] = {
      IsBoss = true,
      Level = 1750,
      Position = CFrame.new(2904, 509, -7349),
      Quest = {"MarineTreeIsland", CFrame.new(2485, 74, -6788)}
    },
    ["Captain Elephant"] = {
      IsBoss = true,
      Level = 1875,
      Position = CFrame.new(-13393, 319, -8423),
      Quest = {"DeepForestIsland", CFrame.new(-13233, 332, -7626)}
    },
    ["Beautiful Pirate"] = {
      IsBoss = true,
      Level = 1950,
      Position = CFrame.new(5370, 22, -89),
      Quest = {"DeepForestIsland2", CFrame.new(-12682, 391, -9901)}
    },
    ["Cake Queen"] = {
      IsBoss = true,
      Level = 2175,
      Position = CFrame.new(-710, 382, -11150),
      Quest = {"IceCreamIslandQuest", CFrame.new(-818, 66, -10964)}
    },
    ["Longma"] = {
      NoQuest = true,
      Position = CFrame.new(-10218, 333, -9444)
    }
  }
  Module.Shop = {
    {"Frags", {{"Race Reroll", {"BlackbeardReward", "Reroll", "2"}}, {"Reset Stats", {"BlackbeardReward", "Refund", "2"}}}},
    {"Fighting Style", {
      {"Buy Black Leg", {"BuyBlackLeg"}},
      {"Buy Electro", {"BuyElectro"}},
      {"Buy Fishman Karate", {"BuyFishmanKarate"}},
      {"Buy Dragon Claw", {"BlackbeardReward", "DragonClaw", "2"}},
      {"Buy Superhuman", {"BuySuperhuman"}},
      {"Buy Death Step", {"BuyDeathStep"}},
      {"Buy Sharkman Karate", {"BuySharkmanKarate"}},
      {"Buy Electric Claw", {"BuyElectricClaw"}},
      {"Buy Dragon Talon", {"BuyDragonTalon"}},
      {"Buy GodHuman", {"BuyGodhuman"}},
      {"Buy Sanguine Art", {"BuySanguineArt"}}
      -- {"Buy Divine Art", {"BuyDivineArt"}}
    }},
    {"Ability Teacher", {
      {"Buy Geppo", {"BuyHaki", "Geppo"}},
      {"Buy Buso", {"BuyHaki", "Buso"}},
      {"Buy Soru", {"BuyHaki", "Soru"}},
      {"Buy Ken", {"KenTalk", "Buy"}}
    }},
    {"Sword", {
      {"Buy Katana", {"BuyItem", "Katana"}},
      {"Buy Cutlass", {"BuyItem", "Cutlass"}},
      {"Buy Dual Katana", {"BuyItem", "Dual Katana"}},
      {"Buy Iron Mace", {"BuyItem", "Iron Mace"}},
      {"Buy Triple Katana", {"BuyItem", "Triple Katana"}},
      {"Buy Pipe", {"BuyItem", "Pipe"}},
      {"Buy Dual-Headed Blade", {"BuyItem", "Dual-Headed Blade"}},
      {"Buy Soul Cane", {"BuyItem", "Soul Cane"}},
      {"Buy Bisento", {"BuyItem", "Bisento"}}
    }},
    {"Gun", {
      {"Buy Musket", {"BuyItem", "Musket"}},
      {"Buy Slingshot", {"BuyItem", "Slingshot"}},
      {"Buy Flintlock", {"BuyItem", "Flintlock"}},
      {"Buy Refined Slingshot", {"BuyItem", "Refined Slingshot"}},
      {"Buy Dual Flintlock", {"BuyItem", "Dual Flintlock"}},
      {"Buy Cannon", {"BuyItem", "Cannon"}},
      {"Buy Kabucha", {"BlackbeardReward", "Slingshot", "2"}}
    }},
    {"Accessories", {
      {"Buy Black Cape", {"BuyItem", "Black Cape"}},
      {"Buy Swordsman Hat", {"BuyItem", "Swordsman Hat"}},
      {"Buy Tomoe Ring", {"BuyItem", "Tomoe Ring"}}
    }},
    {"Race", {{"Ghoul Race", {"Ectoplasm", "Change", 4}}, {"Cyborg Race", {"CyborgTrainer", "Buy"}}}}
  }
  
  function EnableBuso()
    local Char = Player.Character
    if Settings.AutoBuso and Module.IsAlive(Char) and not Char:FindFirstChild("HasBuso") then
      Module.FireRemote("Buso")
    end
  end
  
  function GetToolByName(Name: string): Tool?
    local Cached = CachedTools[Name]
    
    if Cached and Cached.Parent then
      return Cached
    end
    
    local Character = Player.Character
    local Backpack = Player.Backpack
    
    if Character then
      local Tool = Character:FindFirstChild(Name) or Backpack:FindFirstChild(Name)
      if Tool then
        CachedTools[Name] = Tool
        return Tool
      end
    end
  end
  
  function GetToolMastery(Name: string): number?
    local Cached = CachedTools[Name]
    
    if Cached and Cached.Parent then
      return Cached:GetAttribute("Level")
    end
    
    local Tool = GetToolByName(Name)
    return Tool and Tool:GetAttribute("Level")
  end
  
  function VerifyTool(Name: string): boolean
    local Cached = CachedTools[Name]
    
    if Cached and Cached.Parent then
      return true
    end
    
    return GetToolByName(Name)
  end
  
  function VerifyToolTip(Type: string): Instance?
    local Cached = CachedTools[`Tip_{Type}`]
    
    if Cached and Cached.Parent then
      return Cached
    end
    
    for _, Tool in Player.Backpack:GetChildren() do
      if Tool:IsA("Tool") and Tool.ToolTip == Type then
        CachedTools[`Tip_{Type}`] = Tool
        return Tool
      end
    end
    
    if not Module.IsAlive(Player.Character) then
      return nil
    end
    
    for _, Tool in Player.Character:GetChildren() do
      if Tool:IsA("Tool") and Tool.ToolTip == Type then
        CachedTools[`Tip_{Type}`] = Tool
        return Tool
      end
    end
    
    return nil
  end
  
  function ToDictionary(Array: table): table
    local Dictionary = {}
    for _, String in ipairs(Array) do
      Dictionary[String] = true
    end
    table.clear(Array)
    return Dictionary
  end
  
  function noSit(): (nil)
    local Char = Player.Character
    if Module.IsAlive(Char) and Char.Humanoid.Sit then
      Char.Humanoid.Sit = false
    end
  end
  
  function Module.TravelTo(Sea: number?): (nil)
    if SeaList[Sea] then
      Module.FireRemote(SeaList[Sea])
    end
  end
  
  function Module.newCachedEnemy(Name, Enemy)
    CachedEnemies[Name] = Enemy
  end
  
  function Module.Rejoin(): (nil)
    task.spawn(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, Player)
  end
  
  function Module.IsAlive(Character: Model?): boolean
    if Character then
      local Humanoid, NoCache = CachedChars[Character] or GetCharacterHumanoid(Character)
      
      if Humanoid then
        if NoCache ~= true and not CachedChars[Character] then
          CachedChars[Character] = Humanoid
        end
        
        return Humanoid[if Humanoid.ClassName == "Humanoid" then "Health" else "Value"] > 0
      end
    end
  end
  
  function Module.FireRemote(...): any
    return CommF:InvokeServer(...)
  end
  
  function Module.IsFruit(Part: BasePart): Instance?
    return (Part.Name == "Fruit " or Part:GetAttribute("OriginalName")) and Part:FindFirstChild("Handle")
  end
  
  function Module.IsBoss(Name: string): boolean
    return Module.Bosses[Name] and true
  end
  
  function Module.UseSkills(Target: BasePart, Skills: table?): (nil)
    if Player:DistanceFromCharacter(Target.Position) >= 120 then
      return nil
    end
    
    Module.Hooking:SetTarget(Target)
    
    for Skill, Enabled in Skills do
      if Enabled then
        VirtualInputManager:SendKeyEvent(true, Skill, false, game)
        VirtualInputManager:SendKeyEvent(false, Skill, false, game)
      end
    end
  end
  
  function Module.KillAura(Distance: number?, Name: string?): (nil)
    Distance = Distance or 500
    
    for _, Enemy in ipairs(Enemies:GetChildren()) do
      local PrimaryPart = Enemy.PrimaryPart
      
      if (not Name or Enemy.Name == Name) and PrimaryPart and not Enemy:HasTag(KILLAURA_TAG) then
        if Module.IsAlive(Enemy) and Player:DistanceFromCharacter(PrimaryPart.Position) < Distance then
          Enemy:AddTag(KILLAURA_TAG)
        end
      end
    end
  end
  
  function Module.IsSpawned(Enemy)
    local Cached = Module.SpawnLocations[Enemy]
    
    if Cached and Cached.Parent then
      return Cached:GetAttribute("Active") or Module:GetEnemyByTag(Enemy)
    end
    
    return Module:GetEnemyByTag(Enemy)
  end
  
  function Module:ServerHop(MaxPlayers: number?, Region: string?): (nil)
    MaxPlayers = MaxPlayers or self.SH_MaxPlrs or 8
    -- Region = Region or self.SH_Region or "Singapore"
    
    local ServerBrowser = ReplicatedStorage.__ServerBrowser
    
    for i = 1, 100 do
      local Servers = ServerBrowser:InvokeServer(i)
      for id,info in pairs(Servers) do
        if id ~= game.JobId and info["Count"] <= MaxPlayers then
          task.spawn(ServerBrowser.InvokeServer, ServerBrowser, "teleport", id)
        end
      end
    end
  end
  
  function Module:GetEnemy(Name: string): Instance?
    return self.EnemySpawned[Name]
  end
  
  function Module:GetClosestEnemy(Name: string): Instance?
    local Cached = CachedEnemies[Name]
    local Mobs = self.allMobs[Name]
    
    if self.IsAlive(Cached) or (not Mobs) then
      return Cached
    end
    
    local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
    local Distance, Nearest = math.huge
    
    for _, Enemy in Mobs do
      if self.IsAlive(Enemy) and Enemy.PrimaryPart then
        local Magnitude = (Enemy.PrimaryPart.Position - Position).Magnitude
        if Magnitude < Distance then
          Distance, Nearest = Magnitude, Enemy
        end
      end
    end
    
    if Nearest then
      self.newCachedEnemy(Name, Nearest)
      return Nearest
    end
  end
  
  function Module:GetEnemyByList(List: table): Instance?
    for _, Name in List do
      local Cached = CachedEnemies[Name]
      
      if self.IsAlive(Cached) then
        return Cached
      end
      
      local Mobs = self.allMobs[Name]
      
      if Mobs then
        for _, Enemy in Mobs do
          if self.IsAlive(Enemy) then
            self.newCachedEnemy(Name, Enemy)
            return Enemy
          end
        end
      end
    end
  end
  
  function Module:BringEnemies(ToEnemy: Instance, SuperBring: boolean?): (nil)
    if not self.IsAlive(ToEnemy) or not ToEnemy.PrimaryPart then
      return nil
    end
    
    pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)
    
    if Settings.BringMobs then
      local Name = ToEnemy.Name
      local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
      local Target = ToEnemy.PrimaryPart.CFrame
      
      if not CachedBring[Name] or (Target.Position - CachedBring[Name].Position).Magnitude > 5 then
        CachedBring[Name] = Target
      end
      
      for _, Enemy in ipairs(SuperBring and Enemies:GetChildren() or self.allMobs[Name]) do
        if Enemy.Parent ~= Enemies or Enemy:HasTag(BRING_TAG) then continue end
        
        local PrimaryPart = Enemy.PrimaryPart
        if self.IsAlive(Enemy) and PrimaryPart then
          if (Position - PrimaryPart.Position).Magnitude < Settings.BringDistance then
            PrimaryPart.Size = HitBoxSize
            PrimaryPart.CanCollide = false
            Enemy.Humanoid.WalkSpeed = 0
            Enemy.Humanoid.JumpPower = 0
            Enemy:AddTag(BRING_TAG)
          end
        end
      end
    else
      if not CachedBring[ToEnemy] then
        CachedBring[ToEnemy] = ToEnemy.PrimaryPart.CFrame
      end
      
      ToEnemy.PrimaryPart.CFrame = CachedBring[ToEnemy]
    end
  end
  
  function Module:GetRaidIsland(): Instance?
    if self.RaidIsland then
      return self.RaidIsland
    end
    
    for i = 5, 1, -1 do
      local Name = "Island " .. i
      for _, Island in ipairs(Locations:GetChildren()) do
        if Island.Name == Name and Player:DistanceFromCharacter(Island.Position) < 3500 then
          self.RaidIsland = Island
          return Island
        end
      end
    end
  end
  
  function Module:GetProgress(Tag, ...)
    local Progress = self.Progress
    local entry = Progress[Tag]
    
    if entry and (tick() - entry.debounce) < 1.6 then
      return entry.result
    end
    
    local result = self.FireRemote(...)
    
    if entry then
      entry.result = result
      entry.debounce = tick()
    else
      Progress[Tag] = {
        debounce = tick(),
        result = result
      }
    end
    
    return result
  end
  
  Module.EnemySpawned = setmetatable({}, {
    __index = function(self, index)
      return Module:GetClosestEnemy(index)
    end,
    __call = function(self, index)
      if type(index) == "table" then
        return Module:GetEnemyByList(index)
      end
      
      local Cached = CachedEnemies[index]
      
      if Module.IsAlive(Cached) then
        return Cached
      end
      
      return self[index]
    end
  })
  
  Module.FruitsName = setmetatable({}, {
    __index = function(self, Fruit)
      local Ids = Module.FruitsId
      local Name = Fruit.Name
      
      if Name ~= "Fruit " then
        rawset(self, Fruit, Name)
        return Name
      end
      
      local FruitHandle = WaitChilds(Fruit, "Fruit", "Fruit")
      
      if FruitHandle and FruitHandle:IsA("MeshPart") then
        local RealName = Ids[FruitHandle.MeshId]
        
        if RealName and type(RealName) == "string" then
          rawset(self, Fruit, `Fruit [ {RealName} ]`)
          return rawget(self, Fruit)
        end
      end
      
      rawset(self, Fruit, "Fruit [ ??? ]")
      return "Fruit [ ??? ]"
    end
  })
  
  Module.MoonId = setmetatable({}, {
    __index = function(self, index)
      return Lighting.Sky.MoonTextureId == ("http://www.roblox.com/asset/?id=" .. index)
    end
  })
  
  Module.EquipTool = setmetatable({}, {
    __call = function(self, Name, byTip)
      local Char = Player.Character
      if Module.IsAlive(Char) then
        local Equipped = self.Equipped
        
        if Equipped and Equipped.Parent and Equipped[byTip and "ToolTip" or "Name"] == Name then
          if Equipped.Parent ~= Char then
            Char:WaitForChild("Humanoid"):EquipTool(Equipped)
          end
          return nil
        end
        
        if Name and not byTip then
          local Tool = Player.Backpack:FindFirstChild(Name)
          if Tool then
            self.Equipped = Tool
            Char:WaitForChild("Humanoid"):EquipTool(Tool)
          end
          return nil
        end
        
        local ToolTip = (byTip and Name) or Settings.FarmTool
        for _, Tool in Player.Backpack:GetChildren() do
          if Tool:IsA("Tool") and Tool.ToolTip == ToolTip then
            self.Equipped = Tool
            Char:WaitForChild("Humanoid"):EquipTool(Tool)
            break
          end
        end
      end
    end
  })
  
  Module.Chests = setmetatable({}, {
    __call = function(self, ...)
      if self.Cached and not self.Cached:GetAttribute("IsDisabled")  then
        return self.Cached
      end
      
      if self.Debounce and (tick() - self.Debounce) < 0.5 then
        return nil
      end
      
      local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
      local Chests = CollectionService:GetTagged("_ChestTagged")
      
      if #Chests == 0 then
        return nil
      end
      
      local Distance, Nearest = math.huge
      
      for _, Chest in ipairs(Chests) do
        local Magnitude = (Chest:GetPivot().Position - Position).Magnitude
        if not Chest:GetAttribute("IsDisabled") and Magnitude < Distance then
          Distance, Nearest = Magnitude, Chest
        end
      end
      
      self.Debounce = tick()
      self.Cached = Nearest
      return Nearest
    end
  })
  
  Module.Berry = setmetatable({}, {
    __call = function(self, BerryArray)
      local CachedBush = self.Cached
      
      if CachedBush then
        for Tag, CFrame in pairs(CachedBush:GetAttributes()) do
          return CachedBush
        end
      end
      
      if self.Debounce and (tick() - self.Debounce) < 0.5 then
        return nil
      end
      
      local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
      local BerryBush = CollectionService:GetTagged("BerryBush")
      
      local Distance, Nearest = math.huge
      
      for _, Bush in ipairs(BerryBush) do
        for AttributeName, BerryName in pairs(Bush:GetAttributes()) do
          if not BerryArray or table.find(BerryArray, BerryName) then
            local Magnitude = (Bush.Parent:GetPivot().Position - Position).Magnitude
            
            if Magnitude < Distance then
              Nearest, Distance = Bush, Magnitude
            end
          end
        end
      end
      
      self.Debounce = tick()
      self.Cached = Nearest
      return Nearest
    end
  })
  
  Module.PirateRaid = 0 do
    Module.PirateRaidEnemies = {}
    
    local Spawn = Vector3.new(-5556, 314, -2988)
    local BlackList = ToDictionary({ "rip_indra True Form", "Blank Buddy" })
    
    local IsPirateRaidEnemy = function(Enemy)
      local PrimaryPart = Enemy.PrimaryPart
      
      if Module.IsAlive(Enemy) and not BlackList[Enemy.Name] then
        if PrimaryPart and (PrimaryPart.Position - Spawn).Magnitude < 700 then
          table.insert(Module.PirateRaidEnemies, Enemy)
          Module.PirateRaid = tick()
        end
      end
    end
    
    CollectionService:GetInstanceAddedSignal("BasicMob"):Connect(IsPirateRaidEnemy)
    for _, Mob in CollectionService:GetTagged("BasicMob") do IsPirateRaidEnemy(Mob) end
  end
  
  task.spawn(function()
    local allMobs = Module.allMobs
    
    local Elites = ToDictionary({ "Deandre", "Diablo", "Urban" })
    local Bones = ToDictionary({ "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy" })
    local CakePrince = ToDictionary({ "Head Baker", "Baking Staff", "Cake Guard", "Cookie Crafter" })
    
    function Module:GetClosestByTag(Tag)
      local Cached = CachedEnemies[Tag]
      local Mobs = allMobs[Tag]
      
      if Cached and Cached.Parent and self.IsAlive(Cached) then
        return Cached
      elseif not Mobs or #Mobs == 0 then
        return nil
      end
      
      local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
      local Distance, Nearest = math.huge
      
      for _, Enemy in Mobs do
        local PrimaryPart = Enemy.PrimaryPart
        
        if PrimaryPart and self.IsAlive(Enemy) then
          local Magnitude = (Position - PrimaryPart.Position).Magnitude
          
          if Magnitude < 20 then
            CachedEnemies[Tag] = Enemy
            return Enemy
          elseif Magnitude < Distance then
            Distance, Nearest = Magnitude, Enemy
          end
        end
      end
      
      if Nearest then
        CachedEnemies[Tag] = Nearest
        return Nearest
      end
    end
    
    function Module:GetEnemyByTag(Tag)
      local Mobs = allMobs[Tag]
      if not Mobs then return end
      
      for _, Enemy in ipairs(Mobs) do
        if self.IsAlive(Enemy) then
          return Enemy
        end
      end
    end
    
    local function MobAdded(Enemy)
      local EnemyName = Enemy.Name
      local RaidBoss = Enemy:GetAttribute("RaidBoss")
      
      if RaidBoss then
        table.insert(allMobs.__RaidBoss, Enemy)
      elseif Elites[EnemyName] then
        table.insert(allMobs.__Elite, Enemy)
      elseif Bones[EnemyName] then
        table.insert(allMobs.__Bones, Enemy)
      elseif CakePrince[EnemyName] then
        table.insert(allMobs.__CakePrince, Enemy)
      end
      
      allMobs[EnemyName] = allMobs[EnemyName] or {}
      table.insert(allMobs[EnemyName], Enemy)
    end
    
    local function Bring(Enemy)
      local Humanoid = Enemy:WaitForChild("Humanoid")
      local RootPart = Enemy:WaitForChild("HumanoidRootPart")
      
      while Enemy and Enemy:HasTag(BRING_TAG) and RootPart and Humanoid and Humanoid.Health > 0 do
        if Player:DistanceFromCharacter(RootPart.Position) < Settings.BringDistance then
          RootPart.CFrame = CachedBring[Enemy.Name]
        else
          Enemy:RemoveTag(BRING_TAG)
        end
        task.wait()
      end
    end
    
    local function KillAura(Enemy)
      local Humanoid = Enemy:FindFirstChild("Humanoid")
      local RootPart = Enemy:FindFirstChild("HumanoidRootPart")
      
      pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)
      
      if Humanoid and RootPart then
        RootPart.CanCollide = false
        RootPart.Size = Vector3.new(60, 60, 60)
        Humanoid:ChangeState(15)
        Humanoid.Health = 0
        task.wait()
        Enemy:RemoveTag(KILLAURA_TAG)
      end
    end
    
    for _, Enemy in CollectionService:GetTagged("BasicMob") do MobAdded(Enemy) end
    CollectionService:GetInstanceAddedSignal("BasicMob"):Connect(MobAdded)
    
    CollectionService:GetInstanceAddedSignal(KILLAURA_TAG):Connect(KillAura)
    CollectionService:GetInstanceAddedSignal(BRING_TAG):Connect(Bring)
  end)
  
  task.spawn(function()
    local BossesName = Module.BossesName
    local Fruits = Module.SpawnedFruits
    
    workspace.ChildAdded:Connect(function(Part)
      if Module.IsFruit(Part) then
        table.insert(Fruits, Part)
        Part:GetPropertyChangedSignal("Parent"):Once(function()
          table.remove(Fruits, table.find(Fruits, Part))
        end)
      end
    end)
    
    for Name, _ in Module.Bosses do
      table.insert(BossesName, Name)
    end
    
    for _, Part in workspace:GetChildren() do
      if Module.IsFruit(Part) then
        table.insert(Fruits, Part)
        Part:GetPropertyChangedSignal("Parent"):Once(function()
          table.remove(Fruits, table.find(Fruits, Part))
        end)
      end
    end
  end)
  
  task.spawn(function()
    local SpawnLocations = Module.SpawnLocations
    local EnemyLocations = Module.EnemyLocations
    
    local function NewIslandAdded(Island)
      if Island.Name:find("Island") then
        Module.RaidIsland = nil
      end
    end
    
    local function NewSpawn(Part)
      local EnemyName = GetEnemyName(Part.Name)
      
      if not EnemyLocations[EnemyName] then
        EnemyLocations[EnemyName] = {}
      end
      
      table.insert(EnemyLocations[EnemyName], Part.CFrame + Vector3.new(0, 25, 0))
      SpawnLocations[EnemyName] = Part
    end
    
    for _, Spawn in EnemySpawns:GetChildren() do NewSpawn(Spawn) end
    EnemySpawns.ChildAdded:Connect(NewSpawn)
    Locations.ChildAdded:Connect(NewIslandAdded)
  end)
  
  task.spawn(function()
    function Module:GetItemCount(index: string?): number
      return self.ItemsCount[index] or 0
    end
    
    function Module:GetItemMastery(index: string?): number
      return self.ItemsMastery[index] or 0
    end
    
    function Module:UpdateItem(item: table): (nil)
      if type(item) == "table" then
        local Name = item.Name
        
        self.Inventory[Name] = item
        
        if not self.Unlocked[Name] then
          self.Unlocked[Name] = true
        end
        
        if item.Count then
          self.ItemsCount[Name] = item.Count
        end
        
        if item.Mastery then
          self.ItemsMastery[Name] = item.Mastery
        end
      end
    end
    
    function Module:RemoveItem(itemName: string): (nil)
      if type(itemName) == "string" then
        self.Unlocked[itemName] = nil
        self.Inventory[itemName] = nil
        self.ItemsCount[itemName] = nil
        self.ItemsMastery[itemName] = nil
      end
    end
    
    local function OnClientEvent(Method, ...)
      if Method == "ItemChanged" then
        Module:UpdateItem(...)
      elseif Method == "ItemRemoved" then
        Module:RemoveItem(...)
      end
    end
    
    Module.ItemsMastery = {}
    Module.ItemsCount = {}
    Module.Inventory = {}
    Module.Unlocked = {}
    
    for _, Tool in ipairs(Module.FireRemote("getInventory")) do Module:UpdateItem(Tool) end
    CommE.OnClientEvent:Connect(OnClientEvent)
  end)
  
  task.spawn(function()
    local DeathM = require(WaitChilds(ReplicatedStorage, "Effect", "Container", "Death"))
    local CameraShaker = require(WaitChilds(ReplicatedStorage, "Util", "CameraShaker"))
    
    CameraShaker:Stop()
    if hookfunction then
      hookfunction(DeathM, function(...) return ... end)
    end
  end)
  
  task.spawn(function()
    local OwnersId = { 3095250 }
    local OwnersFriends = {}
    
    local function OnPlayerAdded(__Player)
      if table.find(OwnersId, __Player.UserId) or OwnersFriends[__Player.UserId] then
        if _ENV.OnFarm then
          game:shitdown()
        else
          _ENV.rz_Settings = nil
          _ENV.rz_Functions = nil
          _ENV.rz_FarmFunctions = nil
          _ENV.rz_EnabledOptions = nil
        end
      end
    end
    
    Players.PlayerAdded:Connect(OnPlayerAdded)
    
    for i = 1, #OwnersId do
      local Friends = Players:GetFriendsAsync(OwnersId[i])
      
      while not Friends.IsFinished do
        for _, Friend in ipairs(Friends:GetCurrentPage()) do
          local __Player = Players:GetPlayerByUserId(Friend.Id)
          
          if __Player then
            OnPlayerAdded(__Player)
          else
            table.insert(OwnersFriends, Friend.Id)
          end
        end
        
        Friends:AdvanceToNextPageAsync()
      end
    end
  end)
  
  Module.Hooking = (function()
    if _ENV.rz_AimBot then
      return _ENV.rz_AimBot
    end
    
    local module = {}
    _ENV.rz_AimBot = module
    
    local Enabled = _ENV.rz_EnabledOptions;
    local IsAlive = Module.IsAlive;
    
    local NextEnemy = nil;
    local NextTarget = nil;
    local UpdateDebounce = 0;
    local TargetDebounce = 0;
    
    local GetPlayers = Players.GetPlayers
    local GetChildren = Enemies.GetChildren
    local Skills = ToDictionary({"Z", "X", "C", "V", "F"})
    
    local function CanAttack(player)
      return player.Team and (player.Team.Name == "Pirates" or player.Team ~= Player.Team)
    end
    
    local function GetNextTarget(Mode)
      if (tick() - TargetDebounce) < 2.5 then
        return NextEnemy
      end
      
      if (Mode and _ENV[Mode]) then
        return NextTarget
      end
    end
    
    local function UpdateTarget()
      if (tick() - UpdateDebounce) < 0.5 then
        return nil
      end
      
      local PrimaryPart = Player.Character and Player.Character.PrimaryPart
      
      if not PrimaryPart then
        return nil
      end
      
      local Position = PrimaryPart.Position
      local Players = Players:GetPlayers()
      local Enemies = Enemies:GetChildren()
      
      local Distance, Nearest = 750
      
      if #Players > 1 then
        for _, player in ipairs(Players) do
          if player ~= Player and CanAttack(player) and IsAlive(player.Character) then
            local UpperTorso = player.Character:FindFirstChild("UpperTorso")
            local Magnitude = UpperTorso and (UpperTorso.Position - Position).Magnitude
            
            if UpperTorso and Magnitude < Distance then
              Distance, Nearest = Magnitude, UpperTorso
            end
          end
        end
      end
      if #Enemies > 0 and not Settings.NoAimMobs then
        for _, Enemy in ipairs(Enemies) do
          local UpperTorso = Enemy:FindFirstChild("UpperTorso")
          if UpperTorso and IsAlive(Enemy) then
            local Magnitude = (UpperTorso.Position - Position).Magnitude
            if Magnitude < Distance then
              Distance, Nearest = Magnitude, UpperTorso
            end
          end
        end
      end
      
      NextTarget, UpdateDebounce = Nearest, tick()
    end
    
    function module:SpeedBypass()
      if _ENV._Enabled_Speed_Bypass then
        return nil
      end
      
      _ENV._Enabled_Speed_Bypass = true
      
      local oldHook;
      oldHook = hookmetamethod(Player, "__newindex", function(self, index, value)
        if self.Name == "Humanoid" and index == "WalkSpeed" then
          return oldHook(self, index, _ENV.WalkSpeedBypass or value)
        end
        return oldHook(self, index, value)
      end)
    end
    
    function module:SetTarget(Part)
      TargetDebounce, NextEnemy = tick(), Part.Parent:FindFirstChild("UpperTorso") or Part
    end
    
    Stepped:Connect(UpdateTarget)
    
    local old_namecall; old_namecall = _ENV.original_namecall or hookmetamethod(game, "__namecall", function(self, ...)
      local Method = string.lower(getnamecallmethod())
      
      if Method ~= "fireserver" then
        return old_namecall(self, ...)
      end
      
      local Name = self.Name
      
      if Name == "RE/ShootGunEvent" then
        local Position, Enemies = ...
        
        if typeof(Position) == "Vector3" and type(Enemies) == "table" then
          local Target = GetNextTarget("AimBot_Gun")
          
          if Target then
            if Target.Name == "UpperTorso" then
              table.insert(Enemies, Target)
            end
            
            Position = Target.Position
          end
          
          return old_namecall(self, Position, Enemies)
        end
      elseif Name == "RemoteEvent" and self.Parent.ClassName == "Tool" then
        local v1, v2 = ...
        
        if typeof(v1) == "Vector3" and not v2 then
          local Target = GetNextTarget("AimBot_Skills")
          
          if Target then
            return old_namecall(self, Target.Position)
          end
        elseif v1 == "TAP" and typeof(v2) == "Vector3" then
          local Target = GetNextTarget("AimBot_Tap")
          
          if Target then
            return old_namecall(self, "TAP", Target.Position)
          end
        end
      end
      
      return old_namecall(self, ...)
    end)
    
    _ENV.original_namecall = old_namecall
    return module
  end)()
  
  Module.FastAttack = (function()
    if _ENV.rz_FastAttack then
      return _ENV.rz_FastAttack
    end
    
    local FastAttack = {
      Distance = 70,
      attackMobs = true,
      attackPlayers = true,
      Equipped = nil
    }
    _ENV.rz_FastAttack = FastAttack
    
    local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
    local RegisterHit = Net:WaitForChild("RE/RegisterHit")
    
    local EquipTool = Module.EquipTool
    local IsAlive = Module.IsAlive
    
    local GunClickDebounce = 0
    
    local function ProcessEnemies(OthersEnemies, Folder)
      local BasePart = nil;
      
      local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
      
      for _, Enemy in Folder:GetChildren() do
        if not Enemy:GetAttribute("IsBoat") and IsAlive(Enemy) then
          local Head = Enemy:FindFirstChild("Head")
          
          if Head and (Position - Head.Position).Magnitude < FastAttack.Distance then
            if Enemy ~= Player.Character then
              table.insert(OthersEnemies, { Enemy, Head })
              BasePart = Head
            end
          end
        end
      end
      
      return BasePart
    end
    
    function Module.GunClick()
      if (tick() - GunClickDebounce) <= 0.1 then
        return nil
      end
      
      GunClickDebounce = tick()
      VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1);task.wait(0.05)
      VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
    
    function FastAttack:AttackNearest(Equipped, ToolTip)
      local OthersEnemies = {}
      
      local Part1 = ProcessEnemies(OthersEnemies, Enemies)
      local Part2 = ProcessEnemies(OthersEnemies, Characters)
      
      if #OthersEnemies > 0 then
        RegisterAttack:FireServer(Settings.ClickDelay or 0.05)
        RegisterHit:FireServer(Part1 or Part2, OthersEnemies)
      else
        task.wait(0.5)
      end
    end
    
    function FastAttack:UseFruitM1()
      for _, Enemy in ipairs(Enemies:GetChildren()) do
        local PrimaryPart = Enemy.PrimaryPart
        
        if IsAlive(Enemy) and PrimaryPart and Player:DistanceFromCharacter(PrimaryPart.Position) <= 50 then
          
          return nil
        end
      end
      
      task.wait(0.25)
    end
    
    function FastAttack:BladeHits()
      local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
      
      if Equipped and Equipped.ToolTip ~= "Gun" then
        local ToolTip = Equipped.ToolTip
        
        if ToolTip == "Blox Fruit" and Equipped:FindFirstChild("") then
          if Settings.UseFruitM1 then
            return self:UseFruitM1(Equipped)
          end
        else
          return self:AttackNearest(Equipped, Equipped.ToolTip)
        end
      else
        task.wait(0.5)
      end
    end
    
    task.spawn(function()
      while task.wait(Settings.ClickDelay or 0.125) do
        if Settings.AutoClick and (tick() - Module.AttackCooldown) >= 1 then
          FastAttack:BladeHits()
        end
      end
    end)
    
    return FastAttack
  end)()
  
  Module.Tween = (function()
    if _ENV.TweenVelocity then
      return _ENV.TweenVelocity
    end
    
    local IsAlive = Module.IsAlive
    local Velocity = Instance.new("BodyVelocity", workspace)
    Velocity.Name = "hidden_user_folder_ :)"
    Velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Velocity.Velocity = Vector3.zero
    
    _ENV.TweenVelocity = Velocity
    
    Stepped:Connect(function()
      local Character = Player.Character
      
      if _ENV.OnFarm and Velocity.Parent ~= nil and Character then
        for _, Part in Character:GetDescendants() do
          if Part:IsA("BasePart") and Part.CanCollide then
            Part.CanCollide = false
          end
        end
      end
    end)
    
    Heartbeat:Connect(function()
      local Character = Player.Character
      local isAlive = IsAlive(Character)
      
      if isAlive and Velocity ~= Vector3.zero and (not Character.Humanoid.SeatPart or not _ENV.OnFarm) then
        Velocity.Velocity = Vector3.zero
      end
      
      if _ENV.OnFarm and isAlive then
        if Velocity.Parent == nil then
          Velocity.Parent = Character.PrimaryPart
        end
      elseif Velocity.Parent ~= nil then
        Velocity.Parent = nil
      end
    end)
    
    return Velocity
  end)()
  
  Module.RaidList = (function()
    local Raids = require(ReplicatedStorage:WaitForChild("Raids"))
    local list = {}
    
    for _,chip in ipairs(Raids.advancedRaids) do table.insert(list, chip) end
    for _,chip in ipairs(Raids.raids) do table.insert(list, chip) end
    
    return list
  end)()
end