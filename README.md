# Knit

A lightweight framework for Roblox that simplifies communication between core parts of your game and bridges the gap between server and client with full type safety and IntelliSense support.

## Features

- **Fully Typed** -- Complete type safety for Luau with exported types
- **IntelliSense Ready** -- Rich autocomplete in VS Code and Studio
- **Zero Boilerplate** -- Services and controllers are plain tables; no `CreateService()` or `CreateController()` calls required
- **Automatic Networking** -- RemoteFunction and RemoteEvent instances are generated from declarative definitions
- **Promise-Based** -- Built-in Promise support for asynchronous operations
- **Middleware** -- Extensible inbound/outbound request pipeline at global and per-service levels
- **Dependency Ordering** -- Optional `DependsOn` field for explicit startup sequencing
- **Deterministic Start** -- Optional mode that awaits all `KnitStart` handlers and surfaces errors

## Installation

### Wally (Recommended)

Add Knit to your `wally.toml`:

```toml
[dependencies]
Knit = "breezy1214/knit@^2"
```

Then install dependencies:

```bash
wally install
```

### Manual

Download the latest release and place the module in `ReplicatedStorage`.

## Documentation

Full documentation is available in the [docs](docs/) directory and at the [documentation site](https://breezy1214.github.io/Knit/).

## Quick Start

The core pattern: create services on the server, controllers on the client, then start Knit.

### Minimal Setup

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.Start():catch(warn)
```

This code works on both server and client. `Knit.Start()` returns a Promise.

## Core Concepts

### Services (Server-Side)

Services are singleton objects that handle server-side game logic. Define a service as a table with a `Name` field:

```lua
-- MoneyService.luau (Server)
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local MoneyService = {
    Name = "MoneyService",
}

-- Server-only methods (not accessible from clients)
function MoneyService:GetMoney(player: Player): number
    return someDataStore:GetAsync(tostring(player.UserId)) or 0
end

function MoneyService:GiveMoney(player: Player, amount: number): ()
    local currentMoney = self:GetMoney(player)
    someDataStore:SetAsync(tostring(player.UserId), currentMoney + amount)
end

-- Methods on the Client table are exposed as RemoteFunctions
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

Controllers manage client-side logic and UI. Like services, they are plain tables:

```lua
-- MoneyController.luau (Client)
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local MoneyController = {
    Name = "MoneyController",
}

function MoneyController:KnitStart()
    -- Knit.GetService is the standard way to access server services from the client.
    -- Note: this returns a network proxy, so you will not get type information or
    -- IntelliSense for the service's methods.
    local MoneyService = Knit.GetService("MoneyService")

    MoneyService:GetMoney():andThen(function(money: number)
        print("Player has", money, "coins")
    end):catch(warn)
end

return MoneyController
```

### Auto-Loading

Instead of requiring each module individually, use auto-discovery to load services or controllers from a folder:

```lua
-- Server script
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Load all ModuleScripts that are direct children of the folder
Knit.AddServices(game.ServerScriptService.Services)

-- Filter with a predicate function
Knit.AddServices(game.ServerScriptService.Services, function(moduleScript)
    return moduleScript.Name:match("Service$")
end)

-- Recursively load from nested folders
Knit.AddServicesDeep(game.ServerScriptService, function(moduleScript, parent, depth, path)
    return moduleScript.Name:match("Service$")
        and not moduleScript.Name:match("Test")
        and depth <= 3
        and not path:match("/Legacy/")
end)

-- Pass only scan options (no predicate)
Knit.AddServicesDeep(game.ServerScriptService, {
    MaxDepth = 4,
    IgnoreFolderPatterns = {"^Tests$", "^Dev$"},
})

Knit.Start():catch(warn)
```

```lua
-- Client script
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddControllers(game.StarterPlayer.StarterPlayerScripts.Controllers)

Knit.Start():catch(warn)
```

## Advanced Features

### Signals

Create server-to-client and client-to-server events:

```lua
local ChatService = {
    Name = "ChatService",
    Client = {
        MessageReceived = Knit.CreateSignal(),
    },
}

function ChatService:KnitStart()
    self.Client.MessageReceived:FireAll("Welcome to the game!")
    self.Client.MessageReceived:Fire(somePlayer, "Hello " .. somePlayer.Name)
end
```

```lua
-- Client
local ChatService = Knit.GetService("ChatService")
ChatService.MessageReceived:Connect(function(message: string)
    print("Received:", message)
end)
```

### Properties (State Sync)

Synchronize state between server and clients:

```lua
local GameStateService = {
    Name = "GameStateService",
    Client = {
        RoundTime = Knit.CreateProperty(0),
        GameMode = Knit.CreateProperty("Lobby"),
    },
}

function GameStateService:UpdateRoundTime(newTime: number)
    self.Client.RoundTime:Set(newTime)
end
```

```lua
-- Client
local GameStateService = Knit.GetService("GameStateService")
GameStateService.RoundTime:Observe(function(time: number)
    print("Round time:", time)
end)
```

### Unreliable Signals

For non-critical data where dropped or out-of-order packets are acceptable (e.g., cosmetic effects), use unreliable signals to reduce bandwidth:

```lua
Client = {
    PlayEffect = Knit.CreateUnreliableSignal(),
}
```

### Lifecycle Methods

Services and controllers support two lifecycle hooks:

| Method | When It Runs | Safe To Do |
|---|---|---|
| `KnitInit` | After all services/controllers are created, before any `KnitStart` | Set up internal state; reference (but do not call) other services |
| `KnitStart` | After all `KnitInit` methods complete | Freely use other services and controllers |

```lua
local MyService = {
    Name = "MyService",
    DependsOn = {"OtherService"}, -- Optional: explicit init ordering
}

function MyService:KnitInit()
    -- Set up internal state
end

function MyService:KnitStart()
    local OtherService = require(path.to.OtherService)
end
```

### Deterministic Start

By default, `Knit.Start()` resolves as soon as all `KnitStart` methods are dispatched (fire-and-forget). Enable deterministic mode to wait for all handlers to complete and surface errors:

```lua
Knit.Start({
    DeterministicStart = true,
}):catch(function(err)
    -- err.Message = "KnitStart failed for N service(s)"
    -- err.Errors = { { Name = "ServiceName", Error = <traceback> }, ... }
    warn(err.Message)
end)
```

### Middleware

Intercept and transform inbound/outbound network traffic:

```lua
local function authMiddleware(player: Player, args: {any}): (boolean, ...any)
    if not player:GetAttribute("IsAuthenticated") then
        return false -- Block the request
    end
    return true, unpack(args)
end

Knit.Start({
    Middleware = {
        Inbound = { authMiddleware },
        Outbound = {},
    },
}):catch(warn)
```

See the [Middleware](docs/middleware.md) documentation for per-service middleware and client-side examples.

## Migration from Legacy Knit

### Service/Controller Creation

```lua
-- Legacy (still supported)
local MoneyService = Knit.CreateService({
    Name = "MoneyService",
})

-- Current (recommended)
local MoneyService = {
    Name = "MoneyService",
}
return MoneyService
```

### Auto-Loading

The `AddServices`, `AddServicesDeep`, `AddControllers`, and `AddControllersDeep` functions replace manual `require` loops and support predicate-based filtering and scan options.

## Contributing

Contributions are welcome. Submit pull requests to the repository.

## License

This project is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.
