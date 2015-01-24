--[[
  klu_macros.lua

  Created by Barzilai Spinak on 2011/01/26.
  Copyright 2011 Kalio Ltda. All rights Reserved.
]]


-- localize them!
local fmod=   math.fmod
local pi=     math.pi
local twopi=  2*pi
local pi_2=   pi/2
local pi_4=   pi/4

-- angle arguments can be give in the range -inf..inf
local function UNROLL(a)      return a % twopi end                    -- returns angle in range 0..2pi
local function UNROLL_DEG(a)  return a %   360 end                    -- returns angle in range 0..360

local function SIGNED_UNROLL(a)     return fmod(a, twopi) end         -- returns angle in range -2pi..2pi (respecting sign)
local function SIGNED_UNROLL_DEG(a) return fmod(a,   360) end         -- returns angle in range -360..360 (respecting sign)

local function SHORT_ANGLE(from, to)                                  -- shortest angle from-->to in range -pi..pi
  local diff= UNROLL(to-from);
  return (diff <= pi) and diff or (fmod(diff, pi) - pi)
end

local function SHORT_ANGLE_DEG(from, to)                              -- shortest angle from-->to in range -180..180
  local diff= UNROLL_DEG(to-from);
  return (diff <= 180) and diff or (fmod(diff, 180) - 180)
end


local function CLAMP_SIGNED(min,max,v) return (v < min) and min or ((v > max) and max or v) end
local function CLAMP(a,b,v) if (a < b) then return CLAMP_SIGNED(a,b,v) else return CLAMP_SIGNED(b,a,v) end end

return {
  twopi= twopi,
  pi_2=  pi_2,
  pi_4=  pi_4,
  unroll=             UNROLL,
  unroll_deg=         UNROLL_DEG,
  signed_unroll=      SIGNED_UNROLL,
  signed_unroll_deg=  SIGNED_UNROLL_DEG,
  short_angle=        SHORT_ANGLE,
  short_angle_deg=    SHORT_ANGLE_DEG,
  clamp_signed=       CLAMP_SIGNED,
  clamp=              CLAMP,
}
