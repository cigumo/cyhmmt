----------------------------------------------------------------------
-- MARK: - Optional filesystem functions                             -
----------------------------------------------------------------------

-- Optional require of luafilesystem library (lfs) for optional filesystem functions
-- They live in klua_utils for now...
local success, lfs= pcall(require, "lfs")
lfs= success and lfs or nil

-- The following functions will be defined only if luafilesystem was successfully loaded
if lfs then

    -- Returns a directory iterator for files that match
    --    - dirpath is a directory path string
    --    - filter may be:
    --        - a Lua regex pattern string, as used by string.match()
    --        - a filter function which receives the filename and returns a boolean
    --
    -- It can be used like this:
    --    for filename in dirmatching(dirpath, ".*%.doc$") do
    --        -- do something with each "*.doc" file
    --    end
    --
    function dirmatching(dirpath, filter)
        filter= filter or ".*"                            -- use given filter, or match anything
        local lfsIter, lfsDirObj= lfs.dir(dirpath)
        local isLambda= type(filter) == "function"
        local function iter()
            repeat
                local fn= lfsIter(lfsDirObj)              -- get the next filename
                if fn then                                -- if there's a next filename
                    if  (     isLambda and filter(fn)               )  or
                        ( not isLambda and string.match(fn, filter) )
                    then
                        return fn
                    end
                end
            until not fn
        end
        
        return iter
    end

end -- if lfs

