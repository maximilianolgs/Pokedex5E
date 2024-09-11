local flow = require "utils.flow"

local M = {}

local copy_clipboard_callback
local paste_clipboard_callback

local function js_listener(self, message_id, message)
	if message_id == "clipboard_copy" then
		if copy_clipboard_callback then
			copy_clipboard_callback(message)
		end
	elseif message_id == "clipboard_paste" then
		if paste_clipboard_callback then
			paste_clipboard_callback(message)
		end
	end
end

jstodef.add_listener(js_listener)

-- copy str to the clipboard
function M.copy(value, callback)
	copy_clipboard_callback = callback
	html5.run("clipboard_copy('" .. value .. "')")
end

-- read the content of the clipboard
function M.paste_listener(callback)
	paste_clipboard_callback = callback
	html5.run("clipboard_paste_listener()")
end

return M