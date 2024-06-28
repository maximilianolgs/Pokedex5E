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

function M.get_version_information()
	-- Call this through a flow
	M.BUSY = true
	local version_information = {}
	version_information.current = M.current_version()
	if M.releases == nil then
		M.get_latest()
		flow.until_true(function() return not M.BUSY end)
	end

	version_information.latest = M.releases.latest
	version_information.latest_number = M.releases[M.releases.latest].number
	version_information.latest_url = M.releases[M.releases.latest].url
	version_information.latest_win_url = M.releases[M.releases.latest].win_url
	version_information.current_number = M.releases[version_information.current] and M.releases[version_information.current].number
	version_information.up_to_date = version_information.current == M.releases.latest
	
	if version_information.current_number == nil then
		log.info("Current version not in version json")
	end

	return version_information
end

function M.current_version()
	return sys.get_config("project.version")
end

return M