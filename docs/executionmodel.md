---
sidebar_position: 6
---

# Execution Model

## Lifecycle

The execution model defines the initialization sequence and lifecycle of Knit:

1. Require the Knit module.
2. Create services (server) or controllers (client).
3. Call `Knit.Start()`, which returns a Promise.
   1. All `KnitInit` methods are called sequentially (in dependency order) and awaited.
   2. All `KnitStart` methods are called concurrently.
4. The Promise returned by `Knit.Start()` resolves after all `KnitStart` methods are dispatched (or completed, if `DeterministicStart` is enabled).

![Lifecycle](/lifecycle.svg)

### Recommended Script Layout

On the server, use a single Script in ServerScriptService. On the client, use a single LocalScript in PlayerStarterScripts. Both follow this pattern:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Load services or controllers here

Knit.Start():catch(warn)
```

Once created, services and controllers persist for the lifetime of the session (until the server shuts down or the player leaves).

> **Important:** Services and controllers cannot be created after `Knit.Start()` has been called.

## Error Handling

Errors that occur within `KnitInit` methods are captured as rejected promises. Handle them via `await()` or `catch()`:

```lua
local success, err = Knit.Start():await()
if not success then
    error(tostring(err))
end
```

```lua
Knit.Start():catch(function(err)
    warn(tostring(err))
end)
```

## Best Practices

- Use a single Script on the server and a single LocalScript on the client to manage startup.
- Place each service and controller in its own ModuleScript.
- Keep services in ServerStorage or ServerScriptService to prevent client access to source code.
- Code within `KnitInit` and the root scope of ModuleScripts should complete quickly and avoid yielding where possible.
- Do not add methods or events to a service's `Client` table after `Knit.Start()` has been called.
- Always handle the failure case of `Knit.Start()` to catch initialization errors.
