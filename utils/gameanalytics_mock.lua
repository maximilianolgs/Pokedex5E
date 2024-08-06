local json = require "utils.json"
local log = require "utils.log"

local M = {}

function M.addDesignEvent(event)
	log.info("[Local_GA-Design_Event] " .. json:encode(event))
end

function M.addErrorEvent(event)
	log.error("[Local_GA-Error_Event] " .. json:encode(event))
end

function M.setCustomDimension01(d)
	log.info("[Local_GA-CustomDimension01] " .. d)
end

function M.setRemoteConfigsListener(fn)
end

function M.getRemoteConfigsContentAsString()
	log.info("[Local_GA-RemoteConfigsContentAsString]")
	return "{}"
end

function M.getRemoteConfigsValueAsString(options)
	log.info("[Local_GA-RemoteConfigsValueAsString] " .. json:encode(options))
	return nil
end

M.mock = true

return M