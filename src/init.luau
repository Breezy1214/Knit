local RunService = game:GetService("RunService")
local Types = require(script.Types)

export type Middleware = Types.MiddlewareServer

export type ServerMiddlewareFn = Types.ServerMiddlewareFn
export type ServerMiddleware = Types.ServerMiddleware
export type ServiceDef = Types.ServiceDef
export type Service = Types.Service
export type ServiceClient = Types.ServiceClient
export type KnitServerOptions = Types.KnitServerOptions

export type ClientMiddlewareFn = Types.ClientMiddlewareFn
export type ClientMiddleware = Types.ClientMiddleware
export type PerServiceMiddleware = Types.PerServiceMiddleware
export type ControllerDef = Types.ControllerDef
export type Controller = Types.Controller
export type ClientService = Types.ClientService
export type KnitClientOptions = Types.KnitClientOptions

if RunService:IsServer() then
	return require(script.KnitServer)
else
	local KnitServer = script:FindFirstChild("KnitServer")
	if KnitServer and RunService:IsRunning() then
		KnitServer:Destroy()
	end

	return require(script.KnitClient)
end
