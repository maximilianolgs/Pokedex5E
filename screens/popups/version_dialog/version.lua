local flow = require "utils.flow"
local log = require "utils.log"

local M = {}

local version_url = "https://raw.githubusercontent.com/maximilianolgs/Pokedex5E/master/assets/datafiles/releases.json"

M.BUSY = false

M.releases = nil

function M.get_latest()
	http.request(version_url, "GET", function(self, id, res)
		if res.status == 200 or res.status == 304 then
			M.releases = json.decode(res.response)
		else
			M.releases = nil
			gameanalytics.addErrorEvent {
				severity = "Warning",
				message = "Version:LoadIndex:HTTP:" .. res.status 
			}
			log.info("Version:BAD STATUS:" .. res.status)
			log.info(res.response)
		end
		M.BUSY = false
	end)
end

function M.check_version()
	-- Call this through a flow
	M.BUSY = true
	local current_version = M.current_version()
	if M.releases == nil then
		M.get_latest()
		flow.until_true(function() return not M.BUSY end)
	end
	
	if M.releases[current_version] == nil then
		log.info("Current version not in version json")
		return
	end

	return M.releases.latest == current_version, M.releases[M.releases.latest].number - M.releases[current_version].number, M.releases[M.releases.latest].url
end

function M.current_version()
	return sys.get_config("project.version")
end

return M