% =========================================================================
% FUNCTION
% scd_scheme_display.m
%
% INPUT
% gradient_vectors			nx3
% OR scheme             nx9
%
% OUTPUT
% (-)
%
% EXAMPLE
%   scd_bvecs_display(scheme)
%
% EXAMPLE 2
%   scd_bvecs_display(scd_schemefile_read('qspace.scheme'))
%
% COMMENTS
% Julien Cohen-Adad 2009-10-02
% =========================================================================
%
% See also scd_schemefile_read
function scd_scheme_display(gradient_vectors,display_voronoi)

%% Check if gradient_vectors is a schemefile
if isstr(gradient_vectors)
    error('Input should be a matrix not a filename. Use scd_schemefile_read')
end

if size(gradient_vectors,2)>3
    gradient_vectors = gradient_vectors(:,1:3).*repmat(gradient_vectors(:,4),[1 3]);
end

% gradient_vectors=gradient_vectors/max(max(gradient_vectors));
gradient_norm = sqrt(gradient_vectors(:,1).^2+gradient_vectors(:,2).^2+gradient_vectors(:,3).^2);
display_3d = 0;
colorindex = jet(1000);
colorprct = max(1,round(gradient_norm/max(gradient_norm)*1000));
color = colorindex(colorprct,:);
% display gradients
if display_3d
	for i = 1:size(gradient_vectors,1)
		plot3(gradient_vectors(i,1),gradient_vectors(i,2),gradient_vectors(i,3),'.','MarkerSize',10,'Color',color(i,:))
		hold on
	end
	xlabel('X')
	ylabel('Y')
	zlabel('Z')
	axis vis3d;
	view(3), axis equal
	axis on, grid
	rotate3d on;
end


% display gradients
subplot(2,2,1)
for i = 1:size(gradient_vectors,1)
    plot3(gradient_vectors(i,1),gradient_vectors(i,2),gradient_vectors(i,3),'.','MarkerSize',10,'Color',color(i,:))
    hold on
end
xlabel('X')
ylabel('Y')
zlabel('Z')
axis vis3d;
view(3), axis equal
axis on, grid
rotate3d on;
view(0,0)
lim = max(max(abs([xlim; ylim; zlim])));
xlim([-lim lim]); ylim([-lim lim]); zlim([-lim lim]);
 

subplot(2,2,2)
for i = 1:size(gradient_vectors,1)
    plot3(gradient_vectors(i,1),gradient_vectors(i,2),gradient_vectors(i,3),'.','MarkerSize',10,'Color',color(i,:))
    hold on
end
xlabel('X')
ylabel('Y')
zlabel('Z')
axis vis3d;
view(3), axis equal
axis on, grid
rotate3d on;
view(90,0)
lim = max(max(abs([xlim; ylim; zlim])));
xlim([-lim lim]); ylim([-lim lim]); zlim([-lim lim]);

subplot(2,2,3)
for i = 1:size(gradient_vectors,1)
    plot3(gradient_vectors(i,1),gradient_vectors(i,2),gradient_vectors(i,3),'.','MarkerSize',10,'Color',color(i,:))
    hold on
end
xlabel('X')
ylabel('Y')
zlabel('Z')
axis vis3d;
view(3), axis equal
axis on, grid
rotate3d on;
view(0,90)
lim = max(max(abs([xlim; ylim; zlim])));
xlim([-lim lim]); ylim([-lim lim]); zlim([-lim lim]);

% % Voronoi transformation
if exist('display_voronoi','var') && display_voronoi 
	X = gradient_vectors;
	h_fig = figure('name','Voronoi');
	[V,C] = voronoin(X);
	K = convhulln(X);
	d = [1 2 3 1];       % Index into K
	for i = 1:size(K,1)
	   j = K(i,d);
	   h(i) = patch(X(j,1),X(j,2),X(j,3),i,'FaceColor','white','FaceLighting','phong','EdgeColor','black');
	end
	hold off
	view(2)
	axis off
	axis equal
	colormap(gray);
	% title('One cell of a Voronoi diagram')
	axis vis3d;
	rotate3d on;
	print(h_fig,'-dpng',strcat(['fig_voronoi.png']));
end
