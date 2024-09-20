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

function M.load_raw_file(filepath)
	local file = io.open(filepath, "rb")
	if not file then
		assert(nil, "Error loading file: " .. filepath)
	end
	local data = file:read("*all")
	file:close()
	return data
end

function M.load_file(filepath)
	local data = M.load_raw_file(filepath)
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
	
	gameanalytics.error("Unable to load json file '" .. filename .. "'")
	return nil
end

function M.write_file(filename, file_content)
	local file_path = sys.get_save_file("pokedex5E/out", filename)
	local out_file = io.open(file_path, "w+")
	assert(out_file, "Error creating file: " .. file_path)
	if type(file_content) == "table" then
		for _, chunk in ipairs(file_content) do
			assert(out_file:write(chunk), "Error writing table on file: " .. file_path)
			assert(out_file:write("\n"), "Error writing table on file: " .. file_path)
		end
	else
		assert(out_file:write(file_content), "Error writing on file: " .. file_path)
	end
	out_file:flush()
	out_file:close()
	return file_path
end

return M