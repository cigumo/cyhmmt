--
-- fonts db
-- 

local G = love.graphics
 
------------------------------------------------------------

local font_db = {} 

function font_db:load()
    local font_chars = "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`'*#=[]\\\"ÁÉÍÓÚÑáéíóúñ¿¡_"

    self.regular_8  = G.newImageFont('fonts/font_04b03_8.png', font_chars)
    self.cond_8     = G.newImageFont('fonts/font_04b24_8.png', font_chars)
    self.regular_16 = G.newImageFont('fonts/font_04b03_16.png', font_chars)
    self.cond_16    = G.newImageFont('fonts/font_04b24_16.png', font_chars)

    G.setFont(self.regular_8)    
end

return font_db
