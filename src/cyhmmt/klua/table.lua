----------------------------------------------------------------------
-- MARK: - Tables                                                    -
----------------------------------------------------------------------

-- return a table with all the keys of the given table, in no particular order
function table.keys(t)
  local kk= {}
  local count= 0
  for k,_ in pairs(t) do count= count+1; kk[count]= k end
  return kk
end

-- return the first key for object o in the table t
function table.keyforobject(t, o)
   local key = nil
   for k,v in pairs(t) do
      if (o == v) then
         key = k
         break
      end
   end
   return key
end


-- different syntax for keyforobject and bool value
function table.contains(t,o)
    return (table.keyforobject(t,o) ~= nil )
end

-- shallow table clone
function table.clone(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

-- deep clone (WARNING: only works for data, will loop forever with data loops)
function table.deepclone(t)
    if type(t) == 'table' then
        local out = {} 
        for k,v in pairs(t) do
            out[k] = table.deepclone(v)
        end
        return out
    else
        return t
    end
end


-- Merge t1, and t2
-- Returns t1, containing also all the entries from t2
-- For identical keys, the entries from t2 override the entries from t1
-- Table t2 is unchanged.
-- If the 'new' argument is true, a new table is returned (and t1 is also unchanged)
function table.merge(t1, t2, new)
    local m= new and table.clone(t1) or t1
    for k,v in pairs(t2) do
        m[k]= v
    end
    return m
end

-- Append arrays t1 and t2
-- Returns t1 or a new table, appending array entries from t2 only
function table.append(t1, t2, new)
    local m = new and table.clone(t1) or t1
    for i,v in ipairs(t2) do
        table.insert(m,v)
    end
    return m
end

-- Reverse array copy
function table.reverse(t1)
    local t2 = {} 
    local l_t1 = #t1
    for i=1,l_t1 do
        t2[i] = t1[l_t1-i+1]
    end
    return t2
end

-- returns count of items accepted by the boolean filter(k, v) function
-- if filter is nil/not-given, it will return a count of keys
function table.count(t, filter)
    local ct= 0
    if filter then
        for k,v in pairs(t) do
            if filter(k, v) then ct= ct + 1 end
        end
    else
        for k,v in pairs(t) do ct= ct + 1 end
    end

    return ct
end


-- Returns the key of the first element in table t matching the filter
-- Filter may be:
--    * a boolean function receiving key and value
--    * not a function, in which case the comparison is done with == for
--      each value in table t agains the filter object, until a match is
--      found
--
-- Returns nil if no match was found
function table.find(t, filter)
    if type(filter) == "function" then
        for k,v in pairs(t) do
            if filter(k, v) then return k end
        end
    else
        for k,v in pairs(t) do
            if filter == v then return k end
        end
    end

    return nil
end


-- returns a new array with the values accepted by the boolean filter(k, v) function
-- the values are returned in no particular order
function table.filter(t, filter)
    local t2= {}
    for k,v in pairs(t) do
        if filter(k, v) then
            t2[#t2+1]= v
        end
    end
    return t2
end

-- returns a new table with the table entries returned by mapping function m.
-- function m receives keys and values (k, v) from t and it may return:
--    * one value a:    map collects an array of values, adding a to the end of the array
--                      the array of values is in no particular order
--    * two values a,b: map collects a table of entries [a]= b
--
-- (if m returns sometimes one, and sometimes two values, the
-- returned table will have mixed, array and dictionary, entries!!)
function table.map(t, m)
    local t2= {}
    for k,v in pairs(t) do
        local ra,rb= m(k, v)
        if rb ~= nil then         -- two values (a, b) returned
            t2[ra]= rb
        else                      -- one value (a) returned
            t2[#t2+1]= ra
        end
    end
    return t2
end


-- returns the maximum value contained in the table and the corresponding key
function table.maxv(t)
    local max = nil 
    local max_k = nil
    for k,v in pairs(t) do
        if max == nil or max < v then 
            max = v
            max_k = k
        end
    end
    return max_k,max
end

-- returns the minimum value contained in the table and the corresponding key
function table.minv(t)
    local min = nil
    local min_k = nil 
    for k,v in pairs(t) do
        if min == nil or min > v then 
            min = v
            min_k = k
        end
    end
    return min_k,min
end

-- returns a new table slice (only works for arrays)
function table.slice(t, i1, i2)
    local out = {} 
    local n = #t
    i1 = i1 or 1
    i2 = i2 or n
    if i2 < 0 then 
        i2 = n +i2 + 1
    elseif i2 > n then 
        i2 = n
    end
    if i1 < 1 or i1 > n then 
        return {}
    end
    local k = 1
    for i = i1,i2 do
        out[k] = t[i]
        k = k + 1
    end
    return out
end

-- removes the first object found in the table
function table.removeobject(t,o)
    local k = table.keyforobject(t,o)
    if k ~= nil then 
        table.remove(t,k)
    end
end

