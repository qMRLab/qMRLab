%% Lookup table approach to MTsat with arbitrary readouts. 
function MTsat = calcMTsatThruLookupTable(inputMTw_img, b1, T1, mask, M0, echoSpacing, numExcitation, TD, flip)
% Make sure the T1, echospacing and Time delay (TD) are all in the same
% units (seconds or milliseconds).
% Flip is in degrees

%% First divide by the MTw image by M0 to get relative signal 
MTw_sig = inputMTw_img ./ M0;


%% Generate a lookup table based on B1, T1 and MTsaturation

%setup vectors
B1_vector = 0.005:0.05:1.9;
T1_vector = (0.5:0.05:5) *1000; 
MT_vector = 0:0.005:0.50;
MTsig_vector = 0:0.0005:0.25;

SignalMatrix = zeros(length(MT_vector),1);
MTsatMatrix = zeros(length(B1_vector), length(T1_vector), length(MTsig_vector));


% calculate the lookup table
for i = 1:length(B1_vector)
    
    for j = 1:length(T1_vector)
        
        for k = 1:length(MT_vector)
            
            SignalMatrix(k) = MTrage_sig_eqn_v5(echoSpacing, flip, T1_vector(j), TD, numExcitation, 1, MT_vector(k), B1_vector(i), 1);  

        end
        
        % We have the signal values for the metrics. We need the total
        % matrix to have the z direction be signal with the matrix values
        % being the MTdrop value. 
        MTsatMatrix(i,j,:) = interp1(SignalMatrix , MT_vector, MTsig_vector, 'pchip',0);     
    end
end

%% Now fit the image using gridded interpolant
% matrix values (MTsat) are defined by vectors: B1, T1 and MTw signal
[b, t, m] = ndgrid(B1_vector, T1_vector, MTsig_vector);
F = griddedInterpolant(b ,t, m, MTsatMatrix);

%% Turn the images into vectors then fit
q = find( (mask(:)>0));
b1_v = b1(q);
t1_v = T1(q);
mt_v = MTw_sig(q);


mtsat = F(b1_v, t1_v, mt_v);

MTsat = zeros( size(T1));
MTsat(q) = mtsat;

% % OLD CODE -> WAY TOO SLOW
% MTsat = zeros(size(mask));
% MTdrop_table = 0:0.005:0.50;
% simSig = zeros(size(MTdrop_table));
% 
% tic
% for i = 1:size(mask,1)
%     for j = 1:size(mask,2)
%         for k = 1:size(mask,3)
%             if mask(i,j,k) > 0 && T1(i,j,k) > 500 && T1(i,j,k) < 5000 && b1(i,j,k) > 0.4 % use for masked data
%                 
%                 for z = 1:size(MTdrop_table,2)
%                     simSig(z) = MTrage_sig_eqn_v5(echoSpacing, flip, T1(i,j,k), TD, numExcitation, M0(i,j,k), MTdrop_table(z), b1(i,j,k), 1);  
%                                                 
%                 end
%                 
%                 MTsat(i,j,k) = interp1( simSig, MTdrop_table, inputMTw_img(i,j,k));
% 
%             end
%         end
%     end
% end
% 
% toc

