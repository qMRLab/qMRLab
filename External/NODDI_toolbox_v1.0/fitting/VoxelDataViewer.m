function VoxelDataViewer(protocol, data, fibredir, b0, h, style)
% Plots the normalized measurements in one image voxel against the
% absolute dot product of the gradient and fibre directions.
%
% VoxelDataViewer(protocol, data, fibredir, b0, h)
% brings up a window containing the plot.
%
% protocol is the imaging protocol.
%
% data is the set of measurements in the voxel.
%
% fibredir is an estimate of the fibre direction in that voxel. By default
% this is set to the z-axis
%
% b0 is an estimate of the b=0 signal.  By default, this is set to one.
%
% h is a figure handle to add the plot to.  If not specified, a new figure
% appears.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang     (gary.zhang@ucl.ac.uk)
%

if(nargin<3)
    fibredir = [0 0 1]';
end
if(nargin<4)
    b0=1;
end
if(nargin<5)
    h = figure;
end

% Compute b-values
GAMMA = 2.675987E8;
modQ = GAMMA*protocol.usmalldel.*protocol.uG;
diffTime = (protocol.udelta - protocol.usmalldel/3);
bvals = diffTime.*modQ.^2;

% Create normalized data set.
normdw = data/b0;

if(nargin<6)
    style = 'x';
end

linedef{1} = ['r', style];
linedef{2} = ['b', style];
linedef{3} = ['g', style];
linedef{4} = ['m', style];
linedef{5} = ['c', style];
linedef{6} = ['k', style];
linedef{7} = ['y', style];

hold on;
set(gca, 'FontName', 'Times');
set(gca, 'FontSize', 17);
for j=1:length(protocol.uG)
    inds = find(protocol.G == protocol.uG(j) & protocol.delta == protocol.udelta(j) & protocol.smalldel == protocol.usmalldel(j));
    scatter(abs(protocol.grad_dirs(inds,:)*fibredir), normdw(inds), linedef{j});
end
xlabel('|n.G|/|G|_{max}');
ylabel('S/S_0');
%ylim([0,b0*1.1]);

% Add b=0 measurements
b0_meas = data(protocol.b0_Indices);
for b=1:length(b0_meas)
    h(1) = plot([0 1], [b0_meas(b)/b0 b0_meas(b)/b0], ':k');
end
