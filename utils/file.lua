local log = require "utils.log"
local ljson = require "utils.json"
local settings = require "pokedex.settings"

local M = {}

function M.load_json(j)
	local json_data = nil
	-- Use pcall to catch possible parse errors so that we can print out the name of the file that we failed to parse
	if pcall(function() json_data = ljson:decode(j) end) then
		return json_data
	else
		return nil
	end
end

function M.load_file(filepath)
	local file = io.open(filepath, "rb")
	if not file then
		assert(nil, "Error loading file: " .. filepath)
	end
	local data = file:read("*all")
	file:close()
	if pcall(function() json_data = json.decode(data) end) then
		return json_data
	else
		assert(nil, "Error parsing json data from file: " .. filepath)
		return json_data
	end
end

function M.load_resource(filename)
	file = sys.load_resource(filename)
	return file
end

function M.load_json_from_resource(filename)
	local file = M.load_resource(filename)
	if file then
		local json_data = M.load_json(file)
		-- Use pcall to catch possible parse errors so that we can print out the name of the file that we failed to parse
		if json_data == nil then
			assert(nil, "Error parsing json data from file: " .. filename)
		end
		return json_data
	end

	local e = "Unable to load json file '" .. filename .. "'"
	gameanalytics.addErrorEvent {
		severity = gameanalytics.SEVERITY_ERROR,
		message = e
	}
	log.error(e)
	return nil
end

return M