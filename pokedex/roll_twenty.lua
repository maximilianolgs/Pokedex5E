local pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local feats = require "pokedex.feats"
local JSON = require "defsave.json"
local constants = require "utils.constants"
local md5 = require "utils.md5"

local M = {}

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

local function move_full_description(move_data)
	local full_description = ""
	if move_data.save then
		full_description = full_description  .. "Save DC: " .. move_data.save_dc .. " " .. move_data.save .. "\n"
	end
	full_description = full_description  .. "Type: " .. move_data.type
	if move_data.power then
		full_description = full_description  .. "\nMove Power: " .. table.concat(move_data.power, "/")
	end
	full_description = full_description  .. "\nMove Time: " .. move_data.time
	full_description = full_description  .. "\nPP: " .. move_data.PP
	full_description = full_description  .. "\nDuration: " .. move_data.duration
	full_description = full_description  .. "\nRange: " .. move_data.range
	
	full_description = full_description  .. "\nDescription: " .. move_data.description
	return full_description
end

local function create_default_attributes(pkmn, attribs)
	table.insert(attribs, create_attrib(pkmn.id, "version", 4.21))
	table.insert(attribs, create_attrib(pkmn.id, "showleveler", 0))
	table.insert(attribs, create_attrib(pkmn.id, "invalidXP", 0))
	table.insert(attribs, create_attrib(pkmn.id, "global_damage_mod_roll", ""))
	table.insert(attribs, create_attrib(pkmn.id, "global_damage_mod_crit", ""))
	table.insert(attribs, create_attrib(pkmn.id, "global_damage_mod_type", ""))
	table.insert(attribs, create_attrib(pkmn.id, "appliedUpdates", "upgrade_to_4_2_1,fix_npc_missing_attack_display_flag_attribute,fix_npc_version_number,fix_npcs_in_modules_saves_and_ability_mods,fix_spell_attacks,fix_npc_in_modules_triggering_popup,fix_npc_actions_to_support_translation,fix_pc_skill_and_saving_rolls,fix_pc_saving_rolls,fix_pc_skill_and_saving_rolls_with_expertise,fix_pc_skill_and_saving_rolls_with_reliable_talent,fix_npc_attacks,fix_npc_attacks_with_auto_damage_roll,enable_powerful_build_on_existing_characters,fix_pc_global_critical_damage_rolls,fix_npc_actions_with_damage,fix_pc_global_critical_stacked_damage_rolls,fix_npc_charname_output,fix_pc_skill_rolls_tooltips,fix_pc_global_statical_critical_damage,fix_spell_school_ouput,fix_pc_global_multiple_statical_critical_damage,fix_spell_savedc_output,fix_spellpoints,fix_advantage_query,fix_attacks_spelllink,fix_pc_skills_when_jack_and_odd_prof,fix_armor_stealth_penalty"))
	table.insert(attribs, create_attrib(pkmn.id, "queryadvantage", "{{query=1}} ?{Advantage?|Normal Roll,&#123&#123normal=1&#125&#125 &#123&#123r2=[[0d20|Advantage,&#123&#123advantage=1&#125&#125 &#123&#123r2=[[@{d20}|Disadvantage,&#123&#123disadvantage=1&#125&#125 &#123&#123r2=[[@{d20}}"))
	table.insert(attribs, create_attrib(pkmn.id, "npc", "1"))
	table.insert(attribs, create_attrib(pkmn.id, "charname_output", "{{charname=@{npc_name}}}"))
	table.insert(attribs, create_attrib(pkmn.id, "armorwarningflag", "hide"))
	table.insert(attribs, create_attrib(pkmn.id, "customacwarningflag", "hide"))
	table.insert(attribs, create_attrib(pkmn.id, "npcspellcastingflag", "0"))
	table.insert(attribs, create_attrib(pkmn.id, "spell_attack_bonus", "0"))
	table.insert(attribs, create_attrib(pkmn.id, "spell_save_dc", "0"))
	table.insert(attribs, create_attrib(pkmn.id, "weighttotal", 0))
	table.insert(attribs, create_attrib(pkmn.id, "encumberance", " "))
	table.insert(attribs, create_attrib(pkmn.id, "npc_options-flag", "0"))
	table.insert(attribs, create_attrib(pkmn.id, "ui_flags", ""))
	table.insert(attribs, create_attrib(pkmn.id, "rtype", "@{advantagetoggle}"))
	table.insert(attribs, create_attrib(pkmn.id, "advantagetoggle", "{{query=1}} {{normal=1}} {{r2=[[0d20"))
	table.insert(attribs, create_attrib(pkmn.id, "mancer_npc", "on"))
	table.insert(attribs, create_attrib(pkmn.id, "l1mancer_status", "completed"))
	table.insert(attribs, create_attrib(pkmn.id, "mancer_confirm_flag", ""))
end

local function insert_common_abilities(ab)
	table.insert(ab, create_ability("Iniciative", "%{selected|npc_init}"))
	table.insert(ab, create_ability("Resistencia/Inmunidad", "&{template:default} {{name=Resistencia/Inmunidad}} {{Resistencia= @{selected|npc_resistances}}} {{Vulnerabilidad= @{selected|npc_vulnerabilities}}} {{Inmunidad= @{selected|npc_immunities}}}"))
end

local function create_save_attrib(pkmn_id, name)
	local _name = name .. "_save"
	return create_attrib(pkmn_id, _name .. "_roll", "@{wtype}&{template:simple} {{rname=^{" .. name .. "-save-u}}} {{mod=@{" .. _name .. "_bonus}}} {{r1=[[@{d20}+@{" .. _name .. "_bonus}@{pbd_safe}]]}} @{advantagetoggle}+@{" .. _name .. "_bonus}@{pbd_safe}]]}} {{global=@{global_save_mod}}} @{charname_output}")
end

-- this returns "Size type1/type2 Type"
local function get_npc_type(pkmn)
	local poke_type = pokemon.get_type(pkmn)

	local _type = poke_type[1]
	if poke_type[2] then _type = _type .. "/" .. poke_type[2] end

	local npc_type = pokemon.get_size(pkmn) .. " " .. _type .. " Type"
	
	return npc_type
end

-- this returns all the speeds that the pokemon has ie: Walking 10ft; Flying 30ft
local function get_speed(pkmn)
	local speeds = {}
	for name, amount in pairs(pokemon.get_all_speed(pkmn)) do
		if amount~=0 then
			speeds[#speeds+1] = name .. " " .. amount .. "ft"
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

local function create_action(id_prefix, action, pkmn, attribs, abilities, move_data, pkmn_attrb_mod)
	-- the actions in roll20 are a mess.. it needs to have a bonding id across several attributes... as part of the name...
	-- and then it orders them, by this "in name" id, so we add a prefix to mantain order
	local move_id = action .. id_prefix .. get_id(pkmn.id .. move_data.name)
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_name", move_data.name))
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_description", move_data.description))
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_show_desc", move_full_description(move_data)))
	
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damage2", ""))
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damagetype2", ""))
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_crit2", ""))


	local move_range = {}
	if move_data.range then
		if move_data.range == "Melee" then
			move_range.type = "Melee"
			-- tiny - large = 5ft ; huge - gargantuan = 10ft
			if pokemon.get_size(pkmn) == "Huge" or pokemon.get_size(pkmn) == "Gargantuan" then
				move_range.reach = "10ft"
			else
				move_range.reach = "5ft"
			end
		else
			move_range.type = "Ranged"
			move_range.reach = move_data.range
		end
	end

	-- in roll20 an attack is something that needs a d20 roll
	if move_data.AB then
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_flag", "on"))
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_damage_flag", "{{damage=1}} {{dmg1flag=1}} "))

		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_type", move_range.type))
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_range", move_range.reach))

		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damage", move_data.damage:gsub("x", "*")))
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damagetype", move_data.type))
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_tohit", "" .. move_data.AB))

		local ab_sign = "+"
		if move_data.AB < 0 then
			ab_sign = "-"
		end
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_tohitrange", ab_sign .. move_data.AB .. ", Reach " .. move_range.reach))
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_onhit", average_damage(move_data.damage) .. " (" .. move_data.damage .. ") " .. move_data.type .. " damage"))
		
		local _, _, dice_sides, _ = detailed_damage(move_data.damage)
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_crit", "1d" .. dice_sides))
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_rollbase", "@{wtype}&{template:npcatk} {{attack=1}} @{damage_flag} @{npc_name_flag} {{rname=[@{name}](~repeating_npcaction_npc_dmg)}} {{rnamec=[@{name}](~repeating_npcaction_npc_crit)}} {{type=[^{attack-u}](~repeating_npcaction_npc_dmg)}} {{typec=[^{attack-u}](~repeating_npcaction_npc_crit)}} {{r1=[[@{d20}+(@{attack_tohit}+0)]]}} @{rtype}+(@{attack_tohit}+0)]]}} @{charname_output}"))
	else
		-- autohit moves, save moves and other kind of moves
		table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_tohitrange", "+0"))
		
		if move_data.damage then
			-- moves that have a damage like component, it could be healing points
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_damage_flag", "{{damage=1}} {{dmg1flag=1}} "))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damage", move_data.damage:gsub("x", "*")))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_damagetype", move_data.type))
			table.insert(attribs, create_attrib(pkmn.id, move_id .. "_attack_onhit", average_damage(move_data.damage) .. " (" .. move_data.damage .. ") " .. move_data.type .. " damage"))
			local _, _, dice_sides, _ = detailed_damage(move_data.damage)
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

local function create_reaction(id_prefix, pkmn, attribs, move_data)
	-- the actions in roll20 are a mess.. it needs to have a bonding id across several attributes... as part of the name...
	-- and then it orders them, by this "in name" id, so we add a prefix to mantain order
	local move_id = "repeating_npcreaction_" .. id_prefix .. get_id(pkmn.id .. move_data.name)
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_name", move_data.name))
	table.insert(attribs, create_attrib(pkmn.id, move_id .. "_description", move_full_description(move_data)))
end

function M.create_sheet(pkmn)
	local sheet = {}
	sheet.schema_version = 3
	sheet.type = "character"

	-- character properties
	local character = {}
	character.oldId = pkmn.id
	character.name = pkmn.nickname or pkmn.species.current
	character.avatar = "https://raw.githubusercontent.com/maximilianolgs/Pokedex5E/master/assets/textures/pokemons/" .. pokemon.get_index_number(pkmn) .. pkmn.species.current .. ".png"
	character.bio = ""
	character.gmnotes = ""
	character.tags = "[]"
	character.controlledby = ""
	character.inplayerjournals = ""

	local size_multiplier = 1
	if pokemon.get_size(pkmn) == "Tiny" then
		size_multiplier = 0.5
	elseif pokemon.get_size(pkmn) == "Small" or pokemon.get_size(pkmn) == "Medium" then
		size_multiplier = 1
	elseif pokemon.get_size(pkmn) == "Large" then
		size_multiplier = 2
	elseif pokemon.get_size(pkmn) == "Huge" then
		size_multiplier = 3
	elseif pokemon.get_size(pkmn) == "Gargantuan" then
		size_multiplier = 4
	end

	-- token properties
	local defaulttoken = {}
	defaulttoken.width = 70 * size_multiplier
	defaulttoken.height = 70 * size_multiplier
	defaulttoken.imgsrc = character.avatar
	defaulttoken.layer = "objects"
	defaulttoken.name = pkmn.species.current
	defaulttoken.show_tooltip = false
	defaulttoken.represents = character.oldId
	defaulttoken.page_id = get_id(pkmn.id .. "page_id")
	defaulttoken.bar2_value = pokemon.get_AC(pkmn)
	defaulttoken.bar3_value = pokemon.get_current_hp(pkmn)
	defaulttoken.bar3_max = pokemon.get_total_max_hp(pkmn)
	character.defaulttoken = JSON.encode(defaulttoken)

	local attribs = {}
	local abilities = {}

	local skill_flag = 0
	local saving_flag = 0

	-- default attributes
	create_default_attributes(pkmn, attribs)

	-- basic npc info
	table.insert(attribs, create_attrib(pkmn.id, "npc_name", character.name))
	table.insert(attribs, create_attrib(pkmn.id, "npc_type", get_npc_type(pkmn)))
	table.insert(attribs, create_attrib(pkmn.id, "ac", "" .. defaulttoken.bar2_value))
	table.insert(attribs, create_attrib(pkmn.id, "npc_ac", "" .. defaulttoken.bar2_value))
	table.insert(attribs, create_attrib(pkmn.id, "npc_actype", "Natural Armor"))
	table.insert(attribs, create_attrib(pkmn.id, "hp", "" .. defaulttoken.bar3_value, "" .. defaulttoken.bar3_max))
	table.insert(attribs, create_attrib(pkmn.id, "npc_speed", get_speed(pkmn)))
	table.insert(attribs, create_attrib(pkmn.id, "hitdieroll", "" .. pokemon.get_hit_dice(pkmn)))


	local pkmn_attrb = pokemon.get_attributes(pkmn)
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

		local saving_throw_mod = pokemon.get_saving_throw_modifier(pkmn)[abrev]
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
	local pkmn_skills_prof = pokemon.get_skills(pkmn)
	local is_proficient = {}
	local proficient_in_all
	if #pkmn_skills_prof == 1 and pkmn_skills_prof[1] == "All Skills" then
		proficient_in_all = true
	else
		for _, skill in pairs(pkmn_skills_prof) do
			is_proficient[skill] = true
		end
	end

	local pkmn_skills_mod = pokemon.get_skills_modifier(pkmn)

	-- skill modifiers and proficiencies
	-- proficiencies are weird, all need to have a flag set to one, except for the last one
	-- this is the Roll20 way to know where to put a comma in the list of proficiencies
	last_prof = {}
	for _skill, att_abrev in pairs(pokedex.skills) do
		local skill = _skill:lower():gsub(" ", "_")
		-- hacky skill proficiencies flag handling
		if proficient_in_all or is_proficient[_skill] then 
			skill_flag = skill_flag + 1
			if last_prof.abrev ~= nil then
				-- all intermediate profs are a 1
				table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_flag", 1))
				table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev, last_prof.mod))
				table.insert(attribs, create_attrib(pkmn.id, "npc_" .. last_prof.abrev .. "_base", "" .. last_prof.mod))
			end
			last_prof.abrev = skill
			last_prof.mod = pkmn_skills_mod[_skill]

		else 
			-- if not proficient, roll20 doesn't need the mod
			table.insert(attribs, create_attrib(pkmn.id, "npc_" .. skill .. "_flag", 0))
			table.insert(attribs, create_attrib(pkmn.id, "npc_" .. skill, ""))
		end
		-- skill bonus without proficiency and skill roll
		table.insert(attribs, create_attrib(pkmn.id, skill .. "_bonus", pkmn_attrb_mod[att_abrev]))
		table.insert(attribs, create_attrib(pkmn.id, skill .. "_roll", "@{wtype}&{template:simple} {{rname=^{" .. skill .. "-u}}} {{mod=@{" .. skill .. "_bonus}}} {{r1=[[@{d20}+" .. pkmn_skills_mod[_skill] .. "[" .. skill .. "]@{pbd_safe}]]}} @{advantagetoggle}+" .. pkmn_skills_mod[_skill] .. "[" .. skill .. "]@{pbd_safe}]]}} {{global=@{global_skill_mod}}} @{charname_output}"))
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


	table.insert(attribs, create_attrib(pkmn.id, "npc_vulnerabilities", table.concat(pokemon.get_vulnerabilities(pkmn), ", ")))
	table.insert(attribs, create_attrib(pkmn.id, "npc_resistances", table.concat(pokemon.get_resistances(pkmn), ", ")))
	table.insert(attribs, create_attrib(pkmn.id, "npc_immunities", table.concat(pokemon.get_immunities(pkmn), ", ")))
	-- there is no easy way to set real condition immunities..
	table.insert(attribs, create_attrib(pkmn.id, "npc_condition_immunities", ""))
	table.insert(attribs, create_attrib(pkmn.id, "npc_senses", table.concat(pokemon.get_senses(pkmn), ", ")))
	table.insert(attribs, create_attrib(pkmn.id, "npc_challenge", "" .. pokemon.get_SR(pkmn)))
	table.insert(attribs, create_attrib(pkmn.id, "npc_xp", pokemon.get_exp_worth(pkmn)))

	--proficiency bonus
	table.insert(attribs, create_attrib(pkmn.id, "npc_pb", "" .. pokemon.get_proficency_bonus(pkmn)))
	table.insert(attribs, create_attrib(pkmn.id, "pb_custom", pokemon.get_proficency_bonus(pkmn)))
	table.insert(attribs, create_attrib(pkmn.id, "pb_type", "custom"))
	table.insert(attribs, create_attrib(pkmn.id, "pb", pokemon.get_proficency_bonus(pkmn)))
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

	-- making an ordered list of moves.. in hopes roll20 honors the order
	-- it doesn't, the moves are ordered by id
	local ordered_moves = {}
	local pkmn_known_moves = pokemon.get_moves(pkmn, {append_known_to_all=true})
	for move, data in pairs(pkmn_known_moves) do
		ordered_moves[data.index] = move
	end

	local c_actions = 0
	local c_bonus_actions = 0
	local c_reactions = 0
	
	-- actions, reactions and bonus actions (aka moves)
	for _, move in ipairs(ordered_moves) do

		local move_data = pokemon.get_move_data(pkmn, move)
		local move_time = move_data.time:sub(3)
		if move_time == "action" then
			-- c_actions is used as part of the id, to get them in the right order
			create_action(c_actions, "repeating_npcaction_", pkmn, attribs, abilities, move_data, pkmn_attrb_mod)
			table.insert(abilities, create_ability("act-" .. c_actions .. ": " .. move_data.name, "%{selected|repeating_npcaction_$" .. c_actions .. "_npc_action}"))
			c_actions = c_actions + 1
		elseif move_time == "reaction" then
			has_reactions = "1"
			-- c_reactions is used as part of the id, to get them in the right order
			create_reaction(c_reactions, pkmn, attribs, move_data)
			table.insert(abilities, create_ability("react-" .. c_reactions .. ": " .. move_data.name, "&{template:npcaction} {{name=@{selected|npc_name}}} {{rname=@{selected|repeating_npcreaction_$" .. c_reactions .. "_name}}} {{description=@{selected|repeating_npcreaction_$" .. c_reactions .. "_description} }}"))
			c_reactions = c_reactions + 1
		elseif move_time == "bonus action" then
			has_bonus_actions = "1"
			-- c_bonus_actions is used as part of the id, to get them in the right order
			create_action(c_bonus_actions, "repeating_npcbonusaction_", pkmn, attribs, abilities, move_data, pkmn_attrb_mod)
			table.insert(abilities, create_ability("bns-" .. c_bonus_actions .. ": " .. move_data.name, "%{selected|repeating_npcbonusaction_$" .. c_bonus_actions .. "_npc_action}"))
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
	for idx, trait in ipairs(pkmn.abilities) do
		local trait_id = idx .. get_id(pkmn.id .. trait)
		table.insert(attribs, create_attrib(pkmn.id, "repeating_npctrait_" .. trait_id .. "_name", trait))
		table.insert(attribs, create_attrib(pkmn.id, "repeating_npctrait_" .. trait_id .. "_description", pokedex.get_ability_description(trait)))
		table.insert(abilities, create_ability("trait-" .. (idx-1) .. ": " .. trait, "&{template:npcaction} {{name=@{selected|npc_name}}} {{rname=@{selected|repeating_npctrait_$" .. #trait_order .. "_name}}} {{description=@{selected|repeating_npctrait_$" .. #trait_order .. "_description}}}"))
		trait_order[idx] = trait_id
	end
	-- feats
	for idx, feat in ipairs(pkmn.feats) do
		local feat_id = idx .. get_id(pkmn.id .. feat)
		table.insert(attribs, create_attrib(pkmn.id, "repeating_npctrait_" .. feat_id .. "_name", feat))
		table.insert(attribs, create_attrib(pkmn.id, "repeating_npctrait_" .. feat_id .. "_description", feats.get_feat_description(feat)))
		table.insert(abilities, create_ability("feat-" .. (idx-1) .. ": " .. feat, "&{template:npcaction} {{name=@{selected|npc_name}}} {{rname=@{selected|repeating_npctrait_$" .. #trait_order .. "_name}}} {{description=@{selected|repeating_npctrait_$" .. #trait_order .. "_description}}}"))
		trait_order[#trait_order + idx] = feat_id
	end

	if #trait_order > 0 then
		table.insert(attribs, create_attrib(pkmn.id, "_reporder_repeating_npctrait", table.concat(trait_order, ",")))
	end
	
	-- putting everything together
	character.attribs = attribs
	character.abilities = abilities
	sheet.character = character
	return sheet
end

return M