% nlsS = getNLSStruct( extra, dispOn, zoom)
%
% extra.tVec    : defining TIs 
%               (not called TIVec because it looks too much like T1Vec)
% extra.T1Vec   : defining T1s
% dispOn        : 1 - display the struct at the end
%                 0 (or omitted) - no display
% zoom          : 1 (or omitted) - do a non-zoomed search
%                 x>1 - do an iterative zoomed search (x-1) times (slower search)
%                 NOTE: When zooming in, convergence is not guaranteed.
%
% Data Model    : a + b*exp(-TI/T1) 
%    
% written by J. Barral, M. Etezadi-Amoli, E. Gudmundson, and N. Stikov, 2009
%  (c) Board of Trustees, Leland Stanford Junior University 

function nlsS = getNLSStruct(extra, dispOn, zoom)

nlsS.tVec = extra.tVec(:);
nlsS.N = length(nlsS.tVec);
nlsS.T1Vec = extra.T1Vec(:);
nlsS.T1Start = nlsS.T1Vec(1);
nlsS.T1Stop = nlsS.T1Vec(end);
nlsS.T1Len = length(nlsS.T1Vec);

% The search algorithm to be used
nlsS.nlsAlg = 'grid'; % Grid search

% Display the struct so that the user can see it went ok
if nargin < 2 
  dispOn = 0;
end

% Set the number of times you zoom the grid search in, 1 = no zoom
% Setting this greater than 1 will reduce the step size in the grid search
% (and slow down the fit significantly)

if nargin < 3
	nlsS.nbrOfZoom = 2;
else
	nlsS.nbrOfZoom = zoom;
end

if nlsS.nbrOfZoom > 1
    nlsS.T1LenZ = 21; % Length of the zoomed search
end
		
if dispOn
  % Display the structure for inspection
  nlsS
end

% Set the help variables that can be precomputed:
% alpha is 1/T1,
% theExp is a matrix of exp(-TI/T1) for different TI and T1,
% rhoNormVec is a vector containing the norm-squared of rho over TI,
% where rho = exp(-TI/T1), for different T1's.
switch(nlsS.nlsAlg)
  case{'grid'}
    alphaVec = 1./nlsS.T1Vec; 
    nlsS.theExp = exp( -nlsS.tVec*alphaVec' );
    nlsS.rhoNormVec = ...
        sum( nlsS.theExp.^2, 1)' - ...
        1/nlsS.N*(sum(nlsS.theExp,1)').^2;    
end 

