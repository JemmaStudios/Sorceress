-- flexdash_ui_radio.lua
local white = {1, 1, 1, 1}

local MOUSE_OFF = 1
local MOUSE_HOVER = 2
local MOUSE_DOWN = 3
local DIMMED = 4
local mouse_status = MOUSE_OFF

local IS_CHECKED = 1
local IS_UNCHECKED = 2

flexdash_lib.num_click_spots = flexdash_lib.num_click_spots + 1
local is_me = flexdash_lib.num_click_spots

defineProperty("my_radio_group", 0)
defineProperty("my_radio_id", 0)
defineProperty("width", 30)
defineProperty("height", 29)
local radio_image = {}
radio_image[IS_CHECKED] = {}
radio_image[IS_UNCHECKED] = {}
radio_image[IS_UNCHECKED][MOUSE_OFF] = sasl.gl.loadImage ("ui_assets/fd_radio_button_off_out.png", 0, 0, get(width), get(height))
radio_image[IS_UNCHECKED][MOUSE_HOVER] = sasl.gl.loadImage ("ui_assets/fd_radio_button_off_over.png", 0, 0, get(width), get(height))
radio_image[IS_UNCHECKED][MOUSE_DOWN] = sasl.gl.loadImage ("ui_assets/fd_radio_button_on_over.png", 0, 0, get(width), get(height))
radio_image[IS_UNCHECKED][DIMMED] = sasl.gl.loadImage ("ui_assets/fd_radio_button_off_dim.png", 0, 0, get(width), get(height))
radio_image[IS_CHECKED][MOUSE_OFF] = sasl.gl.loadImage ("ui_assets/fd_radio_button_on_out.png", 0, 0, get(width), get(height))
radio_image[IS_CHECKED][MOUSE_HOVER] = sasl.gl.loadImage ("ui_assets/fd_radio_button_on_over.png", 0, 0, get(width), get(height))
radio_image[IS_CHECKED][MOUSE_DOWN] = sasl.gl.loadImage ("ui_assets/fd_radio_button_off_over.png", 0, 0, get(width), get(height))
radio_image[IS_CHECKED][DIMMED] = sasl.gl.loadImage ("ui_assets/fd_radio_button_on_dim.png", 0, 0, get(width), get(height))

function onMouseMove(component, x, y, button, parentX, parentY)
    return true
end

function onMouseDown(component, x, y, button, parentX, parentY)
    if flexdash_lib.owns_mousedown == 0 then
        flexdash_lib.owns_mousedown = is_me     -- only one clicky thing should have control of the mouseUp/mouseHold events or strange things happens
        if button == MB_LEFT then
            mouse_status = MOUSE_DOWN
        end
        flexdash_lib.doMouseDown (button, parentX, parentY, "radio", get(my_radio_id))
    end
    return true
end

function onMouseUp(component, x, y, button, parentX, parentY)
    mouse_status = MOUSE_HOVER
    if flexdash_lib.owns_mousedown == is_me then
        if  x < 0 or y < 0 or x > get(position)[3] or y > get(position)[4] then
            mouse_status = MOUSE_OFF
        else
            radio_group_lib.doMouseUp (button, parentX, parentY, "radio", get(my_radio_id))
        end
    else
        mouse_status = MOUSE_OFF
    end
    flexdash_lib.owns_mousedown = 0
    return true
end

function onMouseHold (component, x, y, button, parentX, parentY)
    if flexdash_lib.owns_mousedown == is_me then
        flexdash_lib.doMouseHold(button, parentX, parentY, "radio", get(my_radio_id))
    end
    return true
end

function onMouseEnter()
    if flexdash_lib.owns_mousedown == is_me then
        mouse_status = MOUSE_DOWN
    else
        mouse_status = MOUSE_HOVER
    end
end

function onMouseLeave()
    mouse_status = MOUSE_OFF
end

function draw()
    local t = radio_group_id [get(my_radio_group)][get(my_radio_id)]
    sasl.gl.drawTexture ( radio_image[t][mouse_status], 0, 0, size[1] , size[2], white)
end

function update()
    if fd_move_flag[get(my_radio_group)] then
        mouse_status = DIMMED
    elseif mouse_status == DIMMED then
        mouse_status = MOUSE_OFF
    end
end

