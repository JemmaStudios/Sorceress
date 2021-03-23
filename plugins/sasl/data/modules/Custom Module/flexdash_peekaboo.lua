-- flexdash_peekaboo.lua
local black	    = {0, 0, 0, 1}
local cyan	    = {0, 1, 1, 1}
local magenta	= {1, 0, 1, 1}
local yellow	= {1, 1, 0, 1}
local red       = {1, 0, 0, 1}
local white     = {1, 1, 1, 1}

local SLIDING_IN = -1
local SLIDING_OUT = 1
local NOT_SLIDING = 0
local is_sliding = NOT_SLIDING
local MOUSE_OFF = 1
local MOUSE_HOVER = 2
local MOUSE_DOWN = 3
mouse_status = MOUSE_OFF

local image_x, min_x = 0, -168+21
local slide_speed = 0.30 -- how fast the peekaboo image slides in seconds.


button_image = {}
button_image[MOUSE_OFF] = {}
button_image[MOUSE_OFF]["image"] = sasl.gl.loadImage ("ui_assets/fd_peekaboo1_dim.png")
button_image[MOUSE_OFF]["width"] = 21
button_image[MOUSE_HOVER] = {}
button_image[MOUSE_HOVER]["image"] = sasl.gl.loadImage ("ui_assets/fd_peekaboo2.png")
button_image[MOUSE_HOVER]["width"] = 168
button_image[MOUSE_DOWN] = {}
button_image[MOUSE_DOWN]["image"] = sasl.gl.loadImage ("ui_assets/fd_peekaboo2.png")
button_image[MOUSE_DOWN]["width"] = 168

function onMouseMove(component, x, y, button, parentX, parentY)
    return true
end

function onMouseDown(component, x, y, button, parentX, parentY)
    if button == MB_LEFT then
        mouse_status = MOUSE_DOWN
    end
    return false
end

function onMouseUp(component, x, y, button, parentX, parentY)
    mouse_status = MOUSE_HOVER
    if  x < 0 or y < 0 or x > get(position)[3] or y > get(position)[4] then
        mouse_status = MOUSE_OFF
    else
        fd_config_flags["close"] = false
    end
    return false
end

function onMouseHold (component, x, y, button, parentX, parentY)
    return false
end

function onMouseEnter()
    if image_x == 0 or is_sliding == SLIDING_IN then
        image_x = min_x
        is_sliding = SLIDING_OUT
    else
        is_sliding = SLIDING_IN
    end
    mouse_status = MOUSE_HOVER
    return false
end

function onMouseLeave()
    is_sliding = SLIDING_IN
    return false
end

function do_slide()
    local move_step = math.floor (168 / get (slide_speed) * timer_lib.SIM_PERIOD)
    image_x = image_x + (move_step * is_sliding)
    if is_sliding == SLIDING_OUT and image_x >= 0 then
        image_x = 0
        is_sliding = NOT_SLIDING
    end
    if is_sliding == SLIDING_IN and image_x <= min_x then
        image_x = min_x
        is_sliding = NOT_SLIDING
        mouse_status = MOUSE_OFF
    end
end

function draw()
    sasl.gl.drawTexture ( button_image[mouse_status]["image"], image_x, 0, button_image[mouse_status]["width"], 48, white)
end

function update ()
    if is_sliding ~= NOT_SLIDING then
        do_slide()
    else
        image_x = 0
    end
end
