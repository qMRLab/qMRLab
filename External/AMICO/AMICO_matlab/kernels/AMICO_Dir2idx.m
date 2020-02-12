function [ i1, i2 ] = AMICO_Dir2idx( dir )
% i1 = theta
% i2 = phi

i2 = mod( atan2(dir(2), dir(1)), 2*pi );
if ( i2 < 0 )
	i2 = mod( i2 + 2*pi, 2*pi );
end
if ( i2 > pi )
	i2 = mod( atan2(-dir(2), -dir(1)), 2*pi );
	i1 = atan2(sqrt(dir(1)*dir(1) + dir(2)*dir(2)), -dir(3));
else
	i1 = atan2(sqrt(dir(1)*dir(1) + dir(2)*dir(2)), dir(3));
end

i1 = round( i1/pi*180 ) + 1;
i2 = round( i2/pi*180 ) + 1;
if i1<0 || i1>181 || i2<0 || i2>181
	error( '[AMICO_Dir2idx] out of bounds' )
end



