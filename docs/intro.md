---
sidebar_position: 1
---

# About

Knit is a lightweight framework that simplifies communication between core parts of your Roblox experience and bridges the gap between the server and the client.

See the [Getting Started](gettingstarted.md) guide to begin using Knit.

## Why Choose Knit?

### Structure

Services and controllers form the backbone of a Knit application. By organizing game logic around these singleton objects, developers benefit from cleaner codebases and easier long-term maintenance. Both services and controllers are straightforward to create and include a built-in networking layer.

### Networking Layer

Knit automatically manages RemoteEvent and RemoteFunction instances. Developers declare which endpoints are exposed to clients through the service's `Client` table, and Knit handles the underlying infrastructure. There is no need to manually create or organize remote objects in the hierarchy.

### Extensible

Knit is designed to be extended. Developers write their own bootstrapping code to start and configure the framework, which provides full control over initialization, middleware, and custom module organization.

### For Everyone

From professional studios to independent developers, Knit provides a reliable foundation for Roblox experiences. It is available through Wally for Rojo-based workflows and as a standalone module for Studio-based workflows.

### Battle-Tested

Knit has been widely adopted across the Roblox ecosystem and has proven reliable at scale. The project is open-source and welcomes community contributions.
