local file = require "utils.file"
local settings = require "pokedex.settings"
local log = require "utils.log"

local M = {}

M.dictionary = {}

M.LOCALIZATION_ASSETS_ROOT = "/assets/localization/"

M.DEFAULT_LANG = "en_us"

function M.init()
	if not settings.get("lang") then
		settings.set("lang", M.DEFAULT_LANG)
		log.info("default lang set " .. settings.get("lang"))
	end
end

-- the default string.lower() doesn't handle all characters
function M.lower(str)
	local sLowercase = str:lower()
	sLowercase = sLowercase:gsub("Ñ", "ñ")
	sLowercase = sLowercase:gsub("Á", "á")
	sLowercase = sLowercase:gsub("É", "é")
	sLowercase = sLowercase:gsub("Í", "í")
	sLowercase = sLowercase:gsub("Ó", "ó")
	sLowercase = sLowercase:gsub("Ú", "ú")
	sLowercase = sLowercase:gsub("Ü", "ü")
	return sLowercase
end

-- the default string.upper() doesn't handle all characters
function M.upper(str)
	local sUppercase = str:upper()
	sUppercase = sUppercase:gsub("ñ", "Ñ")
	sUppercase = sUppercase:gsub("á", "Á")
	sUppercase = sUppercase:gsub("é", "É")
	sUppercase = sUppercase:gsub("í", "Í")
	sUppercase = sUppercase:gsub("ó", "Ó")
	sUppercase = sUppercase:gsub("ú", "Ú")
	sUppercase = sUppercase:gsub("ü", "Ü")
	return sUppercase
end

local function remove_accents(str)
	local accent_table = {}
	accent_table["ñ"] = "n"
	accent_table["á"] = "a"
	accent_table["é"] = "e"
	accent_table["í"] = "i"
	accent_table["ó"] = "o"
	accent_table["ú"] = "u"
	accent_table["ü"] = "u"
	accent_table["Ñ"] = "N"
	accent_table["Á"] = "A"
	accent_table["É"] = "E"
	accent_table["Í"] = "I"
	accent_table["Ó"] = "O"
	accent_table["Ú"] = "U"
	accent_table["Ü"] = "U"
	
	local o_str = ""
	for strChar in string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)") do
		if accent_table[strChar] ~= nil then
			o_str = o_str..accent_table[strChar]
		else
			o_str = o_str..strChar
		end
	end
	return o_str
end

function M.get(source, key, default)
	if not source or not key or not default then
		local e = "source " .. (source or "missing") .. ", key" .. (key or "missing") .. ", default " .. (default or "missing")
		gameanalytics.addErrorEvent {
			severity = gameanalytics.SEVERITY_CRITICAL,
			message = e
		}
		log.fatal(e)
		return default or ""
	end
	
	if source == "" or key == "" then
		local e = "source or key empty: " .. source .. "/" .. key
		gameanalytics.addErrorEvent {
			severity = gameanalytics.SEVERITY_ERROR,
			message = e
		}
		log.error(e)
		return default
	end

	if not M.dictionary[source] then
		M.dictionary[source] = file.load_json_from_resource(M.LOCALIZATION_ASSETS_ROOT .. source .. ".json")
	end

	if not M.dictionary[source] then
		local e = "Error loading localization file '" .. M.LOCALIZATION_ASSETS_ROOT .. source .. ".json'"
		gameanalytics.addErrorEvent {
			severity = gameanalytics.SEVERITY_ERROR,
			message = e
		}
		log.error(e)
		return default
	end

	local lkey = key:lower()

	if not M.dictionary[source][lkey] or not M.dictionary[source][lkey][settings.get("lang")] then
		local e = "Key " .. lkey .. "/" .. settings.get("lang") .. " not found on file " .. M.LOCALIZATION_ASSETS_ROOT .. source .. ".json"
		gameanalytics.addErrorEvent {
			severity = gameanalytics.SEVERITY_WARNING,
			message = e
		}
		log.warn(e)
		return default
	end
	
	return M.dictionary[source][lkey][settings.get("lang")]
end

function M.get_upper(source, key, default)
	local result = M.get(source, key, default)
	if result then
		result = M.upper(result)
	end
	return result
end

function M.get_lower(source, key, default)
	local result = M.get(source, key, default)
	if result then
		result = M.lower(result)
	end
	return result
end

function M.translate_table(source, prefix, table)
	local t = {}
	if table ~= nil then
		for i,v in ipairs(table) do
			t[i] = M.get(source, prefix .. v, v)
		end
	end
	return t
end

function M.comparator(a, b)
	return remove_accents(a) < remove_accents(b)
end

-- sorts the native table by it's localized names
function M.sort_table(source, prefix, tbl)
	if tbl ~= nil then
		table.sort(tbl, function(a,b) return M.comparator(M.get(source, prefix .. a, a), M.get(source, prefix .. b, b)) end)
	end
end

local function get_localized_filename(filename)
	local localized_filename = filename
	if settings.get("lang") ~= M.DEFAULT_LANG then
		local extension = filename:match("^.+(%..+)$")
		if extension then
			localized_filename = filename:sub(1, (#filename - #extension)) .. "-" .. settings.get("lang") .. extension
		else
			localized_filename = filename .. "-" .. settings.get("lang")
		end
	end
	return localized_filename
end

function M.load_localized_json_from_resource(filename)
	lfilename = get_localized_filename(filename)
	localized_file = file.load_json_from_resource(lfilename)

	if localized_file then
		return localized_file
	else
		local e = lfilename .. " not found. Returning default file."
		gameanalytics.addErrorEvent {
			severity = gameanalytics.SEVERITY_WARNING,
			message = e
		}
		log.warn(e)
		return file.load_json_from_resource(filename)
	end
end

return M