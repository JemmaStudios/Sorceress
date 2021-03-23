-- flexdash_ui_button.lua
local white = {1, 1, 1, 1}

local MOUSE_OFF = 1
local MOUSE_HOVER = 2
local MOUSE_DOWN = 3
local mouse_status = MOUSE_OFF


flexdash_lib.num_click_spots = flexdash_lib.num_click_spots + 1
local is_me = flexdash_lib.num_click_spots

defineProperty("button_name", "fd_big_button_down")
defineProperty("width", 48)
defineProperty("height", 48)
local button_image = {}
button_image[MOUSE_OFF] = sasl.gl.loadImage ("ui_assets/"..get(button_name).."_off.png", 0, 0, get(width), get(height))
button_image[MOUSE_HOVER] = sasl.gl.loadImage ("ui_assets/"..get(button_name).."_over.png", 0, 0, get(width), get(height))
button_image[MOUSE_DOWN] = sasl.gl.loadImage ("ui_assets/"..get(button_name).."_click.png", 0, 0, get(width), get(height))

function onMouseMove(component, x, y, button, parentX, parentY)
    return true
end

function onMouseDown(component, x, y, button, parentX, parentY)
    if flexdash_lib.owns_mousedown == 0 then
        flexdash_lib.owns_mousedown = is_me     -- only one clicky thing should have control of the mouseUp/mouseHold events or strange things happens
        if button == MB_LEFT then
            mouse_status = MOUSE_DOWN
        end
        flexdash_lib.doMouseDown (button, parentX, parentY, get(button_name))
    end
    return true
end

function onMouseUp(component, x, y, button, parentX, parentY)
    mouse_status = MOUSE_HOVER
    if flexdash_lib.owns_mousedown == is_me then
        if  x < 0 or y < 0 or x > get(position)[3] or y > get(position)[4] then
            mouse_status = MOUSE_OFF
        else
            flexdash_lib.doMouseUp (button, parentX, parentY, get(button_name))
        end
    else
        mouse_status = MOUSE_OFF
    end
    flexdash_lib.owns_mousedown = 0
    return true
end

function onMouseHold (component, x, y, button, parentX, parentY)
    if flexdash_lib.owns_mousedown == is_me then
        flexdash_lib.doMouseHold(button, parentX, parentY, get(button_name))
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
    sasl.gl.drawTexture ( button_image[mouse_status] , 0, 0, size[1] , size[2], white)
end


