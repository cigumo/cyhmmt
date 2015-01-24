-- klua remote repl, listens on port 9000 (default)
-- example usage
--  # rlwrap nc localhost 9000
--  >> a=20
--  >> return a
--  20
--  >> return a+20
--  40
--  >> plus20 = function(x) return x+20 end
--  >> plus20(40)
--  >> return plus20(40)
--  60
--  >> quit

local repl_port = 9000

local repl_bind_address= "127.0.0.1"          -- default

if _PLATFORM == "Mac" or _IOS_SIMULATOR or love then
  repl_bind_address= "127.0.0.1"
elseif _PLATFORM == "iOS" then
  repl_bind_address= "0.0.0.0"
end

-- local klog= require "klua_log"
-- klog= klog:new(klog.ERROR_LEVEL)
local klog= {
   debug= function (...) end,
   info= function (...) end,
   error= function (...) end
}

local socket = require "socket"

function repl_thread(port, bind_address)
    klog.info("entering repl_thread...")

    local server,err = socket.bind(bind_address, port)
    if not server then
        klog.error("bind failed with error: %s", err)
        return
    else
        klog.debug("bind success")
    end

    repl_clients = {}
    local ip, port = server:getsockname()
    local resolved_ip = socket.dns.toip(socket.dns.gethostname("localhost"))
    klog.info("================================================================")
    klog.info("|                                                               ")
    klog.info("|    accepting connections at %s %s:%d                          ",  socket.dns.gethostname("localhost"), tostring(resolved_ip), port)
    klog.info("|                                                               ")
    klog.info("================================================================")

    local client, err
    -- wait for a client to connect
    repeat
        server:settimeout(0.0001, 't')
        client, err = server:accept()

        if not client then
            coroutine.yield()
        else
            klog.info("a wild client appears! [%s:%s]", client:getpeername())
            handle_arriving_client(client)
        end

        local quit = false
        local error

        local active_clients={}
        for client, client_t in pairs(repl_clients) do
            active_clients[#active_clients+1]=client
        end

        -- select on read sockets
        local rd, wr, error = socket.select(active_clients ,nil, 0.0001)

        if not error then
            for i=1,#rd do
                local c = rd[i]
                coroutine.resume(repl_clients[c], c) -- coroutine, client
            end
        elseif error=="timeout" then
            coroutine.yield()
        end

    until false
end

function handle_arriving_client(c)
    klog.info("client arrived: %s", c:getpeername())
    local client_coroutine = coroutine.create(client_thread)
    repl_clients[c] = client_coroutine
    coroutine.resume(client_coroutine, c)
end

function handle_departing_client(c)
    klog.info("departing client: %s", c:getsockname())
    repl_clients[c] = nil
end


function client_thread(c)
    local client = c
    
    -- repl environment for the chunk
    local cenv = {}
    cenv['print']= (function (...)
                        _G.print(...)
                        local dots= {...}
                        for i=1,#dots do client:send(tostring(dots[i]).."\n") end
                    end)
    setmetatable(cenv, {__index = _G, __newindex= _G})
  

    client:send("HELLO!\n")

    local error, quit
    local accLine= ""
    repeat
        client:send(get_prompt(accLine == "" and 1 or 2))
        coroutine.yield()
        local line, err = client:receive()
        local val= nil

        if not err
        then
            if line=="quit" and accLine == "" then
                quit=true
            else
                accLine= accLine.."\n"..line
                local res, lerr = loadstring(accLine)
                if res==nil then
                    if not string.find(lerr, "near '<eof>'$") then   -- it was a real syntax error and not just incomplete code
                        print("error: " .. lerr)
                        val = lerr
                        accLine= ""                         -- abort the whole chunk
                    end
                else
                    accLine= ""                             -- the whole accLine parsed as a chunk so cleanup
                    -- build an environment for the chunk.
                    -- print() will write to stdout on the host _and_ send the
                    -- string back through the socket

                    setfenv(res, cenv)

                    -- evaluate the chunk function
                    local ok, result= xpcall( res, function(err) return debug.traceback(err, 3)  end )

                    if ok then
                        val = result
                    else
                        klog.error("repl chunk execution failed with error: %s", tostring(result))
                        val = result
                    end
                    -- val = res() --print ("res() es " .. res())
                end
                client:send( (val~=nil) and tostring(val).."\n" or "" )
            end
        else
            klog.error("socket error: " .. err .. "\n")
            quit = true
        end
    until quit

    handle_departing_client(client)
    -- client:send("bye\n")
    client:close()
    return
end

function get_prompt(level)
    local prompt
    if level==1 then
        prompt = _PROMPT  or "K> "
    else
        prompt = _PROMPT2 or "K>> "
    end
    return prompt
end

function repl_init(port, bind_address)
   port = port or repl_port
   bind_address = bind_address or repl_bind_address
   klog.debug("about to create coroutine")
   repl_coroutine = coroutine.create( function () repl_thread(port, bind_address) end)
end

function repl_t(a)
    -- klog.debug("entering")
    if repl_coroutine and coroutine.status(repl_coroutine) == "dead" then
        klog.error("====                         ====")
        klog.error("==== REPL may be unavailable ====")
        klog.error("====                         ====")
        repl_coroutine= nil
    end
    if not repl_coroutine then
        return
    end

    local yielded, err = coroutine.resume(repl_coroutine)

    if yielded then
        -- klog.debug("coroutine yielded")
    else
        klog.error("coroutine.resume failed with error: %s", err)
    end
    -- klog.debug("leaving")
end

-- In LOVE, add the following to main.lua:
-- 
-- function love.load()
--    require "repl"
--    repl_init(port)
-- end
-- 
-- function love.update()
--    repl_t()
-- end
