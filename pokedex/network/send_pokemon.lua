local share = require "pokedex.share"
local net_members = require "pokedex.network.net_members"
local net_member_name = require "pokedex.network.net_member_name"
local notify = require "utils.notify"
local localization = require "utils.localization"
local pokedex = require "pokedex.pokedex"

local KEY = "SEND_POKEMON"

local M = {}

M.SEND_TYPE_CATCH = "Catch"
M.SEND_TYPE_GIFT = "Gift"

local function on_pokemon_received(from_member_id, message)
	local pokemon = message.pokemon
	local from_name = net_member_name.get_name(from_member_id)
	
	if pokemon and share.validate(pokemon) then
		local notify_msg
		local pkmn_name = pokemon.nickname or pokemon.species.current
		local display_species =  pokedex.get_species_display(pokemon.species.current, pokemon.variant)
		if not pokemon.nickname and display_species ~= pokemon.species.current then
			pkmn_name = localization.get("pokemon_variants", display_species, display_species)
		end
		if pokemon.ot then
			notify_msg = localization.get("transfer_popup", "pokemon_received_gift", "%s SENT YOU %s!"):format(from_name, pkmn_name)
			gameanalytics.addDesignEvent {
				eventId = "Pokemon:Receive:Group:" .. display_species
			}
		else
			notify_msg = localization.get("transfer_popup", "pokemon_received_catch", "YOU CAUGHT %s!"):format(pkmn_name)
			gameanalytics.addDesignEvent {
				eventId = "Pokemon:Catch:Group:" .. display_species
			}
		end
		share.add_new_pokemon(pokemon)
		notify.notify(notify_msg)
	end	
end

function M.init()
	net_members.register_member_message_callback(KEY, on_pokemon_received)
end

function M.send_pokemon(member_id, pokemon_id, send_type)
	local pokemon = share.get_sendable_pokemon_copy(pokemon_id, send_type ~= M.SEND_TYPE_GIFT)
	local message = 
	{
		pokemon=pokemon
	}

	net_members.send_message_to_member(KEY, message, member_id)
end

return M