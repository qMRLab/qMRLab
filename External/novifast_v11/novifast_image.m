function [ K, T1 ] = novifast_image( Im, alpha, TR, options , varargin )
    %
    % "NOVIFAST": NOVIFAST, a novel, fast, NLLS-based algorithm specifically tailored to VFA SPGR T1 mapping. 
    %  By exploiting the particular structure of the SPGR model, a computationally efficient, yet accurate and 
    %  precise T1 map estimator is derived. 
    %
    %  This code is a vectorized version of the original NOVIFAST implementation [1].  It works on the VFA T1-weighted image set, 
    %  and provides the estimated T1 map (NLLS sense) directly. It is not a voxel-wise, for-loop, implementation of 1D NOVIFAST. 
    %  This is the code we recommend to use for fast VFA T1 mapping.
    %
    %
    %  [ K, T1 ] = novifast_image( Im, alpha, TR, options , initial values, mask )
    %       output:
    %           - K: [x, y, z] Estimated K (linear parameter) map
    %           - T1: [x, y, z] Estimated T1 map
    %       input:
    %           - Im: [x, y, z, N] 2D or 3D VFA T1-weighted image set
    %                   acquired with N flip angles
    %           - alpha:  Column vector with selected flip angles
    %           - TR:  Repetition time of the VFA T1-weighted image set
    %           - options: Structure with convergence settings
    %                    1. options.MaxIter: Maximum number of iterations. NOVIFAST will stop if the number of iterations exceed 'options.MaxIter'
    %                    2. options.Tol: NOVIFAST will stop if the relative l2 norm difference between consecutive iterates is below 'options.Tol'
    %                    3. options.Direct: NOVIFAST will be run 'options.Direct' iterations, without no convergence criterion
    %           -initial values (optional): [Kini,T1ini]^T.  2D column vector which contains a pair of initial values to estimate the K and T1 map
    %           -mask [x, y, z] (optional): mask to apply NOVIFAST in a pre-selected region of interest. Dimensions should match the spatial dimensions of Im.
    %
    %
    %
    %  Authors: Gabriel Ramos Llordén (Gabriel.Ramos-Llorden@uantwerpen.be ; gabrll@gmail.com)
    %  Copyright (c) 2018 University of Antwerp
    %
    %
    %
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
    %      EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    %      MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
    %      NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BELIABLE FOR ANY CLAIM,
    %      DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
    %      OTHERWISE, ARISING FROM, OUT OF ORIN CONNECTION WITH THE SOFTWARE OR THE
    %      USE OR OTHER DEALINGS IN THE SOFTWARE. 
    %       
    %        3. In no event shall University of Antwerp be liable for direct, indirect, special,
    %      incidental or consequential damages in connection with the Software.
    %      Recipient will defend, indemnify and hold University of AntwerpU harmless from any claims or
    %      liability resulting from the use of the Software by recipient. 
    %       
    %        4. Neither anything contained herein nor the delivery of the Software to
    %      recipient shall be deemed to grant the Recipient any right or licenses
    %      under any patents or patent application owned by University of AntwerpU. 
    %       
    %        5. The Software may only be used for non-commercial research and may not
    %      be used for clinical care. 
    %       
    %        6. Any publication by Recipient of research involving the Software shall
    %      cite the references listed below.
    % 
    %      REFERENCES
    %    
    %   [1] Ramos-Llordén, G., Vegas-Sánchez-Ferrero, G., Björk, M., Vanhevel, F.,
    %       Parizel, P. M., San José Estépar, R., den Dekker, A. J., and Sijbers, J.
    %       NOVIFAST: a fast algorithm for accurate and precise VFA MRI T1 mapping.
    %       IEEE Trans. Med. Imag., early access, doi:10.1109/TMI.2018.2833288

    
%% check input
sizeim=size(Im);
nrows=sizeim(1);
ncols=sizeim(2);
if numel(sizeim)==3
    nslices=1;
    nalpha=sizeim(3);
else
    nslices=sizeim(3);
    nalpha=sizeim(4);
end
N=numel(alpha);

if nalpha~=N
    error('Dimensions do not match');
end

if isempty(nslices)
    nslices=1;
end

if ~isfield(options, 'Direct')
    if ~isfield(options, 'MaxIter')
        options.MaxIter = 10; %default
    elseif options.MaxIter<1 || options.MaxIter>200
        error('options: Maxiter should be set to a value between 1 and 200');
    end
    
    if ~isfield(options,'Tol')
        options.Tol = 1e-6; %default
    elseif options.Tol<0 || options.Tol>1e-2
        error('options: Tol should be set to a value between 0 and 1e-2');
    end
    modeDirect=false;
elseif options.Direct<1 || options.Direct>200
    error('options: Directiter should be set to a value between 1 and 200');
else
    modeDirect=true;
end

if isempty(varargin)
    fprintf('User did not provide initial values neither a mask. Using default parameters...\n')
    ini=[0.5,500];
    th=0.05*max(max(max(Im(:)))); %Intensity values smaller than 5% of the maximum value of the SPGR dataset are left out
    if nslices==1
        mask = squeeze(Im(:,:,1))>th;
    else
        mask = squeeze(Im(:,:,:,1))>th;
    end
elseif ~isvector(varargin{1})
     fprintf('User did not provide initial values. Using default parameters... \n');
     ini=[0.5,500];
     mask=varargin{1};
else
    ini=varargin{1};
    if length(varargin)==1
        fprintf('User did not provide a mask. Using default parameters... \n');
        th=0.05*max(max(max(Im(:)))); %Intensity values smaller than 5% of the maximum value of the SPGR dataset are left out
        if nslices==1
            mask = squeeze(Im(:,:,1))>th;
        else
            mask = squeeze(Im(:,:,:,1))>th;
        end
    else
        fprintf('User did provide initial values and a mask \n')
        mask=varargin{2};
    end
end

pm=find(mask);
M=numel(pm);
%% NOVIFAST begins here

% pre-computing
K=squeeze(zeros(nrows,ncols,nslices));
T1=squeeze(zeros(nrows,ncols,nslices));

alphanm=alpha*ones(1,M);
y=reshape(Im(:),nrows*ncols*nslices,N);
ynm=y(pm,:)';
pnm=sind(alphanm);
qnm=cosd(alphanm);

% initialization
Kini=ini(1);
T1ini=ini(2);
c1m=Kini*(1*exp(-TR/T1ini))*ones(1,M);
c2m=exp(-TR/T1ini)*ones(1,M);
k=0;
done=false;

% iterative process
while ~done
    
    c2m_old=c2m;
    c1m=repmat(c1m,[N,1]);
    c2m=repmat(c2m,[N,1]);
    denm=1-c2m.*qnm;
    snm=c1m.*pnm./denm;
    
    %definition of vectors
    A=ynm.*qnm./denm;
    Ahat=snm.*qnm./denm;
    B=pnm./denm;
    Z=ynm./denm;
    
    %definition of inner products
    BB=sum(B.^2,1);
    AAhat=sum(A.*Ahat,1);
    BAhat=sum(B.*Ahat,1);
    BA=sum(B.*A,1);
    BZ=sum(B.*Z,1);
    ZAhat=sum(Z.*Ahat,1);
    
    %calculation of c1m and c2m
    detm=BB.*AAhat- BAhat.*BA;
    c1m=(BZ.*AAhat - ZAhat.*BA)./detm;
    c2m=(BB.*ZAhat - BAhat.*BZ)./detm;
    k=k+1;
    
    %stopping
    if modeDirect %mode with no-convergence criterion
        if k==options.Direct
            done=true;
        end
    else
        % Relative l1 norm for c2 (Convergence is controlled by c2 only)
        finite = isfinite(c2m) & isfinite(c2m_old);
        rel_err=( norm(c2m(finite)-c2m_old(finite),1) )/ norm(c2m(finite),1);  
        if rel_err< options.Tol || k>=options.MaxIter % mode with convergence criterion
            done=true;
        end
    end  
end

non_physical = c2m <= 0 | ~isfinite(c2m);
c2m(non_physical) = NaN;

Km=c1m./(1-c2m);
T1m=-TR./log(c2m);

%K and T1 maps
T1(pm)=T1m;
K(pm)=Km;
end

