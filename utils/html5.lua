local flow = require "utils.flow"
local platform = require "utils.platform"

local M = {}

local copy_clipboard_callback
local paste_clipboard_callback

local function js_listener(self, message_id, message)
	local e = nil
	if message_id == "clipboard_copy" then
		if copy_clipboard_callback then
			copy_clipboard_callback(message)
		else
			e = "Missing copy_clipboard_callback"
		end
	elseif message_id == "clipboard_paste" then
		if paste_clipboard_callback then
			paste_clipboard_callback(message)
		else
			e = "Missing paste_clipboard_callback"
		end
	else
		e = "Unhandled message_id " .. message_id
	end
	if e then
		gameanalytics.critical(e)
	end
end

if platform.WEB then
	jstodef.add_listener(js_listener)
end

local function escape_characters(str)
	str = str:gsub("\\", "\\\\")
	str = str:gsub("'", "\\'")
	str = str:gsub("\n", "\\n")
	str = str:gsub("\r", "\\r")
	return str
end

-- copy str to the clipboard
function M.copy(value, callback)
	copy_clipboard_callback = callback
	value = escape_characters(value)
	html5.run("clipboard_copy('" .. value .. "')")
end

-- read the content of the clipboard
function M.paste_listener(callback)
	paste_clipboard_callback = callback
	html5.run("clipboard_paste_listener()")
end

local function download_file(filename, file_content, file_type)	
	html5.run("download_file('" .. filename .. "', '" .. file_type .. "', '" .. file_content .. "')")
end

function M.download_text_file(filename, file_content)
	file_content = escape_characters(file_content)
	download_file(filename, file_content, "text/plain")
end

return M