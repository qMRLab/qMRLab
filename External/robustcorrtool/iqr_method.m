function [I,value] = iqr_method(a,type)

% Returns a logical vector that flags outliers as 1s based 
% on the IQR methods described in Wilcox 2012 p 96-97.
% 
% FORMAT:  I = iqr_method(a,type)
%          [I,value] = iqr_method(a,type)
%
% INPUTS:
%          a is a vector.
%        
%          type indicates the method to use
%           
%            type = 1 uses the standard boxplot approach,
%            in which the quartiles are estimated by the ideal fourths,
%            q1 and q2. An observation Xi is declared an outlier if:
%            Xi<q1-k(q2-q1) or Xi>q2+k(q2-q1),
%            and k=1.5.
% 
%            type = 2 uses Carling's modification of the boxplot rule.
%            An observation Xi is declared an outlier if:
%            Xi<M-k(q2-q1) or Xi>M+k(q2-q1),
%            where M is the sample median, and
%            k=(17.63n-23.64)/(7.74n-3.71),
%            where n is the sample size.
%
% OUTPUTS: I =     logical vector with 1s for outliers
%          value = IQR, the inter-quartile range 
%
%
% See also IDEALF.

% Cyril Pernet / Guillaume Rousselet 
% ---------------------------------
%  Copyright (C) Corr_toolbox 2012
 
a=a(:);n=length(a);
[q1,q2]=idealf(a);
value=q2-q1;

switch type
    
    case 1
        % standard boxplot method
        k=1.5;
        I=a<(q1-k*value) | a>(q2+k*value);
    
    case 2
        % Carling's modification of the boxplot rule
        M = median(a);
        k=(17.63*n-23.64)/(7.74*n-3.71);        
        I=a<(M-k*value) | a>(M+k*value);
end

I = I+isnan(a);

