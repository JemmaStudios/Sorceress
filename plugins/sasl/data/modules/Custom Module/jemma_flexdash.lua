--[[
    sorceress_flexdash.lua

]]

defineProperty ("popup_timeout", 3) -- number of seconds popup windows stay on

num_instruments = 11

ttable = {}
for i = 1, num_instruments do
    table.insert(ttable, 0)
end

gauge_show = createGlobalPropertyia ("sorceress/flexdash/gauge_show", ttable)
gauge_xpos = createGlobalPropertyfa ("sorceress/flexdash/gauge_xpos", ttable)
gauge_zpos = createGlobalPropertyfa ("sorceress/flexdash/gauge_zpos", ttable)
gauge_move = createGlobalPropertyfa ("sorceress/flexdash/gauge_move", ttable)

xp_network_time = globalPropertyf ("sim/network/misc/network_time_sec")

flexdash_config = {}
flexdash_settings = {}
config_path = sasl.getAircraftPath ()
config_path = config_path.. "/flexdash.json"

showhide_name = {"Show ", "Hide "}

function load_instruments()
    if isFileExists ( config_path ) then 
        flexdash_config = sasl.readConfig ( config_path , "JSON" )
        for i, v in pairs (flexdash_config) do
            flexdash_settings[i] = v
        end
        for i=1, num_instruments do
            set (gauge_show, flexdash_settings["gauge_show_"..i], i)
            set (gauge_xpos, flexdash_settings["gauge_xpos_"..i], i)
            set (gauge_zpos, flexdash_settings["gauge_zpos_"..i], i)
        end    
    end
end

load_instruments()

local pop_w = 300
local pop_h = 100

screen_x, screen_y, screen_width, screen_height = sasl.windows.getScreenBoundsGlobal ()
local pop_x = (screen_width-pop_w)/2
local pop_y = (screen_height-pop_h)/2

local popup_error = contextWindow {
    name			= "My first popup",
    position		= {pop_x, pop_y, pop_w, pop_h},
    noResize		= true,
    visible			= false,
    vrAuto			= true,
    noDecore        = true,
    components		= {flexdash_popup{position={0, 0, pop_w, pop_h}, message="Error Saving File.\nCheck log.txt"}},
}
local popup_saved = contextWindow {
    name			= "My first popup",
    position		= {pop_x, pop_y, pop_w, pop_h},
    noResize		= true,
    visible			= false,
    vrAuto			= true,
    noDecore        = true,
    components		= {flexdash_popup{position={0, 0, pop_w, pop_h}, message="FlexDash Configuration Saved"}},
}
move_popups = {}
for i = 1, num_instruments do
    local msg = "Moving "..flexdash_settings["gauge_name_"..i].."\n\n".."Click and drag this window\nto reposition."
    move_popups[i] = contextWindow {
        name			= "Move Popup "..i,
        position		= {pop_x, pop_y, pop_w, pop_h},
        noResize		= true,
        visible			= false,
        vrAuto			= true,
        noDecore        = true,
        components		= {flexdash_popup{position={0, 0, pop_w, pop_h}, message=msg}},
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
    end
end

flexdash_move_fn = {}
for i = 1, num_instruments do
    flexdash_move_fn[i] = function()
        debug_lib.on_debug("ver 1.0")
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
    end
    if sasl.writeConfig ( config_path , "JSON" , flexdash_settings) then
        sasl.logInfo ("Sorceress settings saving to "..config_path)
        popup_saved:setIsVisible(true)
    else
        sasl.logError("Error writing Sorceress settings to "..config_path)
        popup_error:setIsVisible(true)
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
    flexdash_movemenu_items[i] = sasl.appendMenuItem (  Flexdash_Move_Menu, 
                            "Move ".. flexdash_settings["gauge_name_"..i], 
                            flexdash_move_fn[i])
end
sasl.appendMenuSeparator ( Flexdash_Menu )
Flexdash_save_instruments_menuitem = sasl.appendMenuItem ( Flexdash_Menu , "Save Instruments", save_flexdash_settings )

debug_lib.on_debug(string.format("screen_width: %i\tscreen_height: %i\tpop_x: %i\tpop_y: %i", screen_width, screen_height, pop_x, pop_y))
local popped_up = false
local old_time = 0
function update ()
    local is_popup = popup_error:isVisible() or popup_saved:isVisible()
    if is_popup then
        if not popped_up then
            popped_up = true
            old_time = get(xp_network_time)
            debug_lib.on_debug(get(xp_network_time))
        elseif old_time + get(popup_timeout) <= get(xp_network_time) then
            debug_lib.on_debug(old_time + get(popup_timeout).."\t"..get(xp_network_time))
            popped_up = false
            popup_error:setIsVisible(false)
            popup_saved:setIsVisible(false)
        end
    end
    updateAll (components)
end
