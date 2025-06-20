# Knit

A modern, lightweight framework for Roblox that simplifies communication between core parts of your game and seamlessly bridges the gap between server and client with **full type safety** and **IntelliSense support**.

## ✨ Features

- 🔒 **Fully Typed** - Complete type safety for Luau
- 🧠 **IntelliSense Ready** - Rich autocomplete
- 🚀 **Zero Boilerplate** - No more `CreateService()` or `CreateController()` calls
- 🌉 **Seamless Networking** - Automatic RemoteFunction/RemoteEvent generation
- ⚡ **Promise-based** - Built-in Promise support for async operations
- 🛡️ **Middleware Support** - Extensible request/response pipeline

## 📦 Installation

### Wally (Recommended)

Add Knit to your `wally.toml`:

```toml
[dependencies]
Knit = "breezy1214/knit@^2"
```

Then sync with your package manager:

```bash
wally install
```

### Manual Installation

Download the latest release and place it in your project's dependencies folder.

## 📚 Documentation

Read the full [documentation](https://breezy1214.github.io/Knit/) for detailed guides and API reference.

## 🚀 Quick Start

The core pattern is simple: create services on the server, controllers on the client, then start Knit.

### Minimal Setup

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.Start():catch(warn)
-- Knit.Start() returns a Promise for error handling
-- You can also chain :await() to yield until completion
```

This code works on both server and client, but let's build something more interesting!

## 💡 Core Concepts

### Services (Server-Side)

Services handle your game's core logic and data management. With modern Knit, you simply create a table with a `Name` field - **no more `CreateService()` calls needed!**

```lua
-- MoneyService.luau (Server)
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- ✨ Just create a table - Knit handles the rest!
local MoneyService = {
    Name = "MoneyService",
}

-- Server-only methods (private)
function MoneyService:GetMoney(player: Player): number
    -- Your data logic here
    return someDataStore:GetAsync(tostring(player.UserId)) or 0
end

function MoneyService:GiveMoney(player: Player, amount: number): ()
    local currentMoney = self:GetMoney(player)
    someDataStore:SetAsync(tostring(player.UserId), currentMoney + amount)
end

-- 🌉 Expose methods to clients via the Client table
function MoneyService.Client:GetMoney(player: Player): number
    return self.Server:GetMoney(player)
end

function MoneyService.Client:SpendMoney(player: Player, amount: number): boolean
    local currentMoney = self.Server:GetMoney(player)
    if currentMoney >= amount then
        self.Server:GiveMoney(player, -amount)
        return true
    end
    return false
end

return MoneyService
```

### Controllers (Client-Side)

Controllers manage client-side logic and UI. Like services, they're just tables!

```lua
-- MoneyController.luau (Client)
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- ✨ No CreateController() needed!
local MoneyController = {
    Name = "MoneyController",
}

function MoneyController:KnitStart()
    local MoneyService = Knit.GetService("MoneyService")
    
    MoneyService:GetMoney():andThen(function(money: number)
        print("Player has", money, "coins")
    end):catch(warn)
end

return MoneyController
```

### Auto-Loading (Recommended)

Instead of requiring each service/controller individually, modern Knit can auto-discover them:

```lua
-- Server script
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- 🚀 Auto-load all services from a folder
Knit.AddServices(game.ServerScriptService.Services)

-- ✨ NEW: Use predicate functions to filter which services to load
Knit.AddServices(game.ServerScriptService.Services, function(moduleScript)
    return moduleScript.Name:match("Service$") -- Only load files ending with "Service"
end)

-- 🔍 Load from nested folders with AddServicesDeep
Knit.AddServicesDeep(game.ServerScriptService, function(moduleScript)
    return moduleScript.Name:match("Service$") and not moduleScript.Name:match("Test")
end)

Knit.Start():catch(warn)
```

```lua
-- Client script  
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- 🚀 Auto-load all controllers from a folder
Knit.AddControllers(game.StarterPlayer.StarterPlayerScripts.Controllers)

-- ✨ NEW: Filter controllers with predicate functions
Knit.AddControllers(game.StarterPlayer.StarterPlayerScripts.Controllers, function(moduleScript)
    -- Only load controllers for the current platform
    local isDesktop = game:GetService("UserInputService").KeyboardEnabled
    if moduleScript.Name == "MobileController" then
        return not isDesktop
    elseif moduleScript.Name == "DesktopController" then
        return isDesktop
    end
    return true -- Load all other controllers
end)

Knit.Start():catch(warn)
```

## 🔧 Advanced Features

### Signals (Events)

Create real-time communication between server and clients:

```lua
-- Service with signals
local ChatService = {
    Name = "ChatService",
    Client = {
        -- ✨ Create signals with type safety
        MessageReceived = Knit.CreateSignal(),
        PlayerJoined = Knit.CreateSignal(),
    }
}

function ChatService:KnitStart()
    -- Fire signals to all clients
    self.Client.MessageReceived:FireAll("Welcome to the game!")
    
    -- Fire to specific client
    self.Client.MessageReceived:Fire(somePlayer, "Hello " .. somePlayer.Name)
end

-- Client-side listening
local ChatService = Knit.GetService("ChatService")
ChatService.MessageReceived:Connect(function(message: string)
    print("Received:", message)
end)
```

### Properties (State Sync)

Synchronize state between server and clients automatically:

```lua
-- Service with properties
local GameStateService = {
    Name = "GameStateService", 
    Client = {
        -- ✨ Properties with initial values
        RoundTime = Knit.CreateProperty(0),
        GameMode = Knit.CreateProperty("Lobby"),
        PlayerCount = Knit.CreateProperty(0),
    }
}

function GameStateService:UpdateRoundTime(newTime: number)
    -- Automatically syncs to all clients
    self.Client.RoundTime:Set(newTime)
end

-- Client-side observing
local GameStateService = Knit.GetService("GameStateService")
GameStateService.RoundTime:Observe(function(time: number)
    print("Round time:", time)
end)
```

### Lifecycle Methods

Control when your services and controllers initialize and start:

```lua
local MyService = {
    Name = "MyService",
}

-- Called when Knit.Start() begins (before other services start)
function MyService:KnitInit()
    print("Service initializing...")
    -- Set up internal state, connect to datastores, etc.
end

-- Called after all services have initialized
function MyService:KnitStart() 
    print("Service started!")
    -- Safe to reference other services here
    local OtherService = Knit.GetService("OtherService")
end
```

### Middleware

Add custom logic to intercept and modify requests:

```lua
-- Server middleware example
local function authMiddleware(player: Player, args: {any}): (boolean, ...any)
    if not player:GetAttribute("IsAuthenticated") then
        return false -- Block the request
    end
    return true, unpack(args) -- Allow and pass through
end

Knit.Start({
    Middleware = {
        Inbound = { authMiddleware },
        Outbound = {},
    }
}):catch(warn)
```

## 📋 Best Practices

### Type Safety Tips

```lua
-- ✅ Use proper typing for better IntelliSense
export type PlayerData = {
    coins: number,
    level: number,
    inventory: {string}
}

local DataService = {
    Name = "DataService",
}

function DataService:GetPlayerData(player: Player): PlayerData
    -- Return properly typed data
end
```

### Error Handling

```lua
-- ✅ Always handle promise rejections
local MoneyService = Knit.GetService("MoneyService")

MoneyService:GetMoney()
    :andThen(function(money: number)
        print("Success:", money)
    end)
    :catch(function(err)
        warn("Failed to get money:", err)
    end)
```

## 🆚 Migration from Legacy Knit

If you're upgrading from an older version:

### Service/Controller Creation

```lua
-- ❌ Old way (still works but not recommended)
local MoneyService = Knit.CreateService({
    Name = "MoneyService",
})

-- ✅ New way (better IntelliSense + type safety)
local MoneyService = {
    Name = "MoneyService",
}

return MoneyService
```

### Auto-Loading Improvements

```lua
-- ✅ New way - smart auto-loading with predicates
Knit.AddServices(game.ServerScriptService.Services, function(moduleScript)
    -- Fine-grained control over which services to load
    return moduleScript.Name:match("Service$")
end)

-- 🔥 Even better - deep loading with filters
Knit.AddServicesDeep(game.ServerScriptService, function(moduleScript)
    -- Load services from any nested folder, but skip test files
    return moduleScript.Name:match("Service$") and 
           not moduleScript.Name:match("Test") and
           not moduleScript.Parent.Name:match("Tests")
end)
```

## 🤝 Contributing

Contributions are welcome! Submit pull requests to the repository.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.

---

### Happy coding with Knit! 🧶
