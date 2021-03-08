-- flexdash_ui_pos_text.lua
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

defineProperty ("s_offset", 2)

local pos_string = {}
pos_string[MOUSE_OFF] = ""
pos_string[MOUSE_HOVER] = "Click to center instrument"
pos_string[MOUSE_DOWN] = "You have to let go"

function onMouseMove(component, x, y, button, parentX, parentY)
    return true
end

function onMouseDown(component, x, y, button, parentX, parentY)
    if button == MB_LEFT then
        mouse_status = MOUSE_DOWN
    end
    flexdash_lib.doMouseDown (parentX, parentY, button)
    return true
end

function onMouseUp(component, x, y, button, parentX, parentY)
    if mouse_status == MOUSE_DOWN then
        mouse_status = MOUSE_HOVER
    end
    if x > get(position)[3] or y > get(position)[4] then
        mouse_status = MOUSE_OFF
    end
    flexdash_lib.doMouseUp (parentX, parentY, button)
    return true
end

function onMouseHold (component, x, y, button, parentX, parentY)
    flexdash_lib.doMouseHold(parentX, parentY, button)
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
    pos_string[MOUSE_OFF] = string.format ("x: %.4f, y: %.4f", get(gauge_xpos, get(idx)), get(gauge_zpos, get(idx)))
    x = get(position)[1]
    y = get(position)[2]
    drawTextI (urbanist, 0+get(s_offset), 0-get(s_offset), pos_string[mouse_status], TEXT_ALIGN_CENTER, black)
    drawTextI (urbanist, 0, 0, pos_string[mouse_status], TEXT_ALIGN_CENTER, yellow)
end


