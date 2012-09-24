#ifndef TH_GENERIC_FILE
#define TH_GENERIC_FILE "generic/THTensorFftw.c"
#else

TH_API void THFFTW_(fftdim)(THTensor *r_, THTensor *x_, long n, int recurs)
{
  long ndim = THTensor_(nDimension)(x_);

  if (ndim == 1)
  {
    THFFTW_(fft)(r_, x_, n);
  }
  else
  {
    long i;
    long nslice = THTensor_(size)(x_, 0);

    /* need to resize output only at top level */
    if (!recurs)
    {
      long n0 = THTensor_(size)(x_,ndim-1);
      if (n == 0 )
      {
        n = n0;
      }
      THLongStorage *size;
      size = THLongStorage_newWithSize(ndim+1);
      for(i=0;i<ndim-1;i++)
      {
        size->data[i] = THTensor_(size)(x_,i);
      }
      size->data[ndim] = 2;
      size->data[ndim-1] = n;
      THTensor_(resize)(r_, size, NULL);
      THLongStorage_free(size);      
    }
    /* loop over first dim and make recursive call */
    for (i=0; i<nslice; i++)
    {
      THTensor *xslice, *rslice;
      xslice = THTensor_(newSelect)(x_, 0, i);
      rslice = THTensor_(newSelect)(r_, 0, i);
      THFFTW_(fftdim)(rslice, xslice, n, 1);
      THTensor_(free)(xslice);
      THTensor_(free)(rslice);
    }
  }
}

TH_API void THFFTW_(fft)(THTensor *r_, THTensor *x_, long n)
{
  THTensor *x, *xn, *in;
  long n0;

  THArgCheck(THTensor_(nDimension)(x_) == 1, 2, "Tensor is expected to be 1D");

  n0 = THTensor_(size)(x_,0);
  if (n == 0 )
  {
    n = n0;
  }
  
  /* prepare output */
  THTensor_(resize2d)(r_, n, 2);

  /* Allocate stuff input real, output complex */
  if (n <= n0)
  {
    x = THTensor_(newContiguous)(x_);
    in = x;
  }
  else
  {
    /* copy data that is available */
    x = THTensor_(newWithSize1d)(n);
    xn = THTensor_(newNarrow)(x, 0, 0, n0);
    THTensor_(copy)(xn,x_);
    THTensor_(free)(xn);

    /* fill rest with zeros */
    xn = THTensor_(newNarrow)(x, 0, n0, n-n0);
    THTensor_(zero)(xn);
    THTensor_(free)(xn);
    in = x;
  }

  /* Run fft */
  real *out = THTensor_(data)(r_);
  FFTW_(fft)(out, THTensor_(data)(in), n);

  /* Copy stuff to the redundant part */
  long i;
  for(i=n/2+1; i<n; i++)
  {
    out[2*i] = out[2*n-2*i];
    out[2*i+1] = -out[2*n-2*i+1];
  }

  /* clean up */
  THTensor_(free)(x);
}

TH_API void THFFTW_(ifftdim)(THTensor *r_, THTensor *x_, long n, int recurs)
{
  long ndim = THTensor_(nDimension)(x_);
  if (ndim == 2)
  {
    THFFTW_(ifft)(r_, x_, n);
  }
  else
  {
    long i;
    long nslice = THTensor_(size)(x_, 0);
    THLongStorage *size = NULL;

    /* need to resize output only at top level */
    if (!recurs)
    {
      size = THLongStorage_newWithSize(ndim-1);
      for(i=0;i<ndim-1;i++)
      {
        size->data[i] = THTensor_(size)(x_,i);
      }
      THTensor_(resize)(r_, size, NULL);
    }
    /* loop over first dim and make recursive call */
    for (i=0; i<nslice; i++)
    {
      THTensor *xslice, *rslice;
      xslice = THTensor_(newSelect)(x_, 0, i);
      rslice = THTensor_(newSelect)(r_, 0, i);
      THFFTW_(ifftdim)(rslice, xslice, n, 1);
      THTensor_(free)(xslice);
      THTensor_(free)(rslice);
    }
    if (!recurs)
    {
      THLongStorage_free(size);      
    }
  }
}

TH_API void THFFTW_(ifft)(THTensor *r_, THTensor *x_, long n)
{
  THTensor *x, *xn;
  long n0;

  THArgCheck(THTensor_(nDimension)(x_) == 2, 2, "Tensor is expected to be 2D");

  n0 = THTensor_(size)(x_,0);
  if (n == 0) n = n0;
  x = THTensor_(newWithSize2d)(n,2);

  /* Allocate stuff input complex, output real */
  if (n == n0)
  {
    THTensor_(copy)(x,x_);
  }
  else if (n < n0)
  {
    xn = THTensor_(newNarrow)(x_, 0, 0, n);
    THTensor_(copy)(x,xn);
    THTensor_(free)(xn);
  }
  else
  {
    xn = THTensor_(newNarrow)(x, 0, 0, n0);
    THTensor_(copy)(xn,x_);
    THTensor_(free)(xn);

    xn = THTensor_(newNarrow)(x, 0, n0, n-n0);
    THTensor_(zero)(xn);
    THTensor_(free)(xn);
  }
  THTensor_(resize1d)(r_, n);
  
  FFTW_(ifft)(THTensor_(data)(r_), THTensor_(data)(x), n);
  THTensor_(div)(r_,r_,(real)(n));
  THTensor_(free)(x);
}
/*
TH_API void THFFTW_(fft2)(THTensor *r_, THTensor *x_, long m, long n)
{

}
TH_API void THFFTW_(ifft2)(THTensor *r_, THTensor *x_, long m, long n)
{

}
TH_API void THFFTW_(fftn)(THTensor *r_, THTensor *x_)
{

}
TH_API void THFFTW_(ifftn)(THTensor *r_, THTensor *x_)
{

}
*/
#endif
