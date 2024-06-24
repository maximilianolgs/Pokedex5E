local moves = require "pokedex.moves"
local type_data = require "utils.type_data"
local _pokemon = require "pokedex.pokemon"
local gui_utils = require "utils.gui"
local gooey = require "gooey.gooey"
local localization = require "utils.localization"
local entity_localization = require "utils.entity_localization"

local function join_table(title, T, sep)
	if T then
		return title .. table.concat(T, sep)
	end
	return "-"
end

local function initial_setup(data)
end

local function update_desc_list(data, action_id, action)
	gooey.vertical_static_list(data.str_node_prefix, data.str_node_prefix .. "/desc_stencil", {data.str_node_prefix .. "/txt_desc"}, action_id, action, function() end)
end

local MOVE_SUMMARY = {}

function MOVE_SUMMARY.get_size(data)
	return gui.get_size(gui.get_node(data.str_node_prefix .. "/background"))
end

function MOVE_SUMMARY.on_input(data, action_id, action)
	update_desc_list(data, action_id, action)
end

function MOVE_SUMMARY.is_valid_move(data)
	return data.is_valid_move
end


local M = {}

function M.create(str_node_prefix, pokemon, move_name)

	gui.set_text(gui.get_node(str_node_prefix .. "/lbl_dmg"), localization.get("move_info_popup", "lbl_dmg", "Damage"))
	gui.set_text(gui.get_node(str_node_prefix .. "/lbl_duration"), localization.get("move_info_popup", "lbl_duration", "Duration"))
	gui.set_text(gui.get_node(str_node_prefix .. "/lbl_pp"), localization.get("move_info_popup", "lbl_pp", "PP"))
	gui.set_text(gui.get_node(str_node_prefix .. "/lbl_range"), localization.get("move_info_popup", "lbl_range", "Range"))
	gui.set_text(gui.get_node(str_node_prefix .. "/lbl_move_power"), localization.get("move_info_popup", "lbl_move_power", "Move Power"))
	gui.set_text(gui.get_node(str_node_prefix .. "/lbl_time"), localization.get("move_info_popup", "lbl_time", "Casting Time"))
	
	gui_utils.scale_text_to_fit_parent_size(gui.get_node(str_node_prefix .. "/lbl_pp"))
	gui_utils.scale_text_to_fit_parent_size(gui.get_node(str_node_prefix .. "/lbl_dmg"))
	gui_utils.scale_text_to_fit_parent_size(gui.get_node(str_node_prefix .. "/lbl_range"))
	gui_utils.scale_text_to_fit_parent_size(gui.get_node(str_node_prefix .. "/lbl_time"))
	gui_utils.scale_text_to_fit_parent_size(gui.get_node(str_node_prefix .. "/lbl_duration"))
	gui_utils.scale_text_to_fit_parent_size(gui.get_node(str_node_prefix .. "/lbl_move_power"))
	
	local move_data = nil
	if move_name ~= nil then
		-- NOTE: We could get just the flat move data here and not make use of the Pokemon data.
		-- But the Pokemon get_move_data function returns data in a different (nicer) API, is used
		-- by the move_info.gui_script (on which this component is based), and it also is kinda
		-- nice to see what kind of bonus damage you'd get.
		move_data = entity_localization.get_move(pokemon, move_name)
	end
	local is_valid_move = move_data ~= nil


	local data =
	{
		str_node_prefix = str_node_prefix,
		pokemon = pokemon,
		move_name = move_name,
		is_valid_move = is_valid_move,
	}
	
	
	gui.set_enabled(gui.get_node(str_node_prefix .. "/root"), is_valid_move)
	
	if is_valid_move then

		-- NOTE: This code was in large part stolen from move_info.gui_script, which the move summary was based on. It has a similar general layout
		-- but is more compressed to fit 2 on a screen better, and since it fits 2 on a screen we split it out into its own component

		local node_name = gui.get_node(str_node_prefix .. "/txt_name")
		local node_desc = gui.get_node(str_node_prefix .. "/txt_desc")
		local node_time = gui.get_node(str_node_prefix .. "/txt_time")
		local node_duration = gui.get_node(str_node_prefix .. "/txt_duration")
		local node_range = gui.get_node(str_node_prefix .. "/txt_range")
		local node_move_power = gui.get_node(str_node_prefix .. "/txt_move_power")
		local node_type = gui.get_node(str_node_prefix .. "/txt_type")
		local node_icon = gui.get_node(str_node_prefix .. "/icon_type")
		local node_pp = gui.get_node(str_node_prefix .. "/txt_pp")
		local node_dmg = gui.get_node(str_node_prefix .. "/txt_dmg")

		local size_desc = gui.get_size(node_desc)
		local metrics_desc = gui.get_text_metrics_from_node(node_desc)

		gui.set_text(node_name, localization.get("moves", move_name, move_name))
		gui_utils.scale_text_to_fit_parent_size(node_name)
		gui.set_text(node_desc, move_data.description)
		gui.set_text(node_time, move_data.time)
		gui.set_text(node_duration, move_data.duration)
		gui.set_text(node_range, move_data.range.str or "")
		gui.set_text(node_move_power, join_table("", move_data.power, "/"))
		gui.set_text(node_pp, moves.get_move_pp(move_name))
		gui.set_text(node_type, move_data.type)
		gui.set_text(node_dmg, move_data.damage or "-")

		-- Set up the size of the description so it can be scrolled by the gui static list.
		-- NOTE: The item must have CENTER pivot in the Y dimension and 1 scale for the list to work!
		local metrics_desc_new = gui.get_text_metrics_from_node(node_desc)
		local diff_desc_size = metrics_desc_new.height - metrics_desc.height
		size_desc.y = size_desc.y + diff_desc_size
		gui.set_size(node_desc, size_desc)
		update_desc_list(data)

		gui_utils.scale_text_to_fit_size(node_name)
		gui_utils.scale_text_to_fit_size(node_time)
		gui_utils.scale_text_to_fit_size(node_duration)
		gui_utils.scale_text_with_line_breaks(node_range)
		gui_utils.scale_text_to_fit_size(node_move_power)
		gui_utils.scale_text_to_fit_size(node_type)
		gui_utils.scale_text_to_fit_size(node_pp)
		gui_utils.scale_text_to_fit_size(node_dmg)

		gui.play_flipbook(node_icon, type_data[move_data.orig_data.type].icon)

		local color = {"lbl_pp", "lbl_dmg", "lbl_time", "lbl_range", "lbl_duration", "background", "lbl_move_power"}
		for _, node_name in pairs(color)do
			local color_name = type_data[move_data.orig_data.type].color
			local node = gui.get_node(str_node_prefix .. "/" .. node_name)
			gui.set_color(node, color_name)
		end
	end

	local instance = {}
	for name,fn in pairs(MOVE_SUMMARY) do
		instance[name] = function(...) return fn(data, ...) end
	end
	return instance
end

return M