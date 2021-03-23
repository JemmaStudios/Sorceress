-- flexdash_ui_pos_text.lua

defineProperty ("s_offset", 2)

local black	= {0, 0, 0, 1}
local cyan	= {0, 1, 1, 1}
local magenta	= {1, 0, 1, 1}
local yellow	= {1, 1, 0, 1}
local red       = {1, 0, 0, 1}
local green     = {0, 1, 0, 1}
local white = {1,1,1,1}

local urbanist	= loadFont("fonts/Urbanist-ExtraBold.ttf")

local MOUSE_OFF = 1
local MOUSE_HOVER = 2
local MOUSE_DOWN = 3
local mouse_status = MOUSE_OFF

flexdash_lib.num_click_spots = flexdash_lib.num_click_spots + 1
local is_me = flexdash_lib.num_click_spots

local pos_string = {}
pos_string[MOUSE_OFF] = ""
pos_string[MOUSE_HOVER] = "Click to center instrument"
pos_string[MOUSE_DOWN] = "You have to let go"

function onMouseMove(component, x, y, button, parentX, parentY)
    return true
end

function onMouseDown(component, x, y, button, parentX, parentY)
    if flexdash_lib.owns_mousedown == 0 then
        flexdash_lib.owns_mousedown = is_me     -- only one clicky thing should have control of the mouseUp/mouseHold events or strange things happens
        if button == MB_LEFT then
            mouse_status = MOUSE_DOWN
        end
        flexdash_lib.doMouseDown (button, parentX, parentY)
    end
    return true
end

function onMouseUp(component, x, y, button, parentX, parentY)
    mouse_status = MOUSE_HOVER
    if flexdash_lib.owns_mousedown == is_me then
        if x > get(position)[3] or y > get(position)[4] then
            mouse_status = MOUSE_OFF
        else
            flexdash_lib.doMouseUp (button, parentX, parentY)
        end
    else
        mouse_status = MOUSE_OFF
    end
    flexdash_lib.owns_mousedown = 0
    return true
end

function onMouseHold (component, x, y, button, parentX, parentY)
    if flexdash_lib.owns_mousedown == is_me then
        flexdash_lib.doMouseHold(button, parentX, parentY)
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
    pos_string[MOUSE_OFF] = string.format ("x: %.4f, y: %.4f", get(gauge_xpos, get(idx)), get(gauge_zpos, get(idx)))
    x = get(position)[1]
    y = get(position)[2]
    drawTextI (urbanist, 0+get(s_offset), 0-get(s_offset), pos_string[mouse_status], TEXT_ALIGN_CENTER, black)
    drawTextI (urbanist, 0, 0, pos_string[mouse_status], TEXT_ALIGN_CENTER, yellow)
end


