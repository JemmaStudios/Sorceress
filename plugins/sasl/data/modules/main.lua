--[[
	main.lua

]]

--------------------------------------------------------------------------------
-- Global settings
sasl.logInfo("Loading the Beck-Mahoney Sorceress by Jemma Studios...")

local settings = {}
settings["How_long_does_it_take_for_the_canopy_lock_to_move_in_seconds"] = 0.25
settings["How_long_does_it_take_for_the_canopy_to_open_or_close_in_seconds"] = 1.5
settings["How_fast_does_the_engine_turn_for_a_tach_hour"] = 2000
settings["Initial_engine_hours"] = 0
settings["How_long_does_it_take_for_each_tach_hour_digit_to_roll_next_number_in_seconds"] = 0.3

--------------------------------------------------------------------------------
-- Only one of the following lines should be uncommented
sasl.setLogLevel ( LOG_DEBUG )  -- use for development
--sasl.setLogLevel ( LOG_INFO )  -- use for distribution
--------------------------------------------------------------------------------

-- These make SASL light.  You may need to turn one or more on for high level magic
sasl.options.setAircraftPanelRendering ( true )
sasl.options.set3DRendering ( true )
sasl.options.setInteractivity ( true )

timer_lib = {}
debug_lib = {}
function debug_lib.on_debug(tString)
	if getLogLevel() == LOG_DEBUG then print ("DEBUG MODE! "..tString) end
end

debug_lib.on_debug ("********************* DEBUG MODE IS ON ************************")
debug_lib.on_debug ("*  If you are reading this I screwed up before distribution.  *")
debug_lib.on_debug ("***************************************************************")


------------------------------------------------------------------------------------
-- This would be used if you needed/wanted to read in a configuration file

config = {}
config_path = sasl.getAircraftPath ()
config_path = config_path.. "/sorceress_config.ini"

if isFileExists ( config_path ) then 
	config = sasl.readConfig ( config_path , "ini" )
	for i, v in pairs (config) do
		settings[i] = v
	end
end

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

components = {
	timer_library {},
	sorceress_control {		canopy_bolt_time = settings["How_long_does_it_take_for_the_canopy_lock_to_move_in_seconds"],
							canopy_open_time = settings["How_long_does_it_take_for_the_canopy_to_open_or_close_in_seconds"],
							engine_rpm_hour = settings["How_fast_does_the_engine_turn_for_a_tach_hour"],
							engine_hours = settings["Initial_engine_hours"],
							tach_tape_rollout = settings["How_long_does_it_take_for_each_tach_hour_digit_to_roll_next_number_in_seconds"]
						},
	jemma_flexdash {}
}

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

function onModuleDone ()
	if sasl.writeConfig ( config_path , "ini" , config) then
		sasl.logInfo ("Sorceress settings saving to "..config_path)
	else
		sasl.logError("Error writing Sorceress settings to "..config_path)
	end
end