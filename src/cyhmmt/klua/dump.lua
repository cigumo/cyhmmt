----------------------------------------------------------------------
-- MARK: - Dumping and debugging                                     -
----------------------------------------------------------------------

-- call the basic Lua tostring
function rawtostring(v)
  local mt= getmetatable(v)
  local ret
  if mt and mt ~= nil then
    setmetatable(v, nil)
    ret= tostring(v)
    setmetatable(v, mt)
  else
    ret= tostring(v)
  end
  return ret
end

-- key comparator, comparing everything as string
local function keycomp(k1, k2)
  k1= tostring(k1)
  k2= tostring(k2)
  return k1 < k2
end



function getdump(t)
  return getfulldump(t, 1)
end

function dump(t)
  print(getdump(t))
end

function getfulldump(t, level, i)
  i= i or ""                  -- default starting indentation
  level= level or 99999999    -- level or almost infinity!
  currLevel= 1
  local seen={}               -- do not follow already seen tables

  local retstr                -- string to return

  local function _dump(t,i)
    seen[t]= true
 
    local keys= {}            -- store all keys in a sorted array
    local keyStrs= {}         -- and their tostrings here { [key] = { tostring(key), keyLength } }
    local maxKeyLen= 0
    for k,_ in pairs(t) do
      keys[#keys+1]= k
      keyStrs[k]= { type(k) == "string" and "'"..tostring(k).."'" or tostring(k) }  -- keyStrs[k][1]
      local klen= #(keyStrs[k][1])
      keyStrs[k][2]= klen
      maxKeyLen= maxKeyLen <= klen and klen or maxKeyLen
    end
    table.sort(keys, keycomp)     -- sort the keys

    -- _ is an index in the array of keys, k is the value of the key
    for _,k in ipairs(keys) do
      --                             i(ndent),  kstr,   ->, t[k], seen\n
      local arrowIndent= string.rep(" ", maxKeyLen - keyStrs[k][2]).."  "
      retstr= retstr..string.format("%s    [%s]", i, keyStrs[k][1])    -- indentation plus key
      retstr= retstr..arrowIndent
      retstr= retstr..string.format("->  %s\t%s\n",
                                    tostring(t[k]), seen[t[k]] and "(seen)"  or "")

      k= t[k]
      if type(k)=="table" and k ~= nil and not seen[k] and currLevel < level then
        currLevel= currLevel + 1
        _dump(k, i..arrowIndent.."    ")
        currLevel= currLevel - 1
      end
    end
  end

  retstr= "self: \t"..tostring(t).."\n"
  if t ~= nil then
    _dump(t, i)
  end
  return retstr
end -- getfulldump


function fulldump(t, level, i)
  print(getfulldump(t, level, i))
end -- fulldump


function getdumplocals(dumplevel)
  dumplevel= dumplevel or 1
  local locals={}
  for i=1,256 do
    local k,v= debug.getlocal(2, i)
    if k == nil then break end
    locals[k]= v
  end

  return getfulldump(locals, dumplevel)
end

-- Given a table t, and an array of keys, it returns a proxy table for t, which
-- transparently intercepts all read and write acceses to it.
-- The optional mode parameter is a string with letters from the set [wrt]
-- If mode contains 'w', a message is printed for all write accesses.
-- If mode contains 'r', a message is printed for all read accesses.
-- If mode contains 't', a debug.traceback will be added to the printed message.
-- If mode is not given, it defaults to "rw"
--
-- Notes:
--    1- This function works for normal tables and klua_classes instances
--    2- The original table t is *emptied* of all entries, but this is transparent
--       to all users of t which may already have references to it (unless they try
--       to traverse its k,v entries and find it empty!!!!)
--    3- If t is an instance of klua_classes, it will have proxy as its new metatbale,
--       so it will show as a normal table when dumped, and it may not respond to some
--       of the klua_classes magic
--    3- Once a table is proxified, it can't be unproxified yet!!!
function proxywatch(t, keys, mode)
    keys= type(keys) == "table"  and keys or {}
    mode= type(mode) == "string" and mode or "rw"

    local keyDict= table.map(keys, function(k, v) return v, true end)
    local rLog= string.find(mode, "r", 1, true)
    local wLog= string.find(mode, "w", 1, true)
    local tLog= string.find(mode, "t", 1, true)

    local proxy= table.clone(t)        -- new table with all k,v entries
    for k,v in pairs(t) do
        t[k]= nil                      -- empty t
    end

    local tmt= getmetatable(t)
    setmetatable(t, proxy)             -- we want the proxy to be the new mt for t
    setmetatable(proxy, tmt)           -- and chain proxy to t's old mt (if it's nil, no harm done)

    proxy.__index= function (t, k)
        local v= proxy[k]              -- may exist in proxy, or it may trigger a mt lookup
        if rLog and keyDict[k] then
            local msg= string.format("====== Reading from %s | %s ==> %s", tostring(t), tostring(k), tostring(v))
            if tLog then
                msg= debug.traceback(msg, 2)
            end
            print(msg)
        end
        return v
    end

    proxy.__newindex= function (t, k, v)
        if wLog and keyDict[k] then
            local msg= string.format("====== Writing to %s | %s <== %s", tostring(t), tostring(k), tostring(v))
            if tLog then
                msg= debug.traceback(msg, 2)
            end
            print(msg)
        end
        proxy[k]= v
    end

    return proxy
end

