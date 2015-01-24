--
-- klua_log.lua
-- klibs
--
-- Created by Barzilai Spinak in February 2011.
-- Copyright 2011 Kalio Ltda. All rights Reserved.
--

-- This module creates a root logger, from which other local loggers can be constructed,
-- each with their individual log levels. The root logger is returned by this chunk,
-- so it can be retrieved by the require function.
--
-- syntax:
--    childLog= parentLog:new(logLevel)
--
-- If logLevel is nil or not given, the childLog's log level will fall back
-- to its parent's (dynamically resolved for each logging invocation,
-- so childLog.level can be set and cleared as needed).
-- 
-- The log levels are:
--   PARANOID_LEVEL, DEBUG_LEVEL, INFO_LEVEL, WARNING_LEVEL, ERROR_LEVEL, OFF_LEVEL
--
-- The default log level is ERROR_LEVEL
--
-- Example of a local logger within a Lua file/chunk:
--   local root_klog= require "klua_log"
--   local klog= root_klog:new(root_klog.DEBUG_LEVEL)
--
--   klog.debug("This is a format %s", "string")


-- localize some functions
local dgetinfo=   debug.getinfo
local strformat=  string.format

-- map of forbidden names for klogs
local noNames= {
  PARANOID_LEVEL= true, DEBUG_LEVEL= true, INFO_LEVEL= true,
  WARNING_LEVEL= true, ERROR_LEVEL= true, OFF_LEVEL= true,
  new= true, paranoid= true, debug= true, info= true, warning= true, error= true,
}


local klog = {
    -- log levels
    PARANOID_LEVEL = 5,
    DEBUG_LEVEL    = 4,
    INFO_LEVEL     = 3,
    WARNING_LEVEL  = 2,
    ERROR_LEVEL    = 1,
    OFF_LEVEL      = 0,

    -- it is also a registry of named klogs indexed by their name
    -- the name can't be any of the reserved words
    -- ...
}
klog.__index= klog
klog.level = klog.ERROR_LEVEL                        -- default log level


local function log (level, fmt, ...)
    local func_info=  dgetinfo(3, "n")               -- 1 is this function, 2 is the specific logger function, 3 is the client function calling klog.xxxx
    local func_name=  func_info["name"] or "-"
    local time=       os.clock()                     -- cpu seconds, not realtime because not in lua libraries
    local user_str=   strformat(fmt or "",  ...)

    -- time will be printed to 4 decimal places (ten thousandths of a second)
    print(strformat("[%.4f] %s %s() - %s", time, level, func_name, user_str))
end

--
-- Constructor function for a new klog, from a parent log
--
klog.new= function(parentlog, name, newlevel)
  local newlog= setmetatable( {}, parentlog )
  -- parentlog is a logger who is becoming a metatable of another logger,
  -- so set __index to itself (if it was already set to itself it doesn't mater)
  parentlog.__index= parentlog 
  newlog.level= newlevel and newlevel or klog.WARNING_LEVEL

  if type(name) == "string" then
    assert(not noNames[name], "Can't use name "..name.." for a klogger. It's reserved!")
    newlog.name= name
    klog[name]= newlog                                      -- if it's named, register it
  end

  newlog.paranoid = function(fmt, ...)
      if (newlog.level >= klog.PARANOID_LEVEL) then
          log("PARANOID", fmt, ...)
      end
  end
     
  newlog.debug = function(fmt, ...)
       if (newlog.level >= klog.DEBUG_LEVEL) then
           log("DEBUG   ", fmt, ...)
       end
  end
  
  newlog.info = function(fmt, ...)
      if (newlog.level >= klog.INFO_LEVEL) then
          log("INFO    ", fmt, ...)
      end
  end

  newlog.warning = function(fmt, ...)
      if (newlog.level >= klog.WARNING_LEVEL) then
          log("WARNING ", fmt, ...)
      end
  end
  
  newlog.error = function(fmt, ...)
      if (newlog.level >= klog.ERROR_LEVEL) then
          log("ERROR   ", fmt, ...)
      end
  end
 
  return newlog
end

-- create and return a root logger (with the local klog as parent)
return klog:new("root")

