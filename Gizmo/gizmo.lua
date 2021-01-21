------------------------------------------------------------------------------------------------------------------------
-- Name:		gizmo.lua
-- Version:		0.9 (1/21/2021)
-- Author:		Brad Sharp
--
-- Repository:	https://github.com/BradSharp/Roblox-Miscellaneous/tree/master/Gizmo
-- License:		MIT
--
-- Copyright (c) 2021 Brad Sharp
------------------------------------------------------------------------------------------------------------------------

local gizmo = {}

------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------

local POINT_SCALE	= 5

local RunService = game:GetService("RunService")
local Event = RunService:IsServer() and RunService.Heartbeat or RunService.RenderStepped
local Gizmos = Instance.new("Folder", workspace)

local thickness = script:GetAttribute("DefaultThickness")
local globalScale = script:GetAttribute("DefaultScale")
local onRender = nil
local cache = {}
local queue = {}

local properties = {
	Adornee = workspace,
	AlwaysOnTop = true,
	Color3 = script:GetAttribute("DefaultColor"),
	Visible = false,
	ZIndex = 1,
}

Gizmos.Name = "Gizmos"
Gizmos.Archivable = false

------------------------------------------------------------------------------------------------------------------------
-- Utility
------------------------------------------------------------------------------------------------------------------------

local function style(adornment)
	for property, value in pairs(properties) do
		adornment[property] = value
	end
end

local function get(class)
	local classCache = cache[class]
	if not classCache then
		classCache = {}
		cache[class] = classCache
	end
	return table.remove(classCache) or Instance.new(class, Gizmos)
end

local function release(instance)
	local class = instance.ClassName
	local classCache = cache[class]
	if not classCache then
		classCache = {}
		cache[class] = classCache
	end
	table.insert(classCache, instance)
end

local function empty()
	-- do nothing
end

------------------------------------------------------------------------------------------------------------------------
-- Exports
------------------------------------------------------------------------------------------------------------------------

-- Sets the color of drawn gizmos
function gizmo.setColor(color)
	properties.Color3 = BrickColor.new(color).Color
end

-- Sets the color of drawn gizmos
function gizmo.setColor3(color3)
	properties.Color3 = color3
end

function gizmo.setOrigin(origin)
	properties.CFrame = origin
end

-- Sets the transparency of drawn gizmos
function gizmo.setTransparency(transparency)
	properties.Transparency = transparency
end

-- Sets the ZIndex of drawn gizmos
function gizmo.setLayer(index)
	properties.ZIndex = index
end

function gizmo.setScale(scale)
	globalScale = scale
end

-- Resets all custom styling to default values
function gizmo.reset()
	properties.Transparency = 0
	properties.ZIndex = 1
	properties.CFrame = CFrame.new(0, 0, 0)
	properties.Color3 = script:GetAttribute("DefaultColor")
	globalScale = script:GetAttribute("DefaultScale")
	thickness = script:GetAttribute("DefaultThickness")
end

-- Draws a box at a coordine frame with a given size
function gizmo.drawBox(size, orientation)
	local adornment = get("BoxHandleAdornment")
	style(adornment)
	adornment.Size = size
	adornment.CFrame = orientation
	table.insert(queue, adornment)
end

-- Draws a wire-box at a coordine frame with a given size
function gizmo.drawWireBox(size, orientation)
	
end

-- Draws a sphere at a position with a given radius
function gizmo.drawSphere(position, radius)
	local adornment = get("SphereHandleAdornment")
	style(adornment)
	adornment.Radius = radius
	adornment.CFrame = CFrame.new(position)
	table.insert(queue, adornment)
end

-- Draws a wire-sphere at a position with a given radius
function gizmo.drawWireSphere(position, radius)
	local offset = globalScale * thickness * 0.5
	local outerRadius, innerRadius = radius + offset, radius - offset
	local orientation = CFrame.new(position)
	local adornmentX = get("CylinderHandleAdornment")
	local adornmentY = get("CylinderHandleAdornment")
	local adornmentZ = get("CylinderHandleAdornment")
	style(adornmentX)
	adornmentX.Radius = outerRadius
	adornmentX.InnerRadius = innerRadius
	adornmentX.Height = thickness
	adornmentX.CFrame = orientation
	style(adornmentY)
	adornmentY.Radius = outerRadius
	adornmentY.InnerRadius = innerRadius
	adornmentY.Height = thickness
	adornmentY.CFrame = orientation * CFrame.Angles(math.pi * 0.5, 0, 0)
	style(adornmentZ)
	adornmentZ.Radius = outerRadius
	adornmentZ.InnerRadius = innerRadius
	adornmentZ.Height = thickness
	adornmentZ.CFrame = orientation * CFrame.Angles(0, math.pi * 0.5, 0)
	table.insert(queue, adornmentX)
	table.insert(queue, adornmentY)
	table.insert(queue, adornmentZ)
end

-- Draws a point at a position
function gizmo.drawPoint(position)
	local adornment = get("SphereHandleAdornment")
	style(adornment)
	adornment.Radius = globalScale * thickness * POINT_SCALE * 0.5
	adornment.CFrame = CFrame.new(position)
	table.insert(queue, adornment)
end

-- Draws a line between two positions
function gizmo.drawLine(from, to)
	local distance = (to - from).magnitude
	local adornment = get("CylinderHandleAdornment")
	style(adornment)
	adornment.Radius = globalScale * thickness * 0.5
	adornment.InnerRadius = 0
	adornment.Height = distance
	adornment.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -distance * 0.5)
	table.insert(queue, adornment)
end

-- Draws an arrow between two positions
function gizmo.drawArrow(from, to)
	local coneHeight = thickness * POINT_SCALE * globalScale
	local distance = math.abs((to - from).magnitude - coneHeight)
	local orientation = CFrame.lookAt(from, to)
	local adornmentLine = get("CylinderHandleAdornment")
	local adornmentCone = get("ConeHandleAdornment")
	style(adornmentLine)
	adornmentLine.Radius = globalScale * thickness * 0.5
	adornmentLine.InnerRadius = 0
	adornmentLine.Height = distance
	adornmentLine.CFrame = orientation * CFrame.new(0, 0, -distance * 0.5)
	style(adornmentCone)
	adornmentCone.Height = coneHeight
	adornmentCone.Radius = coneHeight * 0.5
	adornmentCone.CFrame = orientation * CFrame.new(0, 0, -distance)
	table.insert(queue, adornmentLine)
	table.insert(queue, adornmentCone)
end

-- Draws an arrow at a position in a given direction
function gizmo.drawRay(from, direction)
	gizmo.drawArrow(from, from + direction)
end

-- Draws text on the screen at the given location
function gizmo.drawText()
	
end

-- Clears all gizmos that are currently being rendered
function gizmo.clear()
	for _, adornment in ipairs(queue) do
		adornment.Visible = false
		release(adornment)
	end
	queue = {}
end

------------------------------------------------------------------------------------------------------------------------
-- Render
------------------------------------------------------------------------------------------------------------------------

local function enableGizmos()
	onRender = Event:Connect(function ()
		local frame = queue
		queue = {}
		for _, adornment in ipairs(frame) do
			adornment.Visible = true
		end
		Event:Wait()
		for _, adornment in ipairs(frame) do
			adornment.Visible = false
			release(adornment)
		end
	end)
end

local function disableGizmos()
	if onRender then
		onRender:Disconnect()
		onRender = nil
	end
end

workspace:GetAttributeChangedSignal("GizmosEnabled"):Connect(function ()
	if workspace:GetAttribute("GizmosEnabled") then
		enableGizmos()
	else
		disableGizmos()
	end
end)

if workspace:GetAttribute("GizmosEnabled") then
	enableGizmos()
end

------------------------------------------------------------------------------------------------------------------------

return gizmo
