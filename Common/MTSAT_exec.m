

function Res = MTSAT_exec(data, MTParams, PDParams, T1Params)

S_T1 = data.T1data;
S_PD = data.PDdata;
S_TM = data.MTdata;

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
S_TM(Index) = 0.001;
Rawdelta = (R1.*TR.*((a5./S_TM)-1))- b5;
MTSATdata = 100*Rawdelta;

Res = MTSATdata;


end
