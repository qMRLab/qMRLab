%% Load numerical phantom data.
data = load('example.mat');
data.example = double(data.example);

%% Show data.
figure;
imagesc( abs(data.example) );
title('Magnitude Image of Numerical Phantom');
colormap gray;
h = colorbar;
set(get(h,'ylabel'),'String', 'Magnitude / a.u.');

figure;
imagesc( angle(data.example) );
title('Phase Image of Numerical Phantom');
colormap gray;
h = colorbar;
set(get(h,'ylabel'),'String', '\Phi / rad');

%% Unwrap phase.
tic;
unwrappedPhase = sunwrap(data.example);         % No threshold.
%unwrappedPhase = sunwrap(data.example, 0.25);  % Threshold: 25% of maximum value.
toc;

%% Show result.
figure;
imagesc( unwrappedPhase );
title('Unwrapped Phase Image of Numerical Phantom');
colormap gray;
h = colorbar;
set(get(h,'ylabel'),'String', '\Phi / rad');
