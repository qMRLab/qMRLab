function protocol = FSL2Protocol(bvalfile, bvecfile)
%
% function protocol = FSL2Protocol(bvalfile, bvecfile)
%
% Note: for NODDI, the exact sequence timing is not important.
%  this function reverse-engineerings one possible sequence timing
%  given the b-values.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

protocol.pulseseq = 'PGSE';
protocol.schemetype = 'multishellfixedG';
protocol.teststrategy = 'fixed';

% load bval
bval = load(bvalfile);
bval = bval';

% set total number of measurements
protocol.totalmeas = length(bval);

% set the b=0 indices
protocol.b0_Indices = find(bval==0);
protocol.numZeros = length(protocol.b0_Indices);

% find the unique non-zero b-values
B = unique(bval(bval>0));

% set the number of shells
protocol.M = length(B);
for i=1:length(B)
    protocol.N(i) = length(find(bval==B(i)));
end

% maximum b-value in the s/mm^2 unit
maxB = max(B);

% set maximum G = 40 mT/m
Gmax = 0.04;

% set smalldel and delta and G
GAMMA = 2.675987E8;
tmp = nthroot(3*maxB*10^6/(2*GAMMA^2*Gmax^2),3);
for i=1:length(B)
    protocol.udelta(i) = tmp;
    protocol.usmalldel(i) = tmp;
    protocol.uG(i) = sqrt(B(i)/maxB)*Gmax;        
end

protocol.delta = zeros(size(bval))';
protocol.smalldel = zeros(size(bval))';
protocol.G = zeros(size(bval))';

for i=1:length(B)
    tmp = find(bval==B(i));
    for j=1:length(tmp)
        protocol.delta(tmp(j)) = protocol.udelta(i);
        protocol.smalldel(tmp(j)) = protocol.usmalldel(i);
        protocol.G(tmp(j)) = protocol.uG(i);
    end
end

% load bvec
bvec = load(bvecfile);
protocol.grad_dirs = bvec';

% make the gradient directions for b=0's [1 0 0]
for i=1:length(protocol.b0_Indices)
    protocol.grad_dirs(protocol.b0_Indices(i),:) = [1 0 0];
end

% make sure the gradient directions are unit vectors
for i=1:protocol.totalmeas
    protocol.grad_dirs(i,:) = protocol.grad_dirs(i,:)/norm(protocol.grad_dirs(i,:));
end

