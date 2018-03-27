function protocol = SchemeToProtocolmat(Prot)
%
% Reads a Camino Version 1 schemefile into a protocol object
%
% function protocol = SchemeToProtocol(schemefile)
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang     (gary.zhang@ucl.ac.uk)
%

Prot = Prot';

% Create the protocol
protocol.pulseseq  = 'PGSE';
protocol.grad_dirs = Prot(1:3,:)';
protocol.G         = Prot(4,:).*sqrt(sum(Prot(1:3,:).^2,1));
protocol.delta     = Prot(5,:);
protocol.smalldel  = Prot(6,:);
protocol.TE        = Prot(7,:);
protocol.totalmeas = length(Prot);

% Find the B0's
bVals = GetB_Values(protocol);
protocol.b0_Indices = find(bVals==0);

end
