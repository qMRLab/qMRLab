%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       AxonPackin : Simulate arrangement of white matter axons 
%                     author : Tom Mingasson
%             https://github.com/neuropoly/axonpacking 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% close all
% clear variables
% clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       CHANGE INPUTS BELOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MAIN INPUTS
N = 100;            % number of axons i.e disks to pack  
d_mean = 3;         % theoretical mean of axon diameters in um
d_var  = 1;         % theoretical variance of axon diameters in um
Delta  = 1;         % gap between the edge of axons in um 
iter_max = 30000;    % number of iteration i.e migrations to perform. Example: iter_max = 30000 ok if N = 1000

% SECONDARY INPUTS
threshold_high = 20;     % no diameter above 'threshold_high'
threshold_low = 0.2;     % no diameter under 'threshold_low'
iter_fvf = iter_max/10;  % to study the packing convergence the disk density i.e Fiber Volume Fraction (FVF) can be computed and displayed every 'iter_fvf' iterations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     AxonPacking Process  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k=1:length(d_mean)

    % axons features
    axons.N{k}      = N;
    axons.d_mean{k} = d_mean(k);
    axons.d_var{k}  = d_var(k);
    axons.Delta{k}           = Delta(k);
    axons.threshold_high{k} = threshold_high;
    axons.threshold_low{k}  = threshold_low;
    
    % axon diameters sampling (under a gamma law or lognormal and initialization of positions 'x0' in a square area of length 'side')
    [d, x0, side] = axons_setup(axons,'gamma', k);
    axons.d{k} = d;
    axons.g_ratio{k} = compute_gratio(d);
    
    % packing process of the axons
    [final_positions, final_overlap, fvf_historic] = process_packing(x0, d, Delta(k), side, iter_max, iter_fvf);
    
    % store packing results
    % main results
    packing.initial_positions{k}    = reshape(x0,2,length(x0)/2);
    packing.final_positions{k}      = final_positions;
    % secondary results
    packing.final_overlap{k}        = final_overlap;
    packing.FVF_historic{k}         = fvf_historic;
    packing.iter_max{k}             = iter_max;
    
    % Statistics from the packing
    [FVF, FR, MVF, AVF] = compute_statistics(axons.d{k}, axons.Delta{k}, packing.final_positions{k}, side, axons.g_ratio{k});
    
    % store stats results
    stats.FVF{k}        = FVF;
    stats.FR{k}         = FR;
    stats.MVF{k}        = MVF;
    stats.AVF{k}        = AVF;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 Save results in a folder named 'results'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save_var = num2str(d_var);  save_var(save_var == ' ') = '';
% save_mean = num2str(d_mean); save_mean(save_mean == ' ') = '';
% save_Delta  = num2str(Delta);  save_Delta(save_Delta == ' ') = '';
% save_iter  = num2str(iter_max);
% saveName  = ['Axons', num2str(N), '_Mean', save_mean, '_Var', save_var, '_Delta', save_Delta, '_Iter',save_iter];
% 
% mkdir('results')
% cd([pwd,filesep, 'results'])
% 
% % save outputs
% save('axons.mat', '-struct', 'axons');
% save('packing.mat', '-struct', 'packing');
% save('stats.mat', '-struct', 'stats');
% 
% % save final substrate
% saveas(figure(1000),[saveName,'.png']);
% 




