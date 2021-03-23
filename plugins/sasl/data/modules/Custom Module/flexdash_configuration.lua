-- flexdash_config.lua

local black	    = {0, 0, 0, 1}
local cyan	    = {0, 1, 1, 1}
local magenta	= {1, 0, 1, 1}
local yellow	= {1, 1, 0, 1}
local red       = {1, 0, 0, 1}
local white     = {1, 1, 1, 1}
local shadow_offset = 2
local urbanist	= loadFont("fonts/Urbanist-ExtraBold.ttf")
sasl.gl.setFontSize ( urbanist, 16 )
local bkgnd_image = sasl.gl.loadImage ("ui_assets/fd_config_background.png", 0, 0, 740, 480)

local IS_CHECKED = 1
local IS_UNCHECKED = 2

-- define global tables
checkbox_id = {}
for i = 1, 12 do
    checkbox_id[i] = 2 - flexdash_preset_settings["show_"..i]
end
radio_group_id = {}

for i = 1, 12 do
    radio_group_id[i] = {}
end

for i = 1, 9 do
    radio_group_id[i]["checked"] = flexdash_preset_settings["which_one_"..i]
end
-- preset group
radio_group_id[10]["checked"] = flexdash_settings["preset"]
radio_group_id[12]["checked"] = flexdash_preset_settings["which_one_12"]

-- set up instrument status configuration data
local SHOW_ME = 1
local MY_SIZE = 2
local MOVE_ME = 3

local IS_SHOWING = 1
local IS_HIDING = 2

local IS_BIG = 1
local IS_SMALL = 2

local IS_LOCKED = 1
local IS_MOVING = 2

local config_buttons = {}
config_buttons["save"] = {530, 35, 148, 48}
config_buttons["restore"] = {380, 35, 148, 48}
config_buttons["close"] = {700, 440, 24, 24}
config_buttons[1] = {48, 318, 28, 27}
config_buttons[2] = {48, 295, 28, 27}
config_buttons[3] = {48, 272, 28, 27}
config_buttons[4] = {48, 249, 28, 27}
config_buttons[5] = {48, 226, 28, 27}
config_buttons[6] = {48, 203, 28, 27}
config_buttons[7] = {48, 180, 28, 27}
config_buttons[8] = {48, 157, 28, 27}
config_buttons[9] = {48, 107, 28, 27}
config_buttons[10] = {378, 326, 28, 27}
config_buttons[11] = {48, 84, 28, 27}

flexdash_lib = {}
flexdash_lib.num_click_spots = 0
flexdash_lib.owns_mousedown = 0

function showhide_instrument(cid)
    local lg_id = flexdash_preset_settings["lg_id_"..cid]
    local sm_id = flexdash_preset_settings["sm_id_"..cid]
    -- first we'll hide both then turn on which one we need if necessary
    flexdash_settings["gauge_show_"..lg_id] = 0
    set (gauge_show, 0, lg_id)
    flexdash_settings["gauge_show_"..sm_id] = 0
    set (gauge_show, 0, sm_id)
    if flexdash_preset_settings["show_"..cid] == 1 then -- we need to show one!
        if flexdash_preset_settings["which_one_"..cid] == IS_BIG then
            flexdash_settings["gauge_show_"..lg_id] = 1
            set (gauge_show, 1, lg_id)
        else
            flexdash_settings["gauge_show_"..sm_id] = 1
            set (gauge_show, 1, sm_id)
        end
    end
end

function flexdash_lib.doMouseUp (button, parentX, parentY, button_name, cid)
    if button_name == "fd_close_button" then
        fd_config_flags["close"] = true
    elseif button_name == "checkbox" then
        checkbox_id[cid] = 3-checkbox_id[cid]
        flexdash_preset_settings["show_"..cid] = 2 - checkbox_id[cid]
        showhide_instrument(cid)
    elseif button_name == "radio_group" then
        if cid[1] == 10 then -- presets radio group
            flexdash_settings["preset"] = cid[2]
        else
            flexdash_preset_settings["which_one_"..cid[1]] = cid[2]
            showhide_instrument(cid[1])
        end
    elseif button_name == "fd_save_button" then
        save_flexdash_settings ()
    elseif button_name == "fd_restore_button" then
        load_preset ()
    elseif button_name == "fd_movelock_button" then
        local i_id
        if flexdash_preset_settings["show_"..cid] == 1 or cid == 10 then  -- if it's not showing we're not moving it.
            if flexdash_preset_settings["which_one_"..cid] == 1 then
                i_id = flexdash_preset_settings["lg_id_"..cid]
            else
                i_id = flexdash_preset_settings["sm_id_"..cid]
            end
            fn = flexdash_move_fn[i_id]
            fn ()
        end
    end
end

function flexdash_lib.doMouseHold (button, parentX, parentY, button_name, id)
end

function flexdash_lib.doMouseDown (button, parentX, parentY, button_name, id)
end

function draw()
    sasl.gl.drawTexture ( bkgnd_image , 0, 0, 740, 480, white)
    drawAll (components)
end


components = {  
    flexdash_ui_button {    position = config_buttons["save"],
                            width = 148,
                            height = 48,
                            button_name = "fd_save_button"
                        },
    flexdash_ui_button {    position = config_buttons["restore"],
                        width = 148,
                        height = 48,
                        button_name = "fd_restore_button"
                    },
    flexdash_ui_button {    position = config_buttons["close"],
                            width = 24,
                            height = 24,
                            button_name = "fd_close_button"
                        },
    }
for i = 1, 9 do
    table.insert (components, flexdash_ui_checkbox {  position = config_buttons[i], width = config_buttons[i][3], height = config_buttons[i][4], my_checkbox_id = i})
end
table.insert (components, flexdash_ui_checkbox {  position = config_buttons[10], width = config_buttons[10][3], height = config_buttons[10][4], my_checkbox_id = 11})
table.insert (components, flexdash_ui_checkbox {  position = config_buttons[11], width = config_buttons[11][3], height = config_buttons[11][4], my_checkbox_id = 12})
for i = 1, 8 do
    table.insert (components, flexdash_ui_radiogroup {position = {220, 318-((i-1)*23), 100, 50}, width = 100, height = 50, my_radio_group_id = i, num_radio_buttons = 2})
    table.insert (components, flexdash_ui_movelock_button {    position = {290, 318-((i-1)*23), 60, 30},
        width = 60,
        height = 30,
        button_group_id = i}
    )
end
table.insert (components, flexdash_ui_radiogroup {position = {220, 103, 100, 50}, width = 100, height = 50, my_radio_group_id = 9, num_radio_buttons = 2})
table.insert (components, flexdash_ui_movelock_button {    position = {290, 103, 60, 30},
    width = 60,
    height = 30,
    button_group_id = 9}
    )
table.insert (components, flexdash_ui_radiogroup {position = {220, 80, 100, 50}, width = 100, height = 50, my_radio_group_id = 12, num_radio_buttons = 2})

table.insert (components, flexdash_ui_radiogroup {position = {378, 103, 50, 300}, width = 100, 
    height = 50, my_radio_group_id = 10, num_radio_buttons = 7, isVertical=true, spacing=23})
table.insert (components, flexdash_ui_movelock_button {    position = {570, 346, 60, 30},
    width = 60,
    height = 30,
    button_group_id = 10}
    )
table.insert (components, flexdash_ui_movelock_button {    position = {570, 323, 60, 30},
    width = 60,
    height = 30,
    button_group_id = 11}
    )

function update ()
    for i = 1, 12 do
        checkbox_id[i] = 2 - flexdash_preset_settings["show_"..i]
    end    
    for i = 1, 9 do
        radio_group_id[i]["checked"] = flexdash_preset_settings["which_one_"..i]
    end
    radio_group_id[12]["checked"] = flexdash_preset_settings["which_one_12"]
    updateAll (components)
end

