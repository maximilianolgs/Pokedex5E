local share = require "pokedex.share"
local net_members = require "pokedex.network.net_members"
local net_member_name = require "pokedex.network.net_member_name"
local notify = require "utils.notify"
local localization = require "utils.localization"
local _pokemon = require "pokedex.pokemon"

local KEY = "SEND_POKEMON"

local M = {}

M.SEND_TYPE_CATCH = "Catch"
M.SEND_TYPE_GIFT = "Gift"

local function on_pokemon_received(from_member_id, message)
	local pokemon = message.pokemon
	local send_type = message.send_type
	local from_name = net_member_name.get_name(from_member_id)
	
	if send_type and pokemon and share.validate(pokemon) then
		share.add_new_pokemon(pokemon)

		local notify_msg
		local pkmn_name = (pokemon.nickname or pokemon.species.current)
		if send_type == M.SEND_TYPE_CATCH then
			notify_msg = localization.get("transfer_popup", "pokemon_received_catch", "YOU CAUGHT %s!"):format(pkmn_name)
			gameanalytics.addDesignEvent {
				eventId = "Pokemon:Receive:Group:Catch",
				value = _pokemon.get_index_number(pokemon)
			}
		elseif send_type == M.SEND_TYPE_GIFT then
			notify_msg = localization.get("transfer_popup", "pokemon_received_gift", "%s SENT YOU %s!"):format(from_name, pkmn_name)
			gameanalytics.addDesignEvent {
				eventId = "Pokemon:Receive:Group:Gift",
				value = _pokemon.get_index_number(pokemon)
			}
		else
			notify_msg = localization.get("transfer_popup", "pokemon_received", "WELCOME, %s!"):format(pkmn_name)
			gameanalytics.addDesignEvent {
				eventId = "Pokemon:Receive:Group",
				value = _pokemon.get_index_number(pokemon)
			}
		end
		notify.notify(notify_msg)
	end	
end

function M.init()
	net_members.register_member_message_callback(KEY, on_pokemon_received)
end

function M.send_pokemon(member_id, pokemon_id, send_type)
	local pokemon = share.get_sendable_pokemon_copy(pokemon_id)

	local message = 
	{
		pokemon=pokemon,
		send_type=send_type,
	}

	net_members.send_message_to_member(KEY, message, member_id)
end

return M