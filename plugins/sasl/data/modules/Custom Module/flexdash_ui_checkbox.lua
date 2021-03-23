-- flexdash_ui_checkbox.lua
local white = {1, 1, 1, 1}

local MOUSE_OFF = 1
local MOUSE_HOVER = 2
local MOUSE_DOWN = 3
local mouse_status = MOUSE_OFF

local IS_CHECKED = 1
local IS_UNCHECKED = 2

flexdash_lib.num_click_spots = flexdash_lib.num_click_spots + 1
local is_me = flexdash_lib.num_click_spots

defineProperty("my_checkbox_id", 0)
defineProperty("width", 28)
defineProperty("height", 27)
local checkbox_image = {}
checkbox_image[IS_CHECKED] = {}
checkbox_image[IS_UNCHECKED] = {}
checkbox_image[IS_UNCHECKED][MOUSE_OFF] = sasl.gl.loadImage ("ui_assets/fd_checkbox_off_out.png", 0, 0, get(width), get(height))
checkbox_image[IS_UNCHECKED][MOUSE_HOVER] = sasl.gl.loadImage ("ui_assets/fd_checkbox_off_over.png", 0, 0, get(width), get(height))
checkbox_image[IS_UNCHECKED][MOUSE_DOWN] = sasl.gl.loadImage ("ui_assets/fd_checkbox_on_over.png", 0, 0, get(width), get(height))
checkbox_image[IS_CHECKED][MOUSE_OFF] = sasl.gl.loadImage ("ui_assets/fd_checkbox_on_out.png", 0, 0, get(width), get(height))
checkbox_image[IS_CHECKED][MOUSE_HOVER] = sasl.gl.loadImage ("ui_assets/fd_checkbox_on_over.png", 0, 0, get(width), get(height))
checkbox_image[IS_CHECKED][MOUSE_DOWN] = sasl.gl.loadImage ("ui_assets/fd_checkbox_off_over.png", 0, 0, get(width), get(height))



function onMouseMove(component, x, y, button, parentX, parentY)
    return true
end

function onMouseDown(component, x, y, button, parentX, parentY)
    if flexdash_lib.owns_mousedown == 0 then
        flexdash_lib.owns_mousedown = is_me     -- only one clicky thing should have control of the mouseUp/mouseHold events or strange things happens
        if button == MB_LEFT then
            mouse_status = MOUSE_DOWN
        end
        flexdash_lib.doMouseDown (button, parentX, parentY, "checkbox", get(my_checkbox_id))
    end
    return true
end

function onMouseUp(component, x, y, button, parentX, parentY)
    mouse_status = MOUSE_HOVER
    if flexdash_lib.owns_mousedown == is_me then
        if  x < 0 or y < 0 or x > get(position)[3] or y > get(position)[4] then
            mouse_status = MOUSE_OFF
        else
            flexdash_lib.doMouseUp (button, parentX, parentY, "checkbox", get(my_checkbox_id))
        end
    else
        mousestatus = MOUSE_OFF
    end
    flexdash_lib.owns_mousedown = 0
    return true
end

function onMouseHold (component, x, y, button, parentX, parentY)
    if flexdash_lib.owns_mousedown == is_me then
        flexdash_lib.doMouseHold(button, parentX, parentY, "checkbox", get(my_checkbox_id))
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
    sasl.gl.drawTexture ( checkbox_image[checkbox_id[get(my_checkbox_id)]][mouse_status] , 0, 0, size[1] , size[2], white)
end


