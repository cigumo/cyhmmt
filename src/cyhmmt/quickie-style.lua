--
-- custom style for cyhmmt
--

local utf8 = require 'quickie.utf8'
local F = require 'font_db'
local I = require 'image_db'
local G = love.graphics

------------------------------------------------------------

-- default style
local color = {
	normal = {bg = {78,78,78}, fg = {200,200,200}, border={20,20,20}},
	hot    = {bg = {98,98,98}, fg = {69,201,84},   border={30,30,30}},
	active = {bg = {88,88,88}, fg = {49,181,64},   border={10,10,10}}
}

-- box drawing
local gradient = {}
function gradient:set(from, to)
	local id = love.image.newImageData(1,2)
	id:setPixel(0,0, to,to,to,255)
	id:setPixel(0,1, from,from,from,255)
	gradient.img = G.newImage(id)
	gradient.img:setFilter('linear', 'linear')
end
gradient:set(200,255)

local function box(x,y,w,h, bg, border, flip)
	G.setLineWidth(1)
	G.setLineStyle('rough')

	G.setColor(bg)
	local sy = flip and -h/2 or h/2
	G.draw(gradient.img, x,y+h/2, 0,w,sy, 0,1)
	G.setColor(border)
	G.rectangle('line', x,y,w,h)
end

-- load default font
if not G.getFont() then
	G.setFont(G.newFont(12))
end

local function Button(state, title, x,y,w,h)
	local c = color[state]
	box(x,y,w,h, c.bg, c.border, state == 'active')
	local f = assert(G.getFont())
	x,y = x + (w-f:getWidth(title))/2, y + (h-f:getHeight(title))/2
	G.setColor(c.fg)
	G.print(title, x,y)
end

local function Label(state, text, align, x,y,w,h)
	local c = color[state]
	G.setColor(c.fg)
	local f = assert(G.getFont())
	y = y + (h - f:getHeight(text))/2
	if align == 'center' then
		x = x + (w - f:getWidth(text))/2
	elseif align == 'right' then
		x = x + w - f:getWidth(text)
	end
	G.print(text, x,y)
end

local function Slider(state, fraction, vertical, x,y,w,h)
    local bg,bg_w,bg_h = I:i('slider_bg')
    local handle,handle_w,handle_h = I:i('slider_handle')

    G.draw(bg, x+handle_w/2 - bg_w/2, y)
    G.draw(handle, x, y + h - h * fraction - handle_h/2)
    
    --local c = color[state]	
    --G.setLineWidth(1)
    --G.setLineStyle('rough')
    --G.setColor(c.bg)
    --if vertical then
    --    G.rectangle('fill', x+w/2-2,y,4,h)
    --    G.setColor(c.border)
    --    G.rectangle('line', x+w/2-2,y,4,h)
    --    y = math.floor(y + h - h * fraction - 5)
    --    h = 10
    --else
    --    G.rectangle('fill', x,y+h/2-2,w,4)
    --    G.setColor(c.border)
    --    G.rectangle('line', x,y+h/2-2,w,4)
    --    x = math.floor(x + w * fraction - 5)
    --    w = 10
    --end
    --box(x,y,w,h, c.bg,c.border)
end

local function Slider2D(state, fraction, x,y,w,h)
	local c = color[state]
	box(x,y,w,h, c.bg, c.border)

	-- draw quadrants
	G.setLineWidth(1)
	G.setLineStyle('rough')
	G.setColor(c.fg[1], c.fg[2], c.fg[3], math.min(127,c.fg[4] or 255))
	G.line(x+w/2,y, x+w/2,y+h)
	G.line(x,y+h/2, x+w,y+h/2)

	-- draw cursor
	local xx = math.ceil(x + fraction[1] * w)
	local yy = math.ceil(y + fraction[2] * h)
	G.setColor(c.fg)
	G.line(xx-3,yy,xx+2.5,yy)
	G.line(xx,yy-2.5,xx,yy+2.5)
end

local function Input(state, text, cursor, x,y,w,h)
	local c = color[state]
	box(x,y,w,h, c.bg, c.border, state ~= 'active')

	local f = G.getFont()
	local th = f:getHeight(text)
	local cursorPos = x + 2 + f:getWidth(utf8.sub(text, 1,cursor))
	local offset = 2 - math.floor((cursorPos-x) / (w-4)) * (w-4)

	local tsx,tsy,tsw,tsh = x+1, y, w-2, h
	local sx,sy,sw,sh = G.getScissor()
	if sx then -- intersect current scissors with our's
		local l,r = math.max(sx, tsx), math.min(sx+sw, tsx+tsw)
		local t,b = math.max(sy, tsy), math.min(sy+sh, tsy+tsh)
		if l > r or t > b then -- there is no intersection
			return
		end
		tsx, tsy, tsw, tsh = l, t, r-l, b-t
	end

	G.setScissor(tsx, tsy, tsw, tsh)
	G.setLineWidth(1)
	G.setLineStyle('rough')
	G.setColor(color.normal.fg)
	G.print(text, x+offset,y+(h-th)/2)
	if state ~= 'normal' then
		G.setColor(color.active.fg)
		G.line(cursorPos+offset, y+4, cursorPos+offset, y+h-4)
	end
	if sx then
		G.setScissor(sx,sy,sw,sh)
	else
		G.setScissor()
	end
end

local function Checkbox(state, checked, label, align, x,y,w,h)
	local c = color[state]
	local bw, bx, by  = math.min(w,h)*.7, x, y
	by = y + (h-bw)/2

	local f = assert(G.getFont())
	local tw,th = f:getWidth(label), f:getHeight(label)
	local tx, ty = x, y + (h-th)/2
	if align == 'left' then
		-- [ ] LABEL
		bx, tx = x, x+bw+4
	else
		-- LABEL [ ]
		tx, bx = x, x+4+tw
	end

	box(bx,by,bw,bw, c.bg, c.border)

	if checked then
		bx,by = bx+bw*.25, by+bw*.25
		bw = bw * .5
		G.setColor(color.active.fg)
		box(bx,by,bw,bw, color.hot.fg, {0,0,0,0}, true)
	end

	G.setColor(c.fg)
	G.print(label, tx, ty)
end


-- the style
return {
	color    = color,
	gradient = gradient,

	Button   = Button,
	Label    = Label,
	Slider   = Slider,
	Slider2D = Slider2D,
	Input    = Input,
	Checkbox = Checkbox,
}
