function [S0, T2, D] = scd_preproc_getS0_T2(scheme, data, bmin, bmax)

% Estimate S0 and T2
% when bvalue = 0 we have : S0_experimental = S0*exp(-T2/TE)   (1)
%
% least square problem y = A*X :
%       - observations y : S0_experimental
%       - matrix for the equation (1) after linearisation ( "ln( (1) )" )
%       - vector of parameters X : for T2 and S0


% extract b0 values
indexb0 = scd_scheme_bvalue(scheme)*1e3>=bmin & scd_scheme_bvalue(scheme)*1e3<=bmax;
schemeb0 = scheme(indexb0, :);
datab0 = data(indexb0);

% extract TE and observations y
y = log(datab0(:));
TE = schemeb0(:, 7);
N = length(TE);

if length(unique(TE))>1 && (max(TE)-min(TE(TE>0)))>10
    
    if length(unique(scd_scheme_bvalue(schemeb0)))>1 && max(scd_scheme_bvalue(schemeb0))*1e3>100
        A = [ones(N,1), -TE -scd_scheme_bvalue(schemeb0)];
        
        % least square problem resolution
        %xMS = (A'*A)^-1*A'*y;
        xMS = lsqlin(A,double(y),[],[],[],[],[0 1/200 0],[inf inf 3],[],optimoptions('lsqlin','Display','off'));
        
        
        S0 = exp(xMS(1));
        T2 = 1/xMS(2);
        D = xMS(3);
    else
        A = [ones(N,1), -TE];
        
        % least square problem resolution
        %xMS = (A'*A)^-1*A'*y;
        xMS = lsqlin(A,double(y),[],[],[],[],[0 1/200],[inf inf],[],optimoptions('lsqlin','Display','off'));
        
        
        S0 = exp(xMS(1));
        T2 = 1/xMS(2);
        
    end
else
    A = [ones(N,1) -scd_scheme_bvalue(schemeb0)];
    
    % least square problem resolution
    %xMS = (A'*A)^-1*A'*y;
    xMS = lsqlin(A,double(y),[],[],[],[],[0 0],[inf 3],[],optimoptions('lsqlin','Display','off','Algorithm','interior-point'));
    
    
    S0 = exp(xMS(1));
    T2 = inf;
    D = xMS(2);
    disp('In order to measure T2, you need b=0 acquired at different echo times')
end

% 
% figure; hold on
% plot(datab0,'r*')
% plot(S0.*exp(-TE./T2),'b-*')
% legend('datab0 experimental', 'least square')

end