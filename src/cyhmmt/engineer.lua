--
-- engineer
--

local serpent = require 'serpent'
local log = require 'klua.log'
local km = require 'klua.macros'
local knet = require 'knetwork'
local vector = require 'hump.vector'

local commands = require 'commands'
require 'constants'

local F = require 'font_db'
local I = require 'image_db'
local Q = require "quickie"
local G = love.graphics

------------------------------------------------------------
local engineer = {} 

------------------------------------------------------------
-- engineer 


function engineer:init(screen_w, screen_h, host, port)
    log.info('Starting engineer...')
    self.screen_w = screen_w
    self.screen_h = screen_h
    self.rt = 0   -- real time

    -- session init
    self.session = {}
    self.session.status = 'S_INIT'
    self.session.ts = 0
    self.session.tick = nil
    self.session.game_state = nil 
    self.session.nc = knet.new_client()
    self.session.nc:connect(host, port)
    if self.session.nc.socket == nil then 
        log.error('Connection to %s:%s failed', host, port)
        return nil 
    end
    log.debug('Connected.')

    -- ui init
    self:init_ui()

    return true
end

function engineer:update(dt)
    self.rt = self.rt + dt  -- realtime

    -- session update
    local s = self.session
    s.nc:update()

    if s.status == 'S_INIT' then 
        -- wait for first game update
        for i,msg in pairs(s.nc:receive()) do
            log.debug('recv:%s', serpent.block(msg))
            if msg.cmd_id == CMD_SET_CLIENT_ID then 
                s.client_id = msg.data
                log.debug('Clientid set to: %s', s.client_id)
            elseif msg.cmd_id == CMD_SET_STATE then 
                s.game_state = msg.data 
                s.tick = msg.tick
                log.debug('Initial game state set from server.')
                break
            end
        end
        if s.game_state and s.client_id then 
            s.status = 'S_PLAY'
        end

    elseif s.status == 'S_PLAY' then 
        for i,msg in pairs(s.nc:receive()) do
            if msg.cmd_id == CMD_SET_STATE then 
                s.game_state = msg.data
            end
        end
        s.ts = s.ts + dt * 1000
        if s.ts > K_GAME_TICK_LENGTH then 
            s.ts = s.ts - K_GAME_TICK_LENGTH
            s.tick = s.tick + 1
        end
    end

    -- ui update
    self:update_ui(dt)
end

function engineer:draw()
    Q.core.draw()
end

------------------------------------------------------------
-- ui handler functions 

function engineer:handle_cooldown_primary()
    log.debug('')
end
function engineer:handle_refuel_primary()
    log.debug('')
end
function engineer:handle_refuel_secondary()
    log.debug('')
end
function engineer:handle_refuel_thrust()
    log.debug('')
end
function engineer:handle_refuel_tractor()
    log.debug('')
end

------------------------------------------------------------

function engineer:init_ui()    
    F:load()
    I:load()    

    Q.core.style = require 'quickie-style'
    Q.group.default.spacing = 20

    local ui = {} 
    self.ui = ui

    -- ui values
    ui.primary_power = { value=0 }
    ui.primary_rate = { value=0 }
    ui.secondary = { value=0 }
    ui.thrust = { value=0 }
    ui.tractor = { value=0 }
end

function engineer:update_ui(dt)
    local ui = self.ui

    -- handles
    Q.group.push{ grow="right", pos={0,50} }

    G.setFont(F.cond_16)

    Q.group.push{ grow="down" }
    Q.Label{ text='WEAPON POWER', size = {88} }
    Q.Slider{ info=self.ui.primary_power, vertical=true, size={88,174} }
    if Q.Button{ text='REFUEL' } then 
        self:handle_refuel_primary()
    end
    Q.group.pop{}

    Q.group.push{ grow="down" }
    Q.Label{ text='WEAPON RATE', size = {88} }
    Q.Slider{ info=self.ui.primary_rate, vertical=true, size={88,174} }
    if Q.Button{ text='COOLDOWN' } then 
        self:handle_cooldown_primary()
    end
    Q.group.pop{}

    Q.group.push{ grow="down" }
    Q.Label{ text='SECONDARY', size = {88} }
    Q.Slider{ info=self.ui.secondary, vertical=true, size={88,174} }
    if Q.Button{ text='REFUEL' } then 
        self:handle_refuel_secondary()
    end
    Q.group.pop{}

    Q.group.push{ grow="down" }
    Q.Label{ text='THRUST', size = {88} }
    Q.Slider{ info=self.ui.thrust, vertical=true, size={88,174} }
    if Q.Button{ text='REFUEL' } then 
        self:handle_refuel_thrust()
    end
    Q.group.pop{}

    Q.group.push{ grow="down" }
    Q.Label{ text='TRACTOR', size = {88} }
    Q.Slider{ info=self.ui.tractor, vertical=true, size={88,174} }
    if Q.Button{ text='REFUEL' } then 
        self:handle_refuel_tractor()
    end
    Q.group.pop{}
    -- end handles

    Q.group.pop{}
end


------------------------------------------------------------

return engineer
