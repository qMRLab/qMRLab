function S_str = cell2str_v3(S,delimiter)
% S_str = cell2str_v3(S)
% Example: S_str = cell2str_v3(varargin)
if nargin<2, delimiter=', '; end
S = S(:)';
S_str = ''; for k=S, if isnumeric(k{1}), S_str =[S_str ', [' num2str(k{:}) ']']; else S_str =[S_str delimiter sprintf('%s',k{:})]; end; end
%S_str = S_str(3:end);