---
sidebar_position: 2
---

# Getting Started

## Tutorial Videos

Knit supports two workflows: Roblox Studio and external tooling with Rojo and Wally. The following tutorials cover each approach:

- [Knit Tutorial for Studio](https://youtu.be/0Ty2ojfdOnA)
- [Knit Tutorial for Rojo/Wally](https://youtu.be/tgndvNQ5agA)

## Installation

### Rojo/Wally Workflow

Add Knit to your `wally.toml` dependency list:

```toml
[dependencies]
Knit = "breezy1214/knit@^2"
```

Then require Knit like any other Wally-managed module.

> **Note:** Wally is a package manager for the Roblox ecosystem, similar to NPM. For setup instructions, see the [Wally repository](https://github.com/UpliftGames/wally).

### Studio Workflow

Place the Knit module directly into ReplicatedStorage.

## Basic Usage

The usage pattern is the same on both server and client: require Knit, register services or controllers, then call `Knit.Start()`.

The simplest possible setup:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.Start():catch(warn)
```

`Knit.Start()` returns a Promise. Use `:catch(warn)` to surface errors, or chain `:await()` to yield until startup completes.

### A Simple Service

A service is a singleton object that handles a specific domain of game logic. The following example defines a basic `MoneyService`:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local MoneyService = {
    Name = "MoneyService",
}

function MoneyService:GetMoney(player)
    local money = someDataStore:GetAsync("money")
    return money
end

function MoneyService:GiveMoney(player, amount)
    local money = self:GetMoney(player)
    money += amount
    someDataStore:SetAsync("money", money)
end

Knit.Start():catch(warn)
```

> **Note:** In practice, services and controllers should be placed in their own ModuleScripts and required from a single bootstrap script. The examples here are consolidated for clarity.

### Exposing Methods to Clients

To make a method callable from the client, define it on the service's `Client` table:

```lua
function MoneyService.Client:GetMoney(player)
    return self.Server:GetMoney(player)
end
```

Under the hood, Knit creates a RemoteFunction bound to this method.

On the client:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
Knit.Start():catch(warn):await()

local MoneyService = Knit.GetService("MoneyService")

MoneyService:GetMoney():andThen(function(money)
    print(money)
end)
```

> **Disabling Promises:** By default, client calls to service methods return Promises. To use synchronous (yielding) calls instead, set `ServicePromises` to `false`:
> ```lua
> Knit.Start({ServicePromises = false}):catch(warn):await()
>
> local MoneyService = Knit.GetService("MoneyService")
> local money = MoneyService:GetMoney()
> ```

## Deep Auto-Loading

When using `Knit.AddServicesDeep` or `Knit.AddControllersDeep`, a predicate function receives extended context and optional scan controls can be provided:

```lua
Knit.AddServicesDeep(game.ServerScriptService.Services, function(moduleScript, parent, depth, path)
    return moduleScript.Name:match("Service$")
        and depth <= 3
        and not path:match("/Tests/")
end, {
    MaxDepth = 4,
    IgnoreFolderPatterns = {"^Tests$", "^Dev$"},
})
```

- `depth` starts at `1` for direct children of the root instance.
- `path` is the module path relative to the root, separated by `/`.
- The predicate can be omitted to pass only options: `Knit.AddServicesDeep(root, { MaxDepth = 2 })`.

See the [Services](services.md) documentation for the full API.
