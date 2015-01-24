----------------------------------------------------------------------
-- MARK: - crypto                                                    -
----------------------------------------------------------------------


local success, ffi= pcall(require, "ffi")
ffi=  success and ffi or nil

if ffi then
    local bit=      require "bit"                                 -- ffi includes the bit module
    local two32=    2^32
    local oneLong=  ffi.new("uint64_t", 1)                        -- a LuaJIT's 64-bit integer to avoid precision loss errors when multiplying large numbers

    fnv1a= function (str)
        -- dumb 32 bit fnv-1a implementation
        --
        -- assumes input string with single-byte encoding
        -- See http://www.isthe.com/chongo/src/fnv/test_fnv.c for test vectors

        local FNV_offset_basis= 0x811C9DC5
        local FNV_prime=        0x01000193

        local hash= FNV_offset_basis
        for i= 1,str:len() do
            local octet=      str:byte(i)
            local xored=      bit.bxor(hash, octet)
            local timesprime= (oneLong * xored) * FNV_prime
            hash= tonumber(timesprime % two32)                    -- going back to a Lua number which fits in 32 bits
        end

        return hash
    end
end -- if bit
