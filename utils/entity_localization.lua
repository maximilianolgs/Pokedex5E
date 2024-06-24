local pokemon = require "pokedex.pokemon"
local localization = require "utils.localization"

local M = {}

local function get_move_range(pkmn, move_data)
	local poke_size = pokemon.get_size(pkmn)

	local distance_feet = localization.get("pokemon_information", "pokemon_distance_feet", "ft")

	local move_range = {}
	if move_data.range then
		-- check if it starts with melee, because we also have: Melee (15ft reach) and Melee/60ft
		if move_data.range:sub(1, 5) == "Melee" then
			move_range.type = localization.get("pokemon_information", "pokemon_move_range_melee", "Melee")
			-- melee move with custom reach, Vine Whip is the only one so far
			local custom_reach = string.match(move_data.range, '%((%d*)ft')
			if custom_reach then
				move_range.reach = custom_reach
				-- tiny - large = 5ft ; huge - gargantuan = 10ft
			elseif poke_size == "Huge" or poke_size == "Gargantuan" then
				move_range.reach = "10"
			else
				move_range.reach = "5"
			end
			move_range.reach = move_range.reach .. distance_feet
			-- melee and range move, Struggle is the only one so far
			custom_reach = string.match(move_data.range, '/(%d*)ft')
			if custom_reach then
				move_range.type = move_range.type .. "/" .. localization.get("pokemon_information", "pokemon_move_range_ranged", "Ranged")
				move_range.reach = move_range.reach .. "/" .. custom_reach .. distance_feet
			end
		elseif move_data.range:sub(1, 4) == "Self" then
			move_range.type = localization.get("pokemon_information", "pokemon_move_range_self", "Self")
			-- some "self" movements are line, cone or radius
			local custom_reach = string.match(move_data.range, '%((%d*)ft')
			if custom_reach then
				move_range.reach = custom_reach .. distance_feet
				local shape = string.match(move_data.range, 'ft (%S*)%)')
				shape = localization.get("pokemon_information", "pokemon_move_shape_" .. shape, shape)
				move_range.reach = move_range.reach .. " " .. shape
			end
		elseif move_data.range == "Varies" then
			move_range.type = localization.get("pokemon_information", "pokemon_move_range_varies", move_data.range)
			--move_range.reach = localization.get("pokemon_information", "pokemon_move_range_varies", move_data.range)
		else
			-- if isn't melee, self or "Varies", is ranged
			move_range.type = localization.get("pokemon_information", "pokemon_move_range_ranged", "Ranged")
			local reach = string.match(move_data.range, '(%d*)ft')
			move_range.reach = reach .. distance_feet
		end
	end
	if move_range.type then
		local move_data_range = move_range.type
		if move_range.reach then
			move_data_range = move_data_range .. " (" .. move_range.reach .. ")"
		end
		move_range.str = move_data_range
	end
	return move_range
end

function M.get_move(pkmn, move)
	local move_data = pokemon.get_move_data(pkmn, move)
	lmove = {}
	lmove.orig_data = move_data
	lmove.name = localization.get("moves", move_data.name, move_data.name)
	lmove.description = move_data.description
	lmove.range = get_move_range(pkmn, move_data)
	lmove.AB = move_data.AB
	lmove.damage = move_data.damage
	lmove.type = localization.get("pokemon_information", "pokemon_type_" .. move_data.type, move_data.type)
	if move_data.save then
		lmove.save = localization.get("pokemon_information", "pokemon_" .. move_data.save, move_data.save)
		lmove.save_dc = move_data.save_dc
	end
	if type(move_data.PP) == "string" then
		lmove.PP = localization.get("pokemon_information", "move_pp_" .. move_data.PP, move_data.PP)
	else
		lmove.PP = move_data.PP
	end
	if move_data.power then
		lmove.power = localization.translate_table("pokemon_information", "pokemon_", move_data.power)
	end
	local move_time = move_data.time:sub(3)
	-- check if it starts with action, there's action; action, charge; action, recharge
	if move_time:sub(1, 6) == "action" then
		lmove.action = true
		lmove.time = move_data.time:sub(1,2) .. localization.get("pokemon_information", "pokemon_action", "action")
		if #move_time > 6 then
			-- charge or recharge
			local complement = move_time:sub(9)
			lmove.time = lmove.time .. ", " .. localization.get("pokemon_information", "pokemon_move_complement_" .. complement, complement)
		end
	elseif move_time == "reaction" then
		lmove.reaction = true
		lmove.time = move_data.time:sub(1,2) .. localization.get("pokemon_information", "pokemon_reaction", "reaction")
	elseif move_time == "bonus action" then
		lmove.bonus = true
		lmove.time = move_data.time:sub(1,2) .. localization.get("pokemon_information", "pokemon_bonus_action", "bonus action")
	end
	--
	if move_data.duration:match("^%d") then
		-- 1 minute(, concentration) - x/x-y round(s)(, concentrarion)/(, charge) - x turns(, concentration)
		local count = move_data.duration:match("^%d[-]?[%d]?")
		local unit = move_data.duration:match("%s(%a+)")
		local complement = move_data.duration:match(unit.."%A*(%a*)")
		lmove.duration = count .. " " .. localization.get("pokemon_information", "pokemon_move_duration_" .. unit, unit)
		if complement ~= "" then
			lmove.duration = lmove.duration .. ", " .. localization.get("pokemon_information", "pokemon_move_complement_" .. complement, complement)
		end
	else
		-- Instantaneous, Varies
		lmove.duration = localization.get("pokemon_information", "pokemon_move_duration_" .. move_data.duration, move_data.duration)
	end
	
	return lmove
end


return M