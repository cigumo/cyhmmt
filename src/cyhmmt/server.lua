--
-- server engine
-- 

require 'serpent'
local log = require 'klua.log'
local km = require 'klua.macros'
local knet = require 'knetwork'
local vector = require 'hump.vector'

local F = require 'font_db'
local commands = require 'commands'
local server_sim = require 'server_sim'
require 'constants' 

------------------------------------------------------------

local server = {} 

server.tick = 0
server.clients = {} 
server.ns = nil
server.data = {} 
server.status = 'S_SERVER_WAITING'
server.bcast_every = 1    -- ticks  
server._ssleep = 0

------------------------------------------------------------

function server:init(screen_w, screen_h, host, port)
    F:load()
    log.info('starting server')
    self.rt = 0
    self.screen_w = screen_w
    self.screen_h = screen_h
    self.last_cmd_in = nil
    self.data = server_sim.init()
    self.ns = knet.new_server()
    self.ns:listen(host, port)
    return (self.ns.socket ~= nil)
end

function server:update(dt)
    self.rt = self.rt + dt  -- realtime

    local ns = self.ns
    
    if self._ssleep > 0 then 
        self._ssleep = self._ssleep - (dt * 1000)
        return
    end

    if self.status == 'S_SERVER_WAITING' then 
        -- wait for clients
        if #self.clients < 2 then
            log.debug('Waiting for clients...')
            ns:update()
            self.clients = table.keys(ns:clients())
            log.debug('Current clients:%s', table.concat(self.clients, ','))
            self._ssleep = 1   -- seconds
        else 
            log.debug('All clients connected!')
            for i,client_id in pairs(self.clients) do 
                -- set client ids
                log.debug('sending client id to %s', client_id)
                ns:send(commands.new('server',
                                     self.tick,
                                     CMD_SET_CLIENT_ID,
                                     client_id), 
                        client_id)
                log.debug('Sending client id to %s', client_id)
            end
            self.status = S_SERVER_PLAYING
            self._ssleep = 0
        end

    elseif self.status == 'S_SERVER_PLAYING' then 
        ns:update()
        -- process commands and update simulation
        for _,client_id in pairs(self.clients) do 
            local cmds = ns:receive(client_id)
            for i=1,#cmds do
                log.debug('CMD IN < client_id:%s cmd_id:%s', client_id, cmds[i].cmd_id)
                self.last_cmd_in = cmds[i]
                server_sim.process_command(self.data,cmds[i])
            end
        end
        server_sim.update(self.data,self.tick)
        -- send game state to all clients every bcast ticks
        if (self.tick % self.bcast_every == 0) then
            --log.debug('CMD OUT > sending game state to clients at tick %i', self.tick)
            ns:send(commands.new('server',
                                 self.tick,
                                 CMD_SET_STATE,
                                 self.data))
        end                
        self.tick = self.tick + 1            
        self._ssleep = K_GAME_TICK_LENGTH + self._ssleep 
    end
    
end

function server:draw()
    local G = love.graphics
    G.setFont(F.regular_8)
    local lh = G.getFont():getHeight()
    local l = 10
    local r = self.screen_w - 10
    local y = lh

    G.printf('Server status: ' .. self.status, l, y, r, 'left')
    y = y + lh
    if self.last_cmd_in then 
        G.printf('Last cmd in: ' .. self.last_cmd_in, l, y, r, 'left')
        y = y + lh
    end
end

------------------------------------------------------------

return server
