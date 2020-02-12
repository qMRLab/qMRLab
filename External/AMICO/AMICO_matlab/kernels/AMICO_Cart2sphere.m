function [colatitude, longitude, r] = AMICO_Cart2sphere(x, y, z)
	r = sqrt(x.^2 + y.^2 + z.^2);
	longitude  = atan2(y, x);
	colatitude = atan2(sqrt(x.^2 + y.^2), z);
end
