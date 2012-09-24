local interface = wrap.CInterface.new()
local method = wrap.CInterface.new()

interface:print([[
#include "TH.h"
#include "luaT.h"
#include "THFFTW.h"
                ]])

-- special argument specific to torch package
local argtypes = {}
argtypes.LongArg = {

   vararg = true,

   helpname = function(arg)
               return "(LongStorage | dim1 [dim2...])"
            end,

   declare = function(arg)
              return string.format("THLongStorage *arg%d = NULL;", arg.i)
           end,

   init = function(arg)
             if arg.default then
                error('LongArg cannot have a default value')
             end
          end,
   
   check = function(arg, idx)
            return string.format("torch_islongargs(L, %d)", idx)
         end,

   read = function(arg, idx)
             return string.format("arg%d = torch_checklongargs(L, %d);", arg.i, idx)
          end,
   
   carg = function(arg, idx)
             return string.format('arg%d', arg.i)
          end,

   creturn = function(arg, idx)
                return string.format('arg%d', arg.i)
             end,
   
   precall = function(arg)
                local txt = {}
                if arg.returned then
                   table.insert(txt, string.format('luaT_pushudata(L, arg%d, "torch.LongStorage");', arg.i))
                end
                return table.concat(txt, '\n')
             end,

   postcall = function(arg)
                 local txt = {}
                 if arg.creturned then
                    -- this next line is actually debatable
                    table.insert(txt, string.format('THLongStorage_retain(arg%d);', arg.i))
                    table.insert(txt, string.format('luaT_pushudata(L, arg%d, "torch.LongStorage");', arg.i))
                 end
                 if not arg.returned and not arg.creturned then
                    table.insert(txt, string.format('THLongStorage_free(arg%d);', arg.i))
                 end
                 return table.concat(txt, '\n')
              end   
}

argtypes.charoption = {
   
   helpname = function(arg)
                 if arg.values then
                    return "(" .. table.concat(arg.values, '|') .. ")"
                 end
              end,

   declare = function(arg)
                local txt = {}
                table.insert(txt, string.format("const char *arg%d = NULL;", arg.i))
                if arg.default then
                   table.insert(txt, string.format("char arg%d_default = '%s';", arg.i, arg.default))
                end
                return table.concat(txt, '\n')
           end,

   init = function(arg)
             return string.format("arg%d = &arg%d_default;", arg.i, arg.i)
          end,
   
   check = function(arg, idx)
              local txt = {}
              local txtv = {}
              table.insert(txt, string.format('(arg%d = lua_tostring(L, %d)) && (', arg.i, idx))
              for _,value in ipairs(arg.values) do
                 table.insert(txtv, string.format("*arg%d == '%s'", arg.i, value))
              end
              table.insert(txt, table.concat(txtv, ' || '))
              table.insert(txt, ')')              
              return table.concat(txt, '')
         end,

   read = function(arg, idx)
          end,
   
   carg = function(arg, idx)
             return string.format('arg%d', arg.i)
          end,

   creturn = function(arg, idx)
             end,
   
   precall = function(arg)
             end,

   postcall = function(arg)
              end   
}

-- both interface & method support these new arguments
for k,v in pairs(argtypes) do
   interface.argtypes[k] = v
   method.argtypes[k] = v
end
   
-- also specific to torch: we generate a 'dispatch' function
-- first we create a helper function
-- note that it let the "torch" table on the stack
interface:print([[
static const void* torch_istensortype(lua_State *L, const char *tname)
{
  if(!tname)
    return NULL;

  if(!luaT_pushmetatable(L, tname))
    return NULL;

  lua_pushstring(L, "torch");
  lua_rawget(L, -2);
  if(lua_istable(L, -1))
    return tname;
  else
  {
    lua_pop(L, 2);
    return NULL;
  }

  return NULL;
}
]])

interface.dispatchregistry = {}
function interface:wrap(name, ...)
   -- usual stuff
   wrap.CInterface.wrap(self, name, ...)

   -- dispatch function
   if not interface.dispatchregistry[name] then
      interface.dispatchregistry[name] = true
      table.insert(interface.dispatchregistry, {name=name, wrapname=string.format("thfftw_%s", name)})

      interface:print(string.gsub([[
static int thfftw_NAME(lua_State *L)
{
  int narg = lua_gettop(L);
  const void *tname;
  if(narg >= 1 && (tname = torch_istensortype(L, luaT_typename(L, 1)))) /* first argument is tensor? */
  {
  }
  else if(narg >= 2 && (tname = torch_istensortype(L, luaT_typename(L, 2)))) /* second? */
  {
  }
  else if(narg >= 1 && lua_isstring(L, narg)
	  && (tname = torch_istensortype(L, lua_tostring(L, narg)))) /* do we have a valid tensor type string then? */
  {
    lua_remove(L, -2);
  }/*
  else if(!(tname = torch_istensortype(L, torch_getdefaulttensortype(L))))
    luaL_error(L, "internal error: the default tensor type does not seem to be an actual tensor");*/
  
  lua_pushstring(L, "NAME");
  lua_rawget(L, -2);
  if(lua_isfunction(L, -1))
  {
    lua_insert(L, 1);
    lua_pop(L, 2); /* the two tables we put on the stack above */
    lua_call(L, lua_gettop(L)-1, LUA_MULTRET);
  }
  else
  {
    return luaL_error(L, "%s does not implement the torch.NAME() function", tname);
  }

  return lua_gettop(L);
}
]], 'NAME', name))
  end
end

function interface:dispatchregister(name)
   local txt = self.txt
   table.insert(txt, string.format('static const struct luaL_Reg %s [] = {', name))
   for _,reg in ipairs(self.dispatchregistry) do
      table.insert(txt, string.format('{"%s", %s},', reg.name, reg.wrapname))
   end
   table.insert(txt, '{NULL, NULL}')
   table.insert(txt, '};')
   table.insert(txt, '')   
   self.dispatchregistry = {}
end

interface:print('/* WARNING: autogenerated file */')
interface:print('')

local reals = {ByteTensor='unsigned char',
               CharTensor='char',
               ShortTensor='short',
               IntTensor='int',
               LongTensor='long',
               FloatTensor='float',
               DoubleTensor='double'}

local accreals = {ByteTensor='long',
               CharTensor='long',
               ShortTensor='long',
               IntTensor='long',
               LongTensor='long',
               FloatTensor='double',
               DoubleTensor='double'}

for _,Tensor in ipairs({"FloatTensor", "DoubleTensor"}) do

   local real = reals[Tensor]
   local accreal = accreals[Tensor]

   function interface.luaname2wrapname(self, name)
      return string.format('thfftw_%s_%s',Tensor , name)
   end

   function method.luaname2wrapname(self, name)
      return string.format('m_thfftw_%s_%s', Tensor, name)
   end

   local function cname(name)
      return string.format('THFftw%s_%s', Tensor, name)
   end

   local function lastdim(argn)
      return function(arg)
                return string.format("TH%s_nDimension(%s)", Tensor, arg.args[argn]:carg())
             end
   end
   

   interface:wrap("fft",
		  cname("fftdim"),
		  {{name=Tensor, returned=true},
		   {name=Tensor},
		   {name=real, default=0},
		   {name="boolean",default=0,invisible=true}},
		  cname("fftdim"),
		  {{name=Tensor, default=true, returned=true, invisible=true},
		   {name=Tensor},
		   {name=real, default=0},
		   {name="boolean",default=0,invisible=true}}
	       )
   interface:wrap("ifft",
		  cname("ifftdim"),
		  {{name=Tensor, returned=true},
		   {name=Tensor},
		   {name=real, default=0},
		   {name="boolean",default=0,invisible=true}},
		  cname("ifftdim"),
		  {{name=Tensor, default=true, returned=true, invisible=true},
		   {name=Tensor},
		   {name=real, default=0},
		   {name="boolean",default=0,invisible=true}}
	       )

   method:register(string.format("m_thfftw_%s__", Tensor))
   interface:print(method:tostring())
   method:clearhistory()
   interface:register(string.format("thfftw_%s__", Tensor))

   interface:print(string.gsub([[
static void thfftw_Tensor_init(lua_State *L)
{
   luaT_pushmetatable(L, "torch.Tensor");

   /* register methods */
   luaL_register(L, NULL, m_thfftw_Tensor__);

   /* register interface functions */
   lua_pushstring(L, "torch");
   lua_rawget(L,-2);
   luaL_register(L, NULL, thfftw_Tensor__);

}
]],'Tensor',Tensor))
end

interface:dispatchregister("thfftw_FFTW__")

interface:print([[
void thfftw_init(lua_State *L)
{
   thfftw_FloatTensor_init(L);
   thfftw_DoubleTensor_init(L);
   luaL_register(L, "torch", thfftw_FFTW__);
}
]])

if arg[1] then
   interface:tofile(arg[1])
else
   print(interface:tostring())
end
