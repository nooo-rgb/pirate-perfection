-- Purpose: Prevents crashes when a player equips a weapon whose unit is not loaded.

local managers = managers
local M_dyn_resource = managers.dyn_resource
local dyn_resource_load = M_dyn_resource and M_dyn_resource.load
local dyn_resources_package = M_dyn_resource and (M_dyn_resource.DYN_RESOURCES_PACKAGE or "packages/dyn_resources")
local Idstring = Idstring
local ids_unit = Idstring("unit")

local backuper = backuper
local hijack = backuper.hijack
local T_W_factory = tweak_data.weapon.factory

local function preload_unit(unit_name)
	if not dyn_resource_load or not unit_name then
		return
	end

	-- Weapon factory entries now store unit paths as strings. Older versions of
	-- this fix called :id() here, which crashes while peers' weapons are spawned.
	if type(unit_name) == "string" then
		unit_name = Idstring(unit_name)
	end

	dyn_resource_load(M_dyn_resource, ids_unit, unit_name, dyn_resources_package, nil)
end

local function factory_unit_name(factory_name, blueprint)
	local weapon_factory = managers.weapon_factory

	if weapon_factory and weapon_factory.get_weapon_unit then
		local ok, unit_name = pcall(weapon_factory.get_weapon_unit, weapon_factory, factory_name, blueprint)
		if ok and unit_name then
			return unit_name
		end
	end

	local factory_data = T_W_factory[factory_name]
	return factory_data and factory_data.unit
end

hijack(backuper, "PlayerInventory.add_unit_by_factory_name", function(o, self, name, equip, instant, blueprint, ...)
	local unit_name = factory_unit_name(name, blueprint)
	if not unit_name then
		return
	end

	preload_unit(unit_name)
	return o(self, name, equip, instant, blueprint, ...)
end)

hijack(backuper, "PlayerInventory.add_unit_by_name", function(o, self, name, ...)
	if not name then
		return
	end

	preload_unit(name)
	return o(self, name, ...)
end)

-- Husk inventories are created for other players during heist drop-in.
hijack(backuper, "HuskPlayerInventory.add_unit_by_name", function(o, self, name, ...)
	if not name then
		return
	end

	preload_unit(name)
	return o(self, name, ...)
end)

hijack(backuper, "HuskPlayerInventory.add_unit_by_factory_name", function(o, self, name, ...)
	local factory_data = T_W_factory[name]
	local unit_name = factory_data and factory_data.unit
	if not unit_name then
		return
	end

	preload_unit(unit_name)
	return o(self, name, ...)
end)

-- For weapon list menu. Fixes crashes when using a not fully loaded weapon.
secure_debug_class(PlayerStandard, void)
