----------------------------------------------------------------------
-- MARK: - Strings                                                   -
----------------------------------------------------------------------

---------------- string functions --------

-- split the string s using sepchars (separator chars)
-- and returns array of strings
function string.split(s, sepchars)
    local ret= {}
    for w in string.gmatch(s, "[^"..sepchars.."]+") do
        ret[#ret + 1]= w
    end
    return ret
end

