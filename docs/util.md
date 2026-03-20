---
sidebar_position: 5
---

# Utility Modules

## Wally Users

When using Knit via Wally, pull in utility modules as separate Wally dependencies. The Knit Wally package includes only the modules necessary for core framework operation.

## Standalone ModuleScript Users

When using Knit as a standalone ModuleScript, utility modules are accessible via `require(Knit.Util.PACKAGE)`.

The following modules are available:

| Module | Documentation |
|---|---|
| `Knit.Util.Comm` | [Comm API](https://sleitnick.github.io/RbxUtil/api/Comm) |
| `Knit.Util.Component` | [Component API](https://sleitnick.github.io/RbxUtil/api/Component) |
| `Knit.Util.EnumList` | [EnumList API](https://sleitnick.github.io/RbxUtil/api/EnumList) |
| `Knit.Util.Input` | [Input API](https://sleitnick.github.io/RbxUtil/api/Input) |
| `Knit.Util.Option` | [Option API](https://sleitnick.github.io/RbxUtil/api/Option) |
| `Knit.Util.Signal` | [Signal API](https://sleitnick.github.io/RbxUtil/api/Signal) |
| `Knit.Util.Streamable` | [Streamable API](https://sleitnick.github.io/RbxUtil/api/Streamable) |
| `Knit.Util.TableUtil` | [TableUtil API](https://sleitnick.github.io/RbxUtil/api/TableUtil) |
| `Knit.Util.Timer` | [Timer API](https://sleitnick.github.io/RbxUtil/api/Timer) |
| `Knit.Util.Trove` | [Trove API](https://sleitnick.github.io/RbxUtil/api/Trove) |
| `Knit.Util.Promise` | [Promise API](https://eryn.io/roblox-lua-promise/api/Promise) |

### Example

```lua
local Signal = require(Knit.Util.Signal)

local MyService = {
    Name = "MyService",
    SomeSignal = Signal.new(),
}
```
