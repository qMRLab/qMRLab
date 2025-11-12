function [ K, T1 ] = novifast_1D( y, alpha, TR, options , varargin )
    %
    % "NOVIFAST": NOVIFAST, a novel, fast, NLLS-based algorithm specifically tailored to VFA SPGR T1 mapping. 
    %  By exploiting the particular structure of the SPGR model, a computationally efficient, yet accurate and 
    %  precise T1 map estimator is derived. 
    %
    %  This code is the 1D version of the original NOVIFAST implementation [1]. It is meant to estimate the T1 value from a SPGR signal. 
    %  To estimate a complete T1 map from a SPGR T1-weighted image set, we do not recommend to apply novifast_1D in a
    %  voxel-wise manner. Instead, we advocate for using 'novifast_image', also included in this NOVIFAST package.
    %
    %
    %  [ K, T1 ] = novifast_1D( y, alpha, TR, options , initial values)
    %       output:
    %           - K: Estimated K (linear parameter) value
    %           - T1:  Estimated T1 value
    %       input:
    %           - y: Column vector with N SPGR samples acquired with varying flip angles
    %           - alpha:  Column vector with selected flip angles
    %           - TR:  Repetition time of the VFA T1-weighted image set
    %           - options: Structure with convergence settings
    %                    1. options.MaxIter: Maximum number of iterations. NOVIFAST will stop if the number of iterations exceed 'options.MaxIter'
    %                    2. options.Tol: NOVIFAST will stop if the relative l2 norm difference between consecutive iterates is below 'options.Tol'
    %                    3. options.Direct: NOVIFAST will be run 'options.Direct' iterations, without no convergence criterion
    %           -initial values (optional): [Kini,T1ini]^T.  2D column vector which contains a pair of initial values to estimate the K and T1 values
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
    fprintf('User did not provide initial values. Using default parameters...\n')
    ini=[0.5,500];
else
    ini=varargin{1};
end

%% NOVIFAST begins here

% pre-computing
p=sind(alpha);
q=cosd(alpha);
yq=y.*q;

% initialization
Kini=ini(1);
T1ini=ini(2);
c1=Kini*(1*exp(-TR/T1ini));
c2=exp(-TR/T1ini);
k=0;
done=false;

% iterative process
while ~done

    c1_old=c1;
    c2_old=c2;
    
    %definition of vectors    
    Denom=1./(1-c2*q);
    s=c1*p.*Denom;
    a=yq.*Denom;
    ahat=s.*q.*Denom;
    b=p.*Denom;
    yvec=y.*Denom;
    
    %Definition of inner products
    yvecb=yvec'*b;
    ba=b'*a;
    yvecahat=yvec'*ahat;
    aahat=a'*ahat;
    bb = b'*b;
    bahat=b'*ahat;
    
    %calculation of c1m and c2m
    detc1=yvecb*aahat - ba*yvecahat;
    detc2=bb*yvecahat - yvecb*bahat;
    detA=bb*aahat - bahat*ba;

    %Definition of function g(c)
    c1=detc1/detA;
    c2=detc2/detA;
    k=k+1;
    
    %stopping
    if modeDirect %mode with no-convergence criterion
        if k==options.Direct
            done=true;
        end
    else
        rel_err= norm([c1-c1_old,c2-c2_old],2) / norm([c1_old,c2_old],2);  %Relative l1 norm for c2 (Convergence is controlled by c2 only)
        if rel_err< options.Tol || k>=options.MaxIter %mode with convergence criterion
            done=true;
        end
    end  
end

K=c1./(1-c2);
T1=-TR./log(c2);

end

