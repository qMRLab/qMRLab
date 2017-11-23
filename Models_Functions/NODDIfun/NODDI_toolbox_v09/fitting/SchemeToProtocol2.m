function protocol = SchemeToProtocol2(schemefile)
%
% Reads a Camino Version 1 schemefile into a protocol object
%
% function protocol = SchemeToProtocol(schemefile)
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang     (gary.zhang@ucl.ac.uk)
%

% Read in the header (assumes one line)

% Read in the data
A = txt2mat(schemefile)'; 

% Create the protocol
protocol.pulseseq = 'PGSE';
protocol.grad_dirs = A(1:3,:)';
protocol.G = A(4,:);
protocol.delta = A(5,:);
protocol.smalldel = A(6,:);
protocol.TE = A(7,:);
protocol.totalmeas = length(A);

% Find the B0's
bVals = GetB_Values(protocol);
protocol.b0_Indices = find(bVals==0);

