local pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local feats = require "pokedex.feats"
local JSON = require "defsave.json"
local constants = require "utils.constants"
local md5 = require "utils.md5"
local utils = require "utils.utils"
local localization = require "utils.localization"
local entity_localization = require "utils.entity_localization"

local M = {}

M.localized_info = {}

local function get_id(str)
	local m = md5.new()
	m:update(str)
	return md5.tohex(m:finish())
end

local function create_attrib(pkmn_id, name, current, max, id)
	local att = {}
	att.name = name
	att.current = current or ""
	att.max = max or ""
	-- it should never be a table.. but for debugging reasons, I allow it
	if type(current) ~= "table" then
		att.id = id or get_id(pkmn_id .. att.name .. att.current .. att.max)
	else
		-- this is allowed only for debugging reasons
		att.id = id or get_id(pkmn_id .. att.name .. att.max)
	end
	return att
end

local function create_ability(name, action)
	local ab = {}
	ab.name = name
	ab.description = ""
	ab.action = action
	ab.istokenaction = true
	ab.order = -1
	return ab
end

local function move_full_description(move)
	local full_description = ""
	if move.save then
		full_description = full_description  .. localization.get("roll_twenty_sheet", "full_desc_save_dc", "Save DC: ") .. 
				move.save_dc .. " " .. move.save .. "\n"
	end
	full_description = full_description  .. localization.get("roll_twenty_sheet", "full_desc_type", "Type: ") .. move.type
	if move.power then
		full_description = full_description  .. localization.get("roll_twenty_sheet", "full_desc_move_power", "\nMove Power: ") .. table.concat(move.power, "/")
	end
	full_description = full_description  .. localization.get("roll_twenty_sheet", "full_desc_move_time", "\nMove Time: ") .. move.time
	full_description = full_description  .. localization.get("roll_twenty_sheet", "full_desc_pp", "\nPP: ") .. move.PP
	full_description = full_description  .. localization.get("roll_twenty_sheet", "full_desc_duration", "\nDuration: ") .. move.duration

	if move.range.type then
		full_description = full_description  .. localization.get("roll_twenty_sheet", "full_desc_range", "\nRange: ") .. move.range.type
		if move.range.reach then
			full_description = full_description .. " - " .. move.range.reach
		end
	end
	
	full_description = full_description  .. localization.get("roll_twenty_sheet", "full_desc_description", "\n\nDescription: ") .. move.description
	return full_description
end

local function create_default_attributes(attribs)
	local id = M.localized_info.pkmn.id
	table.insert(attribs, create_attrib(id, "version", 4.21))
	table.insert(attribs, create_attrib(id, "showleveler", 0))
	table.insert(attribs, create_attrib(id, "invalidXP", 0))
	table.insert(attribs, create_attrib(id, "global_damage_mod_roll", ""))
	table.insert(attribs, create_attrib(id, "global_damage_mod_crit", ""))
	table.insert(attribs, create_attrib(id, "global_damage_mod_type", ""))
	table.insert(attribs, create_attrib(id, "appliedUpdates", "upgrade_to_4_2_1,fix_npc_missing_attack_display_flag_attribute,fix_npc_version_number,fix_npcs_in_modules_saves_and_ability_mods,fix_spell_attacks,fix_npc_in_modules_triggering_popup,fix_npc_actions_to_support_translation,fix_pc_skill_and_saving_rolls,fix_pc_saving_rolls,fix_pc_skill_and_saving_rolls_with_expertise,fix_pc_skill_and_saving_rolls_with_reliable_talent,fix_npc_attacks,fix_npc_attacks_with_auto_damage_roll,enable_powerful_build_on_existing_characters,fix_pc_global_critical_damage_rolls,fix_npc_actions_with_damage,fix_pc_global_critical_stacked_damage_rolls,fix_npc_charname_output,fix_pc_skill_rolls_tooltips,fix_pc_global_statical_critical_damage,fix_spell_school_ouput,fix_pc_global_multiple_statical_critical_damage,fix_spell_savedc_output,fix_spellpoints,fix_advantage_query,fix_attacks_spelllink,fix_pc_skills_when_jack_and_odd_prof,fix_armor_stealth_penalty"))
	table.insert(attribs, create_attrib(id, "queryadvantage", "{{query=1}} ?{Advantage?|Normal Roll,&#123&#123normal=1&#125&#125 &#123&#123r2=[[0d20|Advantage,&#123&#123advantage=1&#125&#125 &#123&#123r2=[[@{d20}|Disadvantage,&#123&#123disadvantage=1&#125&#125 &#123&#123r2=[[@{d20}}"))
	table.insert(attribs, create_attrib(id, "npc", "1"))
	table.insert(attribs, create_attrib(id, "charname_output", "{{charname=@{npc_name}}}"))
	table.insert(attribs, create_attrib(id, "armorwarningflag", "hide"))
	table.insert(attribs, create_attrib(id, "customacwarningflag", "hide"))
	table.insert(attribs, create_attrib(id, "npcspellcastingflag", "0"))
	table.insert(attribs, create_attrib(id, "spell_attack_bonus", "0"))
	table.insert(attribs, create_attrib(id, "spell_save_dc", "0"))
	table.insert(attribs, create_attrib(id, "weighttotal", 0))
	table.insert(attribs, create_attrib(id, "encumberance", " "))
	table.insert(attribs, create_attrib(id, "npc_options-flag", "0"))
	table.insert(attribs, create_attrib(id, "ui_flags", ""))
	table.insert(attribs, create_attrib(id, "rtype", "@{advantagetoggle}"))
	table.insert(attribs, create_attrib(id, "advantagetoggle", "{{query=1}} {{normal=1}} {{r2=[[0d20"))
	table.insert(attribs, create_attrib(id, "mancer_npc", "on"))
	table.insert(attribs, create_attrib(id, "l1mancer_status", "completed"))
	table.insert(attribs, create_attrib(id, "mancer_confirm_flag", ""))
end

local function insert_common_abilities(ab)
	table.insert(ab, create_ability(localization.get("roll_twenty_sheet", "txt_iniciative", "Iniciative"), "%{selected|npc_init}"))
	local name = localization.get("roll_twenty_sheet", "txt_resistance_immunity", "Resistance/Immunity")
	local res = localization.get("pokemon_information", "pokemon_resistances", "Resistances")
	local vul = localization.get("pokemon_information", "pokemon_vulnerabilities", "Vulnerabilities")
	local imm = localization.get("pokemon_information", "pokemon_immunities", "Immunities")
	table.insert(ab, create_ability(name, "&{template:default} {{name=" .. name .. "}} {{" .. res .. "= @{selected|npc_resistances}}} {{" .. vul .. "= @{selected|npc_vulnerabilities}}} {{" .. imm .. "= @{selected|npc_immunities}}}"))
end

local function create_save_attrib(pkmn_id, name)
	local _name = name .. "_save"
	return create_attrib(pkmn_id, _name .. "_roll", "@{wtype}&{template:simple} {{rname=^{" .. name .. "-save-u}}} {{mod=@{" .. _name .. "_bonus}}} {{r1=[[@{d20}+@{" .. _name .. "_bonus}@{pbd_safe}]]}} @{advantagetoggle}+@{" .. _name .. "_bonus}@{pbd_safe}]]}} {{global=@{global_save_mod}}} @{charname_output}")
end

-- this returns "Size type1/type2 Type"
local function get_npc_type()
	local pkmn = M.localized_info.pkmn
	local poke_type = pkmn.type

	local _type = poke_type[1]
	if poke_type[2] then _type = _type .. "/" .. poke_type[2] end

	local npc_type = localization.get("roll_twenty_sheet", "npc_type", "%s %s Type"):format(pkmn.size, _type)
	return npc_type
end

-- this returns all the speeds that the pokemon has ie: Walking 10ft; Flying 30ft
local function get_speed()
	local speeds = {}
	for name, amount in pairs(M.localized_info.pkmn.speeds) do
		if amount~=0 then
			speeds[#speeds+1] = name .. " " .. amount .. localization.get("pokemon_information", "pokemon_distance_feet", "ft")
		end
	end
	return table.concat(speeds, "; ")
end

local function detailed_damage(damage)
	local times, number_of_dice, dice_sides, modif

	local i, j = damage:find("x")
	if i then
		times = damage:sub(1, i-1)
	else
		times = "1"
		i = 0
		j = 0
	end

	local k, l = damage:find("d", j+1)
	number_of_dice = damage:sub(j+1, k-1)

	i, j = damage:find("[+-]", l+1)
	if i then
		dice_sides = damage:sub(l+1, i-1)
		modif = damage:sub(i)
	else
		dice_sides = damage:sub(l+1)
		modif = "0"
	end
	return times, number_of_dice, dice_sides, modif
end

local function average_damage(damage)
	local times, number_of_dice, dice_sides, modif = detailed_damage(damage)
	local i, j = times:find("d")
	if i then
		local times_n = times:sub(1, i-1)
		local times_s = times:sub(i+1)
		times = ((times_s + 1) * times_n) / 2
	end
	return math.floor((((dice_sides + 1) * number_of_dice / 2) + modif) * times)
end

local function create_action(id_prefix, action, attribs, move)
	local pkmn = M.localized_info.pkmn
	-- the actions in roll20 are a mess.. it needs to have a bonding id across several attributes... as part of the name...
	-- and then it orders them, by this "in name" id, so we add a prefix to mantain order
	local move_id = action .. id_prefix .. get_id(pkmn.id .. move.orig_data.name)
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_name", move.name))
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_description", move.description))
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_show_desc", move_full_description(move)))
	
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damage2", ""))
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damagetype2", ""))
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_crit2", ""))
	
	-- in roll20 an attack is something that needs a d20 roll
	if move.AB then
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_flag", "on"))
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_damage_flag", "{{damage=1}} {{dmg1flag=1}} "))

		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_type", move.range.type))
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_range", move.range.reach))

		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damagetype", move.type))
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_tohit", "" .. move.AB))
		
		if move.damage then
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damage", move.damage:gsub("x", "*")))
			local _, number_of_dice, dice_sides, _ = detailed_damage(move.damage)
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_crit", number_of_dice .. "d" .. dice_sides))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_onhit", average_damage(move.damage) .. " (" .. move.damage .. ") " .. localization.get("roll_twenty_sheet", "damage_type", "%s damage"):format(move.type)))
		else
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damage", "0"))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_crit", "0d1"))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_onhit", "0 (0) " .. localization.get("roll_twenty_sheet", "damage_type", "%s damage"):format(move.type)))
		end
		
		local ab_sign = "+"
		if move.AB < 0 then
			ab_sign = ""
		end
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_tohitrange", ab_sign .. move.AB .. ", " .. localization.get("roll_twenty_sheet", "attack_reach", "Reach") .. " " .. move.range.reach))
		
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_rollbase", "@{wtype}&{template:npcatk} {{attack=1}} @{damage_flag} @{npc_name_flag} {{rname=[@{name}](~repeating_npcaction_npc_dmg)}} {{rnamec=[@{name}](~repeating_npcaction_npc_crit)}} {{type=[^{attack-u}](~repeating_npcaction_npc_dmg)}} {{typec=[^{attack-u}](~repeating_npcaction_npc_crit)}} {{r1=[[@{d20}+(@{attack_tohit}+0)]]}} @{rtype}+(@{attack_tohit}+0)]]}} @{charname_output}"))
	else
		-- autohit moves, save moves and other kind of moves
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_tohitrange", "+0"))
		
		if move.damage then
			-- moves that have a damage like component, it could be healing points
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_damage_flag", "{{damage=1}} {{dmg1flag=1}} "))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damage", move.damage:gsub("x", "*")))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damagetype", move.type))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_onhit", average_damage(move.damage) .. " (" .. move.damage .. ") " .. localization.get("roll_twenty_sheet", "damage_type", "%s damage"):format(move.type)))
			local _, _, dice_sides, _ = detailed_damage(move.damage)
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_crit", "1d" .. dice_sides))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_rollbase", "@{wtype}&{template:dmgaction} @{damage_flag} @{npc_name_flag} {{rname=@{name}}} {{dmg1=[[@{attack_damage}+0]]}} {{dmg1type=@{attack_damagetype}}} {{dmg2=[[@{attack_damage2}+0]]}} {{dmg2type=@{attack_damagetype2}}} {{crit1=[[@{attack_crit}+0]]}} {{crit2=[[@{attack_crit2}+0]]}} {{description=@{show_desc}}} @{charname_output}"))
		else
			-- save moves and other effects with no damage
			-- if it doesn't do damage, it isn't an attack, and a bunch of default attributes
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_flag", "off"))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_tohit", "0"))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_onhit", ""))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_damage_flag", ""))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_crit", ""))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_rollbase", "@{wtype}&{template:npcaction} @{npc_name_flag} {{rname=@{name}}} {{description=@{show_desc}}} @{charname_output}"))
		end
	end
end

local function create_reaction(id_prefix, attribs, move)
	-- the actions in roll20 are a mess.. it needs to have a bonding id across several attributes... as part of the name...
	-- and then it orders them, by this "in name" id, so we add a prefix to mantain order
	local move_id = "repeating_npcreaction_" .. id_prefix .. get_id(pkmn.id .. move.orig_data.name)
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_name", move_data.name))
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_description", move_full_description(move)))
end

local function localize_information(pkmn)
	local linfo = M.localized_info
	linfo.pkmn = {}
	linfo.pkmn.id = pkmn.id
	linfo.pkmn.nickname = pkmn.nickname
	linfo.pkmn.species = pkmn.species.current
	linfo.pkmn.index_number = pokemon.get_index_number(pkmn)
	if pokedex.has_variants(pkmn.species.current) and pokemon.get_variant(pkmn) then
		linfo.pkmn.variant = pokemon.get_variant(pkmn)
	end
	linfo.pkmn.type = localization.translate_table("pokemon_information", "pokemon_type_", pokemon.get_type(pkmn))

	linfo.pkmn.raw_size = pokemon.get_size(pkmn)
	linfo.pkmn.size = localization.get("pokemon_information", "pokemon_size_" .. linfo.pkmn.raw_size, linfo.pkmn.raw_size)

	linfo.pkmn.ac = pokemon.get_AC(pkmn)
	linfo.pkmn.SR = pokemon.get_SR(pkmn)
	linfo.pkmn.exp_worth = pokemon.get_exp_worth(pkmn)
	linfo.pkmn.proficency_bonus = pokemon.get_proficency_bonus(pkmn)
	linfo.pkmn.current_hp = pokemon.get_current_hp(pkmn)
	linfo.pkmn.total_max_hp = pokemon.get_total_max_hp(pkmn)
	linfo.pkmn.hit_dice = pokemon.get_hit_dice(pkmn)
	linfo.pkmn.raw_attributes = pokemon.get_attributes(pkmn)
	linfo.pkmn.raw_saving_throw_modifier = pokemon.get_saving_throw_modifier(pkmn)
	linfo.pkmn.raw_skills = pokemon.get_full_skill_info(pkmn)
	linfo.pkmn.raw_abilities = pkmn.abilities
	linfo.pkmn.raw_feats = pkmn.feats
	--SPEEDS-----------------------------------
	local speeds = {}
	for name, amount in pairs(pokemon.get_all_speed(pkmn)) do
		speeds[localization.get("pokemon_information", "pokemon_speed_" .. name, name)] = amount
	end
	linfo.pkmn.speeds = speeds
	--VUL/RES/IMM------------------------------
	linfo.pkmn.vulnerabilities = localization.translate_table("pokemon_information", "pokemon_type_", pokemon.get_vulnerabilities(pkmn))
	linfo.pkmn.resistances = localization.translate_table("pokemon_information", "pokemon_type_", pokemon.get_resistances(pkmn))
	linfo.pkmn.immunities = localization.translate_table("pokemon_information", "pokemon_type_", pokemon.get_immunities(pkmn))
	--SENSES-----------------------------------
	local senses = pokemon.get_senses(pkmn)
	linfo.pkmn.senses = {}
	if next(senses) ~= nil then
		for _, str in pairs(senses) do
			local split = utils.split(str)
			local sense_name = split[1]
			sense_name = localization.get("pokemon_information", "pokemon_sense_" .. sense_name, sense_name)
			local distance = split[2]:match("^%d+")
			local unit = split[2]:match("[^%d]+$")
			unit = localization.get("pokemon_information", "pokemon_distance_feet", unit)
			linfo.pkmn.senses[_] = sense_name .. " " .. distance .. unit
		end
	end
	--MOVES------------------------------------
	-- making an ordered list of moves.. in hopes roll20 honors the order
	-- it doesn't, the moves are ordered by id
	linfo.pkmn.moves = {}
	local ordered_moves = {}
	local pkmn_known_moves = pokemon.get_moves(pkmn, {append_known_to_all=true})
	for move, data in pairs(pkmn_known_moves) do
		ordered_moves[data.index] = move
	end
	-- actions, reactions and bonus actions (aka moves)
	for _, move in ipairs(ordered_moves) do
		linfo.pkmn.moves[_] = entity_localization.get_move(pkmn, move)
	end
	--------------------------------------
end

function M.create_sheet(_pkmn)
	localize_information(_pkmn)
	pkmn = M.localized_info.pkmn
	
	local sheet = {}
	sheet.schema_version = 3
	sheet.type = "character"

	-- character properties
	local character = {}
	character.oldId = pkmn.id
	character.name = pkmn.nickname or pokedex.get_species_display(pkmn.species, pkmn.variant)
	local avatar, _ = pokedex.get_sprite(pkmn.species, pkmn.variant)
	character.avatar = "https://raw.githubusercontent.com/maximilianolgs/Pokedex5E/master/assets/textures/pokemons/" .. avatar .. ".png"
	character.bio = ""
	character.gmnotes = ""
	character.tags = "[]"
	character.controlledby = ""
	character.inplayerjournals = ""

	local size_multiplier = 1
	local pokemon_size = pkmn.raw_size
	if pokemon_size == "Tiny" then
		size_multiplier = 0.5
	elseif pokemon_size == "Small" or pokemon_size == "Medium" then
		size_multiplier = 1
	elseif pokemon_size == "Large" then
		size_multiplier = 2
	elseif pokemon_size == "Huge" then
		size_multiplier = 3
	elseif pokemon_size == "Gargantuan" then
		size_multiplier = 4
	end

	-- token properties
	local defaulttoken = {}
	defaulttoken.width = 70 * size_multiplier
	defaulttoken.height = 70 * size_multiplier
	defaulttoken.imgsrc = character.avatar
	defaulttoken.layer = "objects"
	defaulttoken.name = pkmn.species
	defaulttoken.show_tooltip = false
	defaulttoken.represents = character.oldId
	defaulttoken.page_id = get_id(pkmn.id .. "page_id")
	defaulttoken.bar2_value = pkmn.ac
	defaulttoken.bar3_value = pkmn.current_hp
	defaulttoken.bar3_max = pkmn.total_max_hp
	character.defaulttoken = JSON.encode(defaulttoken)

	local attribs = {}
	local abilities = {}

	local skill_flag = 0
	local saving_flag = 0
	-- default attributes
	create_default_attributes(attribs)
	
	-- basic npc info
	table.insert(attribs, create_attrib(pkmn.id, "npc_name", character.name))
	table.insert(attribs, create_attrib(pkmn.id, "npc_type", get_npc_type()))
	table.insert(attribs, create_attrib(pkmn.id, "ac", "" .. defaulttoken.bar2_value))
	table.insert(attribs, create_attrib(pkmn.id, "npc_ac", "" .. defaulttoken.bar2_value))
	table.insert(attribs, create_attrib(pkmn.id, "npc_actype", localization.get("roll_twenty_sheet", "ac_type", "Natural Armor")))
	table.insert(attribs, create_attrib(pkmn.id, "hp", "" .. defaulttoken.bar3_value, "" .. defaulttoken.bar3_max))
	table.insert(attribs, create_attrib(pkmn.id, "npc_speed", get_speed()))
	table.insert(attribs, create_attrib(pkmn.id, "hitdieroll", "" .. pkmn.hit_dice))


	local pkmn_attrb = pkmn.raw_attributes
	local pkmn_attrb_mod = {}

	-- ability scores, modifiers, saves and proficiencies
	-- proficiencies are weird, all need to have a flag set to one, except for the last one
	-- this is the Roll20 way to know where to put a comma in the list of proficiencies
	local last_prof = {}
	for _, abrev in pairs(constants.ABILITY_LIST) do
		local full = constants.ABRIVATION_TO_FULL_ABILITY[abrev]
		table.insert(attribs, create_attrib(pkmn.id, full:lower() .. "_base", "" .. pkmn_attrb[abrev]))
		table.insert(attribs, create_attrib(pkmn.id, full:lower() .. "_flag", 0))
		table.insert(attribs, create_attrib(pkmn.id, full:lower(), pkmn_attrb[abrev]))

		local attrb_mod = math.floor(((pkmn_attrb[abrev]) - 10) / 2)
		pkmn_attrb_mod[abrev] = attrb_mod
		table.insert(attribs, create_attrib(pkmn.id, full:lower() .. "_mod", attrb_mod))

		local negative
		if pkmn_attrb[abrev] < 10 then negative = 1 else negative = 0 end
		table.insert(attribs, create_attrib(pkmn.id, "npc_" .. abrev:lower() .. "_negative", negative))

		local saving_throw_mod = pkmn.raw_saving_throw_modifier[abrev]
		table.insert(attribs, create_attrib(pkmn.id, full:lower() .. "_save_bonus", saving_throw_mod))

		-- saving throws and proficiencies
		-- this is the only easy way I found to know if a pokemon is proficient in a save throw
		if saving_throw_mod > attrb_mod then 
			-- hacky save proficiencies flag handling
			saving_flag = saving_flag + 1
			if last_prof.abrev ~= nil then
				-- all intermediate profs are a 1
				table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_save_flag", 1))
				table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_save_base", "" .. last_prof.mod))
				table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_save", last_prof.mod))
			end
			last_prof.abrev = abrev:lower()
			last_prof.mod = saving_throw_mod
		else 
			-- if not proficient, roll20 doesn't need any more info, it takes it from the ability
			table.insert(attribs, create_attrib(pkmn.id, "npc_" .. abrev:lower() .. "_save_flag", 0))
			table.insert(attribs, create_attrib(pkmn.id, "npc_" .. abrev:lower() .. "_save", ""))
		end
		-- save roll
		table.insert(attribs, create_save_attrib(pkmn.id, full:lower()))
	end

	-- hacky save proficiencies flag handling
	if last_prof.abrev ~= nil then
		saving_flag = saving_flag + 1
		-- the last one is a 2
		table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_save_flag", 2))
		table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_save_base", "" .. last_prof.mod))
		table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_save", last_prof.mod))
	end

	-- skill proficiency table for the pokemon
	local pkmn_skills_list = pkmn.raw_skills

	-- skill modifiers and proficiencies
	-- proficiencies are weird, all need to have a flag set to one, except for the last one
	-- this is the Roll20 way to know where to put a comma in the list of proficiencies
	last_prof = {}
	for _skill, att_abrev in pairs(pokedex.skills) do
		local skill = _skill:lower():gsub(" ", "_")
		-- hacky skill proficiencies flag handling
		if pkmn_skills_list[_skill].is_proficient then 
			skill_flag = skill_flag + 1
			if last_prof.abrev ~= nil then
				-- all intermediate profs are a 1
				table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_flag", 1))
				table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev, last_prof.mod))
				table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_base", "" .. last_prof.mod))
			end
			last_prof.abrev = skill
			last_prof.mod = pkmn_skills_list[_skill].mod

		else 
			-- if not proficient, roll20 doesn't need the mod
			table.insert(attribs, create_attrib(pkmn.id, "npc_" .. skill .. "_flag", 0))
			table.insert(attribs, create_attrib(pkmn.id, "npc_" .. skill, ""))
		end
		-- skill bonus without proficiency and skill roll
		table.insert(attribs, create_attrib(pkmn.id, skill .. "_bonus", pkmn_attrb_mod[att_abrev]))
		table.insert(attribs, create_attrib(pkmn.id, skill .. "_roll", "@{wtype}&{template:simple} {{rname=^{" .. skill .. "-u}}} {{mod=@{" .. skill .. "_bonus}}} {{r1=[[@{d20}+" .. pkmn_skills_list[_skill].mod .. "[" .. skill .. "]@{pbd_safe}]]}} @{advantagetoggle}+" .. pkmn_skills_list[_skill].mod .. "[" .. skill .. "]@{pbd_safe}]]}} {{global=@{global_skill_mod}}} @{charname_output}"))
	end

	-- hacky skill proficiencies flag handling
	if last_prof.abrev ~= nil then
		-- the last one is a 2
		table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_flag", 2))
		table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev, last_prof.mod))
		table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_base", "" .. last_prof.mod))
	end

	table.insert(attribs, create_attrib(pkmn.id, "passive_wisdom", 10 + pkmn_attrb_mod.WIS))

	table.insert(attribs, create_attrib(pkmn.id, "initiative_bonus", pkmn_attrb_mod.DEX))

	-- the skills flag and saving flag is set to 0 if no proficiency or number of proficiencies +1
	table.insert(attribs, create_attrib(pkmn.id, "npc_skills_flag", skill_flag))
	table.insert(attribs, create_attrib(pkmn.id, "npc_saving_flag", saving_flag))


	table.insert(attribs, create_attrib(pkmn.id, "npc_vulnerabilities", table.concat(pkmn.vulnerabilities, ", ")))
	table.insert(attribs, create_attrib(pkmn.id, "npc_resistances", table.concat(pkmn.resistances, ", ")))
	table.insert(attribs, create_attrib(pkmn.id, "npc_immunities", table.concat(pkmn.immunities, ", ")))
	-- there is no easy way to set real condition immunities..
	table.insert(attribs, create_attrib(pkmn.id, "npc_condition_immunities", ""))
	
	table.insert(attribs, create_attrib(pkmn.id, "npc_senses", table.concat(pkmn.senses, ", ")))
	table.insert(attribs, create_attrib(pkmn.id, "npc_challenge", "" .. pkmn.SR))
	table.insert(attribs, create_attrib(pkmn.id, "npc_xp", pkmn.exp_worth))

	--proficiency bonus
	table.insert(attribs, create_attrib(pkmn.id, "npc_pb", "" .. pkmn.proficency_bonus))
	table.insert(attribs, create_attrib(pkmn.id, "pb_custom", pkmn.proficency_bonus))
	table.insert(attribs, create_attrib(pkmn.id, "pb_type", "custom"))
	table.insert(attribs, create_attrib(pkmn.id, "pb", pkmn.proficency_bonus))
	table.insert(attribs, create_attrib(pkmn.id, "pbd_safe", ""))

	-- are these necesary? I don't think so..
	table.insert(attribs, create_attrib(pkmn.id, "death_save_bonus", 0))
	table.insert(attribs, create_attrib(pkmn.id, "death_save_roll", "@{wtype}&{template:simple} {{rname=^{death-save-u}}} {{mod=@{death_save_bonus}}} {{r1=[[@{d20}+@{death_save_bonus}@{pbd_safe}]]}} {{always=1}} {{r2=[[@{d20}+@{death_save_bonus}@{pbd_safe}]]}} {{global=@{global_save_mod}}} @{charname_output}"))
	table.insert(attribs, create_attrib(pkmn.id, "honor_save_bonus", 0))
	table.insert(attribs, create_attrib(pkmn.id, "honor_save_roll", "@{wtype}&{template:simple} {{rname=^{honor-save-u}}} {{mod=@{honor_save_bonus}}} {{r1=[[@{d20}+@{honor_save_bonus}@{pbd_safe}]]}} @{advantagetoggle}+@{honor_save_bonus}@{pbd_safe}]]}} {{global=@{global_save_mod}}} @{charname_output}"))
	table.insert(attribs, create_attrib(pkmn.id, "sanity_save_bonus", 0))
	table.insert(attribs, create_attrib(pkmn.id, "sanity_save_roll", "@{wtype}&{template:simple} {{rname=^{sanity-save-u}}} {{mod=@{sanity_save_bonus}}} {{r1=[[@{d20}+@{sanity_save_bonus}@{pbd_safe}]]}} @{advantagetoggle}+@{sanity_save_bonus}@{pbd_safe}]]}} {{global=@{global_save_mod}}} @{charname_output}"))


	-- abilities will be the buttons that appear when a token is clicked
	-- all poke will have iniciative and resistance/immunities
	insert_common_abilities(abilities)
	-- reactions and bonus actions flags
	local has_reactions = "0"
	local has_bonus_actions = "0"
	
	local c_actions = 0
	local c_bonus_actions = 0
	local c_reactions = 0
	
	-- actions, reactions and bonus actions (aka moves)
	for _, move in ipairs(M.localized_info.pkmn.moves) do
		if move.action then
			-- c_actions is used as part of the id, to get them in the right order
			create_action(c_actions, "repeating_npcaction_", attribs, move)
			table.insert(abilities, create_ability("act-" .. c_actions .. ": " .. move.name, "%{selected|repeating_npcaction_$" .. c_actions .. "_npc_action}"))
			c_actions = c_actions + 1
		elseif move.reaction then
			has_reactions = "1"
			-- c_reactions is used as part of the id, to get them in the right order
			create_reaction(c_reactions, attribs, move)
			table.insert(abilities, create_ability("react-" .. c_reactions .. ": " .. move.name, "&{template:npcaction} {{name=@{selected|npc_name}}} {{rname=@{selected|repeating_npcreaction_$" .. c_reactions .. "_name}}} {{description=@{selected|repeating_npcreaction_$" .. c_reactions .. "_description} }}"))
			c_reactions = c_reactions + 1
		elseif move.bonus then
			has_bonus_actions = "1"
			-- c_bonus_actions is used as part of the id, to get them in the right order
			create_action(c_bonus_actions, "repeating_npcbonusaction_", attribs, move)
			table.insert(abilities, create_ability("bns-" .. c_bonus_actions .. ": " .. move.name, "%{selected|repeating_npcbonusaction_$" .. c_bonus_actions .. "_npc_action}"))
			c_bonus_actions = c_bonus_actions + 1
		end
	end

	-- actions and bonus actions flags
	table.insert(attribs, create_attrib(pkmn.id, "npcbonusactionsflag", has_bonus_actions))
	table.insert(attribs, create_attrib(pkmn.id, "npcreactionsflag", has_reactions))

	-- traits
	-- the traits in roll20 are also a mess.. it needs to have a bonding id across several attributes... as part of the name...
	-- and then another attribute, where it has the order of the traits
	-- abilities
	local trait_order = {}
	local trait_index = 0
	for idx, trait in ipairs(pkmn.raw_abilities) do
		local ltrait = localization.get("abilities", trait, trait)
		local trait_id = idx .. get_id(pkmn.id .. ltrait)
		table.insert(attribs, create_attrib(pkmn.id, "repeating_npctrait_" .. trait_id .. "_name", ltrait))
		table.insert(attribs, create_attrib(pkmn.id, "repeating_npctrait_" .. trait_id .. "_description", pokedex.get_ability_description(trait)))
		table.insert(abilities, create_ability("trait-" .. (idx-1) .. ": " .. ltrait, "&{template:npcaction} {{name=@{selected|npc_name}}} {{rname=@{selected|repeating_npctrait_$" .. trait_index .. "_name}}} {{description=@{selected|repeating_npctrait_$" .. trait_index .. "_description}}}"))
		trait_index = trait_index+1
		trait_order[trait_index] = trait_id
	end
	-- feats
	for idx, feat in ipairs(pkmn.raw_feats) do
		local lfeat = localization.get("feats", feat, feat)
		local feat_id = idx .. get_id(pkmn.id .. lfeat)
		table.insert(attribs, create_attrib(pkmn.id, "repeating_npctrait_" .. feat_id .. "_name", lfeat))
		table.insert(attribs, create_attrib(pkmn.id, "repeating_npctrait_" .. feat_id .. "_description", feats.get_feat_description(feat)))
		table.insert(abilities, create_ability("feat-" .. (idx-1) .. ": " .. lfeat, "&{template:npcaction} {{name=@{selected|npc_name}}} {{rname=@{selected|repeating_npctrait_$" .. trait_index .. "_name}}} {{description=@{selected|repeating_npctrait_$" .. trait_index .. "_description}}}"))
		trait_index = trait_index+1
		trait_order[trait_index] = feat_id
	end

	if trait_index > 0 then
		table.insert(attribs, create_attrib(pkmn.id, "_reporder_repeating_npctrait", table.concat(trait_order, ",")))
	end
	
	-- putting everything together
	character.attribs = attribs
	character.abilities = abilities
	sheet.character = character
	return sheet
end

return M