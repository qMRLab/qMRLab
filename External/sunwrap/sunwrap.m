function unwrappedPhaseImage = sunwrap( complexImage, relativeMagnitudeThreshold )
% SUNWRAP Magnitude-sorted List, Multi-clustering Phase Unwrapping Algorithm
%
%   sunwrap(complexImage, relativeMagnitudeThreshold)
%
%   This file contains the reference implementation of the magnitude-sorted
%   list, multi-clustering phase unwrapping algorithm published in the
%   journal 'Magnetic Resonance in Medicine' by Florian Maier et al. in
%   2014.
% 
%   The algorithm was implemented to unwrap the phase of magnetic resonance
%   images used for temperature imaging. The input 'complexImage' needs to
%   be an 1D, 2D, or 3D complex matrix. Additionally, the variable
%   'relativeMagnitudeThreshold' can be defined in the interval [0,1]. The
%   algorithm calculcates the actual threshold based on the maximum
%   magnitude value in the image and this ratio. The algorithm returns a
%   double matrix containing the unwrapped phase values in rad.
%
%   This algorithm was designed and implemented by Florian Maier.
%   Copyright (c) 2014 The University of Texas M. D. Anderson Cancer Center

    
    %% Check input arguments.
    % This implementation works for 1D, 2D, or 3D images only.
    if (ndims(complexImage) > 3)
        error('Maximum of image dimensions of 3 is exceeded. Number of dimensions = %d', ndims(complexImage));
    end
        
    % Complex image data is required.
    if (isreal(complexImage ))
        error('This phase unwrapping algorithm requires complex input data.');
    end

    % Set default value of relative magnitude threshold if it's not defined.
    if (nargin == 1)
        relativeMagnitudeThreshold = 0;
    end
    
    % Check relative magnitude variable.
    if (~isreal(relativeMagnitudeThreshold))
        error('Relative magnitude threshold is not a real number.');
    end
    
    % Check if relative threshold is in interval [0, 1].
    if ((relativeMagnitudeThreshold < 0) || (relativeMagnitudeThreshold > 1))
        error('Relative magnitude threshold is %f. It must be in the interval [0, 1].', relativeMagnitudeThreshold);
    end

    %% Initialization.
    % Get magnitude and phase data.
    magnitudeImage = abs(complexImage);
    phaseImage = angle(complexImage);

    % Create sorted list of all pixels.
    pixelList = createSortedListOfPixels( magnitudeImage, phaseImage );

    % Get image dimensions.
    [x_max, y_max, z_max] = size(magnitudeImage);
    numberOfPixels = x_max*y_max*z_max;

    % Initialize array for labels.
    labels = zeros(x_max, y_max, z_max);
    currentMaxLabelId = 0;

    % Initialize label list data structures for faster access. Maximum
    % number of lists equals number of pixels. Total number of nodes equals
    % the number of pixels. 
    % Lists head nodes: The value of each entry points to the head node of
    % the corresponding list.
    labelListsHeadNodes = zeros(1, numberOfPixels);
    % List tail nodes: The value of each entry points to the tail node of
    % the corresponding list.
    labelListsTailNodes = zeros(1, numberOfPixels);
    % Label list nodes: The array entry points to the successor. The last
    % node of a list points to 0.
    labelListsNodes = zeros(1, numberOfPixels);
    % Label list weights: Total weight used for merging for each list.
    labelListsWeights = zeros(1, numberOfPixels);

    % Initialize array for unwrapped phase data.
    unwrappedPhaseImage = zeros(x_max, y_max, z_max);

    % Calculate number of image dimensions.
    dimensions = 0;
    if (x_max > 1)
        dimensions = dimensions + 1;
    end
    if (y_max > 1)
        dimensions = dimensions + 1;
    end
    if (z_max > 1)
        dimensions = dimensions + 1;
    end

    %% Traverse pixels and unwrap phase.
    % The pixels will be traversed from high magnitude to low magnitude.
    for i = 1:numberOfPixels

        % Get next pixel from list. 
        magnitude = pixelList(i,1);
        phase     = pixelList(i,2);
        x         = pixelList(i,3);
        y         = pixelList(i,4);
        z         = pixelList(i,5);

        % Stop algorithm if magnitude is smaller than threshold. Phase
        % unwrapping in noisy air pixels takes a lot of time and doesn't
        % improve the result inside the object.
        if (magnitude < relativeMagnitudeThreshold * pixelList(1,1));
            break;
        end

        % Reset array of labels of other neigboring pixel clusters.
        % No reset of the actual array needed.
        pendingMergeLabelsMaximumIndex = 0;

        % Array of labels of other neigboring pixel clusters.
        % Label id, cluster weight, phase (sum), number of merged pixels with same magnitude.
        pendingMergeLabels = zeros(3^dimensions-1,4);

        % Variables to store maximum intensity neighbor that is already part of a cluster.
        maxMagnitudeLabel = 0;
        maxMagnitude = 0;

        % Traverse all neighbors of current pixel.
        % 1D data: 2 neighbors
        % 2D data: 8 neighbors
        % 3D data: 26 neighbors
        for dz = -1:1
            for dy = -1:1
                for dx = -1:1

                    % Check if pixel [ x+dx y+dy z+dz ] is a neighbor and not the actual pixel itself.
                    if ~((dx == 0) && (dy == 0) && (dz == 0))

                        % Check if neighbor is inside image matrix.
                        if ((1 <= x+dx) && (x+dx <= x_max) && (1 <= y+dy) && (y+dy <= y_max) && (1 <= z+dz) && (z+dz <= z_max))

                            % Check if neighbor was already unwrapped.
                            if (labels(x+dx, y+dy, z+dz) > 0)

                                % Check magnitude.
                                if (magnitudeImage(x+dx, y+dy, z+dz) > maxMagnitude)

                                    % Update maximum magnitude.
                                    maxMagnitude = magnitudeImage(x+dx, y+dy, z+dz);

                                    % Update maximum label.
                                    maxMagnitudeLabel = labels(x+dx, y+dy, z+dz);

                                end

                                % Check if the last label is already scheduled for merge.
                                labelIsAlreadyMergeLabel = 0;
                                for j = 1:pendingMergeLabelsMaximumIndex
                                    if (pendingMergeLabels(j,1) == labels(x+dx, y+dy, z+dz))
                                        labelIsAlreadyMergeLabel = 1;
                                        % Compare magnitude values.
                                        if (pendingMergeLabels(j,2) < magnitudeImage(x+dx, y+dy, z+dz))
                                            % Update phase value if magnitude is bigger than last pixel with same label.
                                            pendingMergeLabels(j,2) = magnitudeImage(x+dx, y+dy, z+dz);
                                            pendingMergeLabels(j,3) = unwrappedPhaseImage(x+dx, y+dy, z+dz);
                                            pendingMergeLabels(j,4) = 1;
                                        elseif (pendingMergeLabels(j,2) == magnitudeImage(x+dx, y+dy, z+dz))
                                            % Use sum of phase values to calculate mean later if magnitude is equal.
                                            pendingMergeLabels(j,3) = pendingMergeLabels(j,3) + unwrappedPhaseImage(x+dx, y+dy, z+dz);
                                            pendingMergeLabels(j,4) = pendingMergeLabels(j,4) + 1;
                                        end
                                        break;
                                    end
                                end

                                % Add label if it's a new one.
                                if (labelIsAlreadyMergeLabel == 0)
                                    pendingMergeLabelsMaximumIndex = pendingMergeLabelsMaximumIndex + 1;
                                    pendingMergeLabels(pendingMergeLabelsMaximumIndex,1) = labels(x+dx, y+dy, z+dz);
                                    pendingMergeLabels(pendingMergeLabelsMaximumIndex,2) = magnitudeImage(x+dx, y+dy, z+dz);
                                    pendingMergeLabels(pendingMergeLabelsMaximumIndex,3) = unwrappedPhaseImage(x+dx, y+dy, z+dz);
                                    pendingMergeLabels(pendingMergeLabelsMaximumIndex,4) = 1;
                                end

                            end

                        end

                    end

                end
            end
        end

        % Update phase values of pixels with same magitudes.
        for j = 1:pendingMergeLabelsMaximumIndex
            if (pendingMergeLabels(j,4) > 1)
                pendingMergeLabels(j,3) = pendingMergeLabels(j,3) / pendingMergeLabels(j,4);
                pendingMergeLabels(j,4) = 1;
            end
        end

        % Check if neighbors were found.
        if (maxMagnitudeLabel ~= 0)

            % Merge with cluster if only one neighboring cluster was found.
            if(pendingMergeLabelsMaximumIndex == 1)

                % Unwrap the current pixel depending on the phase values of its neighbor with maximum magnitude in cluster.
                offset = estimatePhaseOffset(phase, pendingMergeLabels(1,3));
                phase = phase + offset;

                % Add pixel to existing class of pixels, same like first neighbor.
                unwrappedPhaseImage(x,y,z) = phase;
                labels(x,y,z) = pendingMergeLabels(1,1);

                % Add this label to list.
                % Get node index.
                nodeIndex = ((z-1) * y_max + (y-1)) * x_max + (x-1) + 1;
                % Node is successor of current tail node.
                labelListsNodes(labelListsTailNodes(pendingMergeLabels(1,1))) = nodeIndex;
                % Node is new tail node.
                labelListsTailNodes(pendingMergeLabels(1,1)) = nodeIndex;
                % Add magnitude to weight of this list.
                labelListsWeights(pendingMergeLabels(1,1)) = labelListsWeights(pendingMergeLabels(1,1)) + magnitude;

            else

                % Get weights of all pending lists.
                for j = 1:pendingMergeLabelsMaximumIndex
                    pendingMergeLabels(j,2) = labelListsWeights(pendingMergeLabels(j,1));
                end

                % Sort list of pending merge labels by their weights.
                pendingMergeLabels = sortrows(pendingMergeLabels, [-2,3]);

                % Unwrap the current pixel depending on the phase values of its neighbor with maximum magnitude in cluster with maximum weight.
                offset = estimatePhaseOffset(phase, pendingMergeLabels(1,3));
                phase = phase + offset;

                % Add pixel to existing neighboring cluster of pixels with maximum weight.
                unwrappedPhaseImage(x,y,z) = phase;
                labels(x,y,z) = pendingMergeLabels(1,1);

                % Add this label to list.
                % Get node index.
                nodeIndex = ((z-1) * y_max + (y-1)) * x_max + (x-1) + 1;
                % Node is successor of current tail node.
                labelListsNodes(labelListsTailNodes(pendingMergeLabels(1,1))) = nodeIndex;
                % Node is new tail node.
                labelListsTailNodes(pendingMergeLabels(1,1)) = nodeIndex;
                % Add magnitude to weight of this list.
                labelListsWeights(pendingMergeLabels(1,1)) = labelListsWeights(pendingMergeLabels(1,1)) + magnitude;

                % Merge all clusters that were connected by the new pixel.
                for j = 2:pendingMergeLabelsMaximumIndex

                    % This phase offset is calculated for the connecting pixels, but applied to the total adjacent cluster j.
                    offset = estimatePhaseOffset(pendingMergeLabels(j,3), phase);

                    % Traverse all pixels of cluster.
                    % Go to first node.
                    currentNodeIndex = labelListsHeadNodes(pendingMergeLabels(j,1));

                    % Traverse all nodes. Continue as long as there is a successor.
                    while(true)

                        % Get pixel coordinates of successor.
                        x_succ = mod(currentNodeIndex-1,x_max)+1;
                        y_succ = floor(mod(currentNodeIndex-1,x_max*y_max)/(x_max))+1;
                        z_succ = floor((currentNodeIndex-1)/(x_max*y_max))+1;

                        % Adapt label id of merged cluster j.
                        labels(x_succ,y_succ,z_succ) = pendingMergeLabels(1,1);

                        % Apply phase offset to all pixels of cluster j.
                        unwrappedPhaseImage(x_succ,y_succ,z_succ) = unwrappedPhaseImage(x_succ,y_succ,z_succ) + offset;

                        % Go to successor.
                        currentNodeIndex = labelListsNodes(currentNodeIndex);

                        % Stop if there is no successor.
                        if(currentNodeIndex == 0)
                            break; % Mimic do-while-loop.
                        end
                    end

                    % Add list to neighboring cluster with maximum weight.
                    % Head of added list is new successor of maximum cluster's list's tail.
                    labelListsNodes(labelListsTailNodes(pendingMergeLabels(1,1))) = labelListsHeadNodes(pendingMergeLabels(j,1));

                    % Tail of maximum cluster's list is tail of added list now.
                    labelListsTailNodes(pendingMergeLabels(1,1)) = labelListsTailNodes(pendingMergeLabels(j,1));

                    % Add weights of merged lists.
                    labelListsWeights(pendingMergeLabels(1,1)) = labelListsWeights(pendingMergeLabels(1,1)) + labelListsWeights(pendingMergeLabels(j,1));

                    % Added list is no longer existing as independent list.
                    labelListsHeadNodes(pendingMergeLabels(j,1)) = 0;
                    labelListsTailNodes(pendingMergeLabels(j,1)) = 0;

                end

            end

        else

            % There is no unwrapped neighbor.
            % Add new label.
            currentMaxLabelId          = currentMaxLabelId + 1;
            unwrappedPhaseImage(x,y,z) = phase;
            labels(x,y,z)              = currentMaxLabelId;

            % Create new list for this label.
            % Get node index.
            nodeIndex = ((z-1) * y_max + (y-1)) * x_max + (x-1) + 1;

            % Node is head node.
            labelListsHeadNodes(currentMaxLabelId) = nodeIndex;
            % Node is tail node.
            labelListsTailNodes(currentMaxLabelId) = nodeIndex;

            % Magnitude of pixel is weight of list.
            labelListsWeights(currentMaxLabelId) = magnitude;

        end

    end

end



function list = createSortedListOfPixels( magnitudeImage, phaseImage )
%CREATESORTEDLISTOFPIXELS Create list of all pixels sorted by magnitude.
%
%   createSortedListOfPixels( magnitudeImage, phaseImage )
%
%   Sort pixels descending by magnitude. Return list of pixels. If there
%   are pixels with equal magnitude values, they will be sorted by phase
%   additionally. This guarantees that the processing order does not depend
%   on the pixel position. Therefore, rotated images will return the same
%   unwrapping result.


    %% Get image dimensions.
    [x_max, y_max, z_max] = size(magnitudeImage);

    %% Initialize list of all pixels.
    % column 1: magnitude values
    % column 2: phase values
    % column 3: x coordinates
    % column 4: y coordinates
    % column 5: z coordinates
    list = zeros(x_max*y_max*z_max,6);

    %% Copy pixel data to list.
    for z = 1:z_max
        for y = 1:y_max
            for x = 1:x_max

                % Calculate index of pixel.
                index = ((z-1) * y_max + (y-1)) * x_max + (x-1) + 1;

                % Copy data to list.
                list(index,1) = magnitudeImage(x,y,z);
                list(index,2) = phaseImage(x,y,z);
                list(index,3) = x;
                list(index,4) = y;
                list(index,5) = z;

            end
        end
    end

    %% Sort list.
    % Descending by magnitude values, sort by phase to make algorithm independent from pixel locations.
    list = sortrows(list,[-1,2]);

end



function offset = estimatePhaseOffset( phaseToUnwrap, fixedPhase )
%ESTIMATEPHASEOFFSET Return offset to unwrapped phase.
%
%   estimatePhaseOffset( phaseToUnwrap, fixedPhase )
%
%   Estimate and return offset to unwrap 'phaseToUnwrap' based on
%   'fixedPhase'. This offset is always a multiple of 2*pi. All values are
%   given in rad.


    %% Parameters
    % Phase will be unwrapped if absolute difference is bigger than
    % threshold. Algorithm seems to work robustly for a threshold of pi.
    threshold = pi;

    %% Estimation
    % Offset for phase unwrapping.
    offset = 0;

    % Unwrap phase of pixel.
    while (phaseToUnwrap + offset - fixedPhase < -threshold)
        offset = offset + 2 * pi;
    end

    while (phaseToUnwrap + offset - fixedPhase > threshold);
        offset = offset - 2 * pi;
    end

end
