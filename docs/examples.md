---
sidebar_position: 7
---

# Examples

## Auto-Loading All Services

A common pattern is to keep all service ModuleScripts within a single folder. The bootstrap script then loads them all at once.

Directory structure:

```
Server/
    KnitRuntime [Script]
    Services/ [Folder]
        MyService [ModuleScript]
        AnotherService [ModuleScript]
        HelloService [ModuleScript]
```

Bootstrap script:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Option 1: Manual loop
for _, v in script.Parent.Services:GetDescendants() do
    if v:IsA("ModuleScript") then
        require(v)
    end
end

Knit.Start():catch(warn)
```

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Option 2: AddServices (direct children only)
Knit.AddServices(script.Parent.Services)

-- Option 3: AddServicesDeep (all descendants)
Knit.AddServicesDeep(script.Parent.OtherServices)

-- Option 4: AddServicesDeep with filtering
Knit.AddServicesDeep(script.Parent.OtherServices, function(moduleScript, parent, depth, path)
    return moduleScript.Name:match("Service$")
        and depth <= 3
        and not path:match("/Tests/")
end, {
    IgnoreFolderPatterns = {"^Tests$", "^Dev$"},
})

Knit.Start():catch(warn)
```

The same approach works on the client with `Knit.AddControllers` and `Knit.AddControllersDeep`.

---

## Exposing a Module Collection

Similar to `Knit.Util`, you can attach any folder of ModuleScripts to the Knit table for convenient access across your codebase.

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Attach a custom module folder
Knit.MyModules = game:GetService("ReplicatedStorage").MyModules

Knit.Start()
```

Other scripts can then require modules from it:

```lua
local SomeModule = require(Knit.MyModules.SomeModule)
```
