---
sidebar_position: 8
---

# Middleware

Knit's networking layer uses the [Comm](https://sleitnick.github.io/RbxUtil/api/Comm/) module internally, which supports middleware at both the inbound and outbound level.

When a client calls a service method (e.g., `GetMoney`), server-side inbound middleware runs before the method executes, and outbound middleware runs after it returns. This allows you to transform arguments, validate requests, or short-circuit responses.

Middleware applies to both functions and signals. It can be configured at the global level (affecting all services) or per service.

## Function Signatures

Each middleware function receives the arguments and must return a boolean indicating whether to continue processing:

- **Client:** `(args: {any}) -> (boolean, ...any)`
- **Server:** `(player: Player, args: {any}) -> (boolean, ...any)`

Returning `false` blocks the request. An optional variadic list after `false` is returned to the caller as a short-circuit response.

## Usage

Middleware is provided when starting Knit:

```lua
Knit.Start({
    Middleware = {
        Inbound = { ... },
        Outbound = { ... },
    },
})
```

## Examples

### Logger

Client-side logger that prints all inbound data from the server:

```lua
local function Logger(args: { any })
    print(args)
    return true
end

Knit.Start({
    Middleware = { Inbound = { Logger } },
})
```

Server-side equivalent (includes the `player` parameter):

```lua
local function Logger(player: Player, args: { any })
    print(player, args)
    return true
end

Knit.Start({
    Middleware = { Inbound = { Logger } },
})
```

### Argument Transformation

Multiply all inbound numbers by 2 on the client:

```lua
local function DoubleNumbers(args)
    for i, v in args do
        if type(v) == "number" then
            args[i] *= 2
        end
    end
    return true
end

Knit.Start({ Middleware = { Inbound = { DoubleNumbers } } })
```

### Per-Service Middleware

Middleware can be scoped to a specific service, overriding the global middleware for that service.

On the server, define middleware directly on the service:

```lua
local MyService = {
    Name = "MyService",
    Client = {},
    Middleware = {
        Inbound = { Logger },
        Outbound = {},
    },
}
```

On the client, per-service middleware is specified within `Knit.Start()`:

```lua
Knit.Start({
    PerServiceMiddleware = {
        MyService = {
            Inbound = { Logger },
            Outbound = {},
        },
    },
})
```

### Serialization

The following example serializes and deserializes a custom class on the client. A corresponding setup on the server would complete the round trip.

```lua
-- Define a simple class with serialization support
local MyClass = {}
MyClass.__index = MyClass
MyClass.ClassName = "MyClass"

function MyClass.new()
    return setmetatable({
        SomeData = "",
    }, MyClass)
end

function MyClass:Serialize()
    return { _CN = self.ClassName, D = self.SomeData }
end

function MyClass.deserialize(data)
    local myClass = MyClass.new()
    myClass.SomeData = data
    return myClass
end

-- Middleware functions
local function InboundClass(args)
    for i, v in args do
        if type(v) == "table" and v._CN == "MyClass" then
            args[i] = MyClass.deserialize(v)
        end
    end
    return true
end

local function OutboundClass(args)
    for i, v in args do
        if type(v) == "table" and v.ClassName == "MyClass" then
            args[i] = v:Serialize()
        end
    end
    return true
end

Knit.Start({
    Middleware = {
        Inbound = { InboundClass },
        Outbound = { OutboundClass },
    },
})
```
