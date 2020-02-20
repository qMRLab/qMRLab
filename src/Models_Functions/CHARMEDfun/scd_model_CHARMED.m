
function output=scd_model_CHARMED(x,Ax)

% INPUT
%==========================================================================
%   x           vector(>7)          fitted params includes: [fr    Dh   mean    std    fcsf  useless(test)   scale1  scale2  scale3  scale4  sca...]
%                                       fr: restricted water fraction
%                                       Dh: diffusion coefficient for the hindered (extra-axonal) compartment
%                                       alpha and b define the gamma distribution of weights for different axon diameters (a)
%--------------------------------------------------------------------------
%   Ax			structure
%
%         MANDATORY
%
%
%           scheme        matrix(nb_dwi,9)      schemefile
%
%         OPTIONAL
%           data          vector(nb_dwi)      MRI Signal in one voxel
%           Dr            float               Diffusion restricted in um^2/ms;
%           plotfit       logical             plot and save fit
%           save_plot     logical             save final plot in .png
%           HinderedOnly  logical             Hindered Compartment only
%           onediam       logical             alpha (fitting param) = diameter
%           fitname       string              name of the save plot
%           norm.method   string              'fit' OR 'max' OR 'onefit' OR 'none'
%           norm.maxvalue float [0 1]         used with 'max' method
%           output_signal logical             output signal or diff? default = 1;

%==========================================================================
%KEEP ALL UNITS in um/mT/ms
if ~isfield(Ax,'data'), Ax.data=zeros(size(Ax.scheme,1),1); end
if isfield(Ax,'index'), index = Ax.index; else index=1:size(Ax.scheme,1); end
if isstr(Ax.scheme), Ax.scheme=scd_schemefile_read(Ax.scheme); end
bigdelta = Ax.scheme(index,5); bigdelta=bigdelta(:);
littledelta = Ax.scheme(index,6); littledelta=littledelta(:);
G = Ax.scheme(index,4); G=G(:);
Sdata=Ax.data(index); 
Sdata=Sdata(:);
x = real(x);
fr = x(1); Dh = x(2); mean_d = x(3); std_d = x(4); fcsf = x(5); A = x(6)^2*0.2; Dcsf = x(7); Dr = x(8);% lc = sqrt(A)/0.2 : length of coherence for time dependence (experimental)


if isfield(Ax,'plotfit'), plotfit = Ax.plotfit; else plotfit = 0; end
if isfield(Ax,'figures'), figures = Ax.figures; else figures = 0; end
if isfield(Ax,'onediam'), onediam = Ax.onediam; else onediam = 1; end
if isfield(Ax,'fitname'), fitname = Ax.fitname; else fitname = 'fitplot'; end
if isfield(Ax,'output_signal'), output_signal = Ax.output_signal; else output_signal = 1; end
if ~isfield(Ax,'save_plot'), Ax.save_plot=0; end
if ~isfield(Ax,'Dcsf'), Dcsf=3; end
if ~isfield(Ax,'fixDh'), Dh=x(2); else if Ax.fixDh, Dh=Dr*(1-fr-fcsf)/(1-fcsf); end; end  % tortuosity model, D. Alexander 2008




gyro=42.58; %rad.KHz/mT
q=gyro.*Ax.scheme(:,6).*Ax.scheme(:,4); %um-1


%==========================================================================
%Signal model for the hindered (extra-axonal) compartment
%==========================================================================
if ~isfield(Ax,'Time_dependent_models'), Ax.Time_dependent_models='Burcaw 2015'; end
switch Ax.Time_dependent_models
    case 'Burcaw 2015'
        Dh = scd_model_timedependence(Dh,A,bigdelta,littledelta);
    case 'Ning MRM 2016'
        Dh = scd_model_timedependence_Ning(Dh,A,bigdelta,littledelta);
end
Eh=exp(-(2*pi*q).^2.*Dh.*(bigdelta-littledelta/3));


%==========================================================================
%Signal model for CSF;
%==========================================================================

Ecsf=exp(-(2*pi*q).^2*Dcsf.*(bigdelta-littledelta/3));


%==========================================================================
% SIGNAL MODEL FOR INTRA-AXONAL
%==========================================================================
Er_sum=zeros(length(q),1);

% weights for axon diameter distribution (gamma distribution)
resol = 0.2;
if std_d
    diam=0.1:resol:10;  % um : axonal diameter range
    var = std_d^2; beta=var/mean_d; alpha = mean_d/beta;
    w=pdf('Gamma',diam,alpha,beta);
    Er_coeff = w.*(pi*diam.^2)./(pi*sum(diam.^2.*w*resol));
else
    Er_coeff = 1/resol;
    diam = mean_d;
end

% Call analytical equations
if onediam<0 % totally restricted (sticks)
    Er_sum =ones(size(Eh));
else % cylinders
    for i_diam=1:length(diam)
        if (~onediam && Er_coeff(i_diam)>0.01) || i_diam==1
            R=diam(i_diam)/2;
            % Model #1 Gaussian Phase Distribution in cylinder
             b=(2*pi*q).^2.*(bigdelta-littledelta/3);
             Er_sum= Er_sum + resol*Er_coeff(i_diam).*exp(-b.*scd_model_GPD_RDr(R*2,bigdelta,littledelta,Dr));
            %
            % Model #2 Gaussian Phase Distribution in cylinder from NODDI
            % TOOLBOX (FOR SANITY CHECK.. EXACTLY THE SAME)
            % Er_sum= Er_sum + resol*Er_coeff(i_diam).*exp(CylNeumanLePerp_PGSE(Dr*1e-9, R*1e-6, G*1e3, bigdelta*1e-3, littledelta*1e-3, BesselJ_RootsCyl));
            %
            % Model #2 Gaussian Phase Distribution in cylinder (same..)
            %Er_sum= Er_sum + resol*Er_coeff(i_diam).*scd_model_Cyl_GPD(R,G,bigdelta,littledelta,Dr);
            % 
            % Model #3 Small Pulse Approx
            % Er_sum= Er_sum + resol*Er_coeff(i_diam).*scd_model_smallpulse(R,q,bigdelta,Dr);
        end
    end %axon diameter loop
    Er_sum = Er_sum./sum(resol*Er_coeff(Er_coeff>0.01));
end

% Calculating total response :
CHARMED = (1-fr-fcsf).*Eh + fr.*Er_sum + fcsf.*Ecsf;
CHARMED(isnan(CHARMED))=1;



% Output
if output_signal, output = CHARMED; 
elseif sum(w)*resol < 0.8 && ~onediam, output = 100*ones(1,length(CHARMED));
else
    output=(CHARMED-Sdata); %./((q+0.01)/max(q));
end
end


function Er = scd_model_smallpulse(R,q,bigdelta,Dr)
% AxCaliber paper (erratum in the paper --> bessel function are squared...)

          %J0'     J1'    J2'    J3'    ...
beta = [3.8317	1.8412	3.0542	4.2012	5.3175	6.4156; % k=1
        7.0156	5.3314	6.7061	8.0152	9.2824	10.5199; % k=2
        10.1735	8.5363	9.9695	11.3459	12.6819	13.9872; % k=3
        13.3237	11.7060	13.1704	14.5858	15.9641	17.3128; % k=4
        16.4706	14.8636	16.3475	17.7887	19.1960	20.5755]; % k=5

Z = 2*pi*q*R;

Sum1 = 0;
beta0 = [0; beta(:,1)];
for k=1:5
    Sum1 = Sum1+4*exp(-beta0(k).^2*Dr*bigdelta/R^2).*...
                  ((Z.*(-besselj(1, Z)))./((Z).^2-beta0(k).^2)).^2;
end

Sum2 = 0;
for n=1:5
    for k=1:5
        Jnprime = 0.5*(besselj(n-1,Z)-besselj(n+1,Z));
        Sum2 = Sum2+8*exp(-beta(k,n+1).^2*Dr*bigdelta/R^2)*...
                      beta(k,n+1).^2/(beta(k,n+1).^2-n^2).*...
                     ((Z.*Jnprime)./((Z).^2-beta(k,n+1).^2)).^2;
    end
end

Er = Sum1 + Sum2;
end

