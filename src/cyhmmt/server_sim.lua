-- 
-- Server Simulation / Game and Ship data
-- 

------------------------------------------------------------
local log = require 'klua.log'
local km = require 'klua.macros'
local knet = require 'knetwork'
local signal = require 'hump.signal'
local timer = require 'hump.timer'
local vector = require 'hump.vector'
local commands = require 'commands'
require 'constants'

------------------------------------------------------------

local server_sim = {} 

------------------------------------------------------------

function server_sim.init()
    local data = {}
    return data
end

function server_sim.update(data,tick)
    -- TODO: update game state
    -- TODO: update ship state
end

function server_sim.process_command(data,cmd)
    local f = simulation.command_handlers[cmd.cmd_id]
    if f ~= nil then
        f(data,cmd)
    else
        log.error('command handler for %s not found', cmd.cmd_id)
    end
end

------------------------------------------------------------
-- command handlers -- 

server_sim.command_handlers = {
    --[CMD_TOGGLE_PICKUP_BLOCK] = simulation.cmd_toggle_block_selection, 
    
}

-----------------------------------------------------------

return server_sim
