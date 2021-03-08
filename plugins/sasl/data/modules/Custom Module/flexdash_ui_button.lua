-- flexdash_ui_button.lua

local MOUSE_OFF = 1
local MOUSE_HOVER = 2
local MOUSE_DOWN = 3
local mouse_status = MOUSE_OFF

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
    if button == MB_LEFT then
        mouse_status = MOUSE_DOWN
    end
    flexdash_lib.doMouseDown (button, parentX, parentY, get(button_name))
    return true
end

function onMouseUp(component, x, y, button, parentX, parentY)
    if mouse_status == MOUSE_DOWN then
        mouse_status = MOUSE_HOVER
    end
    if x > get(position)[3] or y > get(position)[4] then
        mouse_status = MOUSE_OFF
    end
    flexdash_lib.doMouseUp (button, parentX, parentY, get(button_name))
    return true
end

function onMouseHold (component, x, y, button, parentX, parentY)
    flexdash_lib.doMouseHold(button, parentX, parentY, get(button_name))
    return true
end

function onMouseEnter()
    if mouse_status ~= MOUSE_DOWN then -- we don't want to change state if the mouse button is down
        mouse_status = MOUSE_HOVER
    end
end

function onMouseLeave()
    if mouse_status == MOUSE_HOVER then -- otherwise we're probably mouse-down and don't want to change state.
        mouse_status = MOUSE_OFF
    end
end

function draw()
    sasl.gl.drawTexture ( button_image[mouse_status] , 0, 0, size[1] , size[2])
end


