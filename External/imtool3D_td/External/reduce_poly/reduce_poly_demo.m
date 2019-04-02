% Demo of Polygon simplification to a fixed number of vertices
%
% Example:
% reduce_poly
%
% Coded by: Peter Bone

% Load an image
I = imread('airplane.jpg');
subplot(2,2,1)
imshow(I)

% Convert to binary image
subplot(2,2,2)
BW = im2bw(I, 0.5);
BW = imclose(BW, strel('disk',2,8));
imshow(BW)

% Use contour to obtain a polygon around the object
subplot(2,2,3)
[C,h] = contour(BW, [0 0]);
s = size(C);
poly = C(:,2:C(2,1));

% Show the polygon
subplot(2,2,3)
poly_draw = [poly poly(:,1)]; % add first vertex to end for closed polygon
plot(poly_draw(1,:), poly_draw(2,:), '.-')
axis equal ij

% Reduce polygon and show
subplot(2,2,4)
poly2 = reduce_poly(poly, 11);
poly_draw = [poly2 poly2(:,1)];
plot(poly_draw(1,:), poly_draw(2,:), '.-')
axis equal ij