----------------------------------------------------------------------
-- commands ----------------------------------------------------------
-- 
-- command = { 
--             source_id = 'xxx'   -- id handled by network server
--             cmd_id = 'cmd_xxx'  -- identifier for the command
--             data = { ... }      -- table filled with custom data
--           }

-- commands sent by client
CMD_TOGGLE_PICKUP_BLOCK = 'CMD_TOGGLE_PICKUP_BLOCK'   -- data={['x']=x, ['y']=y}
CMD_TOGGLE_DROP_BLOCK   = 'CMD_TOGGLE_DROP_BLOCK'     -- data={['x']=x, ['y']=y}
CMD_SET_UNIT_DESTINATION= 'CMD_SET_UNIT_DESTINATION'  -- data={['id']=id, ['x']=x, ['y']=y}
CMD_SET_UNIT_TARGET     = 'CMD_SET_UNIT_TARGET'       -- data={['id']=id, ['x']=x, ['y']=y}
-- commands sent by server
CMD_SET_STATE           = 'CMD_SET_STATE'             -- data = Simulation.store
CMD_SET_CLIENT_ID       = 'CMD_SET_CLIENT_ID'         -- data = client_id


------------------------------

local commands = {}

function commands.new(source_id,tick,cmd_id,data)
    return {
        ['source_id'] = source_id,
        ['tick'] = tick,
        ['cmd_id'] = cmd_id,
        ['data'] = data,
    }
end

------------------------------

return commands

