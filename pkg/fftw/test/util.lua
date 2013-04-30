function meshgrid(x,y)
	local xx = torch.repeatTensor(x,y:size(1),1)
	local yy = torch.repeatTensor(torch.reshape(y,y:nElement(),1),1,x:nElement())
	return xx,yy
end
function fftshift(x)
	local xx1 = x:clone()
	local xx2 = x:clone()
	for i=1,x:dim()-1 do
		local nsec = math.floor(x:size(i)/2) -- 1
		local nfir = x:size(i)-nsec          -- 2
		xx2:narrow(i,1+nsec,nfir):copy(xx1:narrow(i,1,nfir))
		xx2:narrow(i,1,nsec):copy(xx1:narrow(i,nfir+1,nsec))
		xx1:copy(xx2)
	end
	return xx2
end
function abs(Y)
	return torch.squeeze( torch.norm(Y,2,Y:dim()) )
end
function log(Y)
	local logY = torch.Tensor():resizeAs(Y)
	local real = abs(Y)
	real:log()
	local theta = torch.atan2(Y:select(Y:dim(),2),Y:select(Y:dim(),1))
	-- print({logY,real,Y})
	logY:select(logY:dim(),1):copy(real)
	logY:select(logY:dim(),2):copy(theta)
	return logY
end
