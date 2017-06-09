function [F,xnames,CRLB]=SimCRLB(obj,Prot,xvalues,sigma)
% F=scd_stats_CRLB(scheme,xvalues,sigma)
% https://en.wikipedia.org/wiki/Cramer-Rao_bound
% Based on: Alexander, D.C., 2008. A general framework for experiment design in diffusion MRI and its application in measuring direct tissue-microstructure features. Magn. Reson. Med. 60, 439?448.
%
% this function look at the stability of model equation -->
% outputs a score F : minimum COV per variable

variables=find(~obj.fx);
F=zeros(size(xvalues,1),length(variables));
xvalues = xvalues + 1e-10;
for ix=1:size(xvalues,1)
    
    CRLB = (SimFisherMatrix(obj,Prot,xvalues(ix,:),variables,sigma))^(-1);
    F(ix,:) = diag(CRLB)'./xvalues(ix).^2;
    
end
xnames=obj.xnames(variables);