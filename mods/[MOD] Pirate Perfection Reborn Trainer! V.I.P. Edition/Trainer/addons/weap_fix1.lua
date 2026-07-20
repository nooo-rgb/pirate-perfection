-- Fixes problems related to weapon preloading.
-- Author: ThisJazzman

backuper:backup("NewRaycastWeaponBase.set_timer")

local alive = alive
local pairs = pairs
local type = type
local NewRaycastWeaponBase = NewRaycastWeaponBase
local super = NewRaycastWeaponBase.super
local super_set_timer = super and super.set_timer

NewRaycastWeaponBase.set_timer = function(self, ...)
	if not alive(self._unit) then
		return
	end

	if super_set_timer then
		super_set_timer(self, ...)
	end

	-- set_timer can run before weapon assembly has populated _parts. Calling
	-- pairs(nil) here used to crash while entering or dropping into a heist.
	if not self._assembly_complete or type(self._parts) ~= "table" then
		return
	end

	for _, data in pairs(self._parts) do
		local unit = data and data.unit
		if alive(unit) then
			unit:set_timer(...)
			unit:set_animation_timer(...)
		end
	end
end
