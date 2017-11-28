function [E tempprot] = RemoveNegMeas(Epn, protocol)
% Removes negative or zero measurements from a set and returns a protocol
% with the corresponding elements removed to exclude the negative
% measurements from the fitting.
%
% Epn is the full set of measurements; E is that with the negative ones
% removed.
%
% protocol is the full protocol; tempprot is that with the entries
% corresponding to negative measurements removed.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

tempprot = protocol;
E = Epn;
if(min(Epn)<=0)
    posonly = find(Epn>0);
    E = Epn(posonly);
    nonposonly = setdiff([1:size(Epn,1)], posonly);
    tempprot.totalmeas = length(posonly);
    % find the b0 indices for the new protocol without the non-positive
    % measurements
    tempprot.b0_Indices = [];
    for i=1:length(protocol.b0_Indices)
        currentB = protocol.b0_Indices(i);
        index = find(nonposonly<=currentB, 1, 'last');
        if isempty(index)
            tempprot.b0_Indices = [tempprot.b0_Indices currentB];
        elseif (nonposonly(index) ~= currentB)
            currentB = currentB - index;
            tempprot.b0_Indices = [tempprot.b0_Indices currentB];
        end
    end
    tempprot.numZeros = length(tempprot.b0_Indices);
    if(strcmp(tempprot.pulseseq, 'PGSE') || strcmp(tempprot.pulseseq, 'STEAM'))
        tempprot.G = tempprot.G(posonly);
        tempprot.delta = tempprot.delta(posonly);
        tempprot.smalldel = tempprot.smalldel(posonly);
        tempprot.grad_dirs = tempprot.grad_dirs(posonly, :);
    else
        error('Need to adapt for other pulse sequences.');
    end
end

if length(tempprot.b0_Indices) == 0
    error('All b=0 measurements are negative');
end
