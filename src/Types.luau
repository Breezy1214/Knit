local Types = {}

--[=[
	@interface Middleware
	.Inbound ServerMiddleware?
	.Outbound ServerMiddleware?
	@within KnitServer
]=]
export type MiddlewareServer = {
	Inbound: ServerMiddleware?,
	Outbound: ServerMiddleware?,
}

--[=[
	@type ServerMiddlewareFn (player: Player, args: {any}) -> (shouldContinue: boolean, ...: any)
	@within KnitServer

	For more info, see [ServerComm](https://sleitnick.github.io/RbxUtil/api/ServerComm/) documentation.
]=]
export type ServerMiddlewareFn = (player: Player, args: { any }) -> (boolean, ...any)

--[=[
	@type ServerMiddleware {ServerMiddlewareFn}
	@within KnitServer
	An array of server middleware functions.
]=]
export type ServerMiddleware = { ServerMiddlewareFn }

--[=[
	@interface ServiceDef
	.Name string
	.Client table?
	.Middleware Middleware?
	.[any] any
	@within KnitServer
	Used to define a service when creating it.

	The middleware tables provided will be used instead of the Knit-level
	middleware (if any). This allows fine-tuning each service's middleware.
	These can also be left out or `nil` to not include middleware.
]=]
export type ServiceDef = {
	Name: string,
	Client: { [any]: any }?,
	Middleware: MiddlewareServer?,
	DependsOn: { string }?,
	[any]: any,
}

--[=[
	@interface Service
	.Name string
	.Client ServiceClient
	.KnitComm Comm
	.[any] any
	@within KnitServer
]=]
export type Service = {
	Name: string,
	Client: ServiceClient,
	KnitComm: any,
	[any]: any,
}

--[=[
	@interface ServiceClient
	.Server Service
	.[any] any
	@within KnitServer
]=]
export type ServiceClient = {
	Server: Service,
	[any]: any,
}

--[=[
	@interface KnitOptions
	.Middleware Middleware?
	@within KnitServer

	- Middleware will apply to all services _except_ ones that define
	their own middleware.
]=]
export type KnitServerOptions = {
	Middleware: MiddlewareServer?,
	DeterministicStart: boolean?,
	OnStartError: ((name: string, err: any) -> ())?,
}

--[=[
	@type DeepPredicateFn (moduleScript: ModuleScript, parent: Instance, depth: number, path: string) -> boolean
	@within KnitServer
	Predicate function used by deep discovery helpers.
]=]
export type DeepPredicateFn = (moduleScript: ModuleScript, parent: Instance, depth: number, path: string) -> boolean

--[=[
	@interface DeepSearchOptions
	.MaxDepth number?
	.IgnoreFolderPatterns {string}?
	@within KnitServer
]=]
export type DeepSearchOptions = {
	MaxDepth: number?,
	IgnoreFolderPatterns: { string }?,
}

--[=[
	@type ClientMiddlewareFn (args: {any}) -> (shouldContinue: boolean, ...: any)
	@within KnitClient

	For more info, see [ClientComm](https://sleitnick.github.io/RbxUtil/api/ClientComm/) documentation.
]=]
export type ClientMiddlewareFn = (args: { any }) -> (boolean, ...any)

--[=[
	@type ClientMiddleware {ClientMiddlewareFn}
	@within KnitClient
	An array of client middleware functions.
]=]
export type ClientMiddleware = { ClientMiddlewareFn }

--[=[
	@type PerServiceMiddleware {[string]: Middleware}
	@within KnitClient
]=]
export type PerServiceMiddleware = { [string]: MiddlewareClient }

--[=[
	@interface ControllerDef
	.Name string
	.[any] any
	@within KnitClient
	Used to define a controller when creating it.
]=]
export type ControllerDef = {
	Name: string,
	DependsOn: { string }?,
	[any]: any,
}

--[=[
	@interface Controller
	.Name string
	.[any] any
	@within KnitClient
]=]
export type Controller = {
	Name: string,
	[any]: any,
}

--[=[
	@interface KnitClientOptions
	.ServicePromises boolean?
	.Middleware Middleware?
	.PerServiceMiddleware PerServiceMiddleware?
	@within KnitClient

	- `ServicePromises` defaults to `true` and indicates if service methods use promises.
	- Each service will go through the defined middleware, unless the service
	has middleware defined in `PerServiceMiddleware`.
]=]
export type KnitClientOptions = {
	ServicePromises: boolean,
	Middleware: MiddlewareClient?,
	PerServiceMiddleware: PerServiceMiddleware?,
	DeterministicStart: boolean?,
	OnStartError: ((name: string, err: any) -> ())?,
}

--[=[
	@interface Service
	.[any] any
	@within KnitClient
]=]
export type ClientService = {
	[any]: any,
}

--[=[
	@interface Middleware
	.Inbound ClientMiddleware?
	.Outbound ClientMiddleware?
	@within KnitClient
]=]
export type MiddlewareClient = {
	Inbound: ClientMiddleware?,
	Outbound: ClientMiddleware?,
}

return Types
