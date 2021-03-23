-- flexdash_ui_radiogroup.lua

defineProperty("my_radio_group_id", 1)
defineProperty("num_radio_buttons", 2)
defineProperty("isVertical", false)
defineProperty("spacing", 35)
defineProperty("width", 30)
defineProperty("height", 29)

local white = {1, 1, 1, 1}

local MOUSE_OFF = 1
local MOUSE_HOVER = 2
local MOUSE_DOWN = 3
local mouse_status = MOUSE_OFF

local IS_CHECKED = 1
local IS_UNCHECKED = 2

for i = 1, get(num_radio_buttons) do
    if radio_group_id[get(my_radio_group_id)]["checked"] == i then
        radio_group_id[get(my_radio_group_id)][i] = IS_CHECKED
    else
        radio_group_id[get(my_radio_group_id)][i] = IS_UNCHECKED
    end
end

radio_group_lib = {}
function radio_group_lib.doMouseUp (button, parentX, parentY, button_name, r_id)
    for i = 1, get(num_radio_buttons) do
        if i == r_id then
            radio_group_id[get(my_radio_group_id)][i] = IS_CHECKED
        else
            radio_group_id[get(my_radio_group_id)][i] = IS_UNCHECKED
        end
    end
    flexdash_lib.doMouseUp (button, parentX, parentY, "radio_group", {get(my_radio_group_id), r_id})
end

function draw ()
    drawAll (components)
end

components = {}

for i = 1, get(num_radio_buttons) do
    local n = (i-1)*get(spacing)
    if get(isVertical) then
        tPosition = {0,n,30,29}
    else
        tPosition = {n,0,30,29}
    end
    table.insert (components, flexdash_ui_radio {  position = tPosition, width = 30, height = 29, my_radio_group = get(my_radio_group_id), my_radio_id = i})
end

function update ()
    if get(my_radio_group_id) < 10 or get(my_radio_group_id) == 12 then
        for i = 1, get(num_radio_buttons) do
            if radio_group_id[get(my_radio_group_id)]["checked"] == i then
                radio_group_id[get(my_radio_group_id)][i] = IS_CHECKED
            else
                radio_group_id[get(my_radio_group_id)][i] = IS_UNCHECKED
            end
        end
    end
end    