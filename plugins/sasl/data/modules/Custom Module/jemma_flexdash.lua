--[[
    sorceress_flexdash.lua

    sample new instrument in flexdash.json
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

]]

defineProperty ("popup_timeout", 3) -- number of seconds popup windows stay on

local saved = true

-- constants used to track which command was used to try to close the acf without saving the dash.
CMD_CLEAR = 0
CMD_FLIGHT_CONFIG = 1
CMD_QUIT = 2
CMD_RELOAD_ACF = 3
CMD_RELOAD_ACF_NOART = 4

-- used by flexdash_saverestore component.
savefirst_flags = {}
savefirst_flags["close"] = false
savefirst_flags["doSave"] = false
savefirst_flags["doRestore"] = false
savefirst_flags["exit_command"] = CMD_CLEAR

num_instruments = 22
debug_lib.on_debug("num_instruments: "..num_instruments)
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
config_path = sasl.getAircraftPath ()
config_path = config_path.. "/flexdash.json"

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

function load_instruments()
    fd_ui["moved"] = false

    if isFileExists ( config_path ) then 
        flexdash_config = sasl.readConfig ( config_path , "JSON" )
        for i, v in pairs (flexdash_config) do
            flexdash_settings[i] = v
        end
        for i=1, num_instruments do
            set (gauge_show, flexdash_settings["gauge_show_"..i], i)
            set (gauge_xpos, flexdash_settings["gauge_xpos_"..i], i)
            set (gauge_zpos, flexdash_settings["gauge_zpos_"..i], i)
            gauge_static[i] = flexdash_settings["gauge_static_"..i]
        end    
        savefirst_flags["doRestore"] = false
        check_exit_commands()
    end
end

load_instruments()

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
        sasl.setMenuItemName (  Flexdash_Show_Menu ,
                                flexdash_showmenu_items[i] ,
                                showhide_name[flexdash_settings["gauge_show_"..i]+1] .. flexdash_settings["gauge_name_"..i])
        if gauge_static[i] == 0 then
            sasl.enableMenuItem ( Flexdash_Move_Menu , flexdash_movemenu_items[i] , get(gauge_show, i))
        end
    end
end

flexdash_move_fn = {}
for i = 1, num_instruments do
    flexdash_move_fn[i] = function()
        set(gauge_move, 1-get(gauge_move, i), i)
        if get(gauge_move, i) == 0 then
            sasl.setMenuItemState ( Flexdash_Move_Menu , flexdash_movemenu_items[i] , MENU_UNCHECKED )
            move_popups[i]:setIsVisible(false)
        else
            sasl.setMenuItemState ( Flexdash_Move_Menu , flexdash_movemenu_items[i] , MENU_CHECKED )
            move_popups[i]:setIsVisible(true)
        end
    end
end

flexdash_reload_cmd = sasl.createCommand("sorceress/flexdash/reload_instruments", "Reload Instruments")
sasl.registerCommandHandler( flexdash_reload_cmd, 0, flexdash_reload_handler)

function save_flexdash_settings()
    for i=1, num_instruments do
        flexdash_settings["gauge_show_"..i] = get (gauge_show, i)
        flexdash_settings["gauge_xpos_"..i] = get (gauge_xpos, i)
        flexdash_settings["gauge_zpos_"..i] = get (gauge_zpos, i)
        flexdash_settings["gauge_static_"..i] = gauge_static[i]
    end
    if sasl.writeConfig ( config_path , "JSON" , flexdash_settings) then
        sasl.logInfo ("Sorceress settings saving to "..config_path)
        popup_saved:setIsVisible(true)
        fd_ui["moved"] = false
        savefirst_flags["doSave"] = false
        check_exit_commands()
    else
        sasl.logError("Error writing Sorceress settings to "..config_path)
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

flexdash_showmenu_items = {}
flexdash_movemenu_items = {}

Flexdash_Menuitem = sasl.appendMenuItem ( AIRCRAFT_MENU_ID , "Sorceress Flex Dash")
Flexdash_Menu = sasl.createMenu ("Sorceress Flex Dash", AIRCRAFT_MENU_ID , Flexdash_Menuitem )
Flexdash_reload_instruments_Menuitem = sasl.appendMenuItem ( Flexdash_Menu , "Reload Instruments", load_instruments )
sasl.appendMenuSeparator ( Flexdash_Menu )
Flexdash_Showmenu_item = sasl.appendMenuItem (Flexdash_Menu, "Show/Hide Instrument")
Flexdash_Show_Menu = sasl.createMenu ("Show/Hide Instrument", Flexdash_Menu , Flexdash_Showmenu_item )
for i=1, num_instruments do
    flexdash_showmenu_items[i] = sasl.appendMenuItem (  Flexdash_Show_Menu, 
                            showhide_name[get(gauge_show, i)+1] .. flexdash_settings["gauge_name_"..i], 
                            flexdash_show_fn[i])
end
Flexdash_Movemenu_item = sasl.appendMenuItem (Flexdash_Menu, "Move Instrument")
Flexdash_Move_Menu = sasl.createMenu ("Move Instrument", Flexdash_Menu , Flexdash_Movemenu_item )
for i=1, num_instruments do
    if gauge_static[i] == 0 then
        flexdash_movemenu_items[i] = sasl.appendMenuItem (  Flexdash_Move_Menu, 
                                "Move ".. flexdash_settings["gauge_name_"..i], 
                                flexdash_move_fn[i])
    end
end
sasl.appendMenuSeparator ( Flexdash_Menu )
Flexdash_save_instruments_menuitem = sasl.appendMenuItem ( Flexdash_Menu , "Save Instruments", save_flexdash_settings )

for i = 1, num_instruments do
    if gauge_static[i] == 0 then
        sasl.enableMenuItem ( Flexdash_Move_Menu , flexdash_movemenu_items[i] , get(gauge_show, i))
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
    updateAll (components)
end
