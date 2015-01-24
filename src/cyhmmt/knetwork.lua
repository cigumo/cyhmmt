local socket= require "socket"
local serpent= require "serpent"
local zlib= require "zlib"
local default_port= 10000

local knetwork= {}
knetwork.compression= true

------------
-- server
-----------

local metat = { __index = {} }

function knetwork.new_server()
   local server= { _clients = {},
                   _sockets_to_clients = {} }
   setmetatable(server, metat)
   return server
end

function metat.__index:listen(bind_address, port)
   local s, err= socket.bind(bind_address or "0.0.0.0", port or default_port)
   if not s then
      print("knetwork: socket.bind() failed: " .. err)
      return
   end
   self.socket= s
   self.socket:settimeout(0.0, 't') -- non-blocking operation
   self.socket:setoption('tcp-nodelay', true)
end

function metat.__index:send(msg, client_id)
   local client
   if client_id then
      client= self._clients[client_id]
      self:_send(msg, client)
   else
      -- send msg to ALL clients
      for cid, client in pairs(self._clients) do
         self:_send(msg, client)
      end
   end
end

function metat.__index:receive(client_id)
   local client= self._clients[client_id]
   return client:receive()
end

local function frame(msg)
   local serialized_msg= serpent.dump(msg)
   
   if knetwork.compression then
      serialized_msg = zlib.compress(serialized_msg)
   end

   local frame= serialized_msg:len() .. '\n' .. serialized_msg
   return frame
end

function metat.__index:_send(msg, client)
   client.socket:send(frame(msg))
end

function metat.__index:clients()
   return self._clients
end

function metat.__index:disconnect(client)
   local client_obj = type(client) == 'string' and self._clients[client] or client
   
   -- remove this client from our clients tables
   self._clients[client_obj]= nil
   self._sockets_to_clients[client_obj.socket]= nil

   -- and disconnect this client
   client_obj:disconnect()
end

local function deframe(client_obj)
   local socket= client_obj.socket

   while true do
      local header, err
      -- read one line (\n marks the end of header)
      local bytes_to_read
      repeat 
         repeat
            header, err= socket:receive("*l")
            if not header then
               if err == 'timeout' then
                  coroutine.yield()
               else
                  print("deframe coroutine ends because: " .. err)
                  return err
               end
            end
         until header
         ---- print("received header: ", header)

         -- now read the number of bytes specified by the header
         bytes_to_read= tonumber(header)
         if bytes_to_read == nil then -- header couldn't be parsed as a number
            print("ignoring malformed header (): " .. header)
         end
      until bytes_to_read

      local chunks= {}
      repeat 
         local chunk, err, partial= socket:receive(bytes_to_read)
         if chunk then
            chunks[#chunks + 1] = chunk
            bytes_to_read = bytes_to_read - chunk:len()  -- assert(length(chunk)==bytes_toread)
         elseif err=='timeout' then
            chunks[#chunks + 1] = partial
            bytes_to_read = bytes_to_read - partial:len()
            coroutine.yield()
         else
            print("deframe coroutine ends because: " .. err)
            return err
         end
         assert(bytes_to_read >= 0, "OOPS, byte_to_read is < 0 ")
      until (bytes_to_read == 0)

      local payload= table.concat(chunks)
      ---- print("received frame with payload: " .. payload)
      
      if (knetwork.compression) then
         payload= zlib.uncompress(payload, payload:len() * 10) -- TODO fix this
      end
      
      local lua_chunk= loadstring(payload)
      if lua_chunk then
         client_obj.inbox[#(client_obj.inbox) + 1]= lua_chunk()
      else
         print("failed deserialize lua object: " .. payload)
      end
   end
end

-- pop all messages received from client
local function messages(client_obj)
   local msgs = client_obj.inbox
   client_obj.inbox= {}
   return msgs
end

local function disconnect(client_obj)
   client_obj.socket:shutdown('both')
   client_obj.socket= nil
end

function metat.__index:update()
   -- are there any clients waiting?
   local client, err = self.socket:accept()
   if client then
      local remote_host, remote_port = client:getpeername()
      local client_id= remote_host .. ":" .. remote_port

      client:settimeout(0)
      local client_obj = { id=         client_id,
                           socket=     client,
                           receive=    messages,
                           messages=   messages,
                           disconnect= disconnect,
                           _receive_and_deframe= coroutine.wrap(deframe),
                           inbox = {} }
      self._clients[client_id]= client_obj
      self._sockets_to_clients[client_obj.socket] = client_obj -- luasocket -> client mapping is a good thing to have because of select()

      print("knetwork: client arrived: " .. client_id)
   end
   
   -- TODO: the active_clients_sockets array can be cached and updated only when a client arrives/leaves
   -- We need an array because that's how socket.select() wants the socket, a table won't do.
   local active_clients_sockets= {}
   for client_id, client_obj in pairs(self._clients) do
      active_clients_sockets[#active_clients_sockets+1]= client_obj.socket
   end
   
   -- select on received data from clients
   local rd, wr, err= socket.select(active_clients_sockets, nil, 0.0)
   if not err then
      for i=1,#rd do
         local client_obj= self._sockets_to_clients[rd[i]]
         if client_obj then
            local rx_err= client_obj:_receive_and_deframe()
            if rx_err then
               self:disconnect(client_obj)
            end
         end
      end
   elseif err ~= 'timeout' then
      print("select() returned with error: " .. err)
   end
end

------------
-- client
------------

local metat = { __index = {} }

function knetwork.new_client()
   local client= { socket= nil,
                   receive= messages,
                   messages= messages,
                   _receive_and_deframe= coroutine.wrap(deframe),
                   inbox = {} }
   setmetatable(client, metat)
   return client
end

function metat.__index:connect(host, port)
   local tcp= socket.tcp()
   tcp:settimeout(10)
   local c, err= socket.connect(host or "localhost", port or default_port)
   if c then
      self.socket= c
      self.socket:settimeout(0.0, 't')
      self.socket:setoption('tcp-nodelay', true)
   else
      print("failed to connect to " .. host .. ":" .. port .. " error: " .. err)
   end
end

function metat.__index:send(msg)
   if self.socket then
      self.socket:send(frame(msg))
   else
      print("client:send() can't send msg. Client is not connected yet.")
   end
end

-- CLIENT: update 
function metat.__index:update(host, port)
   if self.socket then
      local rd, wr, err= socket.select({self.socket}, nil, 0.0)
      if not err then
         self:_receive_and_deframe()
      elseif err ~= 'timeout' then
         print("select() returned with error: " .. err)
      end
   end
end

return knetwork

