-- input.lua
defineProperty(bg, {1,1,1,1})

local fnt =  sasl.gl.loadFont(getXPlanePath() .. "Resources/fonts/DejaVuSansMono.ttf")
local last_char = " "

function draw()
	local w, h = size[3], size[4]
	drawRectangle(0, 0, 50, 50, get(bg))
	drawText(fnt, size[1]/2, size[2]/2, last_char, 60, false, false, TEXT_ALIGN_CENTER, {0,0,0,1})
end

local function process_key(char, vkey, shift, ctrl, alt, event)
	if event == KB_DOWN_EVENT then
		if char == SASL_KEY_ESCAPE or char == SASL_KEY_RETURN then
--			last_char = " "
			return true
		end
		last_char = string.char(char)
	end
	return false
end

function onMouseDown() register_handler(process_key) return true end
