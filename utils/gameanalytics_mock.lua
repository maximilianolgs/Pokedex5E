local json = require "utils.json"
local log = require "utils.log"

local M = {}

function M.addDesignEvent(e)
	log.info("[Local_GA-Design_Event] " .. json:encode(e))
end

function M.addErrorEvent(e)
	log.error("[Local_GA-Error_Event] " .. json:encode(e))
end

function M.setCustomDimension01(e)
	log.info("[Local_GA-CustomDimension01] " .. e)
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