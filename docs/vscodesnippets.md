---
sidebar_position: 10
---

# VS Code Snippets

VS Code snippets allow you to quickly scaffold services, controllers, and other common Knit patterns. No extensions or plugins are required.

![Snippets](/snippets.gif)

## Setup

1. In VS Code, navigate to **File > Preferences > User Snippets**.
2. Type and select `lua.json`.
3. Add any of the snippets below inside the `{}` braces.
4. Save the file.
5. In your source files, type a prefix (e.g., `knit`) and select the autocomplete suggestion.

---

## Snippets

### Knit Require

Inserts a `require` statement for Knit.

<details>
<summary>Snippet</summary>

```json
"Knit": {
    "prefix": ["knit"],
    "body": ["local Knit = require(ReplicatedStorage.Packages.Knit)"],
    "description": "Require the Knit module"
}
```

</details>
<details>
<summary>Output</summary>

```lua
local Knit = require(ReplicatedStorage.Packages.Knit)
```

</details>

---

### Roblox Service

References a Roblox engine service.

<details>
<summary>Snippet</summary>

```json
"Service": {
    "prefix": ["service"],
    "body": ["local ${0:Name}Service = game:GetService(\"${0:Name}Service\")"],
    "description": "Roblox Service"
}
```

</details>
<details>
<summary>Output</summary>

```lua
local HttpService = game:GetService("HttpService")
```

</details>

---

### Knit Service

Creates a complete service template.

<details>
<summary>Snippet</summary>

```json
"Knit Service": {
    "prefix": ["knitservice"],
    "body": [
        "local Knit = require(ReplicatedStorage.Packages.Knit)",
        "",
        "local ${0:$TM_FILENAME_BASE} = {",
        "\tName = \"${0:$TM_FILENAME_BASE}\",",
        "\tClient = {},",
        "}",
        "",
        "",
        "function ${0:$TM_FILENAME_BASE}:KnitStart()",
        "\t",
        "end",
        "",
        "",
        "function ${0:$TM_FILENAME_BASE}:KnitInit()",
        "\t",
        "end",
        "",
        "",
        "return ${0:$TM_FILENAME_BASE}",
        ""
    ],
    "description": "Knit Service template"
}
```

</details>
<details>
<summary>Output</summary>

```lua
local Knit = require(ReplicatedStorage.Packages.Knit)

local MyService = {
    Name = "MyService",
    Client = {},
}

function MyService:KnitStart()
end

function MyService:KnitInit()
end

return MyService
```

</details>

---

### Knit Controller

Creates a complete controller template.

<details>
<summary>Snippet</summary>

```json
"Knit Controller": {
    "prefix": ["knitcontroller"],
    "body": [
        "local Knit = require(ReplicatedStorage.Packages.Knit)",
        "",
        "local ${0:$TM_FILENAME_BASE} = { Name = \"${0:$TM_FILENAME_BASE}\" }",
        "",
        "",
        "function ${0:$TM_FILENAME_BASE}:KnitStart()",
        "\t",
        "end",
        "",
        "",
        "function ${0:$TM_FILENAME_BASE}:KnitInit()",
        "\t",
        "end",
        "",
        "",
        "return ${0:$TM_FILENAME_BASE}",
        ""
    ],
    "description": "Knit Controller template"
}
```

</details>
<details>
<summary>Output</summary>

```lua
local Knit = require(ReplicatedStorage.Packages.Knit)

local MyController = {
    Name = "MyController",
}

function MyController:KnitStart()
end

function MyController:KnitInit()
end

return MyController
```

</details>

---

### Knit Module Require

Requires a module from within Knit's utility folder.

<details>
<summary>Snippet</summary>

```json
"Knit Require": {
    "prefix": ["knitrequire"],
    "body": ["local ${1:Name} = require(Knit.${2:Util}.${1:Name})"],
    "description": "Knit Require template"
}
```

</details>
<details>
<summary>Output</summary>

```lua
local Signal = require(Knit.Util.Signal)
```

</details>

---

### Lua Class

A standard Lua class template (not Knit-specific).

<details>
<summary>Snippet</summary>

```json
"Class": {
    "prefix": ["class"],
    "body": [
        "local ${0:$TM_FILENAME_BASE} = {}",
        "${0:$TM_FILENAME_BASE}.__index = ${0:$TM_FILENAME_BASE}",
        "",
        "",
        "function ${0:$TM_FILENAME_BASE}.new()",
        "\tlocal self = setmetatable({}, ${0:$TM_FILENAME_BASE})",
        "\treturn self",
        "end",
        "",
        "",
        "function ${0:$TM_FILENAME_BASE}:Destroy()",
        "\t",
        "end",
        "",
        "",
        "return ${0:$TM_FILENAME_BASE}",
        ""
    ],
    "description": "Lua Class"
}
```

</details>
<details>
<summary>Output</summary>

```lua
local MyClass = {}
MyClass.__index = MyClass

function MyClass.new()
    local self = setmetatable({}, MyClass)
    return self
end

function MyClass:Destroy()

end

return MyClass
```

</details>

---

## All Snippets Combined

<details>
<summary>Complete lua.json</summary>

```json
{

    "Service": {
        "prefix": ["service"],
        "body": ["local ${0:Name}Service = game:GetService(\"${0:Name}Service\")"],
        "description": "Roblox Service"
    },

    "Class": {
        "prefix": ["class"],
        "body": [
            "local ${0:$TM_FILENAME_BASE} = {}",
            "${0:$TM_FILENAME_BASE}.__index = ${0:$TM_FILENAME_BASE}",
            "",
            "",
            "function ${0:$TM_FILENAME_BASE}.new()",
            "\tlocal self = setmetatable({}, ${0:$TM_FILENAME_BASE})",
            "\treturn self",
            "end",
            "",
            "",
            "function ${0:$TM_FILENAME_BASE}:Destroy()",
            "\t",
            "end",
            "",
            "",
            "return ${0:$TM_FILENAME_BASE}",
            ""
        ],
        "description": "Lua Class"
    },

    "Knit": {
        "prefix": ["knit"],
        "body": ["local Knit = require(ReplicatedStorage.Packages.Knit)"],
        "description": "Require the Knit module"
    },

    "Knit Service": {
        "prefix": ["knitservice"],
        "body": [
            "local Knit = require(ReplicatedStorage.Packages.Knit)",
            "",
            "local ${0:$TM_FILENAME_BASE} = {",
            "\tName = \"${0:$TM_FILENAME_BASE}\",",
            "\tClient = {},",
            "}",
            "",
            "",
            "function ${0:$TM_FILENAME_BASE}:KnitStart()",
            "\t",
            "end",
            "",
            "",
            "function ${0:$TM_FILENAME_BASE}:KnitInit()",
            "\t",
            "end",
            "",
            "",
            "return ${0:$TM_FILENAME_BASE}",
            ""
        ],
        "description": "Knit Service template"
    },

    "Knit Controller": {
        "prefix": ["knitcontroller"],
        "body": [
            "local Knit = require(ReplicatedStorage.Packages.Knit)",
            "",
            "local ${0:$TM_FILENAME_BASE} = { Name = \"${0:$TM_FILENAME_BASE}\" }",
            "",
            "",
            "function ${0:$TM_FILENAME_BASE}:KnitStart()",
            "\t",
            "end",
            "",
            "",
            "function ${0:$TM_FILENAME_BASE}:KnitInit()",
            "\t",
            "end",
            "",
            "",
            "return ${0:$TM_FILENAME_BASE}",
            ""
        ],
        "description": "Knit Controller template"
    },

    "Knit Require": {
        "prefix": ["knitrequire"],
        "body": ["local ${1:Name} = require(Knit.${2:Util}.${1:Name})"],
        "description": "Knit Require template"
    }

}
```

</details>
