local log = require "utils.log"
local settings = require "pokedex.settings"
local platform = require "utils.platform"
local json = require "utils.json"

local M = {}

-- https://gameanalytics.com/docs/item/ga-data
-- https://gameanalytics.com/docs/item/resource-events
local gameanalytics_keys = {
	["Windows"	] = "gameanalytics.game_key_windows",
	["Android"	] = "gameanalytics.game_key_android",
	["HTML5"	] = "gameanalytics.game_key_html5",
	["iPhone OS"] = "gameanalytics.game_key_ios"
}

M.SEVERITY_DEBUG = "Debug"
M.SEVERITY_INFO = "Info"
M.SEVERITY_WARNING = "Warning"
M.SEVERITY_ERROR = "Error"
M.SEVERITY_CRITICAL = "Critical"

local gameanalytics_severity = {
	[M.SEVERITY_DEBUG] = 0,
	[M.SEVERITY_INFO] = 1,
	[M.SEVERITY_WARNING] = 2,
	[M.SEVERITY_ERROR] = 3,
	[M.SEVERITY_CRITICAL] = 4
}

local log_method = {
	[M.SEVERITY_DEBUG	] = "debug",
	[M.SEVERITY_INFO	] = "info",
	[M.SEVERITY_WARNING	] = "warn",
	[M.SEVERITY_ERROR	] = "error",
	[M.SEVERITY_CRITICAL] = "fatal",
}

local log_level = gameanalytics_severity[M.SEVERITY_DEBUG]

local function log_to_file(msg)
	log.info(msg)
end

local function ga_remote_config_listener()
	local raw_config = gameanalytics.getRemoteConfigsContentAsString()
	if raw_config and raw_config ~= "{}" then
		--use pcall to test this w/o breaking anything
		--use notify.notify(message) to see the results in the app
		-- Placeholder for config handling
		--pprint(raw_config)
		
		--works on html, doesn't in windows
		--raw_config = gameanalytics.getRemoteConfigsValueAsString({key="test"})
		--pprint(raw_config)
		
		--works on windows, doesn't in html (sometimes it works)
		--raw_config = gameanalytics.getRemoteConfigsContentAsString()
		--pprint(raw_config)
		--local remote_config = json:decode(raw_config)
	end
end

local function addErrorEvent(ee)
	if gameanalytics_severity[ee.severity] < log_level then
		return
	end
	if settings.get("ga_error_report", true) and M.core then
		log[log_method[ee.severity]](ee.message)
		M.core.addErrorEvent(ee)
	else
		log[log_method[ee.severity]]("[Local_GA-Error_Event] " .. ee.message)
	end
end

-- create a method for every severity
for name, level in pairs(gameanalytics_severity) do
	M[name:lower()] = function(...)
		local msg = tostring(...)
		addErrorEvent({severity=name, message=msg})
	end
end

local function send_crash_on_start()
	local handle = crash.load_previous()
	if handle then
		M.critical(crash.get_extra_data(handle))
		crash.release(handle)
	end
end

function M.init()
	--M.setRemoteConfigsListener(ga_remote_config_listener)
	
	-- DEFAULT LOG LEVEL, SHOULD BE PART OF CONFIGURATION
	log_level = gameanalytics_severity[M.SEVERITY_INFO]
	
	-- manual start can be done here
	send_crash_on_start()
end

function M.set_log_level(level)
	if gameanalytics_severity[level] then
		log_level = gameanalytics_severity[level]
	end
end

function M.addDesignEvent(de)
	if settings.get("ga_design_events", true) and M.core then
		M.core.addDesignEvent(de)
	else
		log_to_file("[Local_GA-Design_Event] " .. json:encode(de))
	end
end

function M.setCustomDimension01(d)
	if M.core then
		M.core.setCustomDimension01(d)
	else
		log_to_file("[Local_GA-CustomDimension01] " .. d)
	end
end

function M.setRemoteConfigsListener(fn)
	if M.core then
		M.core.setRemoteConfigsListener(fn)
	else
		log_to_file("[Local_GA-setRemoteConfigsListener]")
	end
end

function M.getRemoteConfigsContentAsString()
	if M.core then
		return M.core.getRemoteConfigsContentAsString()
	else
		log_to_file("[Local_GA-RemoteConfigsContentAsString]")
		return "{}"
	end
end

function M.getRemoteConfigsValueAsString(options)
	if M.core then
		return M.core.getRemoteConfigsValueAsString(options)
	else
		log_to_file("[Local_GA-RemoteConfigsValueAsString] " .. json:encode(options))
		return nil
	end
end

function M.final()
	-- placeholder for manual end
end

log.set_outfile(sys.get_save_file("pokedex5E", "log"))
local ga_config = sys.get_config(gameanalytics_keys[platform.CURRENT])
if not gameanalytics or ga_config == nil or ga_config == "" then
	M.info("Skipping GameAnalytics")
else
	M.core = gameanalytics
end
gameanalytics = M

return M