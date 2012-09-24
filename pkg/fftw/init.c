#include <stdlib.h>
#include <string.h>

#include "TH.h"
#include "luaT.h"

extern void thfftw_init(lua_State *L);

DLL_EXPORT int luaopen_libfftw(lua_State *L)
{
  thfftw_init(L);

  return 1;
}

