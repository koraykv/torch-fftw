require 'fftw'
dofile 'util.lua'
dofile 'lushio.lua'

n = 2^9-73;
M = torch.zeros(n,n);

I = torch.range(1,n);
x = I-n/2;
y = I-n/2;
y:mul(-1)
X,Y = meshgrid(x,y);
R = 10;
M[torch.le((X:pow(2) + Y:pow(2)),R^2)] = 1

gnuplot.figure(1)
gnuplot.imagesc(M,'gray')
-- colormap([0 0 0; 1 1 1])
gnuplot.axis('image')
gnuplot.title('Circular Aperture')

D1 = torch.fft2(M);
D2 = fftshift(D1);

gnuplot.figure(2)
gnuplot.imagesc(abs(D2),'rgb 34,35,36')
gnuplot.axis('image')
gnuplot.title('Diffraction Pattern')

D3 = log(D2)
D3:div(math.log(2))

gnuplot.figure(3)
gnuplot.imagesc(abs(D3),'rgb 34,35,36')
gnuplot.axis('image')
gnuplot.title('Enhanced Diffraction Pattern')


lushio_write('tD1.t7',D1)
lushio_write('tD2.t7',D2)
lushio_write('tD3.t7',D3)

if paths.filep('mD1.t7') then
	mD1 = lushio_read('mD1.t7')
	mD2 = lushio_read('mD2.t7')
	mD3 = lushio_read('mD3.t7')
end
