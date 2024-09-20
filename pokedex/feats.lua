local file = require "utils.file"
local utils = require "utils.utils"
local fakemon = require "fakemon.fakemon"
local localization = require "utils.localization"

local M = {}

local feats

local initialized = false

local function list_of_feats()
	local d = {}
	for name, description in pairs(feats) do 
		table.insert(d, name)
	end
	return d
end

function M.init()
	if not initialized then
		feats = localization.load_localized_json_from_resource("/assets/datafiles/feats.json")
		if fakemon.DATA and fakemon.DATA["feats.json"] then
			for name, data in pairs(fakemon.DATA["feats.json"]) do
				feats[name] = data
			end
		end
		M.list = list_of_feats()
		initialized = true
	end
end


function M.get_feat_description(name)
	if feats[name] then
		return feats[name].Description
	else
		gameanalytics.error(string.format("Can not find Feat: '%s'", tostring(name)) ..  "\n" .. debug.traceback())
		return "This is an error, the app couldn't find the feat"
	end
end

return M
