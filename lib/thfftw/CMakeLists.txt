INCLUDE_DIRECTORIES("${CMAKE_CURRENT_SOURCE_DIR}")

FIND_PACKAGE(FFTW)
IF(FFTW_FOUND)
  SET(USE_FFTW 1)
  ADD_DEFINITIONS(-DUSE_FFTW)
  MESSAGE(STATUS "FFTW FOUND!!!")
ENDIF(FFTW_FOUND)

SET(src 
  THFFTW.h
  THFFTW.c)

SET(src ${src})

INCLUDE_DIRECTORIES(${FFTW_INCLUDE_DIR})
ADD_LIBRARY(thfftw SHARED ${src})
TARGET_LINK_LIBRARIES(thfftw TH ${FFTW_LIBRARIES})

INSTALL(TARGETS thfftw
  RUNTIME DESTINATION "${Torch_INSTALL_BIN_SUBDIR}"
  LIBRARY DESTINATION "${Torch_INSTALL_LIB_SUBDIR}"
  ARCHIVE DESTINATION "${Torch_INSTALL_LIB_SUBDIR}")
