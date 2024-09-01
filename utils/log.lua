--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local log = { _version = "0.1.0" }

log.usecolor = false
log.outfile = nil
log.level = "trace"
log.log_rotation_enabled = true

local max_backup_files = math.max(sys.get_config("logging.max_files") or 2, 2)-1
local max_file_size = math.max(sys.get_config("logging.max_file_size") or (2*1024*1024), (2*1024*1024))

local function rotate_logs()
	log.log_rotation_enabled = false
	log.info("rotating logs")
	log.log_rotation_enabled = true
	if sys.exists(log.outfile .. "-" .. max_backup_files) then
		local _, err = os.remove(log.outfile .. "-" .. max_backup_files)
		if err then
			log.log_rotation_enabled = false
			log.error("Error removing. Logs can't be rotated: " .. err)
			return
		end
	end
	
	for i=max_backup_files-1, 1, -1 do
		if sys.exists(log.outfile .. "-" .. i) then
			local _, err = os.rename(log.outfile .. "-" .. i, log.outfile .. "-" .. (i+1))
			if err then
				log.log_rotation_enabled = false
				log.error("Error renaming. Logs can't be rotated: " .. err)
				return
			end
		end
	end

	local _, err = os.rename(log.outfile, log.outfile .. "-1")
	if err then
		log.log_rotation_enabled = false
		log.fatal("Error renaming base log. Logs can't be rotated: " .. err)
		return
	end
end

local function write_to_file(line)
	local fp = io.open(log.outfile, "a")
	if log.log_rotation_enabled and fp:seek("end") > max_file_size then
		fp:close()
		rotate_logs()
		fp = io.open(log.outfile, "a")
	end
	fp:write(line)
	fp:close()
end

function log.generate_full_log_file(filename)
	local full_log_file = sys.get_save_file("pokedex5E", filename)
	local consolidated_log = io.open(full_log_file, "w+")
	for i=max_backup_files, 1, -1 do
		if sys.exists(log.outfile .. "-" .. i) then
			local log_fragment = io.open(log.outfile .. "-" .. i)
			consolidated_log:write(log_fragment:read("*all") .. "\n")
			log_fragment:close()
		end
	end
	local log_fragment = io.open(log.outfile)
	consolidated_log:write(log_fragment:read("*all"))
	log_fragment:close()
	consolidated_log:close()
	return full_log_file
end

local modes = {
	{ name = "trace", color = "\27[34m", },
	{ name = "debug", color = "\27[36m", },
	{ name = "info",  color = "\27[32m", },
	{ name = "warn",  color = "\27[33m", },
	{ name = "error", color = "\27[31m", },
	{ name = "fatal", color = "\27[35m", },
}


local levels = {}
for i, v in ipairs(modes) do
	levels[v.name] = i
end


local round = function(x, increment)
	increment = increment or 1
	x = x / increment
	return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end


local _tostring = tostring

local tostring = function(...)
	local t = {}
	for i = 1, select('#', ...) do
		local x = select(i, ...)
		if type(x) == "number" then
			x = round(x, .01)
		end
		t[#t + 1] = _tostring(x)
	end
	return table.concat(t, " ")
end

local buffer = {}

for i, x in ipairs(modes) do
	local nameupper = x.name:upper()
	log[x.name] = function(...)

		-- Return early if we're below the log level
		if i < levels[log.level] then
			return
		end

		local msg = tostring(...)
		local info = debug.getinfo(2, "Sl")
		local lineinfo = info.short_src .. ":" .. info.currentline

		--[[ Output to console
		print(string.format("%s[%-6s%s]%s %s: %s",
		log.usecolor and x.color or "",
		nameupper,
		os.date("%H:%M:%S"),
		log.usecolor and "\27[0m" or "",
		lineinfo,
		msg))--]]

		-- Output to console
		print(string.format("[%s] %s: %s",
		nameupper,
		lineinfo,
		msg))
		
		-- Output to log file
		local str = string.format("[%-6s%s] %s: %s\n",
		nameupper, os.date(), lineinfo, msg)
		if log.outfile then
			write_to_file(str)
		else
			table.insert(buffer, str)
		end

	end
end


function log.set_outfile(filename)
	log.outfile = filename
	if log.outfile then
		for _, line in ipairs(buffer) do
			write_to_file(line)
		end
		buffer = {}
	end
end


return log