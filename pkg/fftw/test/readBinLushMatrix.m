function d = readBinLushMatrix(filename)
% Reads Lush binary formatted matrix and returns it.
% The matrix is stored in 'filename'.
%
%   call : x = readLushMatrix('my_lush_matrix_file_name');
%
% Inputs:
%   filename : the name of the lush matrix file. (string)
%
% Outputs:
%   d   : matrix which is stored in 'filename'.
%
%   Koray Kavukcuoglu

fid = fopen(filename,'r');
magic = fread(fid,1,'int32');
ndim = fread(fid,1,'int32');
if ndim == 0
    dims = [1];
else
    dims = fread(fid,max(3,ndim),'int32');
end
switch magic
    case 507333717       %ubyte matrix
        d = fread(fid,prod(dims),'*uchar');
    case 507333716       %integer matrix
        d = fread(fid,prod(dims),'*long');
    case 507333713       %float matrix
        d = fread(fid,prod(dims),'*float');
    case 507333715       %double matrix
        d = fread(fid,prod(dims),'*double');
    otherwise
        error('Unknown magic number in binary lush matrix');
end

if ndim > 1
    d = reshape(d,fliplr(dims'));
    d = permute(d,[ndims(d):-1:1]);
else
    d = d';
end

fclose(fid);
