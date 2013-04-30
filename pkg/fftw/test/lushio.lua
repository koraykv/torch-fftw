function lushio_write(filename,tensor_)
   -- Writes Lush binary formatted matrix.
   -- The tensor is stored in 'filename'.
   --
   --   call : lushio.write('my_lush_matrix_file_name', tensor);
   --
   -- Inputs:
   --   filename : the name of the lush matrix file. (string)
   --   tensor   : torch tensor to be stored
   --
   --   Koray Kavukcuoglu
   local tensor = tensor_:clone()
   local fid = torch.DiskFile(filename,'w'):binary()
   local magic = 0
   if tensor:type() == 'torch.DoubleTensor' then
      magic = 507333715
   elseif tensor:type() == 'torch.FloatTensor' then
      magic = 507333713
   elseif tensor:type() == 'torch.IntTensor' then
      magic = 507333716
   elseif tensor:type() == 'torch.ByteTensor' then
      magic = 507333717
   else
      error('Can not write ' .. tensor:type())
   end
   local ndim = math.max(3,tensor:dim())
   local tdims = torch.IntStorage(ndim)
   tdims:fill(1)
   for i=1,tensor:dim() do tdims[i] = tensor:size(i) end

   fid:writeInt(magic)
   fid:writeInt(tensor:dim())
   fid:writeInt(tdims)
   if magic == 507333717 then      --ubyte matrix
      fid:writeByte(tensor:storage())
   elseif magic == 507333716 then      --integer matrix
      fid:writeInt(tensor:storage())
   elseif magic == 507333713 then      --float matrix 
      fid:writeFloat(tensor:storage())
   elseif magic == 507333715 then      --double matrix
      fid:writeDouble(tensor:storage())
   else
      error('Unknown magic number in tensor.write')
   end
   fid:close()
end

function lushio_read(filename)
   -- Reads Lush binary formatted matrix and returns it.
   -- The matrix is stored in 'filename'.
   --
   --   call : x = luahio.readBinaryLushMatrix('my_lush_matrix_file_name');
   --
   -- Inputs:
   --   filename : the name of the lush matrix file. (string)
   --
   -- Outputs:
   --   d   : matrix which is stored in 'filename'.
   --
   --   Koray Kavukcuoglu
   
   local fid = torch.DiskFile(filename,'r'):binary()
   local magic = fid:readLong()
   local ndim = fid:readLong()

   local tdims
   if ndim == 0 then
      tdims = torch.LongStorage({1})
   else
      tdims = fid:readLong(math.max(3,ndim))
   end
   local dims = torch.LongStorage(ndim)
   for i=1,ndim do dims[i] = tdims[i] end

   local nelem = 1
   for i=1,dims:size() do
      nelem = nelem * dims[i]
   end
   local d = torch.Storage()
   local x
   if magic == 507333717 then      --ubyte matrix
      d = fid:readInt(nelem)
      x = torch.ByteTensor(d,1,dims)
   elseif magic == 507333716 then      --integer matrix
      d = fid:readLong(nelem)
      x = torch.IntTensor(d,1,dims)
   elseif magic == 507333713 then      --float matrix
      d = fid:readFloat(nelem)
      x = torch.FloatTensor(d,1,dims)
   elseif magic == 507333715 then      --double matrix
      d = fid:readDouble(nelem)
      x = torch.DoubleTensor(d,1,dims)
   else
      error('Unknown magic number in binary lush matrix')
   end

   fid:close()
   return x
end
