function [I,value] = madmedianrule(a,type)

% Returns a logical vector that flags outliers as 1s based
% on the MAD-median rule described in Wilcox 2012 p 97.
%
% FORMAT: I = madmedianrule(a,type)
%
% INPUTS:
%         a is a vector or matrix. In the latter case,
%         the MAD median rule is applied column-wise.
%
%         type indicates the method to use
%
%           for type = 1, MADS = b_n*1.4826*median(abs(a - median(a))
%           b_n is the finite sample correction factor described in
%           William, J Stat Computation and Simulation, 81, 11, 2011
%           1.4826 is the consistancy factor (the std) for the Gaussian distribution
%
%           for type = 2, MADN = median(abs(a - median(a)) ./ 0.6745
%           rescaled MAD by the .6745 to estimate the std of the Gaussian
%           distribution - see Wilcox 2012 p 75.

% Cyril Pernet / Guillaume Rousselet
% ---------------------------------
%  Copyright (C) Corr_toolbox 2012

k = 2.2414; % = sqrt(chi2inv(0.975,1))
[n,p]=size(a);
M = median(a);
MAD=median(abs(a - repmat(median(a),n,1)));

switch type
    
    case 1
        % Median Absolute Deviation with finite sample correction factor
        if n == 2
            bn=1.197; % 1.196;
        elseif n == 3
            bn=1.49; % 1.495;
        elseif n == 4
            bn=1.36; % 1.363;
        elseif n == 5
            bn=1.217; % 1.206;
        elseif n == 6
            bn=1.189; % 1.200;
        elseif n == 7
            bn=1.138; % 1.140;
        elseif n == 8
            bn=1.127; % 1.129;
        elseif n == 9
            bn=1.101; % 1.107;
        else
            bn=n/(n-0.8);
        end
        
        MADS=repmat((MAD.*1.4826.*bn),n,1);
        I = a > (repmat(M,[n 1])+(k.*MADS));
        I = I+isnan(a);
        value = MADS(1,:);
        
    case 2
        % Normalized Median Absolute Deviation
        MADN = repmat((MAD./.6745),n,1); % same as MAD.*1.4826 :-)
        I = (abs(a-repmat(M,n,1)) ./ MADN) > k;
        I = I+isnan(a);
        value = MADN(1,:);
        
    case 3 % S outliers
        
        value = NaN(n,p);
        for p=1:size(a,2)
            tmp = a(:,p);
            points = find(~isnan(tmp));
            tmp(isnan(tmp)) = [];
            
            % compte all distances
            n = length(tmp);
            for i=1:n
                j = points(i);
                indices = [1:n]; indices(i) = [];
                value(j,p) = median(abs(tmp(i) - tmp(indices)));
            end
            
            % get the S estimator
            % consistency factor c = 1.1926;
            Sn = 1.1926*median(value(points,p));
            
            % get the outliers in a normal distribution
            I(:,p) = (value(:,p) ./ Sn) > k; % no scaling needed as S estimates already std(data)
            I(:,p) = I(:,p)+isnan(a(:,p));
        end
end 
