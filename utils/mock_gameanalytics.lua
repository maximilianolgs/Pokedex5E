local json = require "utils.json"
local log = require "utils.log"

local M = {}

function M.addDesignEvent(e)
	log.info("[Mock_GA-Design_Event] " .. json:encode(e))
end

function M.addErrorEvent(e)
	log.error("[Mock_GA-Error_Event] " .. json:encode(e))
end

function M.setCustomDimension01(e)
	log.info("[Mock_GA-CustomDimension01] " .. e)
end

function M.setRemoteConfigsListener(fn)
end

M.mock = true

return M