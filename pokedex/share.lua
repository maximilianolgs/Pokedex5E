local storage = require "pokedex.storage"
local url = require "utils.url"
local notify = require "utils.notify"
local monarch = require "monarch.monarch"
local dex = require "pokedex.dex"
local pokedex = require "pokedex.pokedex"
local _pokemon = require "pokedex.pokemon"
local statuses = require "pokedex.statuses"
local rolltwenty = require "pokedex.roll_twenty"
local messages = require "utils.messages"
local _file = require "utils.file"
local platform = require "utils.platform"
local sjson = require "utils.json"
local localization = require "utils.localization"
local win_utils = require "utils.win-125x"
local log = require "utils.log"

local M = {}

-- For checking if sharing is enabled
M.ENABLED = {
	CLIPBOARD_READ = clipboard ~= nil,
	CLIPBOARD_WRITE = clipboard ~= nil,
	NETWORK = platform.MOBILE_PHONE or platform.MACOS or platform.WINDOWS,
	QRCODE_GENERATE = true,
	QRCODE_READ = platform.MOBILE_PHONE or platform.MACOS,
}

if platform.WEB then
	clipboard = require "utils.html_clipboard"
	M.ENABLED.CLIPBOARD_WRITE = true
	clipboard.has_read_permission(function(has_permission)
		M.ENABLED.CLIPBOARD_READ = has_permission
		if not has_permission then
			notify.notify(localization.get("settings_screen", "html_clipboard", "Make sure to enable clipboard permissons to activate the Receive menu"))
		end
	end)
end

local function get_clipboard_pokemon(clipboard_content)
	local paste = clipboard_content
	local pokemon = nil

	if paste then
		-- Ensure the suppposed json ends with a } - Discord mobile seems to have acquired a bug where it sometimes does not end properly
		local munged = paste:sub(-1) == "}" and paste or (paste .. "}")

		pokemon = _file.load_json(munged)
	end

	return pokemon, paste
end

function M.add_new_pokemon(pokemon)
	storage.add(pokemon)
	dex.set(pokemon.species.current, dex.states.CAUGHT)
	if url.PARTY then
		msg.post(url.PARTY, messages.REFRESH)
	elseif url.STORAGE then
		msg.post(url.STORAGE, messages.PARTY_UPDATED)
		msg.post(url.STORAGE, messages.PC_UPDATED)
	end
end

function M.validate(pokemon)
	if pokemon and type(pokemon) == "table" and pokemon.species and pokemon.species.current and
	pokemon.hp and pokemon.hp.current then
		return true
	end
	return nil
end

function M.encode_status(pokemon)
	local new = {}
	for s, _ in pairs(pokemon.statuses or {}) do
		new[statuses.string_to_state[s]] = true
	end
	pokemon.statuses = new
end

local function get_clipboard_callback(callback, clipboard_content)
	local pokemon = get_clipboard_pokemon(clipboard_content)
	if pokemon then
		if not M.validate(pokemon) then
			return 
		end
		M.encode_status(pokemon)
		callback(pokemon)
	end
	callback(nil)
end

function M.get_clipboard(callback)
	if platform.WEB then
		clipboard.paste(function(clipboard_content) get_clipboard_callback(callback, clipboard_content) end)
	else
		get_clipboard_callback(callback, clipboard.paste())
	end
end

local function decode_status(pokemon)
	local new = {}
	for i, _ in pairs(pokemon.statuses or {}) do
		new[statuses.status_names[i]] = true
	end
	pokemon.statuses = new
end

local function serialize_pokemon(pokemon)
	decode_status(pokemon)
	return sjson:encode(pokemon)
end

function M.generate_qr(id, as_wild)
	local pokemon = storage.get_copy(id, as_wild)
	if pokemon then
		local eventId = "Pokemon:Send:QR:"
		if as_wild then
			eventId = "Pokemon:Wild:QR:"
		end
		gameanalytics.addDesignEvent {
			eventId = eventId .. pokedex.get_species_display(pokemon.species.current, pokemon.variant)
		}
		return qrcode.generate(serialize_pokemon(pokemon))
	end
end

function M.get_sendable_pokemon_copy(id, as_wild)
	local pokemon = storage.get_copy(id, as_wild)
	decode_status(pokemon)
	return pokemon
end

local function export_callback(notification_message, eventId, success)
	if success then
		notify.notify(notification_message)
		gameanalytics.addDesignEvent {
			eventId = eventId
		}
	else
		local e = "Error accesing the clipboard\nThe Pokémon couldn't be exported"
		notify.notify(localization.get("transfer_popup", "export_share_error", e))
		gameanalytics.addErrorEvent {
			severity = gameanalytics.SEVERITY_ERROR,
			message = e
		}
		log.error(e)
	end
end

function M.export(id, as_wild)
	local pokemon = storage.get_copy(id, as_wild)
	
	local notification_message = localization.get("transfer_popup", "pokemon_copied_notif", "%s copied to clipboard!"):format(pokemon.nickname or pokemon.species.current)
	local eventId = "Pokemon:Send:Clipboard:"
	if as_wild then
		eventId = "Pokemon:Wild:Clipboard:"
	end
	eventId = eventId .. pokedex.get_species_display(pokemon.species.current, pokemon.variant)
	
	if platform.WEB then
		clipboard.copy(serialize_pokemon(pokemon), function(success) export_callback(notification_message, eventId, success) end)
	else
		clipboard.copy(serialize_pokemon(pokemon))
		export_callback(notification_message, eventId, true)
	end
end

function M.roll20_export(id)
	local pokemon = storage.get_copy(id)
	local sheet = rolltwenty.create_sheet(pokemon)
	local encoded_sheet = sjson:encode(sheet)
	if platform.WINDOWS then
		encoded_sheet = win_utils.utf8_to_win(encoded_sheet)
	end
	local notification_message = localization.get("transfer_popup", "roll20_sheet_copied_notif", "%s's roll20 sheet copied to clipboard!"):format(pokemon.nickname or pokedex.get_species_display(pokemon.species.current, pokemon.variant))
	local eventId = "Pokemon:Send:Roll20:" .. pokedex.get_species_display(pokemon.species.current, pokemon.variant)
	
	if platform.WEB then
		clipboard.copy(encoded_sheet, function(success) export_callback(notification_message, eventId, success) end)
	else
		clipboard.copy(encoded_sheet)
		export_callback(notification_message, eventId, true)
	end
end

return M