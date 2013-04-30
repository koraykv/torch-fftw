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

TH_API void THFFTW_(fft2dim)(THTensor *r_, THTensor *x_, long m, long n, int recurs)
{
  long ndim = THTensor_(nDimension)(x_);

  if (ndim == 2)
  {
    THFFTW_(fft2)(r_, x_, m, n);
  }
  else
  {
    long i;
    long nslice = THTensor_(size)(x_, 0);

    /* need to resize output only at top level */
    if (!recurs)
    {
      long m0 = THTensor_(size)(x_,ndim-2);
      long n0 = THTensor_(size)(x_,ndim-1);
      if (m == 0 )
      {
        m = m0;
      }
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
      size->data[ndim-2] = m;
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
      THFFTW_(fft2dim)(rslice, xslice, m, n, 1);
      THTensor_(free)(xslice);
      THTensor_(free)(rslice);
    }
  }
}

TH_API void THFFTW_(fft2)(THTensor *r_, THTensor *x_, long m, long n)
{
  THTensor *x, *xn, *xm, *in, *out;
  long m0,n0;

  THArgCheck(THTensor_(nDimension)(x_) == 2, 2, "Tensor is expected to be 2D");

  m0 = THTensor_(size)(x_,0);
  n0 = THTensor_(size)(x_,1);
  if (m == 0)
  {
    m = m0;
  }
  if (n == 0 )
  {
    n = n0;
  }
  
  /* prepare output */
  long ny=(n/2)+1;
  THTensor_(resize3d)(r_, m, n, 2);
  out = THTensor_(newWithSize3d)(m,ny,2);

  /* Allocate stuff input real, output complex */
  if (n <= n0 || m <= m0)
  {
    x = THTensor_(newContiguous)(x_);
    in = x_;
  }
  else
  {
    /* copy data that is available */
    x = THTensor_(newWithSize2d)(m,n);
    xm = THTensor_(newNarrow)(x, 0, 0, m0);
    xn = THTensor_(newNarrow)(xm, 1, 0, n0);
    THTensor_(copy)(xn,x_);
    THTensor_(free)(xn);
    THTensor_(free)(xm);

    /* fill rest with zeros */
    xm = THTensor_(newNarrow)(x, 0, m0, m-m0);
    xn = THTensor_(newNarrow)(xm, 1, n0, n-n0);
    THTensor_(zero)(xn);
    THTensor_(free)(xn);
    THTensor_(free)(xm);
    in = x;
  }

  /* Run fft */
  THTensor_(zero)(r_);
  real *dout = THTensor_(data)(out);
  FFTW_(fft2)(dout, THTensor_(data)(in), m, n);
  xn = THTensor_(newNarrow)(r_,1,0,ny);
  THTensor_(copy)(xn,out);
  THTensor_(free)(xn);

  //m*n*q
  //[i][j][k] = d[i*n*q + j*q + k]

  /* Copy stuff to the redundant part */
  real *dr = THTensor_(data)(r_);
  long i,j;
  long q = 2;
  for(i=0; i<m; i++)
  {
    if (i==0)
    {
      for(j=ny; j<n; j++)
      {
        dr[j*2] = dout[(n-j)*2];
        dr[j*2+1] = -dout[(n-j)*2+1];
      }
    }
    else
    {
      real *pout = dr + i*n*q;
      real *ddout = dout + (m-i)*ny*q;
      for(j=ny; j<n; j++)
      {
        pout[j*2]   = ddout[(n-j)*2];
        pout[j*2+1] = -ddout[(n-j)*2+1];
      }
    }
  }

  /* clean up */
  THTensor_(free)(x);
  THTensor_(free)(out);
}
/*
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
