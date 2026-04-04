local defsave = require "defsave.defsave"
local gam = require "utils.gameanalytics_manager"
local file = require "utils.file"

local M = {}

local function file_paths_to_migrate()
	local file_names = {"settings", "profiles"}
	local file_paths = {}
	local loaded = defsave.load("profiles")
	if loaded then
		local profiles = defsave.get("profiles", "profiles")
		if next(profiles) ~= nil then
			local profile_count = 0
			for _, profile in pairs(profiles.slots) do
				table.insert(file_names, profile.file_name)
				profile_count = profile_count + 1
			end
			gam.debug(profile_count .. " profiles will be migrated")

			for _, file_name in pairs(file_names) do
				file_paths[file_name] = defsave.get_file_path(file_name)
			end

			return file_paths
		end
	end
end

local function load_files_to_migrate()
	local files_to_backup = file_paths_to_migrate()
	if files_to_backup == nil then
		return
	end
	local data = {}

	for name, path in pairs(files_to_backup) do
		data[name] = sys.load(path)
	end
	
	local log_fragment = io.open(sys.get_save_file(sys.get_config("project.legacy_appname"), "log"))
	if log_fragment ~= nil then
		local consolidated_log = {}
		table.insert(consolidated_log, log_fragment:read("*all"))
		log_fragment:close()
		data["log-1"] = table.concat(consolidated_log, "")
	end
	
	return data
end

local function migrate_files(data)
	defsave.set_appname(sys.get_config("project.appname"))
	
	for file_name, file_data in pairs(data) do
		if file_name == "log-1" then
			local file_path = sys.get_save_file(sys.get_config("project.appname"), file_name)
			local out_file = io.open(file_path, "w+")
			if out_file ~= nil then
				out_file:write(file_data)
				out_file:flush()
				out_file:close()
			end
		else
			local save_file = sys.get_save_file(defsave.appname, file_name)
			sys.save(save_file, file_data)
		end
	end
end

function M.migrate()
	
	if defsave.file_exists("profiles") then
		gam.debug("No profile migration needed")
		return
	end
	
	defsave.set_appname(sys.get_config("project.legacy_appname"))
	if defsave.file_exists("profiles") then
		gam.info("Legacy profiles found. Starting migration.")
		local success, data = pcall(load_files_to_migrate)

		defsave.set_appname(sys.get_config("project.appname"))
		
		if not success then
			gam.error("Error loading files to migrate.")
			return
		end
		
		gam.debug("Files loaded successfully. Migrating...")
		local status, error_message = pcall(migrate_files, data)
		if status then
			gam.info("Migration completed.")
		else
			gam.error("Migration failed! " .. error_message)
		end
	else
		gam.info("Legacy profiles not found. No migration needed.")
	end
	defsave.set_appname(sys.get_config("project.appname"))
end

return M