function [grad_z_3d] = t2star_computeGradientZ(multiecho_magn,freq_map_3d_smooth,min_length,polyFitOrder,dz)

sizeData = size(multiecho_magn);
nx = sizeData(1);
ny = sizeData(2);
nz = sizeData(3);
%nt = sizeData(4);

% Calculate frequency gradient in the slice direction (freqGradZ)
freq_map_3d_smooth_polyfit = zeros(nx,ny,nz);
grad_z_3d = zeros(nx,ny,nz);
grad_z_3d_masked = zeros(nx,ny,nz);
icount=1;
for ix=1:nx
	for iy=1:ny
		% Initialize 1D gradient values
		%grad_z = zeros(1,nz);
		% Get frequency along z (discard zero values)
		freq_z = squeeze(freq_map_3d_smooth(ix,iy,:));
		ind_nonzero = find(freq_z);
		if length(ind_nonzero) >= min_length
			% Fit to polynomial function
			p = polyfit(ind_nonzero,freq_z(ind_nonzero),polyFitOrder);
			f = polyval(p,(1:nz));
			% Compute frequency gradient along Z
			grad_z = gradient(f,dz/1000);		
			% Fill 3D gradient matrix
			grad_z_3d(ix,iy,:) = grad_z;
        end
		icount=icount+1;
	end
end
end