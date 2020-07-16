local netcore = require "pokedex.network.netcore"
local broadcast = require "utils.broadcast"
local utils = require "utils.utils"

local server_member_data = {}

local external_member_list = {}
local external_member_id_index_map = {}
local local_member_data = {}

local client_member_message_cbs = {}

local MEMBERS_KEY = "NET_MEMBERS"
local MEMBER_MESSAGE_KEY = "NET_MEMBERS_MESSAGE"

local M = {}

M.MEMBERS_CHANGED_MESSAGE = "net_members_members_changed"

local function send_local_data()
	if netcore.is_connected() and local_member_data ~= nil then
		netcore.send_to_server(MEMBERS_KEY, local_member_data)
	end
end

local function on_connection_change()
	send_local_data()

	if not netcore.is_connected() then
		-- Should we clear this out?
		external_member_list = {}
		external_member_id_index_map = {}
		server_member_clients = {}
		broadcast.send(M.MEMBERS_CHANGED_MESSAGE)
	end
end

local function on_client_members_data(other_members_data)
	external_member_list = other_members_data

	external_member_id_index_map = {}
	for i=1,#external_member_list do
		external_member_id_index_map[external_member_list[i].unique_id] = i
	end
	
	broadcast.send(M.MEMBERS_CHANGED_MESSAGE)
end

local function on_server_members_data(member_id, member_data)
	server_member_data[member_id] = member_data

	-- Send each member data about everyone but themselves
	local all_client_ids = netcore.server_get_connected_ids()
	for i=1,#all_client_ids do
		local this_client_id = all_client_ids[i]		
		local other_members_data = {}
		for k,v in pairs(server_member_data) do
			if k ~= this_client_id then
				local copy = utils.deep_copy(v)
				copy.unique_id = k
				table.insert(other_members_data, copy)
			end
		end
		netcore.send_to_client(MEMBERS_KEY, other_members_data, this_client_id)
	end
end

local function on_client_member_message(payload)
	local success = false
	if payload and payload.key and payload.message and payload.from then
		local cb =  client_member_message_cbs[payload.key]
		if cb then
			cb(payload.from, payload.message)
			success = true
		end
	end

	if not success then
		assert(nil, "Unknown member message or key, key=", tostring(payload.key), "message=", tostring(payload.message), "from=", from)
	end
end

local function on_server_member_message(member_id, payload)
	if payload.to and payload.key and payload.message then
		
		local send_payload =
		{
			key=payload.key,
			message=payload.message,
			from=member_id,
		}
		
		netcore.send_to_client(MEMBER_MESSAGE_KEY, send_payload, payload.to)
	end
end

function M.init()
	netcore.register_connection_change_cb(on_connection_change)
	netcore.register_client_data_callback(MEMBERS_KEY, on_client_members_data)
	netcore.register_server_data_callback(MEMBERS_KEY, on_server_members_data)
	
	netcore.register_client_data_callback(MEMBER_MESSAGE_KEY, on_client_member_message, true)
	netcore.register_server_data_callback(MEMBER_MESSAGE_KEY, on_server_member_message, true)
end

function M.final()
	-- TODO: save server_member_data
	-- TODO: save external_member_list and perhaps external_member_id_index_map (though I think that can be generated)
end

function M.set_local_member_data(name)
	local_member_data =
	{
		name = name,
	}
	send_local_data()
end

function M.has_other_members()
	return #external_member_list > 0
end

function M.get_other_members()
	return external_member_list
end

function M.get_member_name(member_id)
	local index = external_member_id_index_map[member_id]
	if index then
		return external_member_list[index].name
	else
		return "Someone"
	end
end

function M.get_member_key(member_obj)
	return member_obj.unique_id
end

function M.send_message_to_member(key, message, member_key)
	local payload = 
	{
		to=member_key,
		key=key,
		message=message,
	}
	netcore.send_to_server(MEMBER_MESSAGE_KEY, payload)
end

-- cb takes (from_member, message)
function M.register_member_message_callback(key, cb)
	client_member_message_cbs[key] = cb
end

return M