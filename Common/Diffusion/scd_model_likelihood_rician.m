function logp = scd_model_likelihood_rician(Sdata,Smodel,sigma_noise,robust)
% logp = scd_model_likelihood(abs(Sdata),Smodel(:),sigma_noise)
% Probability (log) to have the signal abs(Sdata) given the Smodel(:) by assuming a rician noise
% Sdata and Smodel(:) are vectors of same length
% your objective function is -2*logp--> you want to minimize this
if ~exist('robust','var'), robust = 0; end
logp = inf;
SNR = 50;
while sum(isinf(logp)) % avoid infinite value by reducing the SNR
    logp = log(pdf('rician',Sdata,Smodel,sigma_noise));
    % robust fitting
    if robust
        disp( sum(-logp>median(-logp)+5*std(logp)))
        logp(-logp>median(-logp)+std(logp))=[];
    end
    sigma_noise = max(Sdata)/SNR;
    SNR = SNR-5;
end
