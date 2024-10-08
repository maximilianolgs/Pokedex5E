local type_data = require "utils.type_data"
local file = require "utils.file"
local utils = require "utils.utils"
local fakemon = require "fakemon.fakemon"
local localization = require "utils.localization"

local M = {}

local index = {}
local movedata = {}
local known_to_all_moves = {}
local move_machines
local moves_description = {}

local initialized = false

local warning_list = {}


function M.get_move_data(move)
	if movedata[move] then
		return movedata[move]
	else
		local move_json = file.load_json_from_resource("/p5e-data/data/moves/".. move .. ".json")
		if move_json ~= nil then
			move_json.Description = moves_description[move:lower()].description
			movedata[move] = move_json
			return movedata[move]
		else
			if not warning_list[tostring(move)] then
				gameanalytics.critical(string.format("Can not find move data for: '%s'", tostring(move)))
			end
			warning_list[tostring(move)] = true
			return M.get_move_data("Error")
		end
	end
end

function M.get_move_pp(move)
	local move = M.get_move_data(move)
	return move and move.PP or 0
end

function M.get_known_to_all_moves()
	return known_to_all_moves
end

function M.is_move_known_to_all(move)
	return M.get_known_to_all_moves()[move]
end

function M.get_move_type(move)
	local move = M.get_move_data(move)
	return move and move.Type or "Typeless"
end

local function get_type_data(move)
	if type_data[M.get_move_type(move)] then
		return type_data[M.get_move_type(move)]
	end
	gameanalytics.error(string.format("Can not find type data for: '%s'", tostring(move)))
end

function M.get_move_color(move)
	return get_type_data(move).color
end

function M.get_move_icon(move)
	return get_type_data(move).icon
end

local function list()
	local l = {}
	for m, d in pairs(index) do
		table.insert(l, m)
	end
	table.sort(l)
	return l
end

function M.get_TM(number)
	if move_machines[number] then
		return move_machines[number]
	else
		gameanalytics.error(string.format("Can not find TM: '%s'", tostring(number))  .. "\n" .. debug.traceback())
		return move_machines[999]
	end
end

function M.init()
	if not initialized then
		movedata = {}
		index = file.load_json_from_resource("/p5e-data/data/move_index.json")
		move_machines = file.load_json_from_resource("/assets/datafiles/move_machines.json")
		moves_description = localization.load_localized_json_from_resource("/assets/datafiles/moves_extra.json")
		movedata["Error"] = file.load_json_from_resource("/assets/datafiles/Error_move.json")
		if fakemon.DATA and fakemon.DATA["moves.json"] then
			gameanalytics.info("Merging Move data")
			for name, data in pairs(fakemon.DATA["moves.json"]) do
				gameanalytics.info("    " .. name)
				index[name] = {}
				movedata[name] = data
			end
		end

		M.list = list()

		-- I wanted to make this data-driven, but wasn't sure how MDATA.json is generated and how to test convert_to_game_data.py
		known_to_all_moves = { Struggle = M.get_move_data("Struggle") }
		
		initialized = true
	end
end

return M