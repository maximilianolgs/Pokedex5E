local screeninfo = require "utils.screeninfo"

local M = {}

function M.get_window_scale()
	local layout_size = vmath.vector3(screeninfo.get_project_width(), screeninfo.get_project_height(), 0)
	local screen_size = vmath.vector3(screeninfo.get_window_width(), screeninfo.get_window_height(), 0)

	local sx, sy = screen_size.x / layout_size.x, screen_size.y / layout_size.y -- scale coef for x and y
	return sx, sy
end

function M.get_scale_coefficients()
	local sx, sy = M.get_window_scale()

	local sx2, sy2 = sx/sy, sy/sx

	local scale = math.min(sx2, sy2) -- Fit scale coefficient 
	return scale, sx2, sy2
end

function M.scale_fit_node_with_stretch(node)
	local scale, sx2, sy2 = M.get_scale_coefficients()
	local node_size = gui.get_size(node) -- Get current size

	node_size.y = (node_size.y/scale) * (1/sx2) -- We divide by fit to cancel the fit transformation and then apply a stretch by multiplying (1/sy)

	gui.set_size(node, node_size)
end

function M.scale_text_with_line_breaks(text_node)
	local size = gui.get_size(text_node)
	local metrics = gui.get_text_metrics_from_node(text_node)
	local scale = gui.get_scale(text_node)
	if metrics.height <= size.y then
		return
	end
	
	-- if it has overflow
	-- correction
	local correction = size.y / metrics.height
	local target_size_y = size.y*scale.y
	local new_scale = scale.y * correction

	local target_size_x = size.x*scale.x
	
	gui.set_scale(text_node, vmath.vector3(new_scale))
	gui.set_size(text_node, vmath.vector3(size.x*(1/correction), size.y, size.z))
	metrics = gui.get_text_metrics_from_node(text_node)
	
	-- fits perfect
	if size.y*scale.y == metrics.height*new_scale then
		return
	end
	
	-- the new line break made it too little, let's find out if we can do better
	local min = new_scale
	local max = scale.y
	local iteration = 0
	
	repeat
		size = gui.get_size(text_node)
		if (metrics.height * new_scale) > target_size_y then
			max = new_scale
		else
			min = new_scale
		end
		local mid_point = (min + max) / 2
		correction = mid_point / new_scale
		new_scale = new_scale*correction

		gui.set_scale(text_node, vmath.vector3(new_scale))
		gui.set_size(text_node, vmath.vector3(target_size_x / new_scale, size.y, size.z))
		metrics = gui.get_text_metrics_from_node(text_node)
		
		iteration = iteration +1
	until((metrics.height * new_scale) == target_size_y or iteration == 10)
	-- we tried enough
	if iteration == 10 then
		correction = min / new_scale
		new_scale = new_scale * correction
		gui.set_scale(text_node, vmath.vector3(new_scale))
		gui.set_size(text_node, vmath.vector3(target_size_x / new_scale, size.y, size.z))
	end
end

function M.scale_text_to_fit_size(text_node)
	local metrics = gui.get_text_metrics_from_node(text_node)
	local scale = gui.get_scale(text_node)
	local size = gui.get_size(text_node)
	local text_width = scale.x * metrics.width
	local node_width = scale.x * size.x
	if text_width > node_width then
		local new_scale = node_width / text_width
		gui.set_scale(text_node, vmath.vector3(new_scale * scale.x))
	end
end

function M.scale_text_to_fit_parent_size(text_node)
	local metrics = gui.get_text_metrics_from_node(text_node)
	local scale = gui.get_scale(text_node)
	local text_width = scale.x * metrics.width
	local node_width = gui.get_size(gui.get_parent(text_node)).x
	if text_width > node_width then
		local new_scale = node_width / text_width
		gui.set_scale(text_node, vmath.vector3(new_scale * scale.x))
	end
end

local function resize_node_to_match_text(node, text_node)
	local metrics = gui.get_text_metrics_from_node(text_node)
	local node_size = gui.get_size(node)
	node_size.x = metrics.width
	node_size.y = metrics.height
	gui.set_size(node, node_size)
end

function M.resize_parent_to_match_text(text_node)
	resize_node_to_match_text(gui.get_parent(text_node), text_node)
end

function M.resize_to_match_text(text_node)
	resize_node_to_match_text(text_node, text_node)
end

function M.scale_group_text_to_fit_x(fn_fit, ...)
	nodes = {...}
	group_scale = nil
	for i,v in ipairs(nodes) do
		fn_fit(v)
		if not group_scale or group_scale.x > gui.get_scale(v).x then
			group_scale = gui.get_scale(v)
		end
	end

	for i,v in ipairs(nodes) do
		gui.set_scale(v, group_scale)
	end
end

function M.scale_group_text_to_fit_size(...)
	return M.scale_group_text_to_fit_x(M.scale_text_to_fit_size, ...)
end

function M.scale_group_text_to_fit_parent_size(...)
	return M.scale_group_text_to_fit_x(M.scale_text_to_fit_parent_size, ...)
end

-- Second function that assumes a base text scale of 1 is acceptable. This is better than the above function
-- because it cane be called multiple times without ruining the text. We should consolidate, but at the moment some
-- of the calls to scale_text_to_fit_size sometimes have text nodes with non-1 scales.
function M.scale_text_to_fit_size_2(text_node)
	gui.set_scale(text_node, vmath.vector3(1))
	M.scale_text_to_fit_size(text_node)
end

function M.adjust_for_text_change_vertical(node_text, text_new, nodes_change_size, nodes_shift_down, nodes_shift_up)
	if type(node_text) == "string" then
		node_text = gui.get_node(node_text)
	end
	local metrics_text_before = gui.get_text_metrics_from_node(node_text)
	gui.set_text(node_text, text_new)
	local metrics_text_after = gui.get_text_metrics_from_node(node_text)
	local diff_height = metrics_text_after.height - metrics_text_before.height
	
	if diff_height ~= 0 then
		if nodes_change_size ~= nil then
			for i=1,#nodes_change_size do
				local node = nodes_change_size[i]
				if type(node) == "string" then
					node = gui.get_node(node)
				end
				local size = gui.get_size(node)
				size.y = size.y + diff_height
				gui.set_size(node, size)
			end
		end

		if nodes_shift_down ~= nil then
			for i=1,#nodes_shift_down do
				-- TODO: Could account for pivot here to determine how much shifting to do
				local node = nodes_shift_down[i]
				if type(node) == "string" then
					node = gui.get_node(node)
				end
				local pos = gui.get_position(node)
				pos.y = pos.y - diff_height/2
				gui.set_position(node, pos)
			end
		end

		if nodes_shift_up ~= nil then
			for i=1,#nodes_shift_up do
				-- TODO: Could account for pivot here to determine how much shifting to do
				local node = nodes_shift_up[i]
				if type(node) == "string" then
					node = gui.get_node(node)
				end
				local pos = gui.get_position(node)
				pos.y = pos.y + diff_height/2
				gui.set_position(node, pos)
			end
		end
	end

	return diff_height
end

return M
