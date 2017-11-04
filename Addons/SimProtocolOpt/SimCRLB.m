function [F,xnames,CRLB, Fall]=SimCRLB(obj,Prot,xvalues,sigma,vars)
% Protocol design for qMR: Optimize the stability of fitting parameters
% toward gaussian noise. 
% Use the Cramer-Rao Lower bound for objective function: <a href="matlab: web('https://en.wikipedia.org/wiki/Cramer-Rao_bound')">Wikipedia</a>
% [F,xnames,CRLB]=SimCRLB(obj,Prot,xvalues,sigma)
% https://en.wikipedia.org/wiki/Cramer-Rao_bound
% Based on: Alexander, D.C., 2008. A general framework for experiment design in diffusion MRI and its application in measuring direct tissue-microstructure features. Magn. Reson. Med. 60, 439?448.
%
% [F,xnames,CRLB]=SimCRLB(obj,Prot,xvalues,sigma)
% Outputs:
%   F           minimum COV per variable

if 0%~isprop(obj,'fx'), variables = 1:length(obj.xnames);
else
    variables=find(~obj.fx);
end
F=zeros(size(xvalues,1),length(variables));

for ix=1:size(xvalues,1)
    
    CRLB = (SimFisherMatrix(obj,Prot,xvalues(ix,:),variables,sigma)+eps)^(-1);
    F(ix,:) = diag(CRLB)'./xvalues(ix).^2;
    
end
Fall = F(:);
F = mean(F(:));
xnames=obj.xnames(variables);