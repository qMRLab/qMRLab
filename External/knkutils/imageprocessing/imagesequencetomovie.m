function imagesequencetomovie(dir0,file0,framerate)

% function imagesequencetomovie(dir0,file0,framerate)
%
% <dir0> is a directory containing image files.
%   can also be a 3D or 4D uint8 matrix of images.
% <file0> is output movie file to write
% <framerate> is the frames per second for the output movie
%
% Use QTWriter to make a QuickTime movie from the images in <dir0>.
%
% example:
% mkdirquiet('temp');
% for p=1:90
%   imwrite(uint8(255*rand(100,100,3)),sprintf('temp/images%03d.png',p));
% end
% imagesequencetomovie('temp','temp.mov',30);

% init the movie
mov = QTWriter(file0);
mov.FrameRate = framerate;

% if a directory, load in the images
if ischar(dir0)
  dir0 = imreadmulti([dir0 '/*']);
end

% if 3D grayscale images, reshape them..
if size(dir0,4)==1
  dir0 = permute(dir0,[1 2 4 3]);
end

% write the movie
writeMovie(mov,dir0);

% finish up
close(mov);
