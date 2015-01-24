-- 
-- images database
-- 

local log = require 'klua.log'
local G = love.graphics
require 'klua.dump'

------------------------------------------------------------

local image_db = {} 
image_db.n = {}

function image_db:load()
    local image_files = {
        'images/btn-off.png',
        'images/btn-on.png',
        'images/gauge_bg.png',
        'images/slider_bg.png',
        'images/slider_handle.png',
    }

    for _,f in pairs(image_files) do
        local key = string.gsub(f, '.png$', '')
        key = string.gsub(key, '^images/', '')
        local i = G.newImage(f)
        local w,h = i:getDimensions()
        self.n[key] = {i,w,h}
    end

    log.debug('Images loaded\n%s', getfulldump(self.n))
end

function image_db:i(name)
    local i = self.n[name]
    if self.n[name] then 
        return i[1],i[2],i[3]
    else
        log.error('Image %s not found', name)
        return nil
    end
end

return image_db 
