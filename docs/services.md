---
sidebar_position: 3
---

# Services

## Overview

Services are singleton objects that run on the server and handle specific domains of game logic. For example, a game might have a `PointsService` that manages player scores, a `DataService` for persistence, and an `InventoryService` for item management.

This guide builds a `PointsService` step by step to demonstrate each feature.

## Creating a Service

At minimum, a service requires a `Name` field and should be returned from a ModuleScript:

```lua
local PointsService = { Name = "PointsService", Client = {} }

return PointsService
```

The `Name` must be unique across all services. On the server, other services should access it via `require()` to preserve type safety and IntelliSense. Clients access services via `Knit.GetService()`.

> **Note:** The `Client` table is optional in the definition. If omitted, Knit will add one internally. However, omitting it means the service will operate in server-only mode -- clients cannot access it via `Knit.GetService`.

## Adding Methods

Services are plain tables, so adding methods uses standard Lua syntax:

```lua
function PointsService:AddPoints(player, amount)
    -- Implementation
end

function PointsService:GetPoints(player)
    return 0
end
```

## Adding Properties

Add properties directly to the table:

```lua
PointsService.PointsPerPlayer = {}
```

## Using Methods and Properties Together

```lua
PointsService.PointsPerPlayer = {}

function PointsService:AddPoints(player, amount)
    local points = self:GetPoints(player)
    points += amount
    self.PointsPerPlayer[player] = points
end

function PointsService:GetPoints(player)
    local points = self.PointsPerPlayer[player]
    return if points ~= nil then points else 0
end
```

## Using Events

Internal events (server-side only) can be created with the Signal utility:

```lua
local Signal = require(Knit.Util.Signal)
PointsService.PointsChanged = Signal.new()

function PointsService:AddPoints(player, amount)
    local points = self:GetPoints(player)
    points += amount
    self.PointsPerPlayer[player] = points
    if amount ~= 0 then
        self.PointsChanged:Fire(player, points)
    end
end
```

Other services can listen for this event:

```lua
function SomeOtherService:KnitStart()
    local PointsService = require("PointsService")
    PointsService.PointsChanged:Connect(function(player, points)
        print("Points changed for " .. player.Name .. ":", points)
    end)
end
```

## KnitInit and KnitStart

These are optional lifecycle methods invoked during `Knit.Start()`. See the [Execution Model](executionmodel.md) for the full lifecycle.

- **KnitInit** -- Called after all services are created. All services can be referenced, but should not be used (their `KnitInit` may not have run yet).
- **KnitStart** -- Called after every `KnitInit` has completed. All services are fully initialized and safe to use.

On the server, always use `require()` to reference other services. This preserves full type safety and IntelliSense. If you find yourself needing circular requires between services, that is a sign of an architectural issue -- consider splitting shared logic into a separate module.

Set up your service's internal state in `KnitInit` or in the module scope. By the time `KnitStart` fires, your service should be ready for other services to interact with.

## Memory Management

Any per-player state must be cleaned up when the player leaves to avoid memory leaks:

```lua
function PointsService:KnitInit()
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        self.PointsPerPlayer[player] = nil
    end)
end
```

## Client Communication

This is where the `Client` table becomes essential. Methods, signals, and properties defined on `Client` are exposed to clients over the network.

### Methods

```lua
function PointsService.Client:GetPoints(player)
    return self.Server:GetPoints(player)
end
```

Knit creates a RemoteFunction for this method. On the client:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PointsService = Knit.GetService("PointsService")
PointsService:GetPoints():andThen(function(points)
    print("Points for myself:", points)
end)
```

### Events (Server-to-Client)

Use `Knit.CreateSignal()` in the `Client` table to create a remote signal:

```lua
local PointsService = {
    Name = "PointsService",
    Client = {
        PointsChanged = Knit.CreateSignal(),
    },
}
```

Fire it from the server:

```lua
function PointsService:AddPoints(player, amount)
    local points = self:GetPoints(player)
    points += amount
    self.PointsPerPlayer[player] = points
    if amount ~= 0 then
        self.PointsChanged:Fire(player, points)
        self.Client.PointsChanged:Fire(player, points)
    end
end
```

Listen on the client:

```lua
local PointsService = Knit.GetService("PointsService")
PointsService.PointsChanged:Connect(function(points)
    print("Points for myself now:", points)
end)
```

> See the [RemoteSignal](https://sleitnick.github.io/RbxUtil/api/RemoteSignal) documentation for the full API.

### Events (Client-to-Server)

Signals can also be fired from the client. Define the signal in `Client` and connect a handler in `KnitInit`:

```lua
local PointsService = {
    Name = "PointsService",
    Client = {
        PointsChanged = Knit.CreateSignal(),
        GiveMePoints = Knit.CreateSignal(),
    },
}

function PointsService:KnitInit()
    local rng = Random.new()
    self.Client.GiveMePoints:Connect(function(player)
        local points = rng:NextInteger(0, 10)
        self:AddPoints(player, points)
    end)
end
```

From the client:

```lua
local PointsService = Knit.GetService("PointsService")
PointsService.GiveMePoints:Fire()
```

> See the [ClientRemoteSignal](https://sleitnick.github.io/RbxUtil/api/ClientRemoteSignal) documentation for the full API.

### Unreliable Events

For non-critical data where packet loss or out-of-order delivery is acceptable, use `Knit.CreateUnreliableSignal()`. These use [UnreliableRemoteEvents](https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent) internally, which consume less network bandwidth.

```lua
local MyService = {
    Name = "MyService",
    Client = {
        PlayEffect = Knit.CreateUnreliableSignal(),
    },
}
```

Usage is identical to standard signals.

### Properties

RemoteProperties replicate state from the server to clients. Use `Knit.CreateProperty()` with an initial value:

```lua
PointsService.Client.Points = Knit.CreateProperty(0)

function PointsService:AddPoints(player, amount)
    local points = self:GetPoints(player)
    points += amount
    self.PointsPerPlayer[player] = points
    self.Client.Points:SetFor(player, points)
end
```

On the client, use `Observe` to track the current value and all subsequent changes:

```lua
local PointsService = Knit.GetService("PointsService")
PointsService.Points:Observe(function(points)
    print("Current number of points:", points)
end)
```

> See the [RemoteProperty](https://sleitnick.github.io/RbxUtil/api/RemoteProperty) and [ClientRemoteProperty](https://sleitnick.github.io/RbxUtil/api/ClientRemoteProperty) documentation for the full API.

---

## Full Example

### PointsService

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(Knit.Util.Signal)

local PointsService = {
    Name = "PointsService",
    PointsPerPlayer = {},
    PointsChanged = Signal.new(),
    Client = {
        PointsChanged = Knit.CreateSignal(),
        GiveMePoints = Knit.CreateSignal(),
        Points = Knit.CreateProperty(0),
    },
}

function PointsService.Client:GetPoints(player)
    return self.Server:GetPoints(player)
end

function PointsService:AddPoints(player, amount)
    local points = self:GetPoints(player)
    points += amount
    self.PointsPerPlayer[player] = points
    if amount ~= 0 then
        self.PointsChanged:Fire(player, points)
        self.Client.PointsChanged:Fire(player, points)
    end
    self.Client.Points:SetFor(player, points)
end

function PointsService:GetPoints(player)
    local points = self.PointsPerPlayer[player]
    return points or 0
end

function PointsService:KnitInit()
    local rng = Random.new()

    self.Client.GiveMePoints:Connect(function(player)
        local points = rng:NextInteger(0, 10)
        self:AddPoints(player, points)
        print("Gave " .. player.Name .. " " .. points .. " points")
    end)

    game:GetService("Players").PlayerRemoving:Connect(function(player)
        self.PointsPerPlayer[player] = nil
    end)
end

return PointsService
```

### Client Consumer

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
Knit.Start():catch(warn):await()

local PointsService = Knit.GetService("PointsService")

local function PointsChanged(points)
    print("My points:", points)
end

PointsService:GetPoints():andThen(PointsChanged)
PointsService.PointsChanged:Connect(PointsChanged)

PointsService.GiveMePoints:Fire()
```
