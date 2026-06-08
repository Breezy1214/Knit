local Types = require(script.Parent.Types)

export type Middleware = Types.MiddlewareClient
export type ClientMiddlewareFn = Types.ClientMiddlewareFn
export type ClientMiddleware = Types.ClientMiddleware
export type PerServiceMiddleware = Types.PerServiceMiddleware
export type ControllerDef = Types.ControllerDef
export type Controller = Types.Controller
export type ClientService = Types.ClientService
export type KnitClientOptions = Types.KnitClientOptions
export type DeepPredicateFn = Types.DeepPredicateFn
export type DeepSearchOptions = Types.DeepSearchOptions

local defaultOptions: KnitClientOptions = {
	ServicePromises = true,
	Middleware = nil,
	PerServiceMiddleware = {},
	DeterministicStart = false,
	OnStartError = nil,
}

local selectedOptions = nil

--[=[
	@class KnitClient
	@client
]=]
local KnitClient = {}

--[=[
	@prop Player Player
	@within KnitClient
	@readonly
	Reference to the LocalPlayer.
]=]
KnitClient.Player = game:GetService("Players").LocalPlayer

--[=[
	@prop Util Folder
	@within KnitClient
	@readonly
	References the Util folder. Should only be accessed when using Knit as
	a standalone module. If using Knit from Wally, modules should just be
	pulled in via Wally instead of relying on Knit's Util folder, as this
	folder only contains what is necessary for Knit to run in Wally mode.
]=]
KnitClient.Util = (script.Parent :: Instance).Parent

local Promise = require(KnitClient.Util.Promise)
local Comm = require(KnitClient.Util.Comm)
local ClientComm = Comm.ClientComm
local KnitShared = require(script.Parent.KnitShared)

local controllers: { [string]: Controller } = {}
local controllerOrder: { Controller } = {}
local services: { [string]: ClientService } = {}
local servicesFolder = nil

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")

local function DoesControllerExist(controllerName: string): boolean
	local controller: Controller? = controllers[controllerName]

	return controller ~= nil
end

local function GetServicesFolder()
	if not servicesFolder then
		servicesFolder = (script.Parent :: Instance):WaitForChild("Services")
	end

	return servicesFolder
end

local function GetMiddlewareForService(serviceName: string)
	local knitMiddleware = if selectedOptions.Middleware ~= nil then selectedOptions.Middleware else {}
	local serviceMiddleware = selectedOptions.PerServiceMiddleware[serviceName]

	return if serviceMiddleware ~= nil then serviceMiddleware else knitMiddleware
end

local function BuildService(serviceName: string)
	local folder = GetServicesFolder()
	local middleware = GetMiddlewareForService(serviceName)
	local clientComm = ClientComm.new(folder, selectedOptions.ServicePromises, serviceName)
	local service = clientComm:BuildObject(middleware.Inbound, middleware.Outbound)

	services[serviceName] = service

	return service
end

local function createController(controllerDef: ControllerDef): Controller
	assert(type(controllerDef) == "table", `Controller must be a table; got {type(controllerDef)}`)
	assert(type(controllerDef.Name) == "string", `Controller.Name must be a string; got {type(controllerDef.Name)}`)
	assert(#controllerDef.Name > 0, "Controller.Name must be a non-empty string")
	assert(not DoesControllerExist(controllerDef.Name), `Controller {controllerDef.Name} already exists`)
	assert(not started, `Controllers cannot be created after calling "Knit.Start()"`)

	local controller = controllerDef :: Controller
	controllers[controller.Name] = controller
	table.insert(controllerOrder, controller)

	return controller
end

--[=[
	Requires all the modules that are children of the given parent. This is an easy
	way to quickly load all controllers that might be in a folder.
	```lua
	Knit.AddControllers(somewhere.Controllers)
	```
]=]
function KnitClient.AddControllers(parent: Instance, predicate: ((ModuleScript) -> boolean)?): { Controller }
	assert(not started, `Controllers cannot be added after calling "Knit.Start()"`)

	local addedControllers = {}
	for _, v in parent:GetChildren() do
		if not v:IsA("ModuleScript") then
			continue
		end

		if predicate and not predicate(v) then
			continue
		end

		local controllerDef: ControllerDef = require(v)
		local controller: Controller = createController(controllerDef)
		table.insert(addedControllers, controller)
	end

	return addedControllers
end

--[=[
	Requires all the modules that are descendants of the given parent.
	Optionally, a predicate function can be passed in order to filter
	which controllers are added.

	The predicate receives `(moduleScript, parent, depth, path)` and
	should return a boolean. Existing predicate functions that only
	accept `moduleScript` continue to work.

	You can also pass options to control scanning behavior:
	- `MaxDepth` limits recursion depth (starting at `1` for children)
	- `IgnoreFolderPatterns` skips traversing folders that match any
	  Lua string pattern in the array
]=]
function KnitClient.AddControllersDeep(
	parent: Instance,
	predicateOrOptions: (
		((ModuleScript, Instance, number, string) -> boolean) | DeepSearchOptions | nil
	)?,
	options: DeepSearchOptions?
): { Controller }
	assert(not started, `Controllers cannot be added after calling "Knit.Start()"`)

	local predicate, deepSearchOptions = KnitShared.parseDeepSearchArgs(predicateOrOptions, options, "AddControllersDeep")
	local maxDepth = if deepSearchOptions and deepSearchOptions.MaxDepth then deepSearchOptions.MaxDepth else math.huge
	local ignoreFolderPatterns = if deepSearchOptions and deepSearchOptions.IgnoreFolderPatterns
		then deepSearchOptions.IgnoreFolderPatterns
		else {}

	local addedControllers = {}

	local function walk(node: Instance, depth: number, path: string)
		if depth > maxDepth then
			return
		end

		for _, child in node:GetChildren() do
			local childPath = if path == "" then child.Name else `{path}/{child.Name}`

			if child:IsA("ModuleScript") then
				if predicate and not predicate(child, node, depth, childPath) then
					continue
				end

				local controllerDef: ControllerDef = require(child)
				local controller: Controller = createController(controllerDef)
				table.insert(addedControllers, controller)
			elseif not KnitShared.shouldIgnoreFolder(child, ignoreFolderPatterns) then
				walk(child, depth + 1, childPath)
			end
		end
	end

	walk(parent, 1, "")

	return addedControllers
end

--[=[
	Returns a Service object which is a reflection of the remote objects
	within the Client table of the given service. Throws an error if the
	service is not found.

	If a service's Client table contains RemoteSignals and/or RemoteProperties,
	these values are reflected as
	[ClientRemoteSignals](https://sleitnick.github.io/RbxUtil/api/ClientRemoteSignal) and
	[ClientRemoteProperties](https://sleitnick.github.io/RbxUtil/api/ClientRemoteProperty).

	```lua
	-- Server-side service creation:
	local MyService = {
		Name = "MyService",
		Client = {
			MySignal = Knit.CreateSignal(),
			MyProperty = Knit.CreateProperty("Hello"),
		},
	}
	function MyService:AddOne(player, number)
		return number + 1
	end

	-------------------------------------------------

	-- Client-side service reflection:
	local MyService = Knit.GetService("MyService")

	-- Call a method:
	local num = MyService:AddOne(5) --> 6

	-- Fire a signal to the server:
	MyService.MySignal:Fire("Hello")

	-- Listen for signals from the server:
	MyService.MySignal:Connect(function(message)
		print(message)
	end)

	-- Observe the initial value and changes to properties:
	MyService.MyProperty:Observe(function(value)
		print(value)
	end)
	```

	:::caution
	Services are only exposed to the client if the service has remote-based
	content in the Client table. If not, the service will not be visible
	to the client. `KnitClient.GetService` will only work on services that
	expose remote-based content on their Client tables.
	:::
]=]
function KnitClient.GetService(serviceName: string): ClientService
	local service = services[serviceName]
	if service then
		return service
	end

	assert(started, "Cannot call GetService until Knit has been started")
	assert(type(serviceName) == "string", `ServiceName must be a string; got {type(serviceName)}`)

	return BuildService(serviceName)
end

--[=[
	Gets the controller by name. Throws an error if the controller
	is not found.
]=]
function KnitClient.GetController(controllerName: string): Controller
	local controller = controllers[controllerName]
	if controller then
		return controller
	end

	assert(started, "Cannot call GetController until Knit has been started")
	assert(type(controllerName) == "string", `ControllerName must be a string; got {type(controllerName)}`)
	error(`Could not find controller "{controllerName}". Check to verify a controller with this name exists.`, 2)
end

--[=[
	Gets a table of all controllers.
]=]
function KnitClient.GetControllers(): { [string]: Controller }
	assert(started, "Cannot call GetControllers until Knit has been started")

	return controllers
end

--[=[
	@return Promise
	Starts Knit. Should only be called once per client.
	```lua
	Knit.Start():andThen(function()
		print("Knit started!")
	end):catch(warn)
	```

	By default, service methods exposed to the client will return promises.
	To change this behavior, set the `ServicePromises` option to `false`:
	```lua
	Knit.Start({ServicePromises = false}):andThen(function()
		print("Knit started!")
	end):catch(warn)
	```
]=]
function KnitClient.Start(options: KnitClientOptions?)
	if started then
		return Promise.reject("Knit already started")
	end

	started = true

	table.freeze(controllers)
	table.freeze(controllerOrder)

	if options == nil then
		selectedOptions = defaultOptions
	else
		assert(typeof(options) == "table", `KnitOptions should be a table or nil; got {typeof(options)}`)
		selectedOptions = options
		for k, v in defaultOptions do
			if selectedOptions[k] == nil then
				selectedOptions[k] = v
			end
		end
	end
	if type(selectedOptions.PerServiceMiddleware) ~= "table" then
		selectedOptions.PerServiceMiddleware = {}
	end

	KnitShared.validateStartOptions(selectedOptions)

	KnitShared.validateMiddleware(selectedOptions.Middleware, "KnitOptions.Middleware")

	for serviceName, middleware in selectedOptions.PerServiceMiddleware do
		assert(
			type(serviceName) == "string",
			`KnitOptions.PerServiceMiddleware keys must be strings; got {type(serviceName)}`
		)
		KnitShared.validateMiddleware(middleware, `KnitOptions.PerServiceMiddleware["{serviceName}"]`)
	end

	local orderedControllers = KnitShared.resolveDependencyOrder(controllerOrder, controllers, "controller")

	return KnitShared.runKnitInitSequential(orderedControllers, "controller", selectedOptions.OnStartError)
		:andThen(function()
			-- Start:
			if selectedOptions.DeterministicStart then
				return KnitShared.runKnitStartTracked(orderedControllers, "controller", selectedOptions.OnStartError)
			else
				KnitShared.runKnitStartFireAndForget(orderedControllers, selectedOptions.OnStartError)
				return Promise.resolve()
			end
		end)
		:andThen(function()
			startedComplete = true
			onStartedComplete:Fire()

			task.defer(function()
				onStartedComplete:Destroy()
			end)
		end)
end

--[=[
	@return Promise
	Returns a promise that is resolved once Knit has started. This is useful
	for any code that needs to tie into Knit controllers but is not the script
	that called `Start`.
	```lua
	Knit.OnStart():andThen(function()
		local MyController = Knit.GetController("MyController")
		MyController:DoSomething()
	end):catch(warn)
	```
]=]
function KnitClient.OnStart()
	if startedComplete then
		return Promise.resolve()
	else
		return Promise.fromEvent(onStartedComplete.Event)
	end
end

return KnitClient
