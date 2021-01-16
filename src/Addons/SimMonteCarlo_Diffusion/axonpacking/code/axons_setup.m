function  [D,x0, side] = axons_setup(axons, lawname, k, h)
% author : Tom Mingasson
% axonsSetup creates a randomly generated axon gamma or lognormal distribution and initilialize axons positions in a square area defined by its length 'side'.

% diameters distribution under a gamma or lognormal law
D = samplingHastingsMetropolis(axons, lawname, k, h);

% dimension of the square area
N = axons.N{k};
if  axons.d_var{k} == 0
    side = sqrt(N*(3*max(D(:))+axons.Delta{k}).^2);
else
    side = sqrt(N*(2*max(D(:))+axons.Delta{k}).^2);
end

% Random positions on a grid for the N axons
sqrt_N = round(sqrt(N))+1;

[Xgrid Ygrid] =  meshgrid(1:side/sqrt_N:side, 1:side/sqrt_N:side);
Xgrid =Xgrid(:);
Ygrid =Ygrid(:);
Permutations = randperm(sqrt_N^2);
x0 = zeros(N,2);
for i=1:N
    x0(i,:) = [Xgrid(Permutations(i)) Ygrid(Permutations(i))];
end

x0 = reshape(x0',1,2*N)';

end

function d = samplingHastingsMetropolis(axons,lawName,k, h)

sigma_instru = 1;

N = axons.N{k};
x = zeros(N,1);
x(1)=axons.d_mean{k};

xmin = axons.threshold_low{k};
xmax = axons.threshold_high{k};

axe_hist =linspace(xmin,xmax,100);

for n=1:N-1
    
    % drawing of x* from x(n) (= current point) under a gaussian intrumental law
    x_star = x(n) + sigma_instru*randn;
    
    % acceptation or reject
    proba_accept = (q_instru(x(n),x_star,sigma_instru)*pobj(x_star,axons,lawName,k))/(q_instru(x_star,x(n),sigma_instru)*pobj(x(n),axons,lawName,k));
    
    u=rand;
    if u<proba_accept
        x(n+1)=x_star;
    else
        x(n+1)=x(n);
    end
    
end

if ~exist('h','var')
    figure('Name','Disk diameter histogram')
else
    axes(h);
end
hold off
xth = linspace(0.01,xmax,1000);
yth = pobj(xth, axons,lawName, k);
[n_hist,bins]=hist(x(1:n),axe_hist);
h = bar(bins,n_hist);

set(h,'barwidth',0.5)
hold on
plot(xth,yth/max(yth(:))*max(n_hist),'r', 'LineWidth',1 )
drawnow

xlabel('diameters (um)')
ylabel('number of disks')

d = x;

end


function [ pobj ] = pobj(x, axons,lawName, k)
% Probability pobj(x) where pobj is the function we want to sample

meanAxons      = axons.d_mean{k};
varAxons       = axons.d_var{k};
threshold_high = axons.threshold_high{k};
threshold_low  = axons.threshold_low{k};

switch lawName
    case 'lognormal'
        mu = log(meanAxons) - 1/2*log(1 + varAxons/(meanAxons)^2);
        sigma = sqrt( log( 1 + varAxons/(meanAxons)^2) );
        if x>=threshold_high | x <= threshold_low
            pobj=0;
        else
            pobj = lognpdf(x,mu,sigma);
        end
        
    case 'gamma'
        a = meanAxons^2/varAxons;
        b = varAxons/meanAxons;
        if x>=threshold_high | x<=threshold_low
            pobj=0;
        else
            pobj = gampdf(x, a, b);
        end
end
end

function [q] = q_instru( x_star, x_courant, sigma_instru )
% Evaluation of the instrumental function q for (x, x_current)

q = 1/(sigma_instru*sqrt(2*pi))*exp(-(x_star-x_courant)^2/(2*sigma_instru^2));

end


