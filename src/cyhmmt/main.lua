--
-- main 
-- 

require 'klua.repl'
require 'klua.table'
local log = require 'klua.log'
log.level = log.DEBUG_LEVEL
--log.simulation.level = log.INFO_LEVEL

----------------------------------------------------------------------
-- callbacks ---------------------------------------------------------


function love.load(arg)   
    -- command line arguments 
    local F_MODE = nil
    local REPL_PORT = nil
    local SERVER_BIND_HOST = '0.0.0.0'
    local SERVER_HOST = '127.0.0.1' 
    local SERVER_PORT = 10000
    if table.contains(arg, '-server') then 
        F_MODE = 'server'
        REPL_PORT = 9000
    elseif table.contains(arg, '-pilot') then 
        F_MODE = 'pilot'
        REPL_PORT = 9001
    elseif table.contains(arg, '-engineer') then 
        F_MODE = 'engineer'
        REPL_PORT = 9002
    else
        print('USAGE: love cyhmmt (-server | -pilot | -engineer)')        
        love.event.quit()
        return
    end
    
    local F_DEBUG = table.contains(arg, '-debug')  -- -debug for ZeroBrane

    -- for ZeroBrane debugging
    if F_DEBUG then
        local m = require("mobdebug")
        m.coro()   -- coroutine debugging
        m.start()
    else
        repl_init(REPL_PORT)
    end

    local screen_w,screen_h = 1024,768

    local engine = nil
    local success = false
    if F_MODE == 'server' then 
        screen_w,screen_h = 300,100
        engine = require 'server'
        success = engine:init(screen_w, screen_h, SERVER_BIND_HOST, SERVER_PORT)
    elseif F_MODE == 'pilot' then 
        engine = require 'pilot'
        success = engine:init(screen_w, screen_h, SERVER_HOST, SERVER_PORT)
    elseif F_MODE == 'engineer' then 
        engine = require 'engineer'
        success = engine:init(screen_w, screen_h, SERVER_HOST, SERVER_PORT)
    end

    if not success then 
        log.error('Error starting engine %s', F_MODE)
        love.event.quit()
    end

    love.update        = function(dt) 
                             if arg[#arg] ~= "-debug" then 
                                 repl_t()
                             end
                             engine:update(dt)
                         end
    love.draw          = function() engine:draw() end
    --love.keypressed    = function(key, isrepeat) engine:keypressed(key, isrepeat) end
    --love.keyreleased   = function(key, isrepeat) engine:keyreleased(key) end
    --love.mousepressed  = function(x,y,button) engine:mousepressed(x,y,button) end
    --love.mousereleased = function(x,y,button) engine:mousereleased(x,y,button) end
    
    love.window.setMode(screen_w, screen_h, {centered=false})
end

----------------------------------------

local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errhand(msg)
    msg = tostring(msg)
    error_printer(msg, 2)

    if not love.window or not love.graphics or not love.event then
        return
    end

    if not love.graphics.isCreated() or not love.window.isCreated() then
        if not pcall(love.window.setMode, 800, 600) then
            return
        end
    end

    -- Reset state.
    if love.mouse then
        love.mouse.setVisible(true)
        love.mouse.setGrabbed(false)
    end
    if love.joystick then
        for i,v in ipairs(love.joystick.getJoysticks()) do
            v:setVibration() -- Stop all joystick vibrations.
        end
    end
    if love.audio then love.audio.stop() end
    love.graphics.reset()

    return
end
