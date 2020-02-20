function g = compute_gratio(D)

% Ikeda M, Oka Y. Brain Behav, 2012. "The relationship between nerve conduction velocity and fiber morphology during peripheral nerve regeneration."
g = 0.220 .* log10(2*D) + 0.508;
% g = 0.76; % if you want a constant g-ratio

% figure
% plot(2.*R, g)

end
