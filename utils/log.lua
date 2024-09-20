--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local log = {}

log._version = "0.2.0"
log.usecolor = false
log.outfile = nil
log.level = "trace"
log.log_rotation_enabled = true

local max_backup_files = math.max(sys.get_config("logging.max_files") or 2, 2)-1
local max_file_size = math.max(sys.get_config("logging.max_file_size") or (1024*1024), (1024*1024))

local function write_to_file(line)
	local fp = io.open(log.outfile, "a")
	fp:write(line .. "\n")
	fp:flush()
	fp:close()
end

local function rotate_logs()
	write_to_file("#*#*# ROTATING LOGS #*#*#")
	if sys.exists(log.outfile .. "-" .. max_backup_files) then
		local _, err = os.remove(log.outfile .. "-" .. max_backup_files)
		if err then
			log.log_rotation_enabled = false
			gameanalytics.error("Error removing. Logs can't be rotated: " .. err)
			return
		end
	end
	
	for i=max_backup_files-1, 1, -1 do
		if sys.exists(log.outfile .. "-" .. i) then
			local _, err = os.rename(log.outfile .. "-" .. i, log.outfile .. "-" .. (i+1))
			if err then
				log.log_rotation_enabled = false
				gameanalytics.error("Error renaming. Logs can't be rotated: " .. err)
				return
			end
		end
	end

	local _, err = os.rename(log.outfile, log.outfile .. "-1")
	if err then
		log.log_rotation_enabled = false
		gameanalytics.critical("Error renaming base log. Logs can't be rotated: " .. err)
		return
	end
end

local function has_to_rotate_logs()
	local fp = io.open(log.outfile, "r")
	local rotate = log.log_rotation_enabled and fp:seek("end") > max_file_size
	fp:close()
	return rotate
end

function log.get_consolidated_log()
	local consolidated_log = {}
	for i=max_backup_files, 1, -1 do
		if sys.exists(log.outfile .. "-" .. i) then
			local log_fragment = io.open(log.outfile .. "-" .. i)
			table.insert(consolidated_log, log_fragment:read("*all"))
			log_fragment:close()
		end
	end
	local log_fragment = io.open(log.outfile)
	table.insert(consolidated_log, log_fragment:read("*all"))
	log_fragment:close()
	return table.concat(consolidated_log, "")
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
table.insert(buffer, "#################### LOGGER INITIALIZED ####################")

for i, x in ipairs(modes) do
	local nameupper = x.name:upper()
	log[x.name] = function(...)

		-- Return early if we're below the log level
		if i < levels[log.level] then
			return
		end

		local msg = tostring(...)
		-- modfied from 2 to 4, because now its used on gameanalytics_manager
		local info = debug.getinfo(4, "Sl")
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
		local str = string.format("[%-6s%s] %s: %s",
		nameupper, os.date(), lineinfo, msg)
		if log.outfile then
			if has_to_rotate_logs() then
				rotate_logs()
			end
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