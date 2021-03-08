-- flexdash_saverestore.lua
local black	= {0, 0, 0, 1}
local cyan	= {0, 1, 1, 1}
local magenta	= {1, 0, 1, 1}
local yellow	= {1, 1, 0, 1}
local red       = {1, 0, 0, 1}
local white = {1,1,1,1}
local shadow_offset = 2
local urbanist	= loadFont("fonts/Urbanist-ExtraBold.ttf")
sasl.gl.setFontSize ( urbanist, 16 )
local bkgnd_image = sasl.gl.loadImage ("ui_assets/fd_background_LT.png ", 0, 0, 400 , 200)

defineProperty("message", "Hello World!")

local button_images = {}
button_images["save"] = {50, 20, 148, 48}
button_images["restore"] = {202, 20, 148, 48}

flexdash_lib = {}

function flexdash_lib.doMouseUp (button, parentX, parentY, button_name)
    savefirst_flags["close"] = true
    if button_name == "fd_restore_button" then
        savefirst_flags["doRestore"] = true
    elseif button_name == "fd_save_button" then
        savefirst_flags["doSave"] = true
    end
end

function flexdash_lib.doMouseHold (button, parentX, parentY, button_name)
end

function flexdash_lib.doMouseDown (button, parentX, parentY, button_name)
end

function draw()
	local x, y = size[1]/2, (size[2]/2)+25

    -- drawText(urbanist, x, y, get(message), 16, false, false, TEXT_ALIGN_CENTER, white)
    sasl.gl.drawTexture ( bkgnd_image , 0, 0, 400 , 200)
    drawTextI(urbanist, x+shadow_offset, y-25-shadow_offset, get(message), TEXT_ALIGN_CENTER, black)
    drawTextI(urbanist, x, y-25, get(message), TEXT_ALIGN_CENTER, white)

    drawAll (components)
end

components = {
    flexdash_ui_button {    position=button_images["save"],
                            width = 148,
                            height = 48,
                            button_name = "fd_save_button"},
    flexdash_ui_button {    position=button_images["restore"],
                            width = 148,
                            height = 48,
                            button_name = "fd_restore_button"},
}