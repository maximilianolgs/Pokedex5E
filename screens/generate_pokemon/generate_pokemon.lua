local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local pokedex = require "pokedex.pokedex"
local nature = require "pokedex.natures"
local movedex = require "pokedex.moves"
local notify = require "utils.notify"
local utils = require "utils.utils"
local dex = require "pokedex.dex"
local localization = require "utils.localization"

local M = {}

function M.add_pokemon(species, variant, level)
	local name = pokedex.get_species_display(species, variant)
	if variant then
		name = localization.get("pokemon_variants", name, name)
	end
	notify.notify(localization.get("generate_pokemon_screen", "pokemon_added", "%s was added to your team!"):format(name))
	
	local all_moves = utils.shuffle2(pokedex.get_moves(species, variant, level))

	local pokemon = _pokemon.new({species=species, variant=variant})
	local moves = {}
	for i=1, 4 do
		if all_moves[i] then
			local pp = movedex.get_move_pp(all_moves[i])
			moves[all_moves[i]] = {pp=pp, index=i}
		end
	end
	
	pokemon.exp = pokedex.get_experience_for_level(level-1)

	poke_abilities = pokedex.get_abilities(species, variant)
	while #poke_abilities > 1 do
		table.remove(poke_abilities, rnd.range(1, #poke_abilities))
	end
	pokemon.abilities = poke_abilities

	pokemon.level.caught = pokedex.get_minimum_wild_level(species)
	pokemon.level.current = level
	pokemon.moves = moves
	pokemon.nature = nature.list[rnd.range(1, #nature.list)]

	if pokedex.enforce_genders() and _pokemon.get_strict_gender(pokemon) ~= pokedex.ANY then
		pokemon.gender = _pokemon.get_strict_gender(pokemon)
	else
		--TODO include actual ratios
		local genders_list = {}
		table.insert(genders_list, pokedex.MALE)
		table.insert(genders_list, pokedex.FEMALE)
		pokemon.gender = genders_list[rnd.range(1, #genders_list)]
	end
	

	local max_hp = _pokemon.get_default_max_hp(pokemon)
	local con = _pokemon.get_attributes(pokemon).CON
	local con_mod = math.floor((con - 10) / 2)
	pokemon.hp.max = max_hp
	pokemon.hp.current = max_hp + (con_mod * level)
	
	dex.set(pokemon.species.current, dex.states.CAUGHT)
	storage.add(pokemon)
end

return M