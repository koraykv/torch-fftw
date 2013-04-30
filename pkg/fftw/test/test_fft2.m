setenv('GNUTERM','X11')

n = 2^9-73;
M = zeros(n);

I = 1:n;
x = I-n/2;
y = n/2-I;
[X,Y] = meshgrid(x,y);
R = 10;
A = (X.^2 + Y.^2 <= R^2);
M(A) = 1;

figure(1)
imagesc(M)
colormap([0 0 0; 1 1 1])
axis image
title('{f Circular Aperture}')
D1 = fft2(M);
D2 = fftshift(D1);
colorbar

figure(2)
imagesc(abs(D2))
axis image
colormap(hot)
title('{f Diffraction Pattern}')
colorbar


D3 = log2(D2);
figure(3)
imagesc(abs(D3))
axis image
colormap(hot)
title('{f Enhanced Diffraction Pattern}')
colorbar

tD1 = readBinLushMatrix('tD1.t7');
tD2 = readBinLushMatrix('tD2.t7');
tD3 = readBinLushMatrix('tD3.t7');

writeBinLushMatrix('mD1.t7',D1);
writeBinLushMatrix('mD2.t7',D2);
writeBinLushMatrix('mD3.t7',D3);

