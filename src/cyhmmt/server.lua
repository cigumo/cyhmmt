--
-- server engine
-- 

local log = require 'klua.log'
local km = require 'klua.macros'
local knet = require 'knetwork'

local signal = require 'hump.signal'
local timer = require 'hump.timer'
local vector = require 'hump.vector'

local commands = require 'commands'
local server_sim = require 'server_sim'

------------------------------------------------------------

local server = {} 

server.tick = 0
server.clients = {} 
server.ns = nil
server.data = {} 
server.statuses = enum {
    'S_SERVER_WAITING', 
    'S_SERVER_PLAYING'
}
server.status = 'S_SERVER_WAITING'
server.bcast_every = 1    -- ticks  
server._ssleep = 0

------------------------------------------------------------

function server.init()
    log.info('starting server')
    server.data = server_sim.init()
    server.ns = knet.new_server()
    server.ns:listen('0,0,0,0', 10000)
    return (server.ns.socket ~= nil)
end

function server.update(dt)
    local ns = server.ns
    
    if server._ssleep > 0 then 
        server._ssleep = server._ssleep(dt * 1000)
        return
    end

    if server.status == S_SERVER_WAITING then 
        -- wait for clients
        if #server.clients < 2 then
            log.debug('Waiting for clients...')
            ns:update()
            server.clients = keys(ns:clients())
            log.debug('Current clients:%s', table.concat(server.clients, ','))
            server._ssleep = 1   -- seconds
        else 
            log.debug('All clients connected!')
            for i,client_id in pairs(server.clients) do 
                -- set client ids
                log.debug('sending client id to %s', client_id)
                ns:send(commands.new('server',
                                     server.tick,
                                     CMD_SET_CLIENT_ID,
                                     client_id), 
                        client_id)
                log.debug('Sending client id to %s', client_id)
            end
            server.status = S_SERVER_PLAYING
            server._ssleep = 0
        end

    elseif server.status == S_SERVER_PLAYING then 
        ns:update()
        -- process commands and update simulation
        for _,client_id in pairs(server.clients) do 
            local cmds = ns:receive(client_id)
            for i=1,#cmds do
                log.debug('CMD IN < client_id:%s cmd_id:%s', client_id, cmds[i].cmd_id)
                server_sim.process_command(server.data,cmds[i])
            end
        end
        server_sim.update(server.data,server.tick)
        -- send game state to all clients every bcast ticks
        if (server.tick % server.bcast_every == 0) then
            --log.debug('CMD OUT > sending game state to clients at tick %i', server.tick)
            ns:send(commands.new('server',
                                 server.tick,
                                 CMD_SET_STATE,
                                 server.data))
        end                
        server.tick = server.tick + 1            
        server._ssleep = server_sim.tick_length + server._ssleep 
    end

    end
end

------------------------------------------------------------

return server
