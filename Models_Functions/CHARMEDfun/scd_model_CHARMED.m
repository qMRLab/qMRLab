
function output=scd_model_CHARMED(x,Ax)

% INPUT
%==========================================================================
%   x           vector(>7)          fitted params includes: [fh    Dh   mean    std    fcsf  useless(test)   scale1  scale2  scale3  scale4  sca...]
%                                       fh: hindered diffusion fraction
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
fh = x(1); Dh = x(2); mean_d = x(3); std_d = x(4); fcsf = x(5); A = x(6)^2*0.2; % lc = sqrt(A)/0.2 : length of coherence for time dependence (experimental)
x=[x(:)' ones(1,10)];


if isfield(Ax,'Dr'), Dr = Ax.Dr; else Dr = 1.4; end % tortuosity model, D. Alexander 2008
if isfield(Ax,'plotfit'), plotfit = Ax.plotfit; else plotfit = 0; end
if isfield(Ax,'figures'), figures = Ax.figures; else figures = 0; end
if isfield(Ax,'onediam'), onediam = Ax.onediam; else onediam = 1; end
if isfield(Ax,'fitname'), fitname = Ax.fitname; else fitname = 'fitplot'; end
if isfield(Ax,'norm'), norm = Ax.norm; else norm.method = 'fit'; end
if isfield(Ax,'output_signal'), output_signal = Ax.output_signal; else output_signal = 1; end
if ~isfield(Ax,'save_plot'), Ax.save_plot=0; end
if ~isfield(Ax,'Dcsf'), Ax.Dcsf=3; end
if ~isfield(Ax,'fixDh'), Dh=x(2); else if Ax.fixDh, Dh=Dr*fh/(1-fcsf); end; end




gyro=42.58; %rad.KHz/mT
q=gyro.*Ax.scheme(:,6).*Ax.scheme(:,4); %um-1


%==========================================================================
%Signal model for the hindered (extra-axonal) compartment
%==========================================================================
Dh = scd_model_timedependence(Dh,A,bigdelta,littledelta);
Eh=exp(-(2*pi*q).^2.*Dh.*(bigdelta-littledelta/3));


%==========================================================================
%Signal model for CSF;
%==========================================================================

Ecsf=exp(-(2*pi*q).^2*Ax.Dcsf.*(bigdelta-littledelta/3));


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
            % b=(2*pi*q).^2.*(bigdelta-littledelta/3);
            % Er_sum= Er_sum + resol*Er_coeff(i_diam).*exp(-b.*scd_model_GPD_RDr(R*2,bigdelta,littledelta,Dr));
            %
            % Model #2 Gaussian Phase Distribution in cylinder
            Er_sum= Er_sum + resol*Er_coeff(i_diam).*scd_model_Cyl_GPD(R,G,bigdelta,littledelta,Dr);
            %
            % Model #3 Small Pulse Approx
            % Er_sum= Er_sum + resol*Er_coeff(i_diam).*scd_model_smallpulse(R,q,bigdelta,Dr);
        end
    end %axon diameter loop
    Er_sum = Er_sum./sum(resol*Er_coeff(Er_coeff>0.01));
end

% Calculating total response :
CHARMED = fh.*Eh + (1-fh-fcsf).*Er_sum + fcsf.*Ecsf;
CHARMED(isnan(CHARMED))=1;


% S0 : signal without diffusion encoding
Nb_seq = length(unique(Ax.scheme(:,7)));
seqnumbering = unique(Ax.scheme(:,7));
for iseq = 1:Nb_seq
    seq_ind = Ax.scheme(:,7) == seqnumbering(iseq);
    if strcmp(norm,'fit')
        CHARMED(seq_ind)=abs(CHARMED(seq_ind))*x(iseq+7); %OR max(abs(Sdata(TM{i_Delta})))*0.85;
    elseif strcmp(norm,'max')
        Sdata(seq_ind)=abs(Sdata(seq_ind))/max(abs(Sdata))*norm.maxvalue;
        CHARMED(seq_ind)=abs(CHARMED(seq_ind))/max(abs(CHARMED(seq_ind)))*norm.maxvalue;
    elseif strcmp(norm,'onefit')
         Sdata(seq_ind)=abs(Sdata(seq_ind))/x(8);
         x(iseq+8)=x(7);
    end
end



% Output
if output_signal, output = CHARMED; 
elseif sum(w)*resol < 0.8 && ~onediam, output = 100*ones(1,length(CHARMED));
else
    output=(CHARMED-Sdata); %./((q+0.01)/max(q));
end
end


