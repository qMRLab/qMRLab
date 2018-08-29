function [N, eta, sigma_g] = scd_noise_fit_histo(data,varargin)
% [N, eta, sigma_g] = scd_noise_fit_histo(data)
% [N, eta, sigma_g] = scd_noise_fit_histo(__,Name,Value)

data=data(:);
p=inputParser;
addRequired(p,'data',@isnumeric)
addOptional(p,'nbins',max(15,sqrt(length(data))));
[~, xmax] = range_outlier(data);
addOptional(p,'maxval',xmax);
addOptional(p,'maxy',0);
addOptional(p,'color',[0 0 1],@isnumeric);
addOptional(p,'fig',1,@isnumeric);
addOptional(p,'plotfit',0,@isnumeric);
addOptional(p,'distrib','Non-central Chi',@(x) any(validatestring(x,{'Non-central Chi','Rician'})));

if logical(exist('OCTAVE_VERSION', 'builtin'))
    in.fig = varargin{2};
    in.distrib = varargin{4};
    in.nbins = max(15,sqrt(length(data)));
    [~, in.maxval] = range_outlier(data);
    in.maxy = 0;
    in.color = [0 0 1];
    in.plotfit = 0;
else
    parse(p,data,varargin{:});
    in=p.Results;
end

%% PREPARE DATA
data(data==0)=[];
data(data>in.maxval)=[];

if isinteger(data)
    xout=double(unique(data(:)));
    n=double(histc(data(:),xout));
else
    [n,xout]=hist(data,in.nbins);
end
xout(n==0)=[]; n(n==0)=[];  n(xout==0)=0;
n=n/trapz(xout,n);

xout = xout(:); n = n(:);
maxnoise=cumtrapz(xout,n);
maxnoise=xout(find(maxnoise>0.999,1,'first'));
data(data>maxnoise)=[];

if isinteger(data)
    xout=double(unique(data(:)));
    n=double(histc(data(:),xout));
else
    [n,xout]=hist(data,in.nbins);
end

xout(n==0)=[]; n(n==0)=[];  n(xout==0)=0;
n=n/trapz(xout,n);
n(xout<0)=[];
xout(xout<0)=[];

xout = xout(:); n = n(:);
xi=0:max(xout)/in.nbins:max(xout);
yi = interp1(xout,n,xi);
yi(isnan(yi))=0;
yi=yi/trapz(xi,yi);
xi=xout; yi=n;


%% Fit: 'non-central chi'.
%eta = sum(xi.*yi.*mean(diff(xi)));
%    [N      eta     sigma]
var0=[1           eps            std(double(data))];
lb = [1           0                  0.1        ]; 
ub= [10    double(max(data)) std(double(data)*2)];
switch in.distrib
    case 'Non-central Chi'
        fx = [0 0 0];
    case 'Rician'
        fx = [1 1 0];
end

options = optimset('Algorithm','trust-region-reflective','TolFun',1e-8,'Display','final','MaxIter',10,'Display','off');
disp('     N        eta      sigma_g')
[varfit] = lsqnonlin(@(x1) noncentralchi_error(addfixparameters(var0,x1,fx),xi,yi,in.plotfit), var0(~fx), lb(~fx), ub(~fx),options);
varfit = addfixparameters(var0,varfit,fx);
disp(varfit)
N=varfit(1); eta=varfit(2); sigma_g=varfit(3);
fval = noncentralchi(xi, N,sigma_g,eta);

if in.fig
    figure(73)
    set(73,'Name','Noise histogram','NumberTitle','off')
    plot(xi,yi,'+','Color',in.color,'MarkerSize',10); hold on, plot(xi,fval,'Color',[1 0 0],'Linewidth',2);
    xlim([0 in.maxval]);
    if ~in.maxy, maxy=2*max(yi); else maxy=in.maxy; end
    ylim([0 maxy])
    title(['N = ' num2str(N) ', eta = ' num2str(eta) ', sigma = ' num2str(sigma_g)])
end

end

function Error = noncentralchi_error(var,x,y,plotfit)
N=var(1); eta=var(2); sigma_g=var(3);
f= noncentralchi(x, N,sigma_g,eta);
f(isnan(f))=0;
f=f/trapz(x,f);
if rand<plotfit
    disp(num2str(var))
    figure(4)
    hold off, plot(x,y); hold on, plot(x,f,'r');
    xlim([0 max(x)]);
    ylim([0 2*max(y)])
    pause(0.1)
end
Error = abs(f-y);
end

function p= noncentralchi(x, N,sigma_g,eta)
p = abs(x).^N./(sigma_g^2*eta^(N-1)).*exp(-(x.^2+eta^2)/(2*sigma_g^2)).*besseli(N-1,x*eta/sigma_g^2);
end
