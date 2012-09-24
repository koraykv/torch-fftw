#ifndef TH_GENERIC_FILE
#define TH_GENERIC_FILE "generic/THFftw.h"
#else

#include "fftw3.h"

/* 1-D FFT */
void FFTW_(fft)(real *r, real *x, long n);
/* 1-D IFFT */
void FFTW_(ifft)(real *r, real *x, long n);

#endif
