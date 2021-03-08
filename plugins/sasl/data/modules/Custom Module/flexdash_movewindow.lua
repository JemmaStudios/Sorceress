-- flexdash_movewindow.lua

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

local urbanist	= loadFont("fonts/Urbanist-ExtraBold.ttf")
local bkgnd_image = sasl.gl.loadImage ("ui_assets/fd_background_LT.png ", 0, 0, 400 , 200)

local button_images = {}
button_images["big_down"] = {}
button_images["big_down"]["xywh"] = {300, 15, 36, 36}
button_images["big_right"] = {}
button_images["big_right"]["xywh"] = {350, 65, 36 , 36}
button_images["big_up"] = {}
button_images["big_up"]["xywh"] = {300, 115, 36 , 36}
button_images["big_left"] = {}
button_images["big_left"]["xywh"] = {250, 65, 36 , 36}
button_images["small_down"] = {}
button_images["small_down"]["xywh"] = {308, 52, 20 , 20}
button_images["small_right"] = {}
button_images["small_right"]["xywh"] = {329, 73, 20 , 20}
button_images["small_up"] = {}
button_images["small_up"]["xywh"] = {308, 93, 20 , 20}
button_images["small_left"] = {}
button_images["small_left"]["xywh"] = {288, 73, 20 , 20}

slowmove = get(move_step)
fastmove = slowmove * 10
local click_delay = 0.5 -- number of seconds to wait before spamming the mouse down.
local x_lo_limit = -0.2
local x_hi_limit = 0.2
local z_lo_limit = -0.15
local z_hi_limit = 0.35
local x_zero = 0
local z_zero = 0.175

local msg_x = 140
local msg_y = 100
local pos_msg_x = msg_x
local pos_msg_y = 25
local shadow_offset=2


function draw()
	local x, y = size[1]/2, size[2]/2

    local pos_string = string.format ("x: %.4f, y: %.4f", get(gauge_xpos, get(idx)), get(gauge_zpos, get(idx)))
    sasl.gl.drawTexture ( bkgnd_image , 0, 0, 400 , 200)
    
    -- x = msg_x
    -- y = pos_msg_y
    -- drawTextI (urbanist, x+shadow_offset, y-shadow_offset, pos_string, TEXT_ALIGN_CENTER, black)
    -- drawTextI (urbanist, x, y, pos_string, TEXT_ALIGN_CENTER, yellow)
    x = msg_x
    y = msg_y
    drawTextI(urbanist, x+shadow_offset, y-shadow_offset, get(message), TEXT_ALIGN_CENTER, black)
    drawTextI(urbanist, x, y, get(message), TEXT_ALIGN_CENTER, white)

    drawAll ( components )
end

function checked_closed(x, y)
    if x >= size[1] - 36 and x <= size[1] and y >= size[2] - 38 and y <= size[2] then
        fd_ui[get(idx)] = true
        fd_ui["flag"] = true
    end
end

function check_zeroed(x, y, i)
    local wx, wy = pos_msg_x, pos_msg_y
    if x >= wx-50 and x <= wx+50 and y >= wy-10 and y <= wy+10 then
        set(gauge_xpos, x_zero, i)
        set(gauge_zpos, z_zero, i)
    end
end

locked = false

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
    fd_ui["moved"] = true
    local doit = false
    if phase == 0 then
        oldtime = get(xp_network_time)
    end
    if (phase == 0 or get(xp_network_time) >= oldtime + click_delay) then
        doit = true
    end
    
    if  x >= button_images["big_left"]["xywh"][1] and 
        x <= button_images["big_left"]["xywh"][1] + button_images["big_left"]["xywh"][3] and
        y >= button_images["big_left"]["xywh"][2] and 
        y <= button_images["big_left"]["xywh"][2] + button_images["big_left"]["xywh"][4] and doit then
        change_xpos(-1, false)
    elseif  x >= button_images["small_left"]["xywh"][1] and 
            x <= button_images["small_left"]["xywh"][1] + button_images["small_left"]["xywh"][3] and
            y >= button_images["small_left"]["xywh"][2] and 
            y <= button_images["small_left"]["xywh"][2] + button_images["small_left"]["xywh"][4] and doit then
        change_xpos(-1, true)
    elseif  x >= button_images["big_right"]["xywh"][1] and 
            x <= button_images["big_right"]["xywh"][1] + button_images["big_right"]["xywh"][3] and
            y >= button_images["big_right"]["xywh"][2] and 
            y <= button_images["big_right"]["xywh"][2] + button_images["big_right"]["xywh"][4] and doit then
        change_xpos(1, false)
    elseif  x >= button_images["small_right"]["xywh"][1] and 
            x <= button_images["small_right"]["xywh"][1] + button_images["small_right"]["xywh"][3] and
            y >= button_images["small_right"]["xywh"][2] and 
            y <= button_images["small_right"]["xywh"][2] + button_images["small_right"]["xywh"][4] and doit then
        change_xpos(1, true)
    elseif  x >= button_images["big_down"]["xywh"][1] and 
            x <= button_images["big_down"]["xywh"][1] + button_images["big_down"]["xywh"][3] and
            y >= button_images["big_down"]["xywh"][2] and 
            y <= button_images["big_down"]["xywh"][2] + button_images["big_down"]["xywh"][4] and doit then
        change_zpos(1, false)
    elseif  x >= button_images["small_down"]["xywh"][1] and 
            x <= button_images["small_down"]["xywh"][1] + button_images["small_down"]["xywh"][3] and
            y >= button_images["small_down"]["xywh"][2] and 
            y <= button_images["small_down"]["xywh"][2] + button_images["small_down"]["xywh"][4] and doit then
        change_zpos(1, true)
    elseif  x >= button_images["big_up"]["xywh"][1] and 
            x <= button_images["big_up"]["xywh"][1] + button_images["big_up"]["xywh"][3] and
            y >= button_images["big_up"]["xywh"][2] and 
            y <= button_images["big_up"]["xywh"][2] + button_images["big_up"]["xywh"][4] and doit then
        change_zpos(-1, false)
    elseif  x >= button_images["small_up"]["xywh"][1] and 
            x <= button_images["small_up"]["xywh"][1] + button_images["small_up"]["xywh"][3] and
            y >= button_images["small_up"]["xywh"][2] and 
            y <= button_images["small_up"]["xywh"][2] + button_images["small_up"]["xywh"][4] and doit then
        change_zpos(-1, true)
    end
    return locked
end

flexdash_lib = {}
function flexdash_lib.doMouseUp (button, parentX, parentY)
    if button == MB_LEFT then
        checked_closed(parentX, parentY)
        check_zeroed(parentX, parentY, get(idx)) 
    end
    locked = false
    return true
end


function flexdash_lib.doMouseDown (button, parentX, parentY, button_name)
    if button == MB_LEFT and button_name ~= "fd_close_button" then
        return check_moves(parentX, parentY, 0)
    else
        return false
    end
end

function flexdash_lib.doMouseHold (button, parentX, parentY, button_name)

    if button == MB_LEFT and button_name ~= "fd_close_button" then
        return check_moves(parentX, parentY, 1)
    else
        return locked
    end
end

function onKeyDown ( component , char , key , shDown , ctrlDown , altOptDown )
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

components = {
    flexdash_ui_button {    position=button_images["big_down"]["xywh"],
                            button_name = "fd_big_button_down"},
    flexdash_ui_button {    position=button_images["big_up"]["xywh"],
                            button_name = "fd_big_button_up"},
    flexdash_ui_button {    position=button_images["small_down"]["xywh"],
                            button_name = "fd_big_button_down"},
    flexdash_ui_button {    position=button_images["small_up"]["xywh"],
                            button_name = "fd_big_button_up"},
    flexdash_ui_button {    position=button_images["big_left"]["xywh"],
                            button_name = "fd_big_button_left"},
    flexdash_ui_button {    position=button_images["big_right"]["xywh"],
                            button_name = "fd_big_button_right"},
    flexdash_ui_button {    position=button_images["small_left"]["xywh"],
                            button_name = "fd_big_button_left"},
    flexdash_ui_button {    position=button_images["small_right"]["xywh"],
                            button_name = "fd_big_button_right"},
    flexdash_ui_button {    position={364, 172, 24 , 24},
                            width = 24,
                            height = 24,
                            button_name = "fd_close_button"},
    flexdash_ui_pos_text {  position = {pos_msg_x, pos_msg_y, 100, 20},
                            s_offset = shadow_offset},
}
