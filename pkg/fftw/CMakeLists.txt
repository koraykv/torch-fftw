
SET(src init.c thfftw.c)
SET(luasrc init.lua)

ADD_TORCH_WRAP(thfftwwrap thfftw.lua)

INCLUDE_DIRECTORIES(${FFTW_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${Torch_SOURCE_INCLUDES})

ADD_TORCH_PACKAGE(fftw "${src}"  "${luasrc}")
ADD_TORCH_DOK(dok fftw "FFTW" "FFTW Interface" 11111.)

TARGET_LINK_LIBRARIES(fftw luaT TH thfftw ${FFTW_LIBRARIES})


