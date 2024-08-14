local flow = require "utils.flow"

local M = {}

local read_permission_callback
local paste_clipboard_callback

local function js_listener(self, message_id, message)
	if message_id == "read_permission" then
		M.read_permission = message
		if read_permission_callback then
			read_permission_callback(message == "granted")
			jstodef.remove_listener(js_listener)
		end
	elseif message_id == "clipboard_paste" then
		if paste_clipboard_callback then
			paste_clipboard_callback(message)
			jstodef.remove_listener(js_listener)
		end
	end
end

-- check if we have permission
function M.has_read_permission(callback)
	read_permission_callback = callback
	if M.read_permission then
		read_permission_callback(M.read_permission)
	end
	jstodef.add_listener(js_listener)
	
	html5.run("check_read_permission()")
end

-- copy str to the clipboard
function M.copy(value)
	html5.run("clipboard_copy('" .. value .. "')")
end

-- read the content of the clipboard (needs permission)
function M.paste(callback)
	paste_clipboard_callback = callback
	jstodef.add_listener(js_listener)

	html5.run("clipboard_paste()")
end

return M