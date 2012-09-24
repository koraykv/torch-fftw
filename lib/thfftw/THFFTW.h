#ifndef TH_FFTW_INC
#define TH_FFTW_INC

#include "TH.h"

#define FFTW_(NAME) TH_CONCAT_4(TH,Real,Fftw_,NAME)
#define THFFTW_(NAME) TH_CONCAT_4(THFftw,Real,Tensor_,NAME)

#include "generic/THFftw.h"
#include "THGenerateFloatTypes.h"

#include "generic/THTensorFftw.h"
#include "THGenerateFloatTypes.h"


#endif
