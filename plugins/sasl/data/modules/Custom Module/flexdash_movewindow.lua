-- flexdash_popup.lua

defineProperty("message", "Hello World!")
defineProperty("idx", 0)
defineProperty("move_step",0.0005)

local black	= {0, 0, 0, 1}
local cyan	= {0, 1, 1, 1}
local magenta	= {1, 0, 1, 1}
local yellow	= {1, 1, 0, 1}
local red       = {1, 0, 0, 1}
local green     = {0, 1, 0, 1}
local white = {1,1,1,1}
local roboto	= loadFont(getXPlanePath() .. "Resources/fonts/Roboto-Regular.ttf")

slowmove = get(move_step)
fastmove = slowmove * 10
local click_delay = 0.5 -- number of seconds to wait before spamming the mouse down.
local x_lo_limit = -0.2
local x_hi_limit = 0.2
local z_lo_limit = -0.15
local z_hi_limit = 0.30
local x_zero = 0
local z_zero = 0.175


function draw()
	local x, y = size[1]/2, size[2]/2
    -- drawText(roboto, x, y, get(message), 16, false, false, TEXT_ALIGN_CENTER, white)
    local pos_string = string.format ("x: %.4f, y: %.4f", get(gauge_xpos, get(idx)), get(gauge_zpos, get(idx)))
    drawTextI (roboto, x, y+50, pos_string, TEXT_ALIGN_CENTER, yellow)
    drawTextI(roboto, x, y, get(message), TEXT_ALIGN_CENTER, white)
    x, y = size[1]-8, size[2]-8
    drawCircle ( x, y, 5, true, red )
    drawTriangle ( 10 , 150 , 30 , 160 , 30 , 140 , green )
    drawTriangle ( 35, 150, 45, 155, 45, 145, green)
    drawTriangle (290, 150, 270, 160, 270, 140, green)
    drawTriangle (265, 150, 255, 155, 255, 145, green)
    drawTriangle (150, 10, 160, 30, 140, 30, green)
    drawTriangle (150, 35, 155, 45, 145, 45, green)
    drawTriangle (150, 290, 160, 270, 140, 270, green)
    drawTriangle (150, 265, 155, 255, 145, 255, green)
    drawAll ( components )
end

function checked_closed(x, y)
    if x >= size[1] - 10 and x <= size[1] and y >= size[2] - 10 and y <= size[2] then
        closed_move_window[get(idx)] = true
        closed_move_window["flag"] = true
    end
end

function check_zeroed(x, y, i)
    local wx, wy = size[1]/2, size[2]/2+50
    if x >= wx-50 and x <= wx+50 and y >= wy-10 and y <= wy+10 then
        set(gauge_xpos, x_zero, i)
        set(gauge_zpos, z_zero, i)
    end
end

local locked = false

function change_xpos(updown, is_slow)
    locked = true
    if is_slow then
        set (gauge_xpos, get(gauge_xpos, get(idx))+(updown*slowmove), get(idx))
    else
        set (gauge_xpos, get(gauge_xpos, get(idx))+(updown*fastmove), get(idx))
    end
    if get(gauge_xpos, get(idx)) <= x_lo_limit then
        set(gauge_xpos, x_lo_limit, get(idx))
    end
    if get(gauge_xpos, get(idx)) >= x_hi_limit then
        set(gauge_xpos, x_hi_limit, get(idx))
    end
end

function change_zpos(updown, is_slow)
    locked = true
    if is_slow then
        set (gauge_zpos, get(gauge_zpos, get(idx))+(updown*slowmove), get(idx))
    else
        set (gauge_zpos, get(gauge_zpos, get(idx))+(updown*fastmove), get(idx))
    end
    if get(gauge_zpos, get(idx)) <= z_lo_limit then
        set(gauge_zpos, z_lo_limit, get(idx))
    end
    if get(gauge_zpos, get(idx)) >= z_hi_limit then
        set(gauge_zpos, z_hi_limit, get(idx))
    end
end

local oldtime = 0
function check_moves (x, y, phase)
    local doit = false
    if phase == 0 then
        oldtime = get(xp_network_time)
    end
    if (phase == 0 or get(xp_network_time) >= oldtime + click_delay) then
        doit = true
    end
    if x >= 10 and x <= 30 and y >= 140 and y <= 160 and doit then
        change_xpos(-1, false)
    elseif x >= 35 and x <= 45 and y >= 145 and y <= 155 and doit then
        change_xpos(-1, true)
    elseif x >= 270 and x <= 290 and y >= 140 and y <= 160 and doit then
        change_xpos(1, false)
    elseif x >= 255 and x <= 265 and y >= 145 and y <= 155 and doit then
        change_xpos(1, true)
    elseif x >= 140 and x <= 160 and y >= 10 and y <= 30 and doit then
        change_zpos(1, false)
    elseif x >= 145 and x <= 155 and y >= 35 and y <= 45 and doit then
        change_zpos(1, true)
    elseif x >= 140 and x <= 160 and y >= 270 and y <= 290 and doit then
        change_zpos(-1, false)
    elseif x >= 145 and x <= 155 and y >= 255 and y <= 265 and doit then
        change_zpos(-1, true)
    end
    return locked
end

function onMouseUp ( component , x, y, button , parentX , parentY )
    if button == MB_LEFT then
        checked_closed(x, y)
        check_zeroed(x, y, get(idx)) 
    end
    locked = false
    return true
end

function onMouseDown (component, x, y, button, parentX, parentY)
    if button == MB_LEFT then
        return check_moves(x, y, 0)
    else
        return false
    end
end

function onMouseHold (component, x, y, button, parentX, parentY)
    if button == MB_LEFT then
        return check_moves(x, y, 1)
    else
        return locked
    end
end

function onKeyDown ( component , char , key , shDown , ctrlDown , altOptDown )
    debug_lib.on_debug(" Char :" ..string.char ( char ))
    if char == SASL_KEY_LEFT then
        if shDown == 1 then
            change_xpos(-1, false)
        else
            change_xpos(-1, true)
        end
        return true
    elseif char == SASL_KEY_RIGHT then
        if shDown == 1 then
            change_xpos(1, false)
        else
            change_xpos(1, true)
        end
        return true
    elseif char == SASL_KEY_UP then
        if shDown == 1 then
            change_zpos(-1, false)
        else
            change_zpos(-1, true)
        end
        return true
    elseif char == SASL_KEY_DOWN then
        if shDown == 1 then
            change_zpos(1, false)
        else
            change_zpos(1, true)
        end
        return true
    end
    return false
end
