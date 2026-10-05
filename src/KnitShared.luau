local Types = require(script.Parent.Types)

type DeepSearchOptions = Types.DeepSearchOptions

local Util = (script.Parent :: Instance).Parent
local Promise = require(Util.Promise)

local KnitShared = {}

function KnitShared.isPromiseLike(value: any): boolean
	return type(value) == "table" and type(value.andThen) == "function" and type(value.catch) == "function"
end

function KnitShared.validateStartOptions(options: {
	DeterministicStart: boolean?,
	OnStartError: ((name: string, err: any) -> ())?,
})
	if options.DeterministicStart ~= nil then
		assert(
			type(options.DeterministicStart) == "boolean",
			`KnitOptions.DeterministicStart must be a boolean if provided; got {type(options.DeterministicStart)}`
		)
	end

	if options.OnStartError ~= nil then
		assert(
			type(options.OnStartError) == "function",
			`KnitOptions.OnStartError must be a function if provided; got {type(options.OnStartError)}`
		)
	end
end

function KnitShared.resolveStartOptions(options: any, defaultOptions: any): any
	if options == nil then
		return table.clone(defaultOptions)
	end

	assert(typeof(options) == "table", `KnitOptions should be a table or nil; got {typeof(options)}`)

	-- Copy so the caller's table is never mutated:
	local resolved = table.clone(options)
	for key, value in defaultOptions do
		if resolved[key] == nil then
			resolved[key] = value
		end
	end

	return resolved
end

function KnitShared.validateMiddleware(middleware: any, context: string)
	if middleware == nil then
		return
	end

	assert(type(middleware) == "table", `{context} must be a table if provided; got {type(middleware)}`)

	if middleware.Inbound ~= nil then
		assert(
			type(middleware.Inbound) == "table",
			`{context}.Inbound must be an array if provided; got {type(middleware.Inbound)}`
		)
		for i, fn in middleware.Inbound do
			assert(type(fn) == "function", `{context}.Inbound[{i}] must be a function; got {type(fn)}`)
		end
	end

	if middleware.Outbound ~= nil then
		assert(
			type(middleware.Outbound) == "table",
			`{context}.Outbound must be an array if provided; got {type(middleware.Outbound)}`
		)
		for i, fn in middleware.Outbound do
			assert(type(fn) == "function", `{context}.Outbound[{i}] must be a function; got {type(fn)}`)
		end
	end
end

function KnitShared.validateDeepSearchOptions(options: DeepSearchOptions?)
	if options == nil then
		return
	end

	assert(type(options) == "table", `Deep search options must be a table if provided; got {type(options)}`)

	if options.MaxDepth ~= nil then
		assert(
			type(options.MaxDepth) == "number",
			`Deep search option MaxDepth must be a number; got {type(options.MaxDepth)}`
		)
		assert(options.MaxDepth >= 1, "Deep search option MaxDepth must be >= 1")
	end

	if options.IgnoreFolderPatterns ~= nil then
		assert(
			type(options.IgnoreFolderPatterns) == "table",
			`Deep search option IgnoreFolderPatterns must be an array; got {type(options.IgnoreFolderPatterns)}`
		)

		for i, pattern in options.IgnoreFolderPatterns do
			assert(type(pattern) == "string", `IgnoreFolderPatterns[{i}] must be a string; got {type(pattern)}`)
		end
	end
end

function KnitShared.parseDeepSearchArgs(
	predicateOrOptions: (
		((ModuleScript, Instance, number, string) -> boolean) | DeepSearchOptions | nil
	),
	options: DeepSearchOptions?,
	contextName: string
): (((ModuleScript, Instance, number, string) -> boolean)?, DeepSearchOptions?)
	local predicate: ((ModuleScript, Instance, number, string) -> boolean)? = nil
	local resolvedOptions = options

	if type(predicateOrOptions) == "function" then
		predicate = predicateOrOptions
	elseif type(predicateOrOptions) == "table" then
		if options ~= nil then
			error(`{contextName} received two options tables; pass options as the second argument only`, 3)
		end
		resolvedOptions = predicateOrOptions
	elseif predicateOrOptions ~= nil then
		error(
			`Expected predicate function or options table for {contextName} second argument; got {type(
				predicateOrOptions
			)}`,
			3
		)
	end

	KnitShared.validateDeepSearchOptions(resolvedOptions)

	return predicate, resolvedOptions
end

function KnitShared.shouldIgnoreFolder(instance: Instance, ignoreFolderPatterns: { string }): boolean
	if #ignoreFolderPatterns == 0 then
		return false
	end

	for _, pattern in ignoreFolderPatterns do
		if string.match(instance.Name, pattern) ~= nil then
			return true
		end
	end

	return false
end

function KnitShared.resolveDependencyOrder(items: { any }, lookup: { [string]: any }, itemKind: string): { any }
	local resolved = {}
	local state: { [string]: string } = {}

	local function visit(item: any, stack: { string })
		local itemName = item.Name
		local currentState = state[itemName]

		if currentState == "visited" then
			return
		end

		if currentState == "visiting" then
			table.insert(stack, itemName)
			error(`Circular {itemKind} dependency detected: {table.concat(stack, " -> ")}`, 2)
		end

		state[itemName] = "visiting"
		table.insert(stack, itemName)

		local dependsOn = item.DependsOn
		if dependsOn ~= nil then
			assert(type(dependsOn) == "table", `{itemKind} "{itemName}" DependsOn must be an array of {itemKind} names`)

			for i, dependencyName in dependsOn do
				assert(type(dependencyName) == "string", `{itemKind} "{itemName}" DependsOn[{i}] must be a string`)
				local dependency = lookup[dependencyName]
				assert(dependency ~= nil, `{itemKind} "{itemName}" depends on unknown {itemKind} "{dependencyName}"`)
				visit(dependency, table.clone(stack))
			end
		end

		state[itemName] = "visited"
		table.insert(resolved, item)
	end

	for _, item in items do
		visit(item, {})
	end

	return resolved
end

local function reportStartError(
	onStartErrorFn: ((string, any) -> ())?,
	itemName: string,
	err: any,
	fallbackWarning: string?
)
	if onStartErrorFn then
		local ok, callbackErr = pcall(onStartErrorFn, itemName, err)
		if not ok then
			warn(`Knit OnStartError callback failed for "{itemName}": {callbackErr}`)
		end
	elseif fallbackWarning then
		warn(fallbackWarning)
	end
end

local function callLifecycleMethod(item: any, methodName: string): (boolean, any)
	debug.setmemorycategory(item.Name)
	local ok, result = xpcall(function()
		return item[methodName](item)
	end, debug.traceback)
	debug.resetmemorycategory()

	return ok, result
end

function KnitShared.runKnitInitSequential(
	orderedItems: { any },
	itemKind: string,
	onStartErrorFn: ((string, any) -> ())?
)
	return Promise.new(function(resolve, reject)
		local function failInit(itemName: string, err: any)
			reportStartError(
				onStartErrorFn,
				itemName,
				err,
				`[Knit]: KnitInit errored for {itemKind} "{itemName}"; Knit will not finish starting:\n{err}`
			)
			reject(err)
		end

		local index = 0

		local function runFrom()
			-- Iterate synchronous inits in a loop; only hop to a continuation when
			-- an init returns a promise, so long chains don't deepen the stack.
			while true do
				index += 1
				local item = orderedItems[index]
				if item == nil then
					resolve()
					return
				end

				if type(item.KnitInit) ~= "function" then
					continue
				end

				local ok, result = callLifecycleMethod(item, "KnitInit")

				if not ok then
					failInit(item.Name, result)
					return
				end

				if KnitShared.isPromiseLike(result) then
					result:andThen(function()
						runFrom()
					end, function(err)
						failInit(item.Name, err)
					end)
					return
				end
			end
		end

		runFrom()
	end)
end

local StartFailureMeta = {}
StartFailureMeta.__tostring = function(self): string
	local lines = { self.Message }
	for _, failure in self.Errors do
		table.insert(lines, `- {failure.Name}: {failure.Error}`)
	end
	return table.concat(lines, "\n")
end

function KnitShared.runKnitStartTracked(orderedItems: { any }, itemKind: string, onStartErrorFn: ((string, any) -> ())?)
	return Promise.new(function(resolve, reject)
		-- Starts at 1 so a KnitStart that finishes synchronously inside task.spawn
		-- can't drop the count to zero before the remaining items are dispatched.
		-- The extra count is released once the dispatch loop is done.
		local pending = 1
		local failures = {}

		local function completeOne()
			pending -= 1
			if pending > 0 then
				return
			end

			if #failures == 0 then
				resolve()
				return
			end

			reject(setmetatable({
				Message = `KnitStart failed for {#failures} {itemKind}(s)`,
				Errors = failures,
			}, StartFailureMeta))
		end

		local function fail(itemName: string, err: any)
			reportStartError(onStartErrorFn, itemName, err)
			table.insert(failures, { Name = itemName, Error = err })
			completeOne()
		end

		for _, item in orderedItems do
			if type(item.KnitStart) ~= "function" then
				continue
			end

			pending += 1

			task.spawn(function()
				local ok, result = callLifecycleMethod(item, "KnitStart")

				if not ok then
					fail(item.Name, result)
					return
				end

				if KnitShared.isPromiseLike(result) then
					result:andThen(completeOne, function(err)
						fail(item.Name, err)
					end)
				else
					completeOne()
				end
			end)
		end

		completeOne()
	end)
end

function KnitShared.runKnitStartFireAndForget(
	orderedItems: { any },
	itemKind: string,
	onStartErrorFn: ((string, any) -> ())?
)
	local function fail(itemName: string, err: any)
		reportStartError(onStartErrorFn, itemName, err, `[Knit]: KnitStart errored for {itemKind} "{itemName}":\n{err}`)
	end

	for _, item in orderedItems do
		if type(item.KnitStart) ~= "function" then
			continue
		end

		task.spawn(function()
			local ok, result = callLifecycleMethod(item, "KnitStart")

			if not ok then
				fail(item.Name, result)
				return
			end

			if KnitShared.isPromiseLike(result) then
				result:catch(function(err)
					fail(item.Name, err)
				end)
			end
		end)
	end
end

return KnitShared
