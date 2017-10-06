function [Signal, Sigma] = MPdenoising(data, mask, kernel, sampling, centering)
    %
    % "MPPCA": 4d image denoising and noise map estimation by exploiting  data redundancy in the PCA domain using universal properties of the eigenspectrum of
    % random covariance matrices, i.e. Marchenko Pastur distribution
    %
    %  [Signal, Sigma] = MPdenoising(data, mask, kernel, sampling)
    %       output:
    %           - Signal: [x, y, z, M] denoised data matrix
    %           - Sigma: [x, y, z] noise map
    %       input:
    %           - data: [x, y, z, M] data matrix
    %           - mask:   (optional)  region-of-interest [boolean]
    %           - kernel: (optional)  window size, typically in order of [5 x 5 x 5]
    %           - sampling: 
    %                    1. full: sliding window (default for noise map estimation, i.e. [Signal, Sigma] = MPdenoising(...) )
    %                    2. fast: block processing (default for denoising, i.e. [Signal] = MPdenoising(...))
    % 
    %  Authors: Jelle Veraart (jelle.veraart@nyumc.org)
    % Copyright (c) 2016 New York Universit and University of Antwerp
    %       
    %      Permission is hereby granted, free of charge, to any non-commercial entity
    %      ('Recipient') obtaining a copy of this software and associated
    %      documentation files (the 'Software'), to the Software solely for
    %      non-commercial research, including the rights to use, copy and modify the
    %      Software, subject to the following conditions: 
    %       
    %        1. The above copyright notice and this permission notice shall be
    %      included by Recipient in all copies or substantial portions of the
    %      Software. 
    %       
    %        2. THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
    %      EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIESOF
    %      MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
    %      NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BELIABLE FOR ANY CLAIM,
    %      DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
    %      OTHERWISE, ARISING FROM, OUT OF ORIN CONNECTION WITH THE SOFTWARE OR THE
    %      USE OR OTHER DEALINGS IN THE SOFTWARE. 
    %       
    %        3. In no event shall NYU be liable for direct, indirect, special,
    %      incidental or consequential damages in connection with the Software.
    %      Recipient will defend, indemnify and hold NYU harmless from any claims or
    %      liability resulting from the use of the Software by recipient. 
    %       
    %        4. Neither anything contained herein nor the delivery of the Software to
    %      recipient shall be deemed to grant the Recipient any right or licenses
    %      under any patents or patent application owned by NYU. 
    %       
    %        5. The Software may only be used for non-commercial research and may not
    %      be used for clinical care. 
    %       
    %        6. Any publication by Recipient of research involving the Software shall
    %      cite the references listed below.
    % 
    % REFERENCES
    %      Veraart, J.; Fieremans, E. & Novikov, D.S. Diffusion MRI noise mapping
    %      using random matrix theory Magn. Res. Med., 2016, early view, doi:
    %      10.1002/mrm.26059


 
    if isa(data,'integer') 
        data = single(data);
    end
    [sx, sy, sz, M] = size(data);

       
    if ~exist('mask', 'var') || isempty(mask)
        mask = true([sx, sy, sz]);
    end
    if ~isa(mask,'boolean') 
        mask = mask>0;
    end
  
    if ~exist('kernel', 'var') || isempty(kernel)
        kernel = [5 5 5];
    end
    
    if isscalar(kernel)
        kernel = [kernel, kernel, kernel];
    end
    kernel = kernel + (mod(kernel, 2)-1);   % needs to be odd.
    k = (kernel-1)/2; kx = k(1); ky = k(2); kz = k(3);
    N = prod(kernel);
    
    if ~exist('sampling', 'var') || isempty(sampling)
        if nargout > 1
            sampling = 'full';
        else
            sampling = 'fast';
        end
    end
    
    
    % create mask
    if ~exist('mask', 'var') || isempty(mask)
        mask = true(sx, sy, sz);
    end
    
    if ~exist('centering', 'var') || isempty(centering)
        centering = false;
    end
    
    if strcmp(sampling, 'fast')  
        if nargout>1
            warning('undersampled noise map will be returned')
        end
        % compute center points of patches
        stats = regionprops(mask, 'BoundingBox');
        n = ceil(stats.BoundingBox(4:6) ./ kernel);

        x = linspace(ceil(stats.BoundingBox(1))+k(1), floor(stats.BoundingBox(1))-k(1) + stats.BoundingBox(4), n(1)); x = round(x);
        y = linspace(ceil(stats.BoundingBox(2))+k(2), floor(stats.BoundingBox(2))-k(2) + stats.BoundingBox(5), n(2)); y = round(y);
        z = linspace(ceil(stats.BoundingBox(3))+k(3), floor(stats.BoundingBox(3))-k(3) + stats.BoundingBox(6), n(3)); z = round(z);

        [y, x, z] = meshgrid(x, y, z); x = x(:); y = y(:); z = z(:);
    end
    
    if strcmp(sampling, 'full')
        warning('image bounderies are not processed.')
        mask(1:k(1), :, :) = 0;
        mask(sx-k(1):sx, :, :) = 0;
 
        mask(:, 1:k(2), :) = 0;
        mask(:, sy-k(2):sy, :, :) = 0;           
        mask(:,:,1:k(3)) = 0;
        mask(:,:,sz-k(3)) = 0;
             
        x = []; y = []; z = []; 
        for i = k(3)+1:sz-k(3)
            [x_, y_] = find(mask(:,:,i) == 1);
            x = [x; x_]; y = [y; y_];  z = [z; i*ones(size(y_))];
        end 
        x = x(:); y = y(:); z = z(:);
    end

    
    % Declare variables:
    sigma = zeros(1, numel(x), 'like', data);
    npars = zeros(1, numel(x), 'like', data);
    signal = zeros(M, prod(kernel), numel(x), 'like', data);

    Sigma = zeros(sx, sy, sz, 'like', data);
    Npars = zeros(sx, sy, sz, 'like', data);
    Signal = zeros(sx, sy, sz, M, 'like', data);

    
    % compute scaling factor for in case N<M
    R = min(M, N);
    scaling = (max(M, N) - (0:R-centering-1)) / N;
    scaling = scaling(:);

    
    % start denoising
    for nn = 1:numel(x)
        
        % create data matrix 
        X = data(x(nn)-kx:x(nn)+kx, y(nn)-ky:y(nn)+ky, z(nn)-kz:z(nn)+kz, :);
        X = reshape(X, N, M); X = X';

        if centering
            colmean = mean(X, 1);
            X = X - repmat(colmean, [M, 1]);
        end
        % compute PCA eigenvalues 
        [u, vals, v] = svd(X, 'econ');
        vals = diag(vals).^2 / N;   

        
        % First estimation of Sigma^2;  Eq 1 from ISMRM presentation 
        csum = cumsum(vals(R-centering:-1:1)); cmean = csum(R-centering:-1:1)./(R-centering:-1:1)'; sigmasq_1 = cmean./scaling;
        
        % Second estimation of Sigma^2; Eq 2 from ISMRM presentation 
        gamma = (M - (0:R-centering-1)) / N;
        rangeMP = 4*sqrt(gamma(:));
        rangeData = vals(1:R-centering) - vals(R-centering);
        sigmasq_2 = rangeData./rangeMP;
        
        % sigmasq_2 > sigma_sq1 if signal-components are represented in the
        % eigenvalues
        
        t = find(sigmasq_2 < sigmasq_1, 1);

        if isempty(t)
            sigma(nn) = NaN;
            signal(:, :, nn) = X;  
            t = R+1;
        else
            sigma(nn) = sqrt(sigmasq_1(t));
            vals(t:R) = 0;
            s = u*diag(sqrt(N*vals))*v';
            if centering
               s = s + repmat(colmean, [M, 1]);
            end
        
            signal(:, :, nn) = s;
        end
        npars(nn) = t-1; 
    end

    for nn = 1:numel(x)
        Sigma(x(nn), y(nn), z(nn)) = sigma(nn);
        Npars(x(nn), y(nn), z(nn)) = npars(nn);
        if strcmp(sampling, 'fast')
            Signal(x(nn)-k(1):x(nn)+k(1),y(nn)-k(2):y(nn)+k(2),z(nn)-k(3):z(nn)+k(3), :) = unpatch(signal(:,:,nn), k);
        elseif strcmp(sampling, 'full')
            Signal(x(nn), y(nn),z(nn), :) = signal(:,ceil(prod(kernel)/ 2),nn);
        end
    end
end

function data = unpatch(X, k)
    kernel=k+k+1; 
    data = zeros([kernel, size(X, 1)]);
    tmp = zeros(kernel);
    for i = 1:size(X, 1);
        tmp(:) = X(i, :);
        data(:,:,:,i) = tmp;
    end 
end
