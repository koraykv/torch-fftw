function writeBinLushMatrix(filename,d,mtype)
%
% d : matrix to be saved in lush format
% filename : filename for the lush matrix
% type: can be one of
%   'ubyte'
%   'int'
%   'float'
%   'double'
%
if nargin < 3
    mtype='double';
end
if iscomplex(d) == 1
    dr = real(d);
    di = imag(d);
    dd = [dr(:)' ; di(:)']';
    ds = reshape(dd,[size(d),2]);
    d = ds;
end
fid = fopen(filename,'w');
magic = 0;
if strcmp(mtype,'ubyte')
    magic = 507333717;
elseif strcmp(mtype,'int')
    magic = 507333716;
elseif strcmp(mtype,'float')
    magic = 507333713;
elseif strcmp(mtype,'double')
    magic = 507333715;
end

if (magic == 0)
    display 'Unknown type'
    return;
end

ndim = ndims(d);
dims = size(d);
if ndim == 1
    dims(2:3) = 1;
elseif ndim == 2
    dims (3) = 1;
end
fwrite(fid,magic,'long');
fwrite(fid,ndim,'long');
fwrite(fid,dims,'long');

d = permute(d,fliplr(1:ndims(d)));
if strcmp(mtype,'ubyte')
    d = uint8(d);
    fwrite(fid,d,'uint8');
elseif strcmp(mtype,'int')
    d = int32(d);
    fwrite(fid,d,'long');
elseif strcmp(mtype,'float')
    d = single(d);
    fwrite(fid,d,'float');
elseif strcmp(mtype,'double')
    d = double(d);
    fwrite(fid,d,'double');
end

fclose(fid);