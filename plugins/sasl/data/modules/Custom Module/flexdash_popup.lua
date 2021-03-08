-- flexdash_popup.lua
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
function draw()
	local x, y = size[1]/2, size[2]/2
    -- drawText(urbanist, x, y, get(message), 16, false, false, TEXT_ALIGN_CENTER, white)
    sasl.gl.drawTexture ( bkgnd_image , 0, 0, 400 , 200)
    drawTextI(urbanist, x+shadow_offset, y-25-shadow_offset, get(message), TEXT_ALIGN_CENTER, black)
    drawTextI(urbanist, x, y-25, get(message), TEXT_ALIGN_CENTER, white)
end
