function S=scd_model_Cyl_GPD(R,G,Delta,delta,Dr,varargin)
% Signal=scd_model_GPD(R,G,Delta,delta,Dr (,Spheres?) )
% GDP for cylinders
gamma=42.57; %kHz/mT


% ===========================================
% Model for spheres
% ===========================================
alpham = besselequation_spheres(R);
if ~isempty(varargin);
    % Parts of the sum - Murday & Cotts (1968) SelfDiffusion Coefficient of Liquid Lithium
    for m=1:10
        factor1=1/(alpham(m)^2*(alpham(m)^2*R^2-2))./(alpham(m)^2*Dr);
        factor2=2*delta;
        factor3=2 + exp(-alpham(m)^2*Dr*(Delta-delta)) - 2*exp(-alpham(m)^2*Dr*Delta) - 2*exp(-alpham(m)^2*Dr*delta) + exp(-alpham(m)^2*Dr*(Delta+delta));
        factor4=(alpham(m)^2*Dr);
        
        Summ(:,m)=factor1 .* (factor2 - factor3./factor4);
    end
    S = exp(-2*(2*pi*gamma)^2*G.^2.*sum(Summ,2));
else
    
    
    % ===========================================
    % Model for cylinders (Neuman Equation)
    % ===========================================
    % L. Z. WANG 1995: The Narrow-Pulse Criterion for Pulsed-Gradient Spin-Echo Diffusion Measurements
    % Bessel roots:
    beta=[	 0              3.83170597020751	7.01558666981561	10.1734681350627	13.3236919363142;  % J0'
    1.84118378134065	5.33144277352503	8.53631636634628	11.7060049025920	14.8635886339090;  % J1'
    3.05423692822714	6.70613319415845	9.96946782308759	13.1703708560161	16.3475223183217;  % J2'
    4.20118894121052	8.01523659837595	11.3459243107430	14.5858482861670	17.7887478660664;  % J3'
    5.31755312608399	9.28239628524161	12.6819084426388	15.9641070377315	19.1960288000489;  % J4'
    6.41561637570024	10.5198608737723	13.9871886301403	17.3128424878846	20.5755145213868]; % J5'

    
    Summ=zeros(length(G),1);
    for m=2:6
        lb = beta(m,:)/R;
        for i=1:5
            factor1=1/((lb(i)*R)^6*(lb(i)^2*R^2-1));
            factor2=2*(lb(i)^2*Dr*delta+exp(-lb(i)^2*Dr*delta)-1);
            factor3=exp(-lb(i)^2*Dr*Delta);
            factor4=exp(-lb(i)^2*Dr*delta)-1;
            factor5=exp(lb(i)^2*Dr*delta)-1;
            
            Sumi(:,i)=factor1 .* (factor2 + factor3.*factor4.*factor5);
        end
        Sumi(isnan(Sumi))=0;
        Summ=Summ+sum(Sumi,2);
    end
    S = exp(-2*R^6*(2*pi*gamma)^2*G.^2/Dr^2.*Summ);
end




function eqroots = besselequation_spheres(R)
x=0:00.1/R:100/R;
J = 1/2*(besselj(3/2-1,x*R) - besselj(3/2+1,x*R));
besselequ=x*R.*J-1/2*besselj(3/2,x*R);
[~,eqroots]=crossing(besselequ,x);

function eqroots = besselequation_cyl(R,m)
x=0:00.1/R:100/R;
if m
    J = 1/2*(besselj(m-1,x*R) - besselj(m+1,x*R));
else
    J = -besselj(1,x*R);
end
[~,eqroots]=crossing(J,x);