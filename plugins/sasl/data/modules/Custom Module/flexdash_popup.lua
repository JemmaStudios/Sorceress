-- flexdash_popup.lua
local black	= {0, 0, 0, 1}
local cyan	= {0, 1, 1, 1}
local magenta	= {1, 0, 1, 1}
local yellow	= {1, 1, 0, 1}
local white = {1,1,1,1}
local roboto	= loadFont(getXPlanePath() .. "Resources/fonts/Roboto-Regular.ttf")

defineProperty("message", "message")
function draw()
	local x, y = size[1]/2, size[2]/2
    -- drawText(roboto, x, y, get(message), 16, false, false, TEXT_ALIGN_CENTER, white)
    drawTextI(roboto, x, y, get(message), TEXT_ALIGN_CENTER, white)
    drawAll ( components )
end