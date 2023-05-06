function [t2star_uncorr_3d, t2star_corr_3d,rsquared_uncorr_3d,rsquared_corr_3d,grad_z_final_3d,iter_3d] = t2star_computeCorrectedFitting(multiecho_magn,grad_z_3d,mask_3d,echo_time,do_optimization,fitting_method,threshold_t2star_max)

sizeData = size(multiecho_magn);
nx = sizeData(1);
ny = sizeData(2);
nz = sizeData(3);
nt = sizeData(4);

nb_echoes = nt;

% loop across slices
t2star_uncorr_3d = zeros(nx,ny,nz);
t2star_corr_3d = zeros(nx,ny,nz);
grad_z_final_3d = zeros(nx,ny,nz);
% adjrsquare_3d = zeros(nx,ny,nz);
rsquared_uncorr_3d = zeros(nx,ny,nz);
rsquared_corr_3d = zeros(nx,ny,nz);
iter_3d = zeros(nx,ny,nz);
X = cat(2,echo_time',ones(nb_echoes,1));
for iz=1:nz
    data_multiecho_magn = squeeze(multiecho_magn(:,:,iz,:));
	% Get mask indices
	ind_mask = find(mask_3d(:,:,iz));
	nb_pixels = length(ind_mask);
	
	% Initialization
	t2star_uncorr_2d = zeros(nx,ny);
	t2star_corr_2d = zeros(nx,ny);
% 	adjrsquare_2d = zeros(nx,ny);
	rsquared_uncorr_2d = zeros(nx,ny);
	rsquared_corr_2d = zeros(nx,ny);
	iter_2d = zeros(nx,ny);
	
	% Loop across pixels
	if do_optimization, grad_z_final_2d = zeros(nx,ny); end
	data_multiecho_magn_2d = reshape(data_multiecho_magn,nx*ny,nt);
	grad_z_2d = reshape(grad_z_3d,nx*ny,nz);
	for iPix=1:nb_pixels
	
		% Get data magnitude in 1D
		data_magn_1d = data_multiecho_magn_2d(ind_mask(iPix),:);

		if ~isempty(find(data_magn_1d))
			% Perform uncorrected T2* fit
			S = data_magn_1d;
			TE = echo_time;
			method = fitting_method;
% iPix
			[T2star,S0,Sfit,Rsquared,iter] = func_t2star_fit(S,TE,method,X,nt);
			rsquared_uncorr_2d(ind_mask(iPix)) = Rsquared;
			t2star_uncorr_2d(ind_mask(iPix)) = T2star;

			% Get initial freqGradZ value from computed map
			freqGradZ_init = grad_z_2d(ind_mask(iPix),iz);

			% Get final freqGradZ value
			if do_optimization
				% Minimization algorithm
				[freqGradZ_final,sd_err,exitflag,output] = fminsearch(@(delta_f) func_t2star_optimization(data_magn_1d,echo_time,delta_f,X),delta_f_init);
				freqGradZ_final_2d(ind_mask(iPix)) = freqGradZ_final;
			else
				% Just use the initial freqGradZ value - which is acceptable if nicely computed
				freqGradZ_final = freqGradZ_init;
			end

			% Correct signal by sinc function
			data_magn_1d_corr = data_magn_1d ./ abs(sinc(freqGradZ_final*echo_time/2000)); % N.B. echo time is in ms

			% Perform T2* fit
			S = data_magn_1d_corr;
			TE = echo_time;
			method = fitting_method;
			[T2star,S0,Sfit,Rsquared,iter] = func_t2star_fit(S,TE,method,X,nt);
			rsquared_corr_2d(ind_mask(iPix)) = Rsquared;
			t2star_corr_2d(ind_mask(iPix)) = T2star;
			iter_2d(ind_mask(iPix)) = iter;
		
		end
			


% disp(['T2* uncorrected = ',num2str(t2star_2d(ind_mask(iPix)))])
% disp(['T2* corrected = ',num2str(t2star_corr_2d(ind_mask(iPix)))])

% 		data_magn_1d_corr = data_magn_1d ./ sinc(delta_f*echo_time/2);

% 		grad_test = (-50:1:50);
% 		clear sd_err
% 		for i=1:length(grad_test)
% 			data_magn_1d_corr = data_magn_1d ./ sinc(grad_test(i)*echo_time/2);
% 			y = log(data_magn_1d_corr)';
% 			a = inv(X'*X)*X'*y;
% 			t2star_corr = -1/a(1);
% 			Sfitted = exp(a(2)-echo_time/t2star_corr);
% 			% compute error
% 			err = Sfitted - data_magn_1d_corr;
% 			sd_err(i) = std(err);
% % 			figure, plot(echo_time,data_magn_1d_corr), hold on, plot(echo_time,Sfitted,'r'), legend({'Raw data','Fitted Data'}), grid, title(['Freq gradient=',num2str(grad_test(i)),' , err=',num2str(sd_err(i))]), ylim([0 1400])
% 		end
% 		[val ind]=min(sd_err);
% 		min_grad=grad_test(ind);
%  		figure, plot(grad_test,sd_err,'*'), grid, title(['iPix=',num2str(iPix),', MinGradFreq=',num2str(min_grad)])

		% Perform linear least square fit of log(Scorr)
		% y = a.X + err
% 		y = log(data_magn_1d_corr)';
% 		a = inv(X'*X)*X'*y;
% 		t2star_corr = -1/a(1);		
	end %iPix
	
	% Fill 3D T2* matrix
	t2star_uncorr_3d(:,:,iz) = t2star_uncorr_2d;
	t2star_corr_3d(:,:,iz) = t2star_corr_2d;
	if do_optimization, grad_z_final_3d(:,:,iz) = grad_z_final_2d; end
% 	adjrsquare_3d(:,:,iz) = adjrsquare_2d;
	rsquared_uncorr_3d(:,:,iz) = rsquared_uncorr_2d;
	rsquared_corr_3d(:,:,iz) = rsquared_corr_2d;
	iter_3d(:,:,iz) = iter_2d;
	
end % iz

% threshold T2* map (for quantization purpose when saving in NIFTI).
t2star_uncorr_3d(find(t2star_uncorr_3d > threshold_t2star_max)) = threshold_t2star_max;
t2star_corr_3d = abs(t2star_corr_3d);
t2star_corr_3d(find(t2star_corr_3d > threshold_t2star_max)) = threshold_t2star_max;

% % convert to millisecond
% if opt.convert_to_ms
% 	j_disp(opt.fname_log,['Convert T2* to millisecond...'])
% 	t2star_uncorr_3d = t2star_uncorr_3d.*1000;
% 	t2star_corr_3d = t2star_corr_3d.*1000;
% end

% END FUNCTION

function sd_err = func_t2star_optimization(data_magn_1d,echo_time,delta_f,X)
% Optimization function
data_magn_1d_corr = data_magn_1d ./ sinc(delta_f*echo_time/2);
y = log(data_magn_1d_corr)';
a = inv(X'*X)*X'*y;
t2star_corr = -1/a(1);
% Compute error
Sfitted = exp(a(2)-echo_time/t2star_corr);
err = Sfitted - data_magn_1d_corr;
sd_err = std(err);

function [T2star,S0,Sfit,Rsquared,iter] = func_t2star_fit(S,TE,method,X,nt)
% perform T2* fit
% 
% INPUT
% S
% TE
% method
% X				for ols, gls
% nt			for num

iter = 1; % number of iterations (only for NLLS). Max = 20.

if strcmp(method,'ols') % ordinary least squares

	% remove zeroed values (because of the log)
	nonzero = find(S);
	y = log(S(nonzero))';
	X = X(nonzero,:);
	% LLS fitting
	a = inv(X'*X)*X'*y;
	T2star = -1/a(1);
	S0 = exp(a(2));

elseif strcmp(method,'gls') % generalized least squares

	% remove zeroed values (because of the log)
	nonzero = find(S);
	y = log(S(nonzero))';
	X = X(nonzero,:);
	% LLS fitting
	V = eye(length(y)).*repmat(1./exp(y),1,length(y));
	a = inv(X'*inv(V)*X)*X'*inv(V)*y;
	T2star = -1/a(1);
	S0 = exp(a(2));

elseif strcmp(method,'nlls')  % lin_gls

	% GLS estimation to get initial parameters
	[T2star_init,S0_init] = func_t2star_fit(S,TE,'gls',X,nt);
	% Non-linear fitting
	pin = [S0_init, T2star_init]; % vector of initial parameters to be adjusted by leasqr.
	func = @(x,p) p(1)*exp(-x/p(2)); % name of function in quotes,of the form y=f(x,p)
	stol = 0.0001; % scalar tolerances on fractional improvement in ss,default stol=.0001
	niter = 20; % scalar max no. of iterations, default = 20
	wt = 1; % wt=vec(dim=1 or length(x)) of statistical weights.  These should be set to be proportional to (sqrts of var(y))^-1; (That is, the covaraince matrix of the data is assumed to be proportional to diagonal with diagonal  equal to (wt.^2)^-1.  The constant of proportionality will be estimated.),  default=1.
	dp = 0.001*ones(size(pin)); % fractional incr of p for numerical partials,default= .001*ones(size(pin))
	dfdp = 'dfdp';
	compute_covMat = 0;
	[f,p,kvg,iter] = stat_nlleasqr(TE',S',pin,func,stol,niter,wt,dp,dfdp,0);
	% if no convergence, use gls estimator
	if ~kvg
		S0 = S0_init;
		T2star = T2star_init;
	else
		S0 = p(1);
		T2star = p(2);
	end
	
elseif strcmp(method,'num')  % Numerical approximation based on the NumART2* method in [Hagberg, MRM 2002].

	T2star = (TE(nt)-TE(1)) * ( S(1)+S(nt)+sum(2*S(2:nt-1)) ) / (2*(nt-1)*(S(1)-S(nt)));
	S0 = S(1).*exp(TE(1)/T2star);

end

Sfit = S0 * exp(-TE/T2star);

% Compute R2 goodness of fit
SSresid = sum((S-Sfit).^2);
SStotal = (length(S)-1) * var(S);
Rsquared = 1 - SSresid/SStotal;