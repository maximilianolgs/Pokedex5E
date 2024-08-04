local log = require "utils.log"
local settings = require "pokedex.settings"
local mock = require "utils.gameanalytics_mock"
local platform = require "utils.platform"

local M = {}
M.core = {}

-- https://gameanalytics.com/docs/item/ga-data
-- https://gameanalytics.com/docs/item/resource-events
local gameanalytics_keys = {
	["Windows"] = "gameanalytics.game_key_windows",
	["Android"] = "gameanalytics.game_key_android",
	["HTML5"] = "gameanalytics.game_key_html5",
	["iPhone OS"] = "gameanalytics.game_key_ios"
}

local function ga_remote_config_listener()
	local raw_config = gameanalytics.getRemoteConfigsContentAsString()
	if raw_config and raw_config ~= "{}" then
		--use pcall to test this w/o breaking anything
		--use notify.notify(message) to see the results in the app
		-- Placeholder for config handling
		log.info(raw_config)
		--works on html, doesn't in windows
		raw_config = gameanalytics.getRemoteConfigsValueAsString({key="test"})
		log.info(raw_config)
		--works on windows, doesn't in html (sometimes it works)
		raw_config = gameanalytics.getRemoteConfigsContentAsString()
		log.info(raw_config)
		--local remote_config = json.decode(raw_config)
	end
end

local function send_crash_on_start()
	local handle = crash.load_previous()
	if handle then
		M.addErrorEvent {
			severity = "Error",
			message =  crash.get_extra_data(handle)
		}
		crash.release(handle)
	end
end

function M.init()
	local ga_config = sys.get_config(gameanalytics_keys[platform.CURRENT])
	if not gameanalytics or ga_config == nil or ga_config == "" then
		log.info("Skipping GameAnalytics")
	else
		M.core = gameanalytics
	end
	gameanalytics = M
	M.setRemoteConfigsListener(ga_remote_config_listener)

	-- manual start can be done here
	send_crash_on_start()
end

function M.addDesignEvent(de)
	if settings.get("ga_design_events", true) and M.core then
		M.core.addDesignEvent(de)
	else
		mock.addDesignEvent(de)
	end
end

function M.addErrorEvent(ee)
	if settings.get("ga_error_report", true) and M.core then
		M.core.addErrorEvent(ee)
	else
		mock.addErrorEvent(ee)
	end
end

function M.setCustomDimension01(d)
	if M.core then
		M.core.setCustomDimension01(d)
	else
		mock.setCustomDimension01(d)
	end
end

function M.setRemoteConfigsListener(fn)
	if M.core then
		M.core.setRemoteConfigsListener(fn)
	else
		mock.setRemoteConfigsListener(fn)
	end
end

function M.getRemoteConfigsContentAsString()
	if M.core then
		return M.core.getRemoteConfigsContentAsString()
	else
		return mock.getRemoteConfigsContentAsString()
	end
end

function M.getRemoteConfigsValueAsString(options)
	if M.core then
		return M.core.getRemoteConfigsValueAsString(options)
	else
		return mock.getRemoteConfigsValueAsString(options)
	end
end

function M.final()
	-- placeholder for manual end
end

return M