--[[
    sorceress_flexdash.lua

    sample new instrument in instrument.json
    "gauge_show_1": "1",
    "gauge_show_1__type__": "number",
    "gauge_xpos_1": "0",
    "gauge_xpos_1__type__": "number",
    "gauge_zpos_1": "0",
    "gauge_zpos_1__type__": "number",
    "gauge_name_1": "CHT (3 1\/8\")",
    "gauge_name_1__type__": "string",
    "gauge_static_1": "1",
    "gauge_static_1__type__": "number",
    "group_id_1": "0",
    "group_id_1__type__": "number",

 ]]

defineProperty ("popup_timeout", 3) -- number of seconds popup windows stay on

local saved = true

-- constants used to track which command was used to try to close the acf without saving the dash.
CMD_CLEAR = 0
CMD_FLIGHT_CONFIG = 1
CMD_QUIT = 2
CMD_RELOAD_ACF = 3
CMD_RELOAD_ACF_NOART = 4

-- used by flexdash_configuration component.
fd_config_flags = {}
fd_config_flags["close"] = true
local fd_ui_old_open = true

-- used by flexdash_saverestore component.
savefirst_flags = {}
savefirst_flags["close"] = false
savefirst_flags["doSave"] = false
savefirst_flags["doRestore"] = false
savefirst_flags["exit_command"] = CMD_CLEAR

num_instruments = 22

ttable = {}
for i = 1, num_instruments do
    table.insert(ttable, 0)
end


fd_ui = {}
fd_ui["flag"] = false
fd_ui["moved"] = false

for i = 1, num_instruments do
    table.insert(fd_ui, false)
end

gauge_show = createGlobalPropertyia ("sorceress/flexdash/gauge_show", ttable)
gauge_xpos = createGlobalPropertyfa ("sorceress/flexdash/gauge_xpos", ttable)
gauge_zpos = createGlobalPropertyfa ("sorceress/flexdash/gauge_zpos", ttable)
gauge_move = createGlobalPropertyfa ("sorceress/flexdash/gauge_move", ttable)
gauge_static = ttable

xp_network_time = globalPropertyf ("sim/network/misc/network_time_sec")

flexdash_config = {}
flexdash_settings = {}
flexdash_preset_settings = {}  -- used to save the unintelligent json information

showhide_name = {"Show ", "Hide "}

function check_exit_commands()
    if savefirst_flags["exit_command"] == CMD_FLIGHT_CONFIG then
        sasl.commandOnce(xp_flight_config_cmd)
    elseif savefirst_flags["exit_command"] == CMD_QUIT then
        sasl.commandOnce(xp_quit_cmd)

-- Strangely XP crashes if we activate these commands.  Users will just have to select reload again after they save/restore.
    -- elseif savefirst_flags["exit_command"] == CMD_RELOAD_ACF then
    --     sasl.commandOnce(xp_reload_acf_cmd)
    -- elseif savefirst_flags["exit_command"] == CMD_RELOAD_ACF_NOART then
    --     sasl.commandOnce(xp_reload_acf_noart_cmd)
    end
    savefirst_flags["exit_command"] = CMD_CLEAR
end

instrument_file = sasl.getProjectPath() .. "/Custom Module/data/instruments.json"

function load_instruments()
    fd_ui["moved"] = false

    if isFileExists ( instrument_file ) then 
        sasl.logInfo ("Sorceress FlexDash: loading instruments from ".. instrument_file)
        flexdash_config = sasl.readConfig ( instrument_file , "JSON" )
        for i, v in pairs (flexdash_config) do
            flexdash_settings[i] = v
        end
        for i=1, num_instruments do
            gauge_static[i] = flexdash_settings["gauge_static_"..i]
        end    
        savefirst_flags["doRestore"] = false
        check_exit_commands()
    else
        sasl.logWarning ("Sorceress FlexDash: Could not find/load ".. instrument_file)
    end
end

function load_preset ()
    preset_file = sasl.getProjectPath() .. "/Custom Module/data/preset"..flexdash_settings["preset"]..".json"
    local fd_preset = {}
    local fd_preset_tSettings = {}
    if isFileExists (preset_file) then
        sasl.logInfo ("Sorceress FlexDash: loading preset ".. instrument_file)
        local i, v
        fd_preset = sasl.readConfig (preset_file, "JSON")
        for i, v in pairs (fd_preset) do
            flexdash_preset_settings[i] = v
        end
        set (gauge_show, 1, 3)
        for i = 1, 11 do
            if i == 10 then
                set (gauge_show, 1, flexdash_preset_settings["lg_id_"..i])
                flexdash_settings["gauge_show_"..flexdash_preset_settings["lg_id_"..i]] = 1
            else
                set (gauge_show, 0, flexdash_preset_settings["lg_id_"..i])
                set (gauge_show, 0, flexdash_preset_settings["sm_id_"..i])            
                if flexdash_preset_settings["show_"..i] == 1 then
                    if flexdash_preset_settings["which_one_"..i] == 1 then
                        set (gauge_show, 1, flexdash_preset_settings["lg_id_"..i])
                    else
                        set (gauge_show, 1, flexdash_preset_settings["sm_id_"..i])
                    end
                end
            end
            -- set the small instrument position to same position as the large instrument
            set (gauge_xpos, flexdash_preset_settings["pos_x_"..i], flexdash_preset_settings["lg_id_"..i])
            set (gauge_xpos, flexdash_preset_settings["pos_x_"..i], flexdash_preset_settings["sm_id_"..i])
            set (gauge_zpos, flexdash_preset_settings["pos_z_"..i], flexdash_preset_settings["lg_id_"..i])
            set (gauge_zpos, flexdash_preset_settings["pos_z_"..i], flexdash_preset_settings["sm_id_"..i])
            flexdash_settings["group_id_"..flexdash_preset_settings["lg_id_"..i]] = i
            flexdash_settings["group_id_"..flexdash_preset_settings["sm_id_"..i]] = i
        end
    else
        for i = 1, 11 do
            flexdash_preset_settings["show_"..i] = 0
            flexdash_preset_settings["move_"..i] = 0
            flexdash_preset_settings["which_one_"..i] = 1
        end
        flexdash_preset_settings["lg_id_1"] = 4
        flexdash_preset_settings["sm_id_1"] = 8
        flexdash_preset_settings["lg_id_2"] = 2
        flexdash_preset_settings["sm_id_2"] = 11
        flexdash_preset_settings["lg_id_3"] = 5
        flexdash_preset_settings["sm_id_3"] = 9
        flexdash_preset_settings["lg_id_4"] = 15
        flexdash_preset_settings["sm_id_4"] = 16
        flexdash_preset_settings["lg_id_5"] = 17
        flexdash_preset_settings["sm_id_5"] = 18
        flexdash_preset_settings["lg_id_6"] = 13
        flexdash_preset_settings["sm_id_6"] = 14
        flexdash_preset_settings["lg_id_7"] = 1
        flexdash_preset_settings["sm_id_7"] = 10
        flexdash_preset_settings["lg_id_8"] = 19
        flexdash_preset_settings["sm_id_8"] = 20
        flexdash_preset_settings["lg_id_9"] = 21
        flexdash_preset_settings["sm_id_9"] = 22
        flexdash_preset_settings["lg_id_10"] = 3
        flexdash_preset_settings["sm_id_10"] = 3
        flexdash_preset_settings["lg_id_11"] = 12
        flexdash_preset_settings["sm_id_11"] = 12
        flexdash_preset_settings["pos_x_1"] = 0
        flexdash_preset_settings["pos_z_1"] = 0
        flexdash_preset_settings["pos_x_2"] = 0
        flexdash_preset_settings["pos_z_2"] = 0
        flexdash_preset_settings["pos_x_3"] = 0
        flexdash_preset_settings["pos_z_3"] = 0
        flexdash_preset_settings["pos_x_4"] = 0
        flexdash_preset_settings["pos_z_4"] = 0
        flexdash_preset_settings["pos_x_5"] = 0
        flexdash_preset_settings["pos_z_5"] = 0
        flexdash_preset_settings["pos_x_6"] = 0
        flexdash_preset_settings["pos_z_6"] = 0
        flexdash_preset_settings["pos_x_7"] = 0
        flexdash_preset_settings["pos_z_7"] = 0
        flexdash_preset_settings["pos_x_8"] = 0
        flexdash_preset_settings["pos_z_8"] = 0
        flexdash_preset_settings["pos_x_9"] = 0
        flexdash_preset_settings["pos_z_9"] = 0
        flexdash_preset_settings["pos_x_10"] = 0
        flexdash_preset_settings["pos_z_10"] = 0
        flexdash_preset_settings["pos_x_11"] = 0
        flexdash_preset_settings["pos_z_11"] = 0
    end
end
load_instruments()
load_preset()

fd_config_flags["old_preset"] = flexdash_settings["preset"]

local pop_w = 400
local pop_h = 200

screen_x, screen_y, screen_width, screen_height = sasl.windows.getScreenBoundsGlobal ()
local pop_x = (screen_width-pop_w)/2
local pop_y = (screen_height-pop_h)/2

local popup_error = contextWindow {
    name			= "File Save Error",
    position		= {pop_x, pop_y, pop_w, pop_h},
    noResize		= true,
    visible			= false,
    noBackground    = true,
    vrAuto			= true,
    noDecore        = true,
    components		= {flexdash_popup{position={0, 0, pop_w, pop_h}, message="Error Saving File.\nCheck log.txt"}},
}

local popup_saved = contextWindow {
    name			= "Save Success",
    position		= {pop_x, pop_y, pop_w, pop_h},
    noResize		= true,
    visible			= false,
    noBackground    = true,
    vrAuto			= true,
    noDecore        = true,
    components		= {flexdash_popup{position={0, 0, pop_w, pop_h}, message="FlexDash Configuration Saved"}},
}

local popup_savefirst = contextWindow {
    name			= "Save Warning",
    position		= {pop_x, pop_y, pop_w, pop_h},
    noResize		= true,
    visible			= false,
    noBackground    = true,
    vrAuto			= true,
    noDecore        = true,
    components		= {
        flexdash_saverestore{position={0, 0, pop_w, pop_h}, message="FlexDash changes not saved!\nSave Changes or Restore?"}},
}

local popup_config = contextWindow {
    name			= "FlexDash Configuration",
    position		= {(screen_width-740)/2, (screen_height-480)/2, 740, 480},
    noResize		= true,
    visible			= false,
    noBackground    = true,
    vrAuto			= true,
    noDecore        = true,
    components		= {
        flexdash_configuration{position={0, 0, 740, 480}}
    },
}

local hotzone_w, hotzone_h = 300, 150
peekaboo = contextWindow {
    name            = "FlexDash Peekaboo Menu",
    -- position        = {0, pop_y-(hotzone_h/2), hotzone_w, hotzone_h},
    position        = {0, 0, screen_width, screen_height},
    noResize		= true,
    visible			= true,
    noBackground    = true,
    vrAuto			= true,
    noDecore        = true,
    noMove          = true,
    components		= {
        flexdash_peekaboo {position={0, (screen_height/2)-24, 168, 48}},      
    },
}

function flight_config_cmd_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        if fd_ui["moved"] then
            savefirst_flags["exit_command"] = CMD_FLIGHT_CONFIG
            popup_savefirst:setIsVisible(true)
            return 0
        else
            return 1
        end
    end
end

function quit_cmd_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        if fd_ui["moved"] then
            savefirst_flags["exit_command"] = CMD_QUIT
            popup_savefirst:setIsVisible(true)
            return 0
        else
            return 1
        end
    end
end

function reload_acf_cmd_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        if fd_ui["moved"] then
            savefirst_flags["exit_command"] = CMD_RELOAD_ACF
            popup_savefirst:setIsVisible(true)
            return 0
        else
            return 1
        end
    end
end

function reload_acf_noart_cmd_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        if fd_ui["moved"] then
            savefirst_flags["exit_command"] = CMD_RELOAD_ACF_NOART
            popup_savefirst:setIsVisible(true)
            return 0
        else
            return 1
        end
    end
end

xp_flight_config_cmd = sasl.findCommand ("sim/operation/toggle_flight_config")
sasl.registerCommandHandler ( xp_flight_config_cmd , 1 , flight_config_cmd_handler )

xp_quit_cmd = sasl.findCommand ("sim/operation/quit")
sasl.registerCommandHandler ( xp_quit_cmd , 1 , quit_cmd_handler )

xp_reload_acf_cmd = sasl.findCommand ("sim/operation/reload_aircraft")
sasl.registerCommandHandler ( xp_reload_acf_cmd , 1 , reload_acf_cmd_handler )

xp_reload_acf_noart_cmd = sasl.findCommand ("sim/operation/reload_aircraft_no_art")
sasl.registerCommandHandler ( xp_reload_acf_noart_cmd , 1 , reload_acf_noart_cmd_handler )

-- dynamically create the move window popups
pop_w = 400
pop_h = 200
move_popups = {}
for i = 1, num_instruments do
    local msg = "Moving "..flexdash_settings["gauge_name_"..i].."\n\n".."(You can move this window.)"
    move_popups[i] = contextWindow {
        name			= "Move Popup "..i,
        position		= {pop_x, pop_y, pop_w, pop_h},
        noResize		= true,
        visible			= false,
        vrAuto			= true,
        noBackground    = true,
        noDecore        = true,
        components		= {
            flexdash_movewindow{position={0, 0, pop_w, pop_h}, message=msg, idx=i}},
    }
end


function flexdash_reload_handler(phase)

    if phase == SASL_COMMAND_BEGIN then
        load_instruments()
    end
end

-- we're dynamically creating the show/hide menu command functions
flexdash_show_fn = {}
for i = 1, num_instruments do
    flexdash_show_fn[i] = function ()
        flexdash_settings["gauge_show_"..i] = 1-get(gauge_show, i)
        set (gauge_show, flexdash_settings["gauge_show_"..i], i)
    end
end

flexdash_move_fn = {}
for i = 1, num_instruments do
    flexdash_move_fn[i] = function()
        set(gauge_move, 1-get(gauge_move, i), i)
        if get(gauge_move, i) == 0 then
            move_popups[i]:setIsVisible(false)
        else
            move_popups[i]:setIsVisible(true)
        end
    end
end


flexdash_reload_cmd = sasl.createCommand("sorceress/flexdash/reload_instruments", "Reload Instruments")
sasl.registerCommandHandler( flexdash_reload_cmd, 0, flexdash_reload_handler)

function save_flexdash_settings()
    -- local group_id, use_id, t, j
    for i=1, num_instruments do
        flexdash_settings["gauge_show_"..i] = get (gauge_show, i)
        flexdash_settings["gauge_static_"..i] = gauge_static[i]
    end
    if sasl.writeConfig ( instrument_file , "JSON" , flexdash_settings) then
        sasl.logInfo ("Sorceress settings saving to "..config_path)
        popup_saved:setIsVisible(true)
        fd_ui["moved"] = false
        savefirst_flags["doSave"] = false
        check_exit_commands()
    else
        sasl.logError("Error writing Sorceress settings to "..config_path)
        popup_error:setIsVisible(true)
    end
    save_preset()
end

function save_preset ()
    preset_file = sasl.getProjectPath() .. "/Custom Module/data/preset"..flexdash_settings["preset"]..".json"
    local instrument_id
    for i = 1, 11 do
        local lg_id = flexdash_preset_settings["lg_id_"..i]
        local sm_id = flexdash_preset_settings["sm_id_"..i]
        local which_one = flexdash_preset_settings["which_one_"..i]
        if which_one == 1 then
            instrument_id = lg_id
        else
            instrument_id = sm_id
        end
        flexdash_preset_settings["pos_x_"..i] = get(gauge_xpos, instrument_id)
        flexdash_preset_settings["pos_z_"..i] = get(gauge_zpos, instrument_id)    
    end
    if sasl.writeConfig ( preset_file , "JSON" , flexdash_preset_settings) then
        sasl.logInfo ("Sorceress preset saving to "..preset_file)
        popup_saved:setIsVisible(true)
    else
        sasl.logError("Error writing Sorceress preset to "..preset_file)
        popup_error:setIsVisible(true)
    end
end

function check_for_fd_uis()
    for i = 1, num_instruments do
        if fd_ui[i] then
            flexdash_move_fn[i]()
            fd_ui[i] = false
            fd_ui["flag"] = false
        else
        end
    end
end

local popped_up = false
local old_time = 0

function update ()
    local is_popup = popup_error:isVisible() or popup_saved:isVisible()
    if is_popup then
        if not popped_up then
            popped_up = true
            old_time = get(xp_network_time)
        elseif old_time + get(popup_timeout) <= get(xp_network_time) then
            popped_up = false
            popup_error:setIsVisible(false)
            popup_saved:setIsVisible(false)
        end
    end
    if fd_ui["flag"] then
        fd_ui["flag"] = false
        check_for_fd_uis()
    end
    if savefirst_flags["close"] then
        savefirst_flags["close"] = false
        popup_savefirst:setIsVisible(false)
    end
    if savefirst_flags["doRestore"] then
        load_instruments()
    end
    if savefirst_flags["doSave"] then
        save_flexdash_settings()
    end

    if fd_config_flags["old_preset"] ~= flexdash_settings["preset"] then
        fd_config_flags["old_preset"] = flexdash_settings["preset"]
        load_preset ()
    end

    if fd_ui_old_open ~= fd_config_flags["close"] then
        fd_ui_old_open = fd_config_flags["close"]
        if fd_config_flags["close"] == false then
            popup_config:setIsVisible(true)
            peekaboo:setIsVisible(false)
        else
            popup_config:setIsVisible(false)
            peekaboo:setIsVisible(true)
        end
    end
    updateAll (components)
end
