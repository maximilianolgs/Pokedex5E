local profiles = require "pokedex.profiles"
local pokedex = require "pokedex.pokedex"
local storage = require "pokedex.storage"
local utils = require "utils.utils"

local M = {}

local dex = {}
local dex_stats
local initialized = false

M.states = {SEEN=1, CAUGHT=2, UNENCOUNTERED=3}

M.regions = {KANTO=1, JOHTO=2, HOENN=3, SINNOH=4}

local dex_indexes = {[1]=151, [2]=251, [3]=386, [4]=493 }

local function region_from_index(index)
	local is_region = 0
	for region, number in ipairs(dex_indexes) do
		is_region = region
		if index <= number then
			break
		end
	end
	return is_region
end

function M.update_region_stats()
	dex_stats = {[1]={[1]=0, [2]=0}, [2]={[1]=0, [2]=0}, [3]={[1]=0, [2]=0}, [4]={[1]=0, [2]=0}}

	for species, state in pairs(dex) do
		local index = pokedex.get_index_number(species)
		local region = region_from_index(index)
		dex_stats[region][state] = dex_stats[region][state] + 1
	end
end

function M.get_region_seen(region)
	return dex_stats[region][M.states.SEEN]
end

function M.get_region_caught(region)
	return dex_stats[region][M.states.CAUGHT]
end

function M.set(species, state)
	if state == 3 then
		local old_state = M.get(species)
		if old_state ~= 3 then
			local index = pokedex.get_index_number(species)
			local region = region_from_index(index)
			dex_stats[region][old_state] = dex_stats[region][old_state] - 1
		end
		state = nil
	else
		local index = pokedex.get_index_number(species)
		local region = region_from_index(index)
		dex_stats[region][state] = dex_stats[region][state] + 1
	end
	gameanalytics.addDesignEvent {
		eventId = "Pokedex:Set",
		value = state
	}
	dex[species] = state
end

function M.get(species)
	return dex[species] or M.states.UNENCOUNTERED
end

local function get_initial_from_storage()
	local _dex = {}
	for _, id in pairs(storage.list_of_ids_in_storage()) do
		local pokemon = storage.get_copy(id)
		_dex[pokemon.species.current] = M.states.CAUGHT
	end
	for _, id in pairs(storage.list_of_ids_in_inventory()) do
		local pokemon = storage.get_copy(id)
		_dex[pokemon.species.current] = M.states.CAUGHT
	end
	return _dex
end

function M.load(profile)
	dex = profile.pokedex == nil and get_initial_from_storage() or profile.pokedex
	M.update_region_stats()
end

function M.init()
	if not initialized then
		local profile = profiles.get_active()
		if profile then
			M.load(profile)
		end
		initialized = true
	end
end

function M.save()
	profiles.update(profiles.get_active_slot(), {pokedex=dex})
end

return M