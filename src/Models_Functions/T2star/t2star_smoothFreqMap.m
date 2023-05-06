function [freq_3d_smooth_masked,freqGradZ_masked] = t2star_smoothFreqMap(obj,freq_map_3d,mask_3d,multiecho_magn)
% =========================================================================
% 
% SMooth frequency map.
% 
% INPUT
% opt
%	opt.fname_multiecho_magn
%	opt.fname_multiecho_phase
%	opt.fname_freq
%	opt.fname_freq_smooth
%	opt.fname_freq_smooth_masked
%	opt.fname_mask
%	opt.echo_time						= (6.34:3.2:43); % in ms
% 	opt.thresh_mask						= 500; % intensity under which pixels are masked. Default=500.
% 	opt.rmse_thresh						= 2; % threshold above which voxels are discarded for comuting the frequency map. RMSE results from fitting the frequency slope on the phase data. Default=2.
% 
% OUTPUT
% opt
%
% Author: Julien Cohen-Adad <jcohen@nmr.mgh.harvard.edu>
% 2011-10-03: Created

%%Load data
freq_3d = squeeze(freq_map_3d);
nx = size(freq_3d,1);
ny = size(freq_3d,2);
nz = size(freq_3d,3);
%if opt.verbose, j_displayMRI(freq_3d,[-80 80]); title('Frequency map (Hz)'), end

% Downsample field map
[x,y,z] = meshgrid(1:ny,1:nx,1:nz);
dx=obj.options.smoothDownsampling(1); dy=obj.options.smoothDownsampling(2); dz=obj.options.smoothDownsampling(3); 
[xi,yi,zi] = meshgrid(1:dy:ny,1:dx:nx,1:dz:nz);
freq_3d_i = interp3(x,y,z,freq_3d,xi,yi,zi,'nearest');
% j_displayMRI(freq_3d_i,[-80 80]);
nxi = size(freq_3d_i,1);
nyi = size(freq_3d_i,2);
nzi = size(freq_3d_i,3);
%clear freq_3d
	

%% 3d smooth frequency map (zero values are ignored)
if strcmp(obj.options.FilterType,'gaussian')
	% Make kernel
	kernel = ones(obj.options.smoothKernel(1),obj.options.smoothKernel(2),obj.options.smoothKernel(3));
	kernel_x = gausswin(obj.options.smoothKernel(1));
	kernel_x_3d = repmat(kernel_x,[1 obj.options.smoothKernel(2) obj.options.smoothKernel(3)]);
	kernel_y(1,:) = gausswin(obj.options.smoothKernel(2));
	kernel_y_3d = repmat(kernel_y,[obj.options.smoothKernel(1) 1 obj.options.smoothKernel(3)]);
	kernel_z(1,1,:) = gausswin(obj.options.smoothKernel(3));
	kernel_z_3d = repmat(kernel_z,[obj.options.smoothKernel(1) obj.options.smoothKernel(2) 1]);
	kernel = kernel_x_3d.*kernel_y_3d.*kernel_z_3d;
	% 3D convolution
	freq_3d_smooth = conv3(freq_3d,kernel);
end	
if strcmp(obj.options.FilterType,'box')
	% Make kernel
	kernel = ones(obj.options.smoothKernel(1),obj.options.smoothKernel(2),obj.options.smoothKernel(3));
	% 3D convolution
	freq_3d_smooth = conv3(freq_3d,kernel);
end
if strcmp(obj.options.FilterType,'polyfit1d') % fit along Z
	% Calculate frequency gradient in the slice direction (freqGradZ)
	freq_3d_smooth = zeros(nx,ny,nz);
    grad_z_3d = zeros(nx,ny,nz);
	for ix=1:nx
		for iy=1:ny
			% get frequency along z (discard zero values)
			freq_z = squeeze(freq_3d(ix,iy,:));
			ind_nonzero = find(freq_z);
			if length(ind_nonzero) >= obj.options.GradientZ_MinLength
				% fit to polynomial function
				p = polyfit(ind_nonzero,freq_z(ind_nonzero),obj.options.polyOrder);
				f = polyval(p,(1:nz));
				% compute frequency gradient along Z
				grad_z = gradient(f,obj.options.GradientZ_SliceThikcness/1000);		
	% figure, plot(freq_z(ind_nonzero),'o'), hold on, plot(f,'r'), plot(grad_z,'g')
				% fill 3D gradient matrix
				freq_3d_smooth(ix,iy,:) = f;
                grad_z_3d(ix,iy,:) = grad_z;
            end
		end
    end
end	
if strcmp(obj.options.FilterType,'polyfit3d')	
	% re-build X,Y and Z indices
	[xi,yi,zi] = meshgrid(1:nyi,1:nxi,1:nzi);
	
	% find non-zero values
	ind_nonzero = find(freq_3d_i(:));

	% build matrix of polynomial order
	model = [];
	icount = 1;
	for ipz=0:obj.options.polyOrder
		for ipy=0:obj.options.polyOrder
			for ipx=0:obj.options.polyOrder
				model(icount,:) = [ipx ipy ipz];
				icount = icount + 1;
			end
		end
	end
	nb_coeffs = icount - 1;
	
	% Run polynomial fit
 	indepvar = [xi(ind_nonzero) yi(ind_nonzero) zi(ind_nonzero)];
	depvar = freq_3d_i(ind_nonzero);
	ifit = stat_polyfitn(indepvar,depvar,model);
	c = ifit.Coefficients;
	clear indepvar ind_nonzero depvar

	% Build series of unit polynomials
	xi=xi(:)'; yi=yi(:)'; zi=zi(:)';
	matrix_poly = zeros(nb_coeffs,length(xi));
	for iOrder = 1:nb_coeffs
		matrix_poly(iOrder,:) = xi.^model(iOrder,1).*yi.^model(iOrder,2).*zi.^model(iOrder,3);
	end
	
	% reconstruct fitted image
	datafit = c*matrix_poly;
	freq_3d_smooth_i = reshape(datafit,nxi,nyi,nzi);
	clear matrix_poly
	
	% Build matrix of polynomial derivative along Z
	matrix_poly_derivZ = zeros(nb_coeffs,length(xi));
	for iOrder = 1:nb_coeffs
		if model(iOrder,3)==0
			matrix_poly_derivZ(iOrder,:) = zeros(length(xi),1);
		else
			matrix_poly_derivZ(iOrder,:) = model(iOrder,3).*xi.^model(iOrder,1).*yi.^model(iOrder,2).*zi.^(model(iOrder,3)-1);
		end
	end
	
	% take the derivative along Z
	datafit_gradZ_i = c*matrix_poly_derivZ;
	freqGradZ_i = reshape(datafit_gradZ_i,nxi,nyi,nzi);
	clear datafit_gradZ_i matrix_poly_derivZ
end

% upsample data back to original resolution
[x,y,z] = meshgrid(1:ny,1:nx,1:nz);
[xi,yi,zi] = meshgrid(1:(ny-1)/(nyi-1):ny,1:(nx-1)/(nxi-1):nx,1:(nz-1)/(nzi-1):nz);
freq_3d_smooth = interp3(xi,yi,zi,freq_3d_smooth_i,x,y,z,'nearest');
freqGradZ = interp3(xi,yi,zi,freqGradZ_i,x,y,z,'nearest');
clear freqGradZ_i freq_3d_smooth_i


% Load mask
mask = squeeze(mask_3d);
clear mask_3d

% apply magnitude mask
freq_3d_smooth_masked = freq_3d_smooth .* mask;
if strcmp(obj.options.FilterType,'gaussian')
    grad_z_3d = t2star_computeGradientZ(obj,multiecho_magn,freq_3d_smooth_masked);
    freqGradZ_masked = grad_z_3d .* mask;
end
if strcmp(obj.options.FilterType,'box')
    grad_z_3d = t2star_computeGradientZ(obj,multiecho_magn,freq_3d_smooth_masked);
    freqGradZ_masked = grad_z_3d .* mask;
end
if strcmp(obj.options.FilterType,'polydit1d')
    freqGradZ_masked = grad_z_3d .* mask;
end
if strcmp(obj.options.FilterType,'polyfit3d')
    freqGradZ_masked = freqGradZ .* mask;
end
clear mask