local flow = require "utils.flow"
local log = require "utils.log"

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
		gameanalytics.addErrorEvent {
			severity = gameanalytics.SEVERITY_CRITICAL,
			message = e
		}
		log.fatal(e)
	end
end

jstodef.add_listener(js_listener)

-- copy str to the clipboard
function M.copy(value, callback)
	copy_clipboard_callback = callback
	value = value:gsub("\\", "\\\\")
	value = value:gsub("'", "\\'")
	value = value:gsub("\\n", "\\\\n")
	html5.run("clipboard_copy('" .. value .. "')")
end

-- read the content of the clipboard
function M.paste_listener(callback)
	paste_clipboard_callback = callback
	html5.run("clipboard_paste_listener()")
end

return M