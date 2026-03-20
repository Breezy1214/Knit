---
sidebar_position: 4
---

# Controllers

## Overview

Controllers are singleton objects that run on the client and handle specific areas of client-side logic. For example, a game might have a `CameraController` for custom camera behavior or a `UIController` for managing interface elements.

A controller is the client-side equivalent of a service on the server.

This guide builds a `CameraController` step by step.

## Creating a Controller

At minimum, a controller requires a `Name` field:

```lua
local CameraController = { Name = "CameraController" }

return CameraController
```

The `Name` must be unique across all controllers. Other controllers should access it via `require()` to preserve type safety and IntelliSense. While `Knit.GetController()` works, it returns an untyped reference.

## Adding Methods

```lua
function CameraController:LockTo(part)
    -- Lock camera to a part
end

function CameraController:Unlock()
    -- Unlock camera
end
```

## Adding Properties

```lua
CameraController.Distance = 20
CameraController.Locked = false
```

## Adding Basic Behavior

```lua
function CameraController:LockTo(part)
    local cam = workspace.CurrentCamera
    self.Locked = true
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = part.CFrame * CFrame.new(0, 0, self.Distance)
end

function CameraController:Unlock()
    local cam = workspace.CurrentCamera
    self.Locked = false
    cam.CameraType = Enum.CameraType.Custom
end
```

## Continuous Updates with RenderStep

To track a moving part, bind to `RenderStep`:

```lua
local RunService = game:GetService("RunService")

CameraController.RenderName = "CustomCamRender"
CameraController.Priority = Enum.RenderPriority.Camera.Value

function CameraController:LockTo(part)
    if self.Locked then return end
    local cam = workspace.CurrentCamera
    self.Locked = true
    cam.CameraType = Enum.CameraType.Scriptable
    RunService:BindToRenderStep(self.RenderName, self.Priority, function()
        cam.CFrame = part.CFrame * CFrame.new(0, 0, self.Distance)
    end)
end

function CameraController:Unlock()
    if not self.Locked then return end
    local cam = workspace.CurrentCamera
    self.Locked = false
    cam.CameraType = Enum.CameraType.Custom
    RunService:UnbindFromRenderStep(self.RenderName)
end
```

## Events

Create internal events using the Signal utility:

```lua
local Signal = require(Knit.Util.Signal)

CameraController.LockedChanged = Signal.new()

function CameraController:LockTo(part)
    -- Other code...
    self.LockedChanged:Fire(true)
end

function CameraController:Unlock()
    -- Other code...
    self.LockedChanged:Fire(false)
end
```

Other client code can listen for this event by requiring the controller module directly:

```lua
local CameraController = require(path.to.CameraController)

CameraController.LockedChanged:Connect(function(isLocked)
    print(if isLocked then "Camera is now locked" else "Camera was unlocked")
end)
```

## Server Communication

Controllers access server-side services via `Knit.GetService()`. This returns a network proxy that mirrors the service's `Client` table -- methods, signals, and properties are all available. Note that because this is a runtime proxy, you will not get type information or IntelliSense for the service's API.

See the [Services: Client Communication](services.md#client-communication) section for details on what services can expose.

```lua
function CameraController:KnitStart()
    local SomeService = Knit.GetService("SomeService")
    SomeService:DoSomething()
    SomeService.SomeEvent:Connect(function(...) end)
    SomeService.AnotherEvent:Fire("Some data")
end
```

> **Note:** If a service does not define a `Client` table, it operates in server-only mode and cannot be accessed from the client via `Knit.GetService`.

## KnitInit and KnitStart

These lifecycle methods work identically to their service counterparts. See the [Execution Model](executionmodel.md) for the full lifecycle.

```lua
function CameraController:KnitInit()
    -- Set up internal state; require other controllers for type-safe references
end

function CameraController:KnitStart()
    -- All controllers are initialized; safe to use other controllers and services
end
```
