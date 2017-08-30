

function MTSATdata = MTSAT_exec(data, MTParams, PDParams, T1Params) % add 

if ~isfield(data,'Mask'), data.Mask=''; end

% Apply mask
if (~isempty(data.Mask))
    Res.Mask = single(data.Mask);    
    data.MT = data.MT.*data.Mask;
    data.PD = data.PD.*data.Mask;
    data.T1 = data.T1.*data.Mask;
end

S_T1 = data.T1w;
S_PD = data.PDw;
S_TM = double(data.MTw);

[r,c] = find(S_TM);

alpha = MTParams(1);
TR = MTParams(2);
alpha_T1 = T1Params(1);
TR_T1 = T1Params(2);
alpha_PD = PDParams(1);
TR_PD = PDParams(2);


% Equation - 1
a1 = (S_T1.*alpha_T1)./TR_T1; % max 15565
a2 = (S_PD.*alpha_PD)./TR_PD; % max 1534.2
b1 = (S_PD./alpha_PD); % max 6245.2
b2 = (S_T1./alpha_T1); % max 2498.1
BB = b1 - b2;
Index = find(~BB); % locate the 0s in the array
BB(Index) = 0.001;
R1 = (1/2).*((a1 - a2)./(BB)); 

% Equation - 2
a3 = (TR_PD*alpha_T1)/alpha_PD;
a4 = (TR_T1*alpha_PD)/alpha_T1;
b3 = S_T1.*TR_PD.*alpha_T1;
b4 = S_PD.*TR_T1.*alpha_PD;
Denom = b3-b4;  
Index = find(~Denom);
Denom(Index) = 0.001;
A = (S_PD.*S_T1.*(a3 - a4))./(Denom);

% Equation - 3
a5 = A.*alpha;
b5 = (alpha^2)/2;
Index = 0;
Index = find(~S_TM);
S_TM(Index) = 0.001; % keep this in case values cancel out
    % since we are introducing new values here by avoiding /0, make sure to
    % null positions where MT data was initially 0 (when mask applied to 
    % raw image). In case the mask file was provided, use it to null the 
    % background in the result image.
Rawdelta = (R1.*TR.*((a5./S_TM)-1))- b5;
MTSATdata = 100*Rawdelta;

% RMin = min(MTSATdata(MTSATdata > 0))
% 
%         % delimiting signal intensity range for display
%         Index=0;
%         Index = find(MTSATdata > 4); % was previously 7
%         MTSATdata(Index) = 4;
% 
%         Index=0;
%         Index = find(MTSATdata < -3.5);
%         MTSATdata(Index) = -3.5;

    % since we introduced new values to avoid /0, make sure to
    % null positions where MTdata was initially 0 (when mask applied to 
    % raw image). In case the mask file was provided, use it to null the 
    % background in the result image.
if (~isempty(data.Mask))
    MTSATdata = MTSATdata.*data.Mask;
else
    Index = find(~data.MTw);
    MTSATdata(Index) = 0;
end

% figure
% h_MT = histogram(NZ_Val_MT)
% title('MT non zero values')
% xlim([0,550])
% 
% figure
% h_PD = histogram(NZ_Val_PD)
% title('PD non zero values')
% xlim([0,550])
% 
% figure
% h_T1 = histogram(NZ_Val_T1)
% title('T1 non zero values')
% xlim([0,550])
% 
% figure
% H_RE = histogram(NZ_Val_Re)
% title('MT sat non zero values')
% 
% 
% [R,C] = find(MTSATdata < -5);
% t=10
% S_TM(R(t),C(t))
% S_PD(R(t),C(t))
% S_T1(R(t),C(t))
% MTSATdata(R(t),C(t))
% 
% 
% 
% 
% t = 'test'

end
