--[[ 

 klua_types
 types and type handling functions
 
 Created by Barzilai Spinak on 15 Jan 2011.
 Copyright 2011 Kalio Ltda. All rights Reserved.
 
]]


--[[
  A NULL constant that can be used to initialize variables/keys and compared for equality
  It throws an error when trying to read from/write to the member of a NULL value, for example:
  if a == NULL, then the following will throw an error
    b= a.x        -- trying to access "x" of NULL
    a.x= <expr>   -- trying to set member "x" of NULL

  For safety, getmetatable(NULL) returns NULL itself, so it cannot be changed.
]]
NULL= setmetatable( {},                 -- the shared, empty table NULL representing nothingness
    {
        __index= function(t, k)
            error('Error: trying to access member '..tostring(k)..' of NULL value')
            return nil
        end,

        __newindex= function(t, k, v)
            error('Error: trying to set member '..tostring(k)..' of NULL value')
        end,

        __tostring= function(s)
            return "NULL"
        end,
    }
)
getmetatable(NULL).__metatable= NULL    -- protect NULL so that its metatable can't be changed




--[[
  enums
  usage: 
    states = enum { "up", "down", "center", "inside" }
    assert( states.down == 2 )
    assert( states[3] == "center" )
    assert( _G[inside] == 4 )
    assert( up == 1)

    TODO: BBB evaluar si soportamos enums que empiecen en cero
    La sintaxis podria ser asi:
    states= enum { [0]= "cero", "uno", "dos", "tres" }
    Esto generaria "cero" bajo el key [0], y el resto como elementos del array empezando en 1.
    Aunque el mapeo [0] = "cero" pareceria que queda en la parte diccionario de la tabla (en lugar de la parte array)
    esto no ofrece ninguna diferencia sintacticamente al momento del uso del enum. PUEDE ser mas lento acceder al
    elemento [0], pero no he podido hacer pruebas.
    Problemas/diferencias:
      * si pedimos #states nos va a devolver un 3 y no un 4 (solo hay 3 elementos en la parte array de la tabla)
      * al recorrer los keys, la parte array se recorre en orden pero el [0] va a salir fuera de orden
      * hay que refactorear la funcion enum para usar pairs en lugar de for con #enumTable
      * prob. no se puede modificar mientras se esta recorriendo con pairs asi que habria que obtener primero
      * todos sus keys (usando la funcion keys de klua_utils) y recorrer pairs sobre keys y usar cada key para
        acceder a enumTable
      * Si queremos un enum con otra secuencia o valores salteados hay que expresarlos TODOS.
]]
function enum(enumTable)
  assert(type(enumTable) == "table" and #enumTable > 0, "Error: enum expects an array table with at least one string item")
  for i=1,#enumTable do
    local it= enumTable[i]
    assert(type(it) == "string", "Error: enum itmes must be strings ("..type(it).." found at position "..i..")")
    assert(not _G[it], "Error: enum redefines symbol '"..it.."'")
    enumTable[it]= i                                -- map from string to number
    _G[it]= i                                       -- register the name globally
  end

  return enumTable
end
