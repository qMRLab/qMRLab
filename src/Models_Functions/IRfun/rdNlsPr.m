% [T1Est, bMagEst, aMagEst, res, idx] = rdNlsPr(data, nlsS)
%
% Finds estimates of T1, |a|, and |b| using a nonlinear least
% squares approach together with polarity restoration. 
% The model +-|ra + rb*exp(-t/T1)| is used. 
% The residual is the rms error between the data and the fit. 
% idx - is the index of the last polarity-restored data point
%
% INPUT:
% data - the absolute data to estimate from
% nlsS - struct containing the NLS search parameters and
%        the data model to use
%    
% written by J. Barral, M. Etezadi-Amoli, E. Gudmundson, and N. Stikov, 2009
%  (c) Board of Trustees, Leland Stanford Junior University 
%
% Modified By Ilana Leppert June 2017
%  Return the index of the last polarity restored datapoint
%  e.g. if the signal of the 2 first inversion times need to be
%  inverted: idx=2

function [T1Est, bEst, aEst, res, idx] = rdNlsPr(data, nlsS)
    
if ( length(data) ~= nlsS.N )
  error('nlsS.N and data must be of equal length!')
end


% Make sure the data come in increasing TI-order
[tVec,order] = sort(nlsS.tVec); 
data = squeeze(data); 
data = data(order);

% Initialize variables
aEstTmp = zeros(1,2);
bEstTmp = zeros(1,2);
T1EstTmp = zeros(1,2);
resTmp = zeros(1,2);

% Make sure data vector is a column vector
data = data(:);

%% Find the min of the data
[minVal, minInd] = min(data);

%% Fit
switch(nlsS.nlsAlg)
  case 'grid'
    try
      nbrOfZoom = nlsS.nbrOfZoom;
    catch
      nbrOfZoom = 1; % No zoom
    end

    for ii = 1:2
      theExp = nlsS.theExp(order,:);
      
      if ii == 1
        % First, we set all elements up to and including
        % the smallest element to minus
        dataTmp = data.*[-ones(minInd,1); ones(nlsS.N - minInd,1)];
      elseif ii == 2
        % Second, we set all elements up to (not including)
        % the smallest element to minus
        dataTmp = data.*[-ones(minInd-1,1); ones(nlsS.N - (minInd-1),1)];
      end

      % The sum of the data
      ySum = sum(dataTmp);

      % Compute the vector of rho'*t for different rho,
      % where rho = exp(-TI/T1) and y = dataTmp
      rhoTyVec = (dataTmp.'*theExp).' - ...
        1/nlsS.N*sum(theExp,1)'*ySum;
      
      % rhoNormVec is a vector containing the norm-squared of rho over TI,
      % where rho = exp(-TI/T1), for different T1's.
      rhoNormVec = nlsS.rhoNormVec;
      
      %Find the max of the maximizing criterion
      [tmp,ind] = max( abs(rhoTyVec).^2./rhoNormVec );

      T1Vec = nlsS.T1Vec; % Initialize the variable
      if nbrOfZoom > 1 % Do zoomed search
        try
          T1LenZ = nlsS.T1LenZ; % For the zoomed search
        catch
          T1LenZ = 21; % For the zoomed search
        end
        for k = 2:nbrOfZoom
          if( ind > 1 && ind < length(T1Vec) )
            T1Vec = linspace(T1Vec(ind-1),T1Vec(ind+1),T1LenZ)';
          elseif(ind == 1)
            T1Vec = linspace(T1Vec(ind),T1Vec(ind+2),T1LenZ)';
          else
            T1Vec = linspace(T1Vec(ind-2),T1Vec(ind),T1LenZ)';
          end
          % Update the variables
          alphaVec = 1./T1Vec;
          theExp = exp( -tVec*alphaVec' );
          yExpSum = (dataTmp.'*theExp).';
          rhoNormVec = ...
            sum( theExp.^2, 1)' - ...
            1/nlsS.N*(sum(theExp,1)').^2;
          rhoTyVec = yExpSum - ...
            1/nlsS.N*sum(theExp,1)'*ySum;
          
          %Find the max of the maximizing criterion
          [tmp,ind] = max( abs(rhoTyVec).^2./rhoNormVec );
        end
      end % of zoom

      % The estimated parameters
      T1EstTmp(ii) = T1Vec(ind);
      bEstTmp(ii) = rhoTyVec(ind)/ rhoNormVec(ind);
      aEstTmp(ii) = 1/nlsS.N*(ySum - bEstTmp(ii)*sum(theExp(:,ind)));
      
      % Compute the residual
      modelValue = aEstTmp(ii) + bEstTmp(ii)*exp(-tVec/T1EstTmp(ii));
      resTmp(ii) = 1/sqrt(nlsS.N) * norm(1 - modelValue./dataTmp);
    end % of for loop

  otherwise % Here you can add other search methods
  error('Unknown search method!')
end

% Finally, we choose the point of sign shift as the point giving
% the best fit to the data, i.e. the one with the smallest residual
[res,ind] = min(resTmp);
aEst = aEstTmp(ind);
bEst = bEstTmp(ind);
T1Est = T1EstTmp(ind);
if ind ==1
    idx = minInd; % best fit when inverting the signal at the minimum
else
    idx = minInd-1; % best fit when NOT inverting the signal at the minimum
end
