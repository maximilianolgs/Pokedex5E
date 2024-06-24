local log = require "utils.log"


local M = {}

-- Menu
M.HIDE = hash("hide")
M.SHOW = hash("show")

-- Defold standard messages
M.ACQUIRE_INPUT_FOCUS = hash("acquire_input_focus")
M.TOUCH = hash("touch")

-- Party messages
M.REFRESH = hash("refresh")
M.RESPONSE = hash("response")
M.UPDATE_EXP = hash("update_exp")
M.UPDATE_HP = hash("update_hp")
M.REFRESH_HP = hash("refresh_hp")
M.UPDATE_TEMP_HP = hash("update_temp_hp")
M.REFRESH_PP = hash("refresh_pp")
M.REFRESH_STATUS = hash("refresh_status")
M.PARTY_SET_ACTIVE = hash("party_set_active")
M.FULL_REST = hash("full_rest")

-- Pokedex
M.MARK = hash("mark")
M.SEARCH = hash("search")

-- Locations, also used as strings in the interface
M.LOCATION_PARTY = "PARTY"
M.LOCATION_PC = "PC"

-- Messages for flow
M.SHOW_PROFILE = hash("show_profile")
M.SHOW_STORAGE = hash("show_storage")
M.SHOW_PARTY = hash("show_party")
M.SHOW_SPLASH = hash("show_splash")


-- Change Pokemon
M.NATURE = hash("nature")
M.SPECIES = hash("species")
M.VARIANT = hash("variant")
M.EVOLVE = hash("evolve")
M.EVOLVE_CONFIRM = hash("evolve_confirm")
M.ABILITIES = hash("abilities")
M.FEATS = hash("feats")
M.ITEM = hash("item")
M.MOVE = hash("move")
M.SKILLS = hash("skills")
M.CHANGE_HP = hash("change_hp")
M.RESET = hash("reset")

M.PC_UPDATED = hash("pc_updated")
M.PARTY_UPDATED = hash("party_updated")

M.UPDATE_PROFILE_NAME = hash("UPDATE_PROFILE_NAME")
M.DELETE_PROFILE = hash("delete_profile")
M.NEW_GROUP_NAME = hash("new_group_name")
M.DELETE_GROUP = hash("delete_group")
M.TRANSFER_POKEMON = hash("transfer_pokemon")
M.TRANSFER_POKEMON_LOCAL = hash("transfer_pokemon_local")
M.RELEASE_POKEMON = hash("release_pokemon")


-- Used for debugging, makes sure that our message is in this table
--[[
setmetatable(M, {
	__index = function(t, i)
		if rawget(t, i) == nil then
			log.error("Check up for value that does not exist in messages.lua: " .. i)
		end
	end
})
--]]


return M
