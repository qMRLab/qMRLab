function parInfo = sweepExample()
% Copyright 2010 The MathWorks, Inc.

%% Initialize Problem
m     =         5;  % mass
bVals =  .1:.1 :5;  % damping values
kVals = 1.5:.05:5;  % stiffness values
[kGrid, bGrid] = meshgrid(bVals, kVals);
peakVals = nan(size(kGrid));

%% Parameter Sweep
% disp('Computing ...');drawnow;

parInfo = Par(numel(kGrid));

parfor idx = 1:numel(kGrid)
   Par.tic;
  % Solve ODE
  [T,Y] = ode45(@(t,y) odesystem(t, y, m, bGrid(idx), kGrid(idx)), ...
    [0, 25], ...  % simulate for 25 seconds
    [0, 1]);      % initial conditions
 
  % Determine peak value
  peakVals(idx) = max(Y(:,1));
  parInfo(idx) = Par.toc;
end

stop(parInfo);


function dy = odesystem(t, y, m, b, k)
% 2nd-order ODE
%
%   m*X'' + b*X' + k*X = 0
%
% --> system of 1st-order ODEs
%
%   y  = X'
%   y' = -1/m * (k*y + b*y')

dy(1) = y(2);
dy(2) = -1/m * (k * y(1) + b * y(2));

dy = dy(:); % convert to column vector